module tb_mac_unit_3ch;
    parameter DATA_WIDTH = 32;
    parameter FRAC_WIDTH = 24;

    reg signed [DATA_WIDTH-1:0] win_r[0:8], win_g[0:8], win_b[0:8];
    reg signed  [DATA_WIDTH-1:0] weights[0:26];
    reg signed  [DATA_WIDTH-1:0] bias;
    wire signed [DATA_WIDTH-1:0] out;

    mac_unit_3ch #(DATA_WIDTH, FRAC_WIDTH) uut (
        .win_r(win_r),
        .win_g(win_g),
        .win_b(win_b),
        .weights(weights),
        .bias(bias),
        .out(out)
    );

    integer i;
    initial begin
        // dumpfile and dumpvars for waveform viewing
        $dumpfile("sim/tb_mac_unit_3ch.vcd");
        $dumpvars(0, tb_mac_unit_3ch);

        // Initialize weights to 0.1 (Q8.24) and pixels to 1.0 (Q8.24)
        bias = 32'h00000000;
        for (i = 0; i < 9; i = i + 1) begin
            win_r[i] = 32'h01000000;
            win_g[i] = 32'h01000000;
            win_b[i] = 32'h01000000;
        end
        // Set all 27 weights to approx 0.01 (Hex: 00028F5C)
        for (i = 0; i < 27; i = i + 1) weights[i] = 32'h00028F5C;

        #10;
        $display("MAC Output: %h", out);  // Expected: 27 * 0.01 = 0.27 (Hex: 00451EB8)
        $finish;
    end
endmodule
