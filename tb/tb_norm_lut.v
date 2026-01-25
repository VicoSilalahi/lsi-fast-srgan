`timescale 1ns / 1ps

module tb_norm_lut;
    parameter DATA_WIDTH = 32;
    parameter FRAC_WIDTH = 24;

    reg [7:0] addr;
    wire signed [DATA_WIDTH-1:0] data_out;

    norm_lut #(DATA_WIDTH, FRAC_WIDTH) uut (
        .addr(addr),
        .data_out(data_out)
    );

    initial begin
        // dumpfile and dumpvars for waveform viewing
        $dumpfile("sim/tb_norm_lut.vcd");
        $dumpvars(0, tb_norm_lut);

        $display("Testing norm_lut: 8-bit to Q%0d.%0d", DATA_WIDTH - FRAC_WIDTH, FRAC_WIDTH);

        addr = 8'd0;
        #10;
        $display("In: %d | Out: %h (Exp: FF000000)", addr, data_out);
        addr = 8'd127;
        #10;
        $display("In: %d | Out: %h (Exp: 00000000)", addr, data_out);
        addr = 8'd255;
        #10;
        $display("In: %d | Out: %h (Exp: 01000000)", addr, data_out);

        // Test a middle value (e.g., 64)
        addr = 8'd64;
        #10;
        $display("In: %d | Out: %h (Exp: FF800000)", addr, data_out);

        $finish;
    end
endmodule
