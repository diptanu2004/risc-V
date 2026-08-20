module rv32i_cpu(
    input clk,
    input rst,
    output [31:0] imem_addr,
    input  [31:0] imem_rdata,
    output [31:0] dmem_addr,
    output [31:0] dmem_wdata,
    output        dmem_we,
    output        dmem_re,
    input  [31:0] dmem_rdata
);
    // Supported RV32I subset: R-type ADD/SUB/AND/OR/XOR/SLT,
    // ADDI, LW, SW and BEQ. Five stages: IF, ID, EX, MEM, WB.
    localparam OP_BR=7'b1100011;

    reg [31:0] pc;
    assign imem_addr = pc;

    // IF/ID
    reg [31:0] ifid_pc, ifid_instr;
    // ID/EX
    reg [31:0] idex_pc, idex_rs1_val, idex_rs2_val, idex_imm;
    reg [4:0] idex_rs1, idex_rs2, idex_rd;
    reg idex_reg_write, idex_mem_read, idex_mem_write, idex_mem_to_reg, idex_alu_src, idex_branch;
    reg [3:0] idex_alu_ctrl;
    // EX/MEM
    reg [31:0] exmem_alu_result, exmem_rs2_val;
    reg [4:0] exmem_rd;
    reg exmem_reg_write, exmem_mem_read, exmem_mem_write, exmem_mem_to_reg;
    // MEM/WB
    reg [31:0] memwb_mem_data, memwb_alu_result;
    reg [4:0] memwb_rd;
    reg memwb_reg_write, memwb_mem_to_reg;

    wire [6:0] opcode = ifid_instr[6:0];
    wire [4:0] rs1 = ifid_instr[19:15];
    wire [4:0] rs2 = ifid_instr[24:20];
    wire [4:0] rd  = ifid_instr[11:7];
    wire [2:0] funct3 = ifid_instr[14:12];
    wire [6:0] funct7 = ifid_instr[31:25];

    wire reg_write_d, mem_read_d, mem_write_d, mem_to_reg_d, alu_src_d, branch_d;
    wire [3:0] alu_ctrl_d;
    control ctrl(opcode, funct3, funct7, reg_write_d, mem_read_d, mem_write_d,
                 mem_to_reg_d, alu_src_d, branch_d, alu_ctrl_d);

    wire [31:0] wb_data = memwb_mem_to_reg ? memwb_mem_data : memwb_alu_result;
    wire [31:0] rs1_val, rs2_val;
    regfile rf(clk, rst, rs1, rs2, memwb_rd, wb_data, memwb_reg_write, rs1_val, rs2_val);

    wire stall;
    hazard_unit hz(idex_mem_read, idex_rd, rs1, rs2, stall);

    wire [31:0] imm_i = {{20{ifid_instr[31]}}, ifid_instr[31:20]};
    wire [31:0] imm_s = {{20{ifid_instr[31]}}, ifid_instr[31:25], ifid_instr[11:7]};
    wire [31:0] imm_b = {{19{ifid_instr[31]}}, ifid_instr[31], ifid_instr[7],
                          ifid_instr[30:25], ifid_instr[11:8], 1'b0};
    wire [31:0] id_imm = (opcode == 7'b0100011) ? imm_s :
                         (opcode == OP_BR) ? imm_b : imm_i;

    wire [1:0] forward_a, forward_b;
    forwarding_unit fu(exmem_reg_write, exmem_rd, memwb_reg_write, memwb_rd,
                       idex_rs1, idex_rs2, forward_a, forward_b);

    wire [31:0] wb_forward_a = wb_data;
    wire [31:0] ex_a = (forward_a == 2'b10) ? exmem_alu_result :
                       (forward_a == 2'b01) ? wb_forward_a : idex_rs1_val;
    wire [31:0] ex_b_reg = (forward_b == 2'b10) ? exmem_alu_result :
                           (forward_b == 2'b01) ? wb_forward_a : idex_rs2_val;
    wire [31:0] ex_b = idex_alu_src ? idex_imm : ex_b_reg;
    wire [31:0] ex_branch_target = idex_pc + idex_imm;
    wire ex_branch_taken = idex_branch && (ex_a == ex_b_reg);

    wire [31:0] alu_result;
    wire alu_zero;
    alu alu0(ex_a, ex_b, idex_alu_ctrl, alu_result, alu_zero);

    assign dmem_addr  = exmem_alu_result;
    assign dmem_wdata = exmem_rs2_val;
    assign dmem_we    = exmem_mem_write;
    assign dmem_re    = exmem_mem_read;

    always @(posedge clk) begin
        if (rst) begin
            pc <= 0;
            ifid_pc <= 0; ifid_instr <= 0;
            idex_pc <= 0; idex_rs1_val <= 0; idex_rs2_val <= 0; idex_imm <= 0;
            idex_rs1 <= 0; idex_rs2 <= 0; idex_rd <= 0;
            idex_reg_write <= 0; idex_mem_read <= 0; idex_mem_write <= 0;
            idex_mem_to_reg <= 0; idex_alu_src <= 0; idex_branch <= 0; idex_alu_ctrl <= 0;
            exmem_alu_result <= 0; exmem_rs2_val <= 0; exmem_rd <= 0;
            exmem_reg_write <= 0; exmem_mem_read <= 0; exmem_mem_write <= 0; exmem_mem_to_reg <= 0;
            memwb_mem_data <= 0; memwb_alu_result <= 0; memwb_rd <= 0;
            memwb_reg_write <= 0; memwb_mem_to_reg <= 0;
        end else begin
            // MEM -> WB
            memwb_mem_data <= dmem_rdata;
            memwb_alu_result <= exmem_alu_result;
            memwb_rd <= exmem_rd;
            memwb_reg_write <= exmem_reg_write;
            memwb_mem_to_reg <= exmem_mem_to_reg;

            // EX -> MEM
            exmem_alu_result <= alu_result;
            exmem_rs2_val <= ex_b_reg;
            exmem_rd <= idex_rd;
            exmem_reg_write <= idex_reg_write;
            exmem_mem_read <= idex_mem_read;
            exmem_mem_write <= idex_mem_write;
            exmem_mem_to_reg <= idex_mem_to_reg;

            // ID -> EX. A load-use hazard inserts one bubble.
            if (stall || ex_branch_taken) begin
                idex_pc <= 0; idex_rs1_val <= 0; idex_rs2_val <= 0; idex_imm <= 0;
                idex_rs1 <= 0; idex_rs2 <= 0; idex_rd <= 0;
                idex_reg_write <= 0; idex_mem_read <= 0; idex_mem_write <= 0;
                idex_mem_to_reg <= 0; idex_alu_src <= 0; idex_branch <= 0; idex_alu_ctrl <= 0;
            end else begin
                idex_pc <= ifid_pc;
                idex_rs1_val <= rs1_val;
                idex_rs2_val <= rs2_val;
                idex_imm <= id_imm;
                idex_rs1 <= rs1; idex_rs2 <= rs2; idex_rd <= rd;
                idex_reg_write <= reg_write_d;
                idex_mem_read <= mem_read_d;
                idex_mem_write <= mem_write_d;
                idex_mem_to_reg <= mem_to_reg_d;
                idex_alu_src <= alu_src_d;
                idex_branch <= branch_d;
                idex_alu_ctrl <= alu_ctrl_d;
            end

            // IF -> ID. Freeze on a load-use stall; flush after a taken branch.
            if (ex_branch_taken) begin
                pc <= ex_branch_target;
                ifid_pc <= 0;
                ifid_instr <= 0;
            end else if (stall) begin
                pc <= pc;
                ifid_pc <= ifid_pc;
                ifid_instr <= ifid_instr;
            end else begin
                pc <= pc + 4;
                ifid_pc <= pc;
                ifid_instr <= imem_rdata;
            end
        end
    end
endmodule
