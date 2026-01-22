// ================================================================================
// Testbench for Parametric ReLU (PReLU) Module
// ================================================================================

`timescale 1ns / 1ps

// ================================================================================
// Testbench Module Definition
// ================================================================================
module tb_parametric_relu;

    // Parameters
    localparam DATA_WIDTH = 32;
    localparam FRAC_WIDTH = 16;

    localparam ONE = 1 << FRAC_WIDTH;  // Fixed-point representation of 1.0

    // Ports
    reg clk;
    reg rst_n;
    reg [DATA_WIDTH-1:0] in_data;
    reg [DATA_WIDTH-1:0] slope;
    wire [DATA_WIDTH-1:0] out_data;

    // Clock Generation
    initial clk = 0;
    always #5 clk = ~clk;

    parametric_relu #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC_WIDTH(FRAC_WIDTH)
    ) prelu_inst (
        .clk(clk),
        .rst_n(rst_n),
        .in_data(in_data),
        .slope(slope),
        .out_data(out_data)
    );

    // ======================================================================
    // Test Vectors
    // ======================================================================
    initial begin

        // File for waveform dump
        $dumpfile("sim/tb_parametric_relu.vcd");
        $dumpvars(0, tb_parametric_relu);

        // Initialize signals
        rst_n   = 0;
        in_data = 0;
        slope   = 1 * ONE;
        #15;
        rst_n = 1;
        #10;
        // Test positive input
        in_data = 2 * ONE;  // 2.0 Output should be 2.0
        #40;
        $display("Input: %0f, Slope: %0f, Output: %0f", $itor(in_data) / ONE, $itor(slope) / ONE,
                 $itor(out_data) / ONE);
        // Test negative input
        in_data = -1 * ONE;  // -1.0 Output should be -1.0 * slope = -1.0
        #40;
        $display("Input: %0f, Slope: %0f, Output: %0f", $itor(in_data) / ONE, $itor(slope) / ONE,
                 $itor(out_data) / ONE);
        // Test zero input
        in_data = 0 * ONE;  // 0.0
        #40;
        $display("Input: %0f, Slope: %0f, Output: %0f", $itor(in_data) / ONE, $itor(slope) / ONE,
                 $itor(out_data) / ONE);
        // Test another negative input with different slope
        slope   = 0.5 * ONE;  // Slope = 0.5 in fixed-point
        in_data = -0.5 * ONE;  // -0.5
        #40;
        $display("Input: %0f, Slope: %0f, Output: %0f", $itor(in_data) / ONE, $itor(slope) / ONE,
                 $itor(out_data) / ONE);
        // Finish simulation
        $finish;
    end

endmodule
