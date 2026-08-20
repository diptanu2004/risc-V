module hazard_unit(
    input        idex_mem_read,
    input [4:0]  idex_rd,
    input [4:0]  ifid_rs1,
    input [4:0]  ifid_rs2,
    output       stall
);
    assign stall = idex_mem_read && idex_rd != 0 &&
                   ((idex_rd == ifid_rs1) || (idex_rd == ifid_rs2));
endmodule
