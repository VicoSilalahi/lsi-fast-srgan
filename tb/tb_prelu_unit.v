module tb_prelu_unit;
    parameter DATA_WIDTH = 32;
    parameter FRAC_WIDTH = 24;

    reg signed [DATA_WIDTH-1:0] data_in, slope;
    wire signed [DATA_WIDTH-1:0] data_out;

    prelu_unit #(DATA_WIDTH, FRAC_WIDTH) uut (
        .data_in(data_in),
        .slope(slope),
        .data_out(data_out)
    );

    initial begin
        // dumpfile and dumpvars for waveform viewing
        $dumpfile("sim/tb_prelu_unit.vcd");
        $dumpvars(0, tb_prelu_unit);

        slope   = 32'h00200000;  // 0.125 in Q8.24

        // Test Positive
        data_in = 32'h00800000;
        #10;  // 0.5
        $display("Positive In: %h | Out: %h (Exp: 00800000)", data_in, data_out);

        // Test Negative
        data_in = 32'hFF800000;
        #10;  // -0.5
        // Expected: -0.5 * 0.125 = -0.0625 (Hex: FFF00000)
        $display("Negative In: %h | Out: %h (Exp: FFF00000)", data_in, data_out);

        $finish;
    end
endmodule
