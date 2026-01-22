// ================================================================================
// Module: Parametric ReLU Activation Function
// Description: This module implements the Parametric ReLU (PReLU) activation
//              function. It takes a fixed-point input and applies the PReLU
//              activation, which allows for a learnable slope for negative inputs.
//              The output is also in fixed-point format.
//              For fixed leaky ReLU, set the slope parameter to a constant
//              value. (in controller)
// --------------------------------------------------------------------------------
// Notes:
// - Fixed-point representation is used for input, slope, and output.
// - The module assumes that the input and slope are provided in
//   signed fixed-point format with DATA_WIDTH bits, where FRAC_WIDTH bits
//   represent the fractional part.
// - The output is also in signed fixed-point format with DATA_WIDTH bits.
// ================================================================================




// ================================================================================
// Module Definition
// ================================================================================
module parametric_relu #(
    parameter DATA_WIDTH = 32,
    parameter FRAC_WIDTH = 16
) (
    input  wire                         clk,
    input  wire                         rst_n,
    input  wire signed [DATA_WIDTH-1:0] in_data,  // Input Data (fixed-point)
    input  wire signed [DATA_WIDTH-1:0] slope,    // Learnable Slope Parameter
    output reg signed  [DATA_WIDTH-1:0] out_data  // Output Data
);

    // ======================================================================
    // PReLU Activation
    // ======================================================================
    reg signed [2*DATA_WIDTH-1:0] product;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_data <= 0;
            product  <= 0;
        end else begin
            if (in_data >= 0) begin
                out_data <= in_data;
            end else begin
                product  <= in_data * slope;

                // Adjust for fixed-point scaling
                out_data <= product >>> FRAC_WIDTH;
            end
        end
    end

endmodule
