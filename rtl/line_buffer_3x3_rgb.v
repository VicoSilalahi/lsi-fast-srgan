// ============================================================================
// Module: 3-Channel Line Buffer (3x3 Window)
// Description: Buffers incoming RGB pixels and provides a simultaneous
//              3x3 window for each channel.
//              Includes "Zero Padding" logic to support 'Same' padding.
// ============================================================================

module line_buffer_3x3_rgb #(
    parameter DATA_WIDTH = 32,
    parameter IMG_WIDTH  = 8
) (
    input wire clk,
    input wire rst_n,

    // Input Stream (Parallel RGB)
    input wire signed [DATA_WIDTH-1:0] r_in,
    input wire signed [DATA_WIDTH-1:0] g_in,
    input wire signed [DATA_WIDTH-1:0] b_in,
    input wire                         valid_in,

    // Window Outputs (0=TopLeft, 4=Center, 8=BottomRight)
    output reg signed [DATA_WIDTH-1:0] win_r[0:8],
    output reg signed [DATA_WIDTH-1:0] win_g[0:8],
    output reg signed [DATA_WIDTH-1:0] win_b[0:8],

    // Status
    output reg window_valid
);

    // --- Line Memories ---
    reg signed [DATA_WIDTH-1:0] row0_r[0:IMG_WIDTH-1];
    reg signed [DATA_WIDTH-1:0] row1_r[0:IMG_WIDTH-1];
    reg signed [DATA_WIDTH-1:0] row0_g[0:IMG_WIDTH-1];
    reg signed [DATA_WIDTH-1:0] row1_g[0:IMG_WIDTH-1];
    reg signed [DATA_WIDTH-1:0] row0_b[0:IMG_WIDTH-1];
    reg signed [DATA_WIDTH-1:0] row1_b[0:IMG_WIDTH-1];

    // Pointers
    reg [$clog2(IMG_WIDTH)-1:0] wr_ptr;
    reg [$clog2(IMG_WIDTH)-1:0] rd_ptr;

    // Fill Counter
    reg [31:0] pixel_cnt;

    // Internal Raw Windows
    reg signed [DATA_WIDTH-1:0] raw_win_r[0:8];
    reg signed [DATA_WIDTH-1:0] raw_win_g[0:8];
    reg signed [DATA_WIDTH-1:0] raw_win_b[0:8];

    integer k;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            pixel_cnt <= 0;
            window_valid <= 0;
            for (k = 0; k < 9; k = k + 1) begin
                raw_win_r[k] <= 0;
                raw_win_g[k] <= 0;
                raw_win_b[k] <= 0;
            end
        end else if (valid_in) begin
            // 1. Shift Raw Window
            raw_win_r[0]   <= raw_win_r[1];
            raw_win_r[1]   <= raw_win_r[2];
            raw_win_r[3]   <= raw_win_r[4];
            raw_win_r[4]   <= raw_win_r[5];
            raw_win_r[6]   <= raw_win_r[7];
            raw_win_r[7]   <= raw_win_r[8];

            raw_win_g[0]   <= raw_win_g[1];
            raw_win_g[1]   <= raw_win_g[2];
            raw_win_g[3]   <= raw_win_g[4];
            raw_win_g[4]   <= raw_win_g[5];
            raw_win_g[6]   <= raw_win_g[7];
            raw_win_g[7]   <= raw_win_g[8];

            raw_win_b[0]   <= raw_win_b[1];
            raw_win_b[1]   <= raw_win_b[2];
            raw_win_b[3]   <= raw_win_b[4];
            raw_win_b[4]   <= raw_win_b[5];
            raw_win_b[6]   <= raw_win_b[7];
            raw_win_b[7]   <= raw_win_b[8];

            // 2. Load New Column
            raw_win_r[2]   <= row0_r[wr_ptr];
            raw_win_g[2]   <= row0_g[wr_ptr];
            raw_win_b[2]   <= row0_b[wr_ptr];
            raw_win_r[5]   <= row1_r[wr_ptr];
            raw_win_g[5]   <= row1_g[wr_ptr];
            raw_win_b[5]   <= row1_b[wr_ptr];
            raw_win_r[8]   <= r_in;
            raw_win_g[8]   <= g_in;
            raw_win_b[8]   <= b_in;

            // 3. Update Line Memories
            row0_r[wr_ptr] <= row1_r[wr_ptr];
            row1_r[wr_ptr] <= r_in;
            row0_g[wr_ptr] <= row1_g[wr_ptr];
            row1_g[wr_ptr] <= g_in;
            row0_b[wr_ptr] <= row1_b[wr_ptr];
            row1_b[wr_ptr] <= b_in;

            // 4. Update Write Pointer
            if (wr_ptr == IMG_WIDTH - 1) wr_ptr <= 0;
            else wr_ptr <= wr_ptr + 1;

            // 5. Update Read Pointer (Tracks Center Column)
            if (wr_ptr == 0) rd_ptr <= IMG_WIDTH - 1;
            else rd_ptr <= wr_ptr - 1;

            // 6. Global Validity Logic
            // Corrected: Valid starts when 1st pixel hits center (after 2 rows + 1 pixel)
            if (pixel_cnt < (2 * IMG_WIDTH + 1)) begin
                pixel_cnt <= pixel_cnt + 1;
                window_valid <= 0;
            end else begin
                window_valid <= 1;
            end
        end else begin
            window_valid <= 0;
        end
    end

    // Combinational Logic: Zero Padding Muxes
    always @(*) begin
        for (k = 0; k < 9; k = k + 1) begin
            win_r[k] = raw_win_r[k];
            win_g[k] = raw_win_g[k];
            win_b[k] = raw_win_b[k];
        end

        if (rd_ptr == 0) begin
            win_r[0] = 0;
            win_r[3] = 0;
            win_r[6] = 0;
            win_g[0] = 0;
            win_g[3] = 0;
            win_g[6] = 0;
            win_b[0] = 0;
            win_b[3] = 0;
            win_b[6] = 0;
        end

        if (rd_ptr == IMG_WIDTH - 1) begin
            win_r[2] = 0;
            win_r[5] = 0;
            win_r[8] = 0;
            win_g[2] = 0;
            win_g[5] = 0;
            win_g[8] = 0;
            win_b[2] = 0;
            win_b[5] = 0;
            win_b[8] = 0;
        end
    end

endmodule
