module control(
    input  [6:0] opcode,
    input  [2:0] funct3,
    input  [6:0] funct7,
    output reg reg_write,
    output reg mem_read,
    output reg mem_write,
    output reg mem_to_reg,
    output reg alu_src,
    output reg branch,
    output reg [3:0] alu_ctrl
);
    localparam OP_R=7'b0110011, OP_I=7'b0010011, OP_LW=7'b0000011,
               OP_SW=7'b0100011, OP_BR=7'b1100011;
    localparam ADD=4'd0, SUB=4'd1, AND_=4'd2, OR_=4'd3, XOR_=4'd4, SLT=4'd5;

    always @(*) begin
        reg_write=0; mem_read=0; mem_write=0; mem_to_reg=0;
        alu_src=0; branch=0; alu_ctrl=ADD;
        case (opcode)
            OP_R: begin
                reg_write=1;
                case (funct3)
                    3'b000: alu_ctrl = funct7[5] ? SUB : ADD;
                    3'b111: alu_ctrl = AND_;
                    3'b110: alu_ctrl = OR_;
                    3'b100: alu_ctrl = XOR_;
                    3'b010: alu_ctrl = SLT;
                    default: begin reg_write=0; alu_ctrl=ADD; end
                endcase
            end
            OP_I: begin
                reg_write=1; alu_src=1;
                case (funct3)
                    3'b000: alu_ctrl=ADD;
                    3'b111: alu_ctrl=AND_;
                    3'b110: alu_ctrl=OR_;
                    3'b100: alu_ctrl=XOR_;
                    3'b010: alu_ctrl=SLT;
                    default: begin reg_write=0; alu_ctrl=ADD; end
                endcase
            end
            OP_LW: begin reg_write=1; mem_read=1; mem_to_reg=1; alu_src=1; alu_ctrl=ADD; end
            OP_SW: begin mem_write=1; alu_src=1; alu_ctrl=ADD; end
            OP_BR: begin branch=1; alu_ctrl=SUB; end
            default: begin end
        endcase
    end
endmodule
