// ================================================================================
// Module: 3x3 Convolution MAC Unit
// Description: This module performs a 3x3 convolution operation
//              using multiply-accumulate (MAC) operations on input
//              pixel values and weights, followed by adding a bias term.
//              pipelined for high throughput.
// ================================================================================

// ================================================================================
// Module Definition
// ================================================================================
module conv_mac_3x3 #(
    parameter DATA_WIDTH = 32,
    parameter FRAC_WIDTH = 24
) (
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire [DATA_WIDTH-1:0] p00,
    p01,
    p02,
    p10,
    p11,
    p12,
    p20,
    p21,
    p22,  // 3x3 Window Pixels
    input  wire [DATA_WIDTH-1:0] w00,
    w01,
    w02,
    w10,
    w11,
    w12,
    w20,
    w21,
    w22,  // 3x3 Weights
    input  wire [DATA_WIDTH-1:0] bias,     // Bias
    output reg  [DATA_WIDTH-1:0] conv_out  // Convolution Output
);

  wire signed [2*DATA_WIDTH-1:0] mult00, mult01, mult02,
                                 mult10, mult11, mult12,
                                 mult20, mult21, mult22; // Multiplication Results
  reg signed [2*DATA_WIDTH-1:0] sum;  // Accumulation Result

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
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      sum <= 0;
      conv_out <= 0;
    end else begin
      sum <= (mult00 + mult01 + mult02
      + mult10 + mult11 + mult12
      + mult20 + mult21 + mult22) >>> FRAC_WIDTH; // Adjust for fixed-point

      conv_out <= sum[DATA_WIDTH-1:0] + bias;  // Add bias
    end
  end

endmodule
