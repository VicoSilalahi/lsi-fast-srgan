// ============================================================================
// Module: Line Buffer Testbench
// Description: Verifies the 3x3 Line Buffer with a 4x4 image configuration.
//              Tests zero-padding muxing at boundaries.
// ============================================================================

`timescale 1ns / 1ps

module tb_line_buffer_3x3_rgb;

    parameter DATA_WIDTH = 32;
    parameter IMG_WIDTH = 4;

    reg clk;
    reg rst_n;
    reg valid_in;
    reg signed [DATA_WIDTH-1:0] r_in, g_in, b_in;

    wire signed [DATA_WIDTH-1:0] win_r        [0:8];
    wire signed [DATA_WIDTH-1:0] win_g        [0:8];
    wire signed [DATA_WIDTH-1:0] win_b        [0:8];
    wire                         window_valid;

    // Instantiate DUT
    line_buffer_3x3_rgb #(
        .DATA_WIDTH(DATA_WIDTH),
        .IMG_WIDTH (IMG_WIDTH)
    ) uut (
        .clk(clk),
        .rst_n(rst_n),
        .r_in(r_in),
        .g_in(g_in),
        .b_in(b_in),
        .valid_in(valid_in),
        .win_r(win_r),
        .win_g(win_g),
        .win_b(win_b),
        .window_valid(window_valid)
    );

    // Clock Generation
    always #5 clk = ~clk;

    integer i;
    integer out_count = 0;

    initial begin
        // Vardump for waveform viewing
        $dumpfile("sim/tb_line_buffer_3x3_rgb.vcd");
        $dumpvars(0, tb_line_buffer_3x3_rgb);
        // 1. Initialize
        clk = 0;
        rst_n = 0;
        valid_in = 0;
        r_in = 0;
        g_in = 0;
        b_in = 0;

        // 2. Reset
        #10 rst_n = 1;
        #10;

        $display("=============================================================");
        $display("Testing Line Buffer: %0dx%0d Configuration", IMG_WIDTH, IMG_WIDTH);
        $display("Vertical Padding: -1 | Horizontal Padding: 0 (from Mux)");
        $display("=============================================================");

        // 3. Feed Top Padding Row (Row of -1s)
        feed_row(-1);

        // 4. Feed Image Data (1 to 16 for 4x4)
        for (i = 1; i <= (IMG_WIDTH * IMG_WIDTH); i = i + 1) begin
            feed_pixel(i);
        end

        // 5. Feed Bottom Padding Row (Row of -1s)
        feed_row(-1);

        // 6. Wait for the output monitor to signal completion
        wait (out_count == (IMG_WIDTH * IMG_WIDTH));

        #20;
        $display("=============================================================");
        $display("Test Complete: Processed %0d valid windows.", out_count);
        $finish;
    end

    // Tasks
    task feed_pixel;
        input signed [31:0] val;
        begin
            @(posedge clk);
            valid_in <= 1;
            r_in <= val;
            g_in <= val;
            b_in <= val;
        end
    endtask

    task feed_row;
        input signed [31:0] val;
        integer j;
        begin
            for (j = 0; j < IMG_WIDTH; j = j + 1) begin
                feed_pixel(val);
            end
        end
    endtask

    // Visualization Monitor
    always @(negedge clk) begin
        // Only display if valid and we haven't exceeded the image size
        if (window_valid && out_count < (IMG_WIDTH * IMG_WIDTH)) begin
            out_count = out_count + 1;
            $display("Time: %0t | Center: %2d (Window #%0d)", $time, win_r[4], out_count);
            $display("   [%2d][%2d][%2d]", win_r[0], win_r[1], win_r[2]);
            $display("   [%2d][%2d][%2d]", win_r[3], win_r[4], win_r[5]);
            $display("   [%2d][%2d][%2d]", win_r[6], win_r[7], win_r[8]);
            $display("--------------------------");
        end
    end

endmodule
