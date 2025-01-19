// 
// fetch_top.v 
//

module fetch_top
(
   // Program Counter Register // 
   // ------------------------ //
   input  logic [32-1:0] pc               , // Program counter value
   output logic [32-1:0] pc_next          , // Program counter next value

   // Instruction Register // 
   // -------------------- //
   output logic [32-1:0] id_inst          , // Decode stage instruction 

   // Pipe interlock bubble //
   // --------------------- //
   input  logic          intrlock_bubble  , // pipe interlock bubbel 

   // Branch IF //
   // --------- //
   output logic          id_branch_taken  , // Branch taken by Fetcher branch prediction
   output logic [32-1:0] id_branch_nt_pc  , // non-taken branch PC 
   input  logic          ex_branch_flush  , // Branch flush indicator from execute stage
   input  logic [32-1:0] ex_branch_pc     , // Branch flush PC

   // ----------------------------------------------------------------- //
   // ------------------------ Memory Interface ----------------------- // 
   // ----------------------------------------------------------------- //
   // Input control // 
   // ------------- //
   output logic [32-1:0] mem_addr   , // Address  

   // Output data // 
   // ----------- //
   input  logic [32-1:0] mem_dat_out  // Output data (from memory POV)
);

// Import package //
import utils_top::* ; 

// Internal Logic //
// -------------- //
logic [07-1:0] opcode    ; 
logic [32-1:0] int_inst  ; 
logic [32-1:0] b_imm     ; 
logic [32-1:0] j_imm     ; 
logic [32-1:0] pc_p4     ; 
logic [32-1:0] pc_pb     ; 
logic [32-1:0] pc_pj     ; 

// Next Program Counter Logic //
// -------------------------- //
assign opcode = int_inst[6:0] ; 
// decode immediates //
assign b_imm = { {20{int_inst[31]}} , int_inst[07] , int_inst[30:25] , int_inst[11:08] ,                       1'b0 } ; 
assign j_imm = { {12{int_inst[31]}} , int_inst[19:12] , int_inst[20] , int_inst[30:25] , int_inst[24:21] ,     1'b0 } ; 
// calculate PC options // 
assign pc_p4 = pc + 4 ; 
assign pc_pb = pc + b_imm ; 
assign pc_pj = pc + j_imm ;
// Drive output branch IF //
assign id_branch_taken = opcode==OP_BRANCH & b_imm[31] ; 
assign id_branch_nt_pc = id_branch_taken ? pc_p4 : pc_pb ; 
// Next PC logic //
assign pc_next = ex_branch_flush ? ex_branch_pc : // FLUSH
                 intrlock_bubble ? pc           : // BUBBLE
                 opcode==OP_JAL  ? pc_pj        : // JAL PC
                 id_branch_taken ? pc_pb        : // BRANCH PC
                                   pc_p4        ; // PC + 4 

// Memory Interface //
// ---------------- //
assign mem_addr  = pc          ; 
assign int_inst  = mem_dat_out ; 

// Output instruction //
// ------------------ //
assign id_inst = ex_branch_flush ? BUBBLE : int_inst ; 

endmodule


//|~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~|//
//|                                               |//
//| 1. Project  :  etcpu                          |//
//| 2. Author   :  Etay Sela                      |//
//| 3. Date     :  2025-01-12                     |//
//| 4. Version  :  v0.1.0                         |//
//|                                               |//
//|~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~|//
