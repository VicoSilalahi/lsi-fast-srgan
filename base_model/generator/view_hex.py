import numpy as np
import matplotlib.pyplot as plt
import os
# ============================================================================
# Fixed-point defaults (Q8.24)
# ============================================================================
INT_BITS = 8
FRAC_BITS = 24


class FixedPointConfig:
    def __init__(self, int_bits=None, frac_bits=None):
        if int_bits is None:
            int_bits = INT_BITS
        if frac_bits is None:
            frac_bits = FRAC_BITS
        self.int_bits = int_bits
        self.frac_bits = frac_bits
        self.total_bits = int_bits + frac_bits
        self.scale = 1 << self.frac_bits
        self.sign_bit_mask = 1 << (self.total_bits - 1)
        self.two_comp_mask = 1 << self.total_bits


# File Paths
FILE_INPUT = "mem_export/input_image.hex"
FILE_GOLDEN = "mem_export/output_image_gold.hex"
FILE_INFER = "mem_export/output_image_hardware.hex"

# Dimensions
INPUT_RES = 8
OUTPUT_RES = 32
CHANNELS = 3

# Global Fixed Point Config
FP_CONFIG = FixedPointConfig()

# ============================================================================
# Helper functions
# ============================================================================
def hex_to_float(hex_lines, fp_cfg):
    """
    Parses Hex strings into Floating point list using parameterized Q format.
    """
    values = []
    for line in hex_lines:
        line = line.strip()
        if not line:
            continue

        val_int = int(line, 16)

        # Handle 2's Complement using parameterized sign bit
        if val_int & fp_cfg.sign_bit_mask:
            val_int = val_int - fp_cfg.two_comp_mask

        # Convert to Float using parameterized scale
        values.append(val_int / float(fp_cfg.scale))
    return values


def load_image(filepath, res, fp_cfg):
    """Reads hex file and reshapes to (Height, Width, Channels)"""
    if not os.path.exists(filepath):
        print(f"Warning: File not found: {filepath}")
        return np.zeros((res, res, 3))

    with open(filepath, "r") as f:
        lines = f.readlines()

    data = hex_to_float(lines, fp_cfg)

    expected = CHANNELS * res * res
    if len(data) != expected:
        print(f"Warning: {filepath} has {len(data)} values, expected {expected}.")
        if len(data) < expected:
            data += [0] * (expected - len(data))
        else:
            data = data[:expected]

    # Reshape: (Channels, Height, Width) -> (Height, Width, Channels)
    img = np.array(data).reshape((CHANNELS, res, res))
    img = img.transpose(1, 2, 0)
    return img


def denormalize(img):
    return np.clip((img + 1.0) / 2.0, 0.0, 1.0)


# ============================================================================
# Main
# ============================================================================
def main():
    print(f"--- Visualizing HEX Data (Q{FP_CONFIG.int_bits}.{FP_CONFIG.frac_bits}) ---")

    img_in = load_image(FILE_INPUT, INPUT_RES, FP_CONFIG)
    img_gold = load_image(FILE_GOLDEN, OUTPUT_RES, FP_CONFIG)
    img_inf = load_image(FILE_INFER, OUTPUT_RES, FP_CONFIG)

    # Post-Processing
    img_in_show = denormalize(img_in)
    img_gold_show = denormalize(img_gold)

    # Applying Tanh to the raw fixed-point inference output
    img_inf_tanh = np.tanh(img_inf)
    img_inf_show = denormalize(img_inf_tanh)

    # Error Calculation
    diff = np.abs(img_gold - img_inf_tanh)
    avg_error = np.mean(diff)
    print(f"Average Pixel Error: {avg_error:.6f}")

    # Plotting
    fig, axes = plt.subplots(1, 3, figsize=(15, 6))
    titles = [
        "1. Input (Low Res)",
        "2. Golden (PyTorch)",
        f"3. Hardware Inf\n(Err: {avg_error:.4f})",
    ]
    imgs = [img_in_show, img_gold_show, img_inf_show]

    for ax, image, title in zip(axes, imgs, titles):
        ax.imshow(image, interpolation="nearest")
        ax.set_title(title)
        ax.axis("off")

    plt.tight_layout()
    plt.savefig("mem_export/comparison_view.png")
    plt.show()


if __name__ == "__main__":
    main()

