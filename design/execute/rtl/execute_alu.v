module execute_alu (
   // Input controls //
   input  logic [ 7-1:0] opcode , // opcode 
   input  logic [ 3-1:0] funct3 , // funct3 bits
   input  logic [ 1-1:0] funct7 , // funct7[5] bit
   // Input data // 
   input  logic [32-1:0] a      , // input data A
   input  logic [32-1:0] b      , // input data B
   output logic [32-1:0] y        // ALU output
);

// Imports //
// ------- //
import utils_top::* ; 

// Internal Wires // 
// -------------- //
logic [32-1:0] mask_stype        ; 
logic [32-1:0] mask_jtype        ;
// R-type Masks // 
logic [32-1:0] mask_rtype_add    ; 
logic [32-1:0] mask_rtype_sub    ; 
logic [32-1:0] mask_rtype_and    ; 
logic [32-1:0] mask_rtype_or     ; 
logic [32-1:0] mask_rtype_xor    ; 
logic [32-1:0] mask_rtype_slt    ; 
logic [32-1:0] mask_rtype_sltu   ; 
logic [32-1:0] mask_rtype_srl    ; 
logic [32-1:0] mask_rtype_sra    ; 
logic [32-1:0] mask_rtype_sll    ; 
logic [32-1:0] mask_rtype        ; 
// B-type Masks //
logic [32-1:0] mask_btype_eq     ; 
logic [32-1:0] mask_btype_lt     ; 
logic [32-1:0] mask_btype_ltu    ; 
logic [32-1:0] mask_btype        ;
// I-type Masks //
logic [32-1:0] mask_itype_add    ; 
logic [32-1:0] mask_itype_sll    ; 
logic [32-1:0] mask_itype_slt    ; 
logic [32-1:0] mask_itype_sltu   ; 
logic [32-1:0] mask_itype_xor    ; 
logic [32-1:0] mask_itype_srl    ; 
logic [32-1:0] mask_itype_sra    ; 
logic [32-1:0] mask_itype_or     ; 
logic [32-1:0] mask_itype_and    ; 
logic [32-1:0] mask_itype        ;
// U-type Mask //
logic [32-1:0] mask_utype        ; 
// Calculations //
logic [32-1:0] res_add           ;
logic [32-1:0] res_sub           ;
logic [32-1:0] res_and           ;
logic [32-1:0] res_or            ;
logic [32-1:0] res_xor           ;
logic [32-1:0] res_slt           ; 
logic [32-1:0] res_sltu          ; 
logic [32-1:0] res_sll           ; 
logic [32-1:0] res_srl           ; 
logic [32-1:0] res_sra           ; 
// Result per type // 
logic [32-1:0] res_rtype         ; 
logic [32-1:0] res_btype         ; 
logic [32-1:0] res_itype         ; 
logic [32-1:0] res_stype         ; 
logic [32-1:0] res_jtype         ; 
logic [32-1:0] res_utype         ; 

// Calculate all the possible results //
// ---------------------------------- //
assign res_add  = a + b ; 
assign res_sub  = a - b ; 
assign res_and  = a & b ; 
assign res_or   = a | b ; 
assign res_xor  = a ^ b ; 
assign res_slt  = a[31] != b[31] ? (a[31] ? 1 : 0) : (res_sub[31] ? 1 : 0) ; 
assign res_sltu = a < b ? 1 : 0 ; 
assign res_sll  = a << b[4:0] ; 
assign res_srl  = a >> b[4:0] ; 
assign res_sra  = $signed(a) >> b[4:0] ; 

// Create instruction type masks // 
// ----------------------------- //
// R-type //
assign mask_rtype_add  = {32{{funct7, funct3}==ALU_ADD  }} ; 
assign mask_rtype_sub  = {32{{funct7, funct3}==ALU_SUB  }} ; 
assign mask_rtype_and  = {32{{funct7, funct3}==ALU_AND  }} ; 
assign mask_rtype_or   = {32{{funct7, funct3}==ALU_OR   }} ; 
assign mask_rtype_xor  = {32{{funct7, funct3}==ALU_XOR  }} ; 
assign mask_rtype_slt  = {32{{funct7, funct3}==ALU_SLT  }} ; 
assign mask_rtype_sltu = {32{{funct7, funct3}==ALU_SLTU }} ; 
assign mask_rtype_srl  = {32{{funct7, funct3}==ALU_SRL  }} ; 
assign mask_rtype_sra  = {32{{funct7, funct3}==ALU_SRA  }} ; 
assign mask_rtype_sll  = {32{{funct7, funct3}==ALU_SLL  }} ; 
// B-type //
assign mask_btype_ltu  = {32{funct3==ALU_BGEU}} ; 
assign mask_btype_lt   = {32{(funct3==ALU_BLT)|(funct3==ALU_BGE)}} ; 
assign mask_btype_eq   = {32{(funct3==ALU_BEQ)|(funct3==ALU_BNE)}} ; 
// I-type // 
assign mask_itype_add  = {32{funct3==ALU_ADDI  }} ;  
assign mask_itype_slt  = {32{funct3==ALU_SLTI  }} ;
assign mask_itype_sltu = {32{funct3==ALU_SLTIU }} ;
assign mask_itype_xor  = {32{funct3==ALU_XORI  }} ;
assign mask_itype_or   = {32{funct3==ALU_ORI   }} ;
assign mask_itype_and  = {32{funct3==ALU_ANDI  }} ;
assign mask_itype_sll  = {32{{funct7, funct3}==ALU_SLLI }} ;
assign mask_itype_srl  = {32{{funct7, funct3}==ALU_SRLI }} ;
assign mask_itype_sra  = {32{{funct7, funct3}==ALU_SRAI }} ;

// Create the result for each type //
// ------------------------------- //
assign res_rtype = ( mask_rtype_add  & res_add  ) | 
                   ( mask_rtype_sub  & res_sub  ) | 
                   ( mask_rtype_and  & res_and  ) |
                   ( mask_rtype_or   & res_or   ) |
                   ( mask_rtype_xor  & res_xor  ) |
                   ( mask_rtype_slt  & res_slt  ) |
                   ( mask_rtype_sltu & res_sltu ) |
                   ( mask_rtype_sll  & res_sll  ) |
                   ( mask_rtype_srl  & res_srl  ) |
                   ( mask_rtype_sra  & res_sra  ) ;

assign res_btype = ( mask_btype_ltu  & res_sltu ) | 
                   ( mask_btype_lt   & res_slt  ) | 
                   ( mask_btype_eq   & res_xor  ) ;

assign res_itype = ( mask_itype_add  & res_add  ) | 
                   ( mask_itype_slt  & res_slt  ) | 
                   ( mask_itype_sltu & res_sltu ) | 
                   ( mask_itype_xor  & res_xor  ) |
                   ( mask_itype_or   & res_or   ) |
                   ( mask_itype_and  & res_and  ) |
                   ( mask_itype_sll  & res_sll  ) |
                   ( mask_itype_srl  & res_srl  ) |
                   ( mask_itype_sra  & res_sra  ) ;

assign res_stype = ( res_add ) ; 

assign res_jtype = ( res_add ) ; 

assign res_utype = ( res_add ) ; 

// Create instruction type masks // 
// ----------------------------- //
assign mask_rtype = {32{opcode==OP_RR}} ;
assign mask_jtype = {32{opcode==OP_JAL | opcode==OP_JALR}} ; 
assign mask_btype = {32{opcode==OP_BRANCH}} ;
assign mask_stype = {32{opcode==OP_STORE | opcode==OP_LOAD}} ; 
assign mask_itype = {32{opcode==OP_IMM}} ;
assign mask_utype = {32{(opcode==OP_LUI | opcode==OP_AUIPC)}} ;

// Create the final result //
// ----------------------- //
assign y = ( mask_rtype & res_rtype ) | 
           ( mask_btype & res_btype ) | 
           ( mask_stype & res_stype ) | 
           ( mask_jtype & res_jtype ) | 
           ( mask_utype & res_utype ) | 
           ( mask_itype & res_itype ) ; 

endmodule

//|~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~|//
//|                                               |//
//| 1. Project  :  etcpu                          |//
//| 2. Author   :  Etay Sela                      |//
//| 3. Date     :  2025-01-12                     |//
//| 4. Version  :  v0.1.0                         |//
//|                                               |//
//|~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~|//
