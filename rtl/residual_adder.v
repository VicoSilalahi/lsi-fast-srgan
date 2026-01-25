module residual_adder #(
    parameter DATA_WIDTH = 32
) (
    input  wire signed [DATA_WIDTH-1:0] stream_in,
    input  wire signed [DATA_WIDTH-1:0] identity_in,
    output wire signed [DATA_WIDTH-1:0] data_out
);
    // Standard signed addition. 
    // Note: In a deep GAN, you might want to add saturation logic here
    // to prevent wrapping if the sum exceeds the DATA_WIDTH range.
    assign data_out = stream_in + identity_in;
endmodule
