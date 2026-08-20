module regfile(
    input clk,
    input rst,
    input [4:0] rs1, rs2,
    input [4:0] rd,
    input [31:0] wd,
    input we,
    output [31:0] rd1, rd2
);
    reg [31:0] regs [0:31];
    integer i;

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < 32; i = i + 1)
                regs[i] <= 32'd0;
        end else if (we && rd != 5'd0) begin
            regs[rd] <= wd;
        end
    end

    assign rd1 = (rs1 == 0) ? 32'd0 :
                 ((we && rd != 0 && rd == rs1) ? wd : regs[rs1]);

    assign rd2 = (rs2 == 0) ? 32'd0 :
                 ((we && rd != 0 && rd == rs2) ? wd : regs[rs2]);

endmodule