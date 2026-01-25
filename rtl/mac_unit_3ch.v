// module mac_unit_3ch #(
//     parameter DATA_WIDTH = 32,
//     parameter FRAC_WIDTH = 24
// ) (
//     // 27 Pixel Inputs (9 per channel)
//     input wire signed [DATA_WIDTH-1:0] win_r[0:8],
//     input wire signed [DATA_WIDTH-1:0] win_g[0:8],
//     input wire signed [DATA_WIDTH-1:0] win_b[0:8],
//
//     // 27 Weight Inputs (Flattened for easier port mapping)
//     input wire signed [DATA_WIDTH-1:0] weights[0:26],
//     input wire signed [DATA_WIDTH-1:0] bias,
//
//     output wire signed [DATA_WIDTH-1:0] out
// );
//     reg signed [63:0] acc;
//     integer i;
//
//     always @(*) begin
//         // Align bias to the product's fractional scale before addition
//         acc = $signed(bias) <<< FRAC_WIDTH;
//
//         for (i = 0; i < 9; i = i + 1) begin
//             acc = acc + (win_r[i] * weights[i]);  // Red Channel
//             acc = acc + (win_g[i] * weights[i+9]);  // Green Channel
//             acc = acc + (win_b[i] * weights[i+18]);  // Blue Channel
//         end
//     end
//
//     // Truncate back to the target fixed-point format
//     assign out = acc[DATA_WIDTH+FRAC_WIDTH-1 : FRAC_WIDTH];
// endmodule


module mac_unit_3ch #(
    parameter DATA_WIDTH = 32,
    parameter FRAC_WIDTH = 24
) (
    input  wire signed [DATA_WIDTH-1:0] win_r  [ 0:8],
    input  wire signed [DATA_WIDTH-1:0] win_g  [ 0:8],
    input  wire signed [DATA_WIDTH-1:0] win_b  [ 0:8],
    input  wire signed [DATA_WIDTH-1:0] weights[0:26],
    input  wire signed [DATA_WIDTH-1:0] bias,
    output wire signed [DATA_WIDTH-1:0] out
);
    reg signed [63:0] sum;
    integer i;

    // To implement "Round to Nearest", we add 0.5 in the fractional space 
    // (1 << (FRAC_WIDTH - 1)) before we perform the final shift.
    localparam signed [63:0] HALF_LSB = (1 << (FRAC_WIDTH - 1));

    always @(*) begin
        // 1. Start with Bias aligned to the 64-bit product space (Q8.48 internally)
        sum = $signed(bias) <<< FRAC_WIDTH;

        // 2. Accumulate all 27 products
        for (i = 0; i < 9; i = i + 1) begin
            sum = sum + ($signed(win_r[i]) * $signed(weights[i]));
            sum = sum + ($signed(win_g[i]) * $signed(weights[i+9]));
            sum = sum + ($signed(win_b[i]) * $signed(weights[i+18]));
        end

        // 3. Add the rounding bit
        sum = sum + HALF_LSB;
    end

    // 4. Final shift to bring Qx.48 back to Q8.24
    assign out = sum[DATA_WIDTH+FRAC_WIDTH-1 : FRAC_WIDTH];

endmodule
