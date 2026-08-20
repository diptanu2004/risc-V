module forwarding_unit(
    input        exmem_reg_write,
    input [4:0]  exmem_rd,
    input        memwb_reg_write,
    input [4:0]  memwb_rd,
    input [4:0]  idex_rs1,
    input [4:0]  idex_rs2,
    output reg [1:0] forward_a,
    output reg [1:0] forward_b
);
    always @(*) begin
        forward_a = 2'b00;
        forward_b = 2'b00;
        if (exmem_reg_write && exmem_rd != 0 && exmem_rd == idex_rs1) forward_a = 2'b10;
        else if (memwb_reg_write && memwb_rd != 0 && memwb_rd == idex_rs1) forward_a = 2'b01;
        if (exmem_reg_write && exmem_rd != 0 && exmem_rd == idex_rs2) forward_b = 2'b10;
        else if (memwb_reg_write && memwb_rd != 0 && memwb_rd == idex_rs2) forward_b = 2'b01;
    end
endmodule
