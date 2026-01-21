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
    $dumpfile("conv_mac_3x3_tb.vcd");
    $dumpvars(0, conv_mac_3x3_tb);

    // Initialize signals
    clk   = 0;
    rst_n = 0;
    #10;
    rst_n = 1;

    // Test Case 1
    p00   = 32'h3F800000;  // 1.0
    p01   = 32'h40000000;  // 2.0
    p02   = 32'h40400000;  // 3.0
    p10   = 32'h40800000;  // 4.0
    p11   = 32'h40A00000;  // 5.0
    p12   = 32'h40C00000;  // 6.0
    p20   = 32'h40E00000;  // 7.0
    p21   = 32'h41000000;  // 8.0
    p22   = 32'h41100000;  // 9.0

    w00   = 32'h3F800000;  // 1.0
    w01   = 32'h3F800000;  // 1.0
    w02   = 32'h3F800000;  // 1.0
    w10   = 32'h3F800000;  // 1.0
    w11   = 32'h3F800000;  // 1.0
    w12   = 32'h3F800000;  // 1.0
    w20   = 32'h3F800000;  // 1.0
    w21   = 32'h3F800000;  // 1.0
    w22   = 32'h3F800000;  // 1.0

    bias  = 32'h00000000;  // 0.0

    #20;
    $display("Test Case 1: conv_out = %h", conv_out);
    #50;
    $finish;
  end


endmodule

