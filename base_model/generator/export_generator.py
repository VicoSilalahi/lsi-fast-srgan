import torch
import torch.nn as nn
import numpy as np
import os

import torch.onnx

# ============================================================================
# Fixed-point defaults (Q8.24)
# ============================================================================
INT_BITS = 8
FRAC_BITS = 24
TOTAL_BITS = INT_BITS + FRAC_BITS
SHIFT = FRAC_BITS
SCALE = 1 << SHIFT
SIGN_MASK = 1 << (TOTAL_BITS - 1)
TWO_COMP_MASK = 1 << TOTAL_BITS


# ============================================================================
# Configuration and Seeding
# ============================================================================
class Config:
    def __init__(self):
        self.n_filters = 64
        self.n_layers = 8


def set_seeds():
    torch.manual_seed(42)
    np.random.seed(42)


# ============================================================================
# Model
# ============================================================================
class ResidualBlock(nn.Module):
    def __init__(self, in_channels, out_channels):
        super().__init__()
        self.conv1 = nn.Conv2d(in_channels, out_channels, 3, 1, 1, bias=False)
        self.bn1 = nn.BatchNorm2d(out_channels)
        self.relu1 = nn.PReLU()
        self.conv2 = nn.Conv2d(in_channels, out_channels, 3, 1, 1, bias=False)
        self.bn2 = nn.BatchNorm2d(out_channels)

    def forward(self, x):
        y = self.relu1(self.bn1(self.conv1(x)))
        return self.bn2(self.conv2(y)) + x


class UpSamplingBlock(nn.Module):
    def __init__(self, config):
        super().__init__()
        self.conv = nn.Conv2d(config.n_filters, config.n_filters * 4, 3, 1, 1)
        self.phase_shift = nn.PixelShuffle(upscale_factor=2)
        self.relu = nn.PReLU()

    def forward(self, x):
        return self.relu(self.phase_shift(self.conv(x)))


class Generator(nn.Module):
    def __init__(self, config):
        super().__init__()
        self.neck = nn.Sequential(
            nn.Conv2d(3, config.n_filters, 3, 1, 1),
            nn.PReLU(),
        )

        self.stem = nn.Sequential(
            *[
                ResidualBlock(config.n_filters, config.n_filters)
                for _ in range(config.n_layers)
            ]
        )

        self.bottleneck = nn.Sequential(
            nn.Conv2d(config.n_filters, config.n_filters, 3, 1, 1, bias=False),
            nn.BatchNorm2d(config.n_filters),
        )

        self.upsampling = nn.Sequential(
            UpSamplingBlock(config),
            UpSamplingBlock(config),
        )

        self.head = nn.Sequential(
            nn.Conv2d(config.n_filters, 3, 3, 1, 1),
            nn.Tanh(),
        )

    def forward(self, x):
        residual = self.neck(x)
        x = self.stem(residual)
        x = self.bottleneck(x) + residual
        x = self.upsampling(x)
        return self.head(x)


# ============================================================================
# Helper Function
# ============================================================================
def fuse_bn_sequential(block):
    """Fuses BatchNorm layers into preceding Conv layers for hardware optimization."""
    stack = []
    for m in block.children():
        if isinstance(m, nn.Conv2d):
            stack.append(m)
        elif isinstance(m, nn.BatchNorm2d):
            if stack and isinstance(stack[-1], nn.Conv2d):
                conv = stack.pop()
                bn = m
                with torch.no_grad():
                    mu = bn.running_mean
                    var = bn.running_var
                    gamma = bn.weight
                    beta = bn.bias
                    eps = bn.eps
                    w = conv.weight
                    b = conv.bias if conv.bias is not None else torch.zeros_like(mu)

                    denom = torch.rsqrt(var + eps)
                    scale = gamma * denom
                    scale_w = scale.view(-1, 1, 1, 1)

                    conv.weight.data.mul_(scale_w)
                    conv.bias = nn.Parameter((b - mu) * scale + beta)
                m = nn.Identity()
        elif isinstance(m, nn.Sequential) or isinstance(m, ResidualBlock):
            fuse_bn_sequential(m)
    return block


def float_to_hex(value, integer_bits=8, fraction_bits=24):
    """Converts float to Q8.24 32-bit Hex String."""
    scale = 1 << fraction_bits
    int_val = int(value * scale)
    max_val = (1 << (integer_bits + fraction_bits - 1)) - 1
    min_val = -(1 << (integer_bits + fraction_bits - 1))

    if int_val > max_val:
        int_val = max_val
    if int_val < min_val:
        int_val = min_val

    if int_val < 0:
        int_val = (1 << 32) + int_val
    return f"{int_val:08X}"


def save_tensor_to_hex(tensor, filename):
    data = tensor.detach().cpu().numpy().flatten()
    with open(filename, "w") as f:
        for val in data:
            f.write(
                float_to_hex(val, integer_bits=INT_BITS, fraction_bits=FRAC_BITS) + "\n"
            )
    print(f"Saved {len(data)} entries to {filename}")


def debug_hook(module, input, output):
    """Prints sum of layer output for debugging."""
    if isinstance(output, torch.Tensor):
        val = output.detach().sum().item()
        print(f"[DEBUG PyTorch] Layer {module.__class__.__name__}: Sum = {val:.4f}")


# ============================================================================
# Main Script
# ============================================================================
if __name__ == "__main__":
    set_seeds()

    # Load Model
    config = Config()
    model = Generator(config)

    # Load Weights from Back Propagation/Training done in Kaggle
    path = "generator_epoch_9500.pt"
    if os.path.exists(path):
        print(f"Loading weights from {path}...")
        model.load_state_dict(torch.load(path, map_location="cpu"))
    else:
        print("WARNING: Checkpoint not found. Using random weights!")

    # print(model.eval())

    # model.train()
    # dummy_input = torch.randn(1, 3, 8, 8)
    # torch.onnx.export(
    #     model,
    #     dummy_input,
    #     "generator.onnx",
    #     input_names=["input"],
    #     output_names=["output"],
    #     opset_version=11,
    #     do_constant_folding=False,
    # )

    model.eval()
    print("Fusing Batch Norm...")
    fuse_bn_sequential(model)

    # torch.onnx.export(
    #     model,
    #     dummy_input,
    #     "generator_fbn.onnx",
    #     input_names=["input"],
    #     output_names=["output"],
    #     opset_version=11,
    # )

    print("Registering Debug Hooks")
    model.neck[0].register_forward_hook(debug_hook)  # Conv
    model.neck[1].register_forward_hook(debug_hook)  # PReLU

    # Hook Stem (Residual Blocks)
    for i in range(len(model.stem)):
        model.stem[i].conv1.register_forward_hook(debug_hook)
        model.stem[i].conv2.register_forward_hook(debug_hook)
        # Hook the block output (Post-Addition)
        model.stem[i].register_forward_hook(debug_hook)

    # # Generate Input (Gradient)
    # print("Generating Gradient Input Pattern")
    # input_dummy = torch.zeros(1, 3, 8, 8)
    # for c in range(3):
    #     for y in range(8):
    #         for x in range(8):
    #             val = ((x + y) / 16.0) * 2.0 - 1.0
    #             input_dummy[0, c, y, x] = val

    # Generate Input (Colored Gradient-Somewhat dark)
    print("Generating Colored Gradient Input Pattern")
    input_dummy = torch.zeros(1, 3, 8, 8)
    for y in range(8):
        for x in range(8):
            # input_dummy[0, 0, y, x] = (x / 7.0) * 2.0 - 1.0  # R: Left to Right
            # input_dummy[0, 1, y, x] = (y / 7.0) * 2.0 - 1.0  # G: Top to Bottom
            # # input_dummy[0, 2, y, x] = ((x + y) / 14.0) * 2.0 - 1.0  # B: Diagonal

            # Red: Left to Right
            input_dummy[0, 0, y, x] = (x / 7.0) * 2.0 - 1.0
            # Green: Top to Bottom
            input_dummy[0, 1, y, x] = (y / 7.0) * 2.0 - 1.0
            # Blue: Bottom-Right to Top-Left
            input_dummy[0, 2, y, x] = (((7 - x) + (7 - y)) / 14.0) * 2.0 - 1.0

    # Run Inference and Save Golden Data
    with torch.no_grad():
        output_dummy = model(input_dummy)

    if not os.path.exists("mem_export"):
        os.makedirs("mem_export")

    save_tensor_to_hex(input_dummy, "mem_export/input_image.hex")
    save_tensor_to_hex(output_dummy, "mem_export/output_image_gold.hex")

    # Export Weights to Hex
    print("Exporting Weights")
    for name, param in model.named_parameters():
        clean_name = name.replace(".", "_")
        filename = f"mem_export/{clean_name}.hex"
        save_tensor_to_hex(param, filename)

    print("Files saved in 'mem_export/' folder")
