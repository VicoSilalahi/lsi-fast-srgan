module prelu_unit #(
    parameter DATA_WIDTH = 32,
    parameter FRAC_WIDTH = 24
) (
    input  wire signed [DATA_WIDTH-1:0] data_in,
    input  wire signed [DATA_WIDTH-1:0] slope,
    output wire signed [DATA_WIDTH-1:0] data_out
);
    wire signed [63:0] product = data_in * slope;
    wire signed [DATA_WIDTH-1:0] scaled_neg;

    // Rescale the product back to Q format
    assign scaled_neg = product[DATA_WIDTH+FRAC_WIDTH-1 : FRAC_WIDTH];

    // Select based on sign bit (MSB)
    assign data_out   = (data_in[DATA_WIDTH-1] == 1'b0) ? data_in : scaled_neg;
endmodule
