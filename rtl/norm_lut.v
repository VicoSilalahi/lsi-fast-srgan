// module norm_lut #(
//     parameter DATA_WIDTH = 32,
//     parameter FRAC_WIDTH = 24
// ) (
//     input  wire       [           7:0] addr,     // Raw 8-bit color channel
//     output reg signed [DATA_WIDTH-1:0] data_out  // Normalized output
// );
//     // Constants calculated based on parameters
//     localparam signed [DATA_WIDTH-1:0] POS_ONE = (1 << FRAC_WIDTH);
//     localparam signed [DATA_WIDTH-1:0] NEG_ONE = -POS_ONE;
//     localparam signed [DATA_WIDTH-1:0] ZERO = 0;
//
//     always @(*) begin
//         case (addr)
//             8'd0: data_out = NEG_ONE;
//             8'd127: data_out = ZERO;
//             8'd255: data_out = POS_ONE;
//             // Linear interpolation for other values: (addr - 127) * (2^(FRAC_WIDTH-7))
//             default: data_out = ($signed({1'b0, addr}) - 8'sd127) <<< (FRAC_WIDTH - 7);
//         endcase
//     end
// endmodule


module norm_lut #(
    parameter DATA_WIDTH = 32,
    parameter FRAC_WIDTH = 24
) (
    input  wire       [           7:0] addr,
    output reg signed [DATA_WIDTH-1:0] data_out
);
    // Logic: (Input - 128) * 2^(FRAC_WIDTH - 7)
    // 2^17 happens to be the multiplier that turns 1 (LSB of 8-bit) into Q8.24 scaling
    // Mapping: 0 -> -1.0;  128 -> 0.0;  64 -> -0.5
    always @(*) begin
        // subtract 128 (invert MSB) and shift
        data_out = ($signed({1'b0, addr}) - 9'sd128) <<< (FRAC_WIDTH - 7);
    end
endmodule
