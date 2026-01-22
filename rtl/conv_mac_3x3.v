// ================================================================================
// Module: 3x3 Convolution MAC Unit
// Description: Performs a 3x3 convolution operation using
//              multiply-accumulate (MAC) operations with fixed-point
//              arithmetic. The module takes a 3x3 window of input pixels
//              and a 3x3 kernel of weights, computes the convolution sum,
//              adds a bias, and outputs the result. The design is
//              pipelined for high throughput.
// --------------------------------------------------------------------------------
// Notes:
// - Fixed-point representation is used for inputs, weights, bias, and output.
// - The module assumes that the input pixels and weights are provided in
//   signed fixed-point format with DATA_WIDTH bits, where FRAC_WIDTH bits
//   represent the fractional part.
// - The output is also in signed fixed-point format with DATA_WIDTH bits.
// ================================================================================




// ================================================================================
// Module Definition
// ================================================================================
module conv_mac_3x3 #(
    parameter DATA_WIDTH = 32,
    parameter FRAC_WIDTH = 16
) (
    input  wire                         clk,
    input  wire                         rst_n,
    input  wire signed [DATA_WIDTH-1:0] p00,
    input  wire signed [DATA_WIDTH-1:0] p01,
    input  wire signed [DATA_WIDTH-1:0] p02,
    input  wire signed [DATA_WIDTH-1:0] p10,
    input  wire signed [DATA_WIDTH-1:0] p11,
    input  wire signed [DATA_WIDTH-1:0] p12,
    input  wire signed [DATA_WIDTH-1:0] p20,
    input  wire signed [DATA_WIDTH-1:0] p21,
    input  wire signed [DATA_WIDTH-1:0] p22,      // 3x3 Window Pixels
    input  wire signed [DATA_WIDTH-1:0] w00,
    input  wire signed [DATA_WIDTH-1:0] w01,
    input  wire signed [DATA_WIDTH-1:0] w02,
    input  wire signed [DATA_WIDTH-1:0] w10,
    input  wire signed [DATA_WIDTH-1:0] w11,
    input  wire signed [DATA_WIDTH-1:0] w12,
    input  wire signed [DATA_WIDTH-1:0] w20,
    input  wire signed [DATA_WIDTH-1:0] w21,
    input  wire signed [DATA_WIDTH-1:0] w22,      // 3x3 Weights
    input  wire signed [DATA_WIDTH-1:0] bias,     // Bias (fixed-point)
    output reg signed  [DATA_WIDTH-1:0] conv_out  // Convolution Output (fixed-point)
);

  // Accumulator width (product width = 2*DATA_WIDTH)
  localparam ACC_WIDTH = 2 * DATA_WIDTH;

  wire signed [ACC_WIDTH-1:0] mult00, mult01, mult02,
                              mult10, mult11, mult12,
                              mult20, mult21, mult22; // Multiplication Results
  reg signed [ACC_WIDTH-1:0] sum;  // Accumulation Result
  reg signed [ACC_WIDTH-1:0] rounded;  // Rounding register (declared at module scope)

  // ======================================================================
  // Multiplications
  // ======================================================================
  assign mult00 = $signed(p00) * $signed(w00);
  assign mult01 = $signed(p01) * $signed(w01);
  assign mult02 = $signed(p02) * $signed(w02);
  assign mult10 = $signed(p10) * $signed(w10);
  assign mult11 = $signed(p11) * $signed(w11);
  assign mult12 = $signed(p12) * $signed(w12);
  assign mult20 = $signed(p20) * $signed(w20);
  assign mult21 = $signed(p21) * $signed(w21);
  assign mult22 = $signed(p22) * $signed(w22);

  // ======================================================================
  // Accumulation
  // ======================================================================
  // Simple pipeline: multiply -> accumulate -> round->shift -> add bias
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      sum <= 0;
      conv_out <= 0;
    end else begin
      // Accumulate full-precision products
      sum <= mult00 + mult01 + mult02 + mult10 + mult11 + mult12 + mult20 + mult21 + mult22;

      // Rounding and shifting to convert fixed-point accumulation back to DATA_WIDTH
      // Add half LSB for rounding if FRAC_WIDTH > 0
      if (FRAC_WIDTH > 0) begin
        // rounding value: 1 << (FRAC_WIDTH-1)
        rounded = sum + ({{(ACC_WIDTH - FRAC_WIDTH) {1'b0}}, 1'b1} << (FRAC_WIDTH - 1));
        // Arithmetic right shift
        conv_out <= (rounded >>> FRAC_WIDTH) + bias;
      end else begin
        conv_out <= sum[DATA_WIDTH-1:0] + bias;
      end
    end
  end

endmodule
