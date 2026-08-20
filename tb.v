`timescale 1ns/1ps
module tb;
    reg clk=0, rst=1;
    wire [31:0] imem_addr, dmem_addr, dmem_wdata;
    wire dmem_we, dmem_re;
    reg [31:0] imem_rdata;
    reg [31:0] dmem_rdata;

    reg [31:0] imem [0:63];
    reg [31:0] dmem [0:63];
    integer i;

    rv32i_cpu cpu(clk, rst, imem_addr, imem_rdata, dmem_addr, dmem_wdata,
                  dmem_we, dmem_re, dmem_rdata);

    always #5 clk = ~clk;

    always @(*) begin
        imem_rdata = imem[imem_addr[7:2]];
        dmem_rdata = dmem[dmem_addr[7:2]];
    end

    always @(posedge clk) begin
        if (dmem_we) dmem[dmem_addr[7:2]] <= dmem_wdata;
    end

    function [31:0] rtype;
        input [6:0] funct7; input [4:0] rs2, rs1; input [2:0] funct3; input [4:0] rd;
        begin rtype={funct7,rs2,rs1,funct3,rd,7'b0110011}; end
    endfunction
    function [31:0] addi;
        input [4:0] rd,rs1; input integer imm;
        begin addi={{20{imm[11]}},imm[11:0],rs1,3'b000,rd,7'b0010011}; end
    endfunction
    function [31:0] lw;
        input [4:0] rd,rs1; input integer imm;
        begin lw={{20{imm[11]}},imm[11:0],rs1,3'b010,rd,7'b0000011}; end
    endfunction
    function [31:0] sw;
        input [4:0] rs2,rs1; input integer imm;
        begin sw={imm[11:5],rs2,rs1,3'b010,imm[4:0],7'b0100011}; end
    endfunction
    function [31:0] beq;
        input [4:0] rs1,rs2; input integer imm;
        begin beq={imm[12],imm[10:5],rs2,rs1,3'b000,imm[4:1],imm[11],7'b1100011}; end
    endfunction

    initial begin
        for(i=0;i<64;i=i+1) begin imem[i]=32'h00000013; dmem[i]=0; end

        // 5, 10, 15, 10, store/load, then load-use dependency.
        imem[0] = addi(5'd1,5'd0,5);       // x1=5
        imem[1] = addi(5'd2,5'd0,10);      // x2=10
        imem[2] = rtype(7'b0000000,5'd2,5'd1,3'b000,5'd3); // x3=x1+x2
        imem[3] = rtype(7'b0100000,5'd1,5'd3,3'b000,5'd4); // x4=x3-x1
        imem[4] = sw(5'd4,5'd0,0);         // mem[0]=x4
        imem[5] = lw(5'd5,5'd0,0);         // x5=mem[0]
        imem[6] = addi(5'd6,5'd5,1);       // load-use hazard: x6=x5+1
        imem[7] = beq(5'd6,5'd0,8);        // not taken
        imem[8] = addi(5'd7,5'd0,99);      // x7=99
        imem[9] = 32'h00000013;            // nop

        #12 rst=0;
        #220;
        $display("x1=%0d x2=%0d x3=%0d x4=%0d x5=%0d x6=%0d x7=%0d mem0=%0d",
                 cpu.rf.regs[1],cpu.rf.regs[2],cpu.rf.regs[3],cpu.rf.regs[4],
                 cpu.rf.regs[5],cpu.rf.regs[6],cpu.rf.regs[7],dmem[0]);
        if (cpu.rf.regs[3] !== 15 || cpu.rf.regs[4] !== 10 ||
            cpu.rf.regs[5] !== 10 || cpu.rf.regs[6] !== 11 || dmem[0] !== 10)
            $display("FAIL");
        else
            $display("PASS: forwarding + load-use stall + memory path verified");
        $finish;
    end

    initial begin
        $dumpfile("cpu.vcd");
        $dumpvars(0,tb);
    end
endmodule
