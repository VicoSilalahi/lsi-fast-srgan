// ================================================================================
// Testbench for 3x3 Convolution MAC Module
// ================================================================================

`timescale 1ns / 1ps

// ================================================================================
// Testbench Module Definition
// ================================================================================
module conv_mac_3x3_tb;

  // Parameters
  localparam DATA_WIDTH = 32;
  localparam FRAC_WIDTH = 16;

  //Ports
  reg clk;
  reg rst_n;
  reg [DATA_WIDTH-1:0] p00, p01, p02, p10, p11, p12, p20, p21, p22;
  reg [DATA_WIDTH-1:0] w00, w01, w02, w10, w11, w12, w20, w21, w22;
  reg  [DATA_WIDTH-1:0] bias;
  wire [DATA_WIDTH-1:0] conv_out;

  // Clock Generation
  initial clk = 0;
  always #5 clk = ~clk;

  conv_mac_3x3 #(
      .DATA_WIDTH(DATA_WIDTH),
      .FRAC_WIDTH(FRAC_WIDTH)
  ) conv_mac_3x3_inst (
      .clk(clk),
      .rst_n(rst_n),
      .p00(p00),
      .p01(p01),
      .p02(p02),
      .p10(p10),
      .p11(p11),
      .p12(p12),
      .p20(p20),
      .p21(p21),
      .p22(p22),
      .w00(w00),
      .w01(w01),
      .w02(w02),
      .w10(w10),
      .w11(w11),
      .w12(w12),
      .w20(w20),
      .w21(w21),
      .w22(w22),
      .bias(bias),
      .conv_out(conv_out)
  );

  // ======================================================================
  // Test Vectors
  // ======================================================================
  initial begin

    // File for waveform dump
    $dumpfile("sim/tb_conv_mac_3x3.vcd");
    $dumpvars(0, conv_mac_3x3_tb);

    // Initialize signals
    clk   = 0;
    rst_n = 0;
    #10;
    rst_n = 1;

    // Test Case 1 -- all positive values and unit weights
    // Use fixed-point integers: value * (1 << FRAC_WIDTH)
    p00   = 32'h00010000;  // 1.0
    p01   = 32'h00020000;  // 2.0
    p02   = 32'h00030000;  // 3.0
    p10   = 32'h00040000;  // 4.0
    p11   = 32'h00050000;  // 5.0
    p12   = 32'h00060000;  // 6.0
    p20   = 32'h00070000;  // 7.0
    p21   = 32'h00080000;  // 8.0
    p22   = 32'h00090000;  // 9.0

    w00   = 32'h00010000;  // 1.0
    w01   = 32'h00010000;  // 1.0
    w02   = 32'h00010000;  // 1.0
    w10   = 32'h00010000;  // 1.0
    w11   = 32'h00010000;  // 1.0
    w12   = 32'h00010000;  // 1.0
    w20   = 32'h00010000;  // 1.0
    w21   = 32'h00010000;  // 1.0
    w22   = 32'h00010000;  // 1.0

    bias  = 32'h00000000;  // 0.0

    #20;
    $display("Test Case 1: conv_out (hex) = %h", conv_out);
    $display("Test Case 1: conv_out (real) = %f", $itor($signed(conv_out)) / (1 << FRAC_WIDTH));

    // Test Case 2 -- negative weights and non-zero bias
    // Set weights to -1.0 and bias to +0.5
    w00  = 32'hFFFF0000;  // -1.0 in 32-bit two's complement (scaled)
    w01  = 32'hFFFF0000;
    w02  = 32'hFFFF0000;
    w10  = 32'hFFFF0000;
    w11  = 32'hFFFF0000;
    w12  = 32'hFFFF0000;
    w20  = 32'hFFFF0000;
    w21  = 32'hFFFF0000;
    w22  = 32'hFFFF0000;
    bias = 32'h00008000;  // 0.5

    #20;
    $display("Test Case 2: conv_out (hex) = %h", conv_out);
    $display("Test Case 2: conv_out (real) = %f", $itor($signed(conv_out)) / (1 << FRAC_WIDTH));

    // Test Case 3 -- Zero inputs
    p00  = 32'h00000000;  // 0.0
    p01  = 32'h00000000;  // 0.0
    p02  = 32'h00000000;  // 0.0
    p10  = 32'h00000000;  // 0.0
    p11  = 32'h00000000;  // 0.0
    p12  = 32'h00000000;  // 0.0
    p20  = 32'h00000000;  // 0.0
    p21  = 32'h00000000;  // 0.0
    p22  = 32'h00000000;  // 0.0

    w00  = 32'h00010000;  // 1.0
    w01  = 32'h00010000;  // 1.0
    w02  = 32'h00010000;  // 1.0
    w10  = 32'h00010000;  // 1.0
    w11  = 32'h00010000;  // 1.0
    w12  = 32'h00010000;  // 1.0
    w20  = 32'h00010000;  // 1.0
    w21  = 32'h00010000;  // 1.0
    w22  = 32'h00010000;  // 1.0

    bias = 32'h00000000;  // 0.0

    #20;
    $display("Test Case 3: conv_out (hex) = %h", conv_out);
    $display("Test Case 3: conv_out (real) = %f", $itor($signed(conv_out)) / (1 << FRAC_WIDTH));

    #50;
    $finish;
  end


endmodule

