// ROM
`timescale 1ns / 1ps
module instruction_memory (
    input  [31:0] instr_raddr,
    output [31:0] instr_code
);

    // Word 단위  (32 bit)
    logic [31:0] rom_file[0:63];


    initial begin
        $readmemh("rom_instr_ex0.mem", rom_file);
        /*
        for (int i = 0; i < 16; i++) rom_file[i] = 32'd0 + i;
        // x[i] = i
        // // =============================R-type=============================
        // // add x5,x3,x4
        // rom_file[0]  = 32'h0041_82b3;

        // // sub x6,x8,x7
        // rom_file[1]  = 32'h4074_0333;

        // // sll x9,x8,x2
        // rom_file[2]  = 32'h0024_14b3;

        // // slt x10,x13,x11
        // rom_file[3]  = 32'h00b6_a533;

        // // sltu x12,x13,x11
        // rom_file[4]  = 32'h00b6_b633;

        // // xor x4,x3,x2
        // rom_file[5]  = 32'h0021_c233;

        // // srl x15,x14,x2
        // rom_file[6]  = 32'h0027_57b3;

        // // sra x20,x19,x1
        // rom_file[7]  = 32'h4019_da33;

        // // or x24,x22,x21
        // rom_file[8]  = 32'h015B_6c33;

        // // and x27,x26,x25
        // rom_file[9]  = 32'h019d_7db3;

        // // // =============================I-type==============================
        // // ADDI, x2, x1, 3 : expected reg[2] = 1 + 3 = 4
        // rom_file[0] = 32'h0030_8113;

        // // SLTI, x4, x3, 4 : expected  reg[4] = -1 < 4 ? 1 : 0 -> 1
        // rom_file[1] = 32'h0041_a213;

        // // SLTIU, x6, x3, 4 : expected reg[6] = 2**32-1 < 4 ? 1 : 0 -> 0
        // rom_file[2] = 32'h0041_b313;

        // // XORI, x8, x7, 14 : expected reg[8] = 7 ^ 14 = 9
        // rom_file[3] = 32'h00e3_c413;

        // // ORI, x10, x9, 10 : expected reg[10] = 9 | 10 = 1011 = 11
        // rom_file[4] = 32'h00a4_e513;

        // // ANDI, x12, x11, 7 : expected reg[12] = 11 & 7 = 0011 = 3
        // rom_file[5] = 32'h0075_f613;

        // // SLLI, x14, x13, 2 : expected reg[14] = 13 << 2 = 52(10)
        // rom_file[6] = 32'h0026_9713;

        // // SRLI, x16, x15, 2 : expected reg[16] = 15 >> 2 = 0011 = 3
        // rom_file[7] = 32'h0027_d813;

        // // SRAI, x18, x17, 2 : expected reg[18] = -5 >> 2 = 0010 -> 1110 -> 0001 -> 0010 = -2
        // rom_file[8] = 32'h4028_d913;

        // // (SUB) ADDI, x20, x19, -20 : expected reg[20] = 19 - 20 = -1 
        // rom_file[9] = 32'hfec9_8a13;

        // // // =============================B-type============================= 
        // // beq x2, x1, 12 : branch 
        // rom_file[0] = 32'h0011_0663; // expected_pc = 12

        // // bne x2, x1, 20 // no branch
        // rom_file[3] = 32'h0011_1a63; // expected_pc = 16

        // // blt x7, x8, 12 : branch   x7: -1, x8: 1
        // rom_file[4] = 32'h0083_c663; // expected_pc = 28

        // // bltu x8, x7, 20 : branch  unsigned x7 is 2**32-1, not -1
        // rom_file[7] = 32'h0074_6a63; // expected_pc = 48

        // // bgeu x2, x1, 8 : branch   
        // rom_file[12] = 32'h0011_7463; // expected_pc = 56

        // // bge x10, x11, 12 : no branch 
        // rom_file[14] = 32'h00b5_5663; // expected_pc = 60

        // // bge x11, x10, 12 : branch
        // rom_file[15] = 32'h00a5_d663; // // expected_pc = 72


        // // =============================U-type=============================
        // // lui x1, 0x12345 : expected_reg[1] = 0x12345_000 
        // rom_file[0] = 32'h1234_50b7;

        // // auipc x2 0x67890 :  expected_reg[2] = pc(4) + 0x67890_000 = 0x67890_004
        // rom_file[1] = 32'h6789_0117;

        // // =============================J-type=============================
        // // jal x1, 16  :  expected_pc = 16, expected_reg[1] = 4
        // rom_file[0] = 32'h0100_00ef;

        // // jalr x2, 6(x1) : expected_pc = x1+6 = 4+6 = 10, expected_reg[2] = 16 + 4 = 20
        // rom_file[4] = 32'h0060_8167;

        // // return
        // // jalr x0, 0(x2) : expected_pc = 20
        // rom_file[2] = 32'h0001_0067;

        // // addi x0, x0, 0 : expected_pc = 24
        // rom_file[5] = 32'h0000_0013;

        // // =========================S-type, IL-type=========================
        // sb x1,4(x0) : x1의 data를 data_mem[x0+4]에 저장 (4번지)
        //              4 >> 2 = 1, 4 % 4 = 0 -> expected_data_ram[1] = 0x_xxxx_xxff
        rom_file[0] = 32'h0010_0223;
        
        // sh x2, 2(x6) : x2의 data를 data_mem[x6+2]에 저장 (8번지)
        //              : 8 >> 2 = 2, 8 % 4 = 0 -> expected_data_ram[2] = 0xxxxx_ffff
        rom_file[1] = 32'h0023_1123;

        // sw x3, 12(x0) : x3의 data를 data_mem[x0+3]에 저장 (12번지)
        //               : 12 >> 2 = 3, 12 % 4 = 0 -> expected_data_ram[3] = 0xffff_ffff
        rom_file[2] = 32'h0030_2623;

        // lw x10, 12(x0) : data_mem[x0+12]의 data를 x10에 load -> expected_reg[10] = 0xffff_ffff
        rom_file[3] = 32'h00c0_2503;

        // lh x11, 0(x8) : data_mem[x8+0]의 data를 x11에 load -> expected_reg[11] = 0xffff_ffff (signed!! : msb extends)
        rom_file[4] = 32'h0004_1583;

        // lhu x12, 0(x8) : data_mem[x8+0]의 data를 x12에 load -> expected_reg[12] = 0x0000_ffff (unsigned : zero extends)
        rom_file[5] = 32'h0004_5603;

        // lb x13, 0(x4) : data_mem[x4+0]의 (4번지) data를 x13에 load -> expected_reg[13] = 0xffff_ffff (signed!! : msb extends)
        rom_file[6] = 32'h0002_0683;

        // lbu x14, 4(x0) : data_mem[x0+4]의 (4번지) data를 x14에 load -> expected_reg[14] = 0x0000_00ff (unsigned : zero extends)
        rom_file[7] = 32'h0040_4703;

        // sb x1, 2(x5) : x1의 data를 data_mem[x5+2]에 저장 (7번지) 
        //              : 7 >> 2 = 1, 7 % 4 = 3 -> expected_data_ram[1] = 0xffxx_xxff  , 
        //                data 중첩 (by rom_file[0]) (byte_sel = 3)
        rom_file[8] = 32'h0012_8123;
*/
    end

    assign instr_code = rom_file[instr_raddr[31:2]];  // divide  4  
    //  instr_raddr = pc  (address)



    // byte 단위
    // logic [7:0] rom_file[0:15*4];

    // initial begin
    //     for (int i = 0; i < 16 * 4; i++) rom_file[i] = 8'd0 + i;
    // end

    // assign instr_code = {
    //     rom_file[instr_raddr+3],
    //     rom_file[instr_raddr+2],
    //     rom_file[instr_raddr+1],
    //     rom_file[instr_raddr]
    // };


endmodule