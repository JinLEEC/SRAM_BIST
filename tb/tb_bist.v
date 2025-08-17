`timescale 1ns / 1ps
module tb_bist;

reg             clock, n_reset;
reg             bist_en;
wire    [9:0]   rd_data;
wire            csn;
wire            wen;
wire    [9:0]   wr_data;
wire    [7:0]   wr_addr;
wire            b_done;
wire            b_err;

always #5 clock = ~clock;

initial begin
    n_reset = 1'b0;
    clock   = 1'b0;
    bist_en = 1'b0;

#100 n_reset = 1'b1;
#50 bist_en = 1'b1;
end

initial begin
    $dumpfile("tb_bist.vcd");
    $dumpvars(0, tb_bist);
    #100000
    $finish;
end

bist #(
    .value_3ff(10'h3FF),
    .value_00 (10'h00 ),
    .value_2aa(10'h2AA)
) t0(
    .clock          (clock),
    .n_reset        (n_reset),
    .bist_en        (bist_en),
    .rd_data        (rd_data),
    .csn            (csn),
    .wen            (wen),
    .wr_data        (wr_data),
    .wr_addr        (wr_addr),
    .b_done         (b_done),
    .b_err          (b_err)
);

u40spsram_256x10 t1(
    .clka           (clock),
    .ena            (~csn),
    .wea            (~wen),
    .addra          (wr_addr),
    .dina           (wr_data),
    .douta          (rd_data)
);

endmodule
