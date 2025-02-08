module execute_branch_flush (
   // Branch instruction cond //
   input  logic          inst_branch , 
   input  logic          inst_jalr , 
   // ALU output //
   input  logic [32-1:0] alu_dat_out , 
   // Funct3 of instruction //
   input  logic [ 3-1:0] funct3 , 
   // Branch taken control //
   input  logic          br_pred , 
   // Output flush condition // 
   output logic          flush 
);

// Imports //
// ------- //
import utils_top::* ; 

// Internal wires //
// -------------- //
logic br_act ; 

assign br_act = funct3==ALU_BGEU | funct3==ALU_BGE ?    ~alu_dat_out[0] : // BGE or BGEU
                funct3==ALU_BLT                    ?     alu_dat_out[0] : // BLT 
                funct3==ALU_BEQ                    ? ~(|(alu_dat_out))  : // BEQ
                                                       |(alu_dat_out)   ; // BNE

assign flush = inst_jalr | (inst_branch & (br_pred ^ br_act)) ;

endmodule

//|~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~|//
//|                                               |//
//| 1. Project  :  etcpu                          |//
//| 2. Author   :  Etay Sela                      |//
//| 3. Date     :  2025-02-08                     |//
//| 4. Version  :  v1.0.0                         |//
//|                                               |//
//|~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~|//
