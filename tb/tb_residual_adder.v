module tb_residual_adder;
    parameter DATA_WIDTH = 32;

    reg signed [DATA_WIDTH-1:0] stream_in, identity_in;
    wire signed [DATA_WIDTH-1:0] data_out;

    residual_adder #(DATA_WIDTH) uut (
        .stream_in(stream_in),
        .identity_in(identity_in),
        .data_out(data_out)
    );

    initial begin
        // Dump waveforms
        $dumpfile("sim/tb_residual_adder.vcd");
        $dumpvars(0, tb_residual_adder);

        // 0.5 + 0.25 = 0.75
        stream_in   = 32'h00800000;
        identity_in = 32'h00400000;
        #10;
        $display("Sum: %h (Exp: 00C00000)", data_out);

        // -0.5 + 1.0 = 0.5
        stream_in   = 32'hFF800000;
        identity_in = 32'h01000000;
        #10;
        $display("Sum: %h (Exp: 00800000)", data_out);

        $finish;
    end
endmodule
