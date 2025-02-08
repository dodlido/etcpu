// 
// fetch_top.v 
//

module fetch_top #(
   // Parameters //
   // ---------- //
   parameter int INST_MEM_BYTE_ADD_W = 8 // Byte address width of instruction memory
)(
   // Configurations //
   // -------------- //
   input  logic [32-1:0] cfg_trap_hdlr_addr , // configurable trap handler base address 
   // Program Counter Register // 
   // ------------------------ //
   input  logic [32-1:0] pc                 , // Program counter value
   output logic [32-1:0] pc_next            , // Program counter next value

   // Instruction Register // 
   // -------------------- //
   output logic [32-1:0] id_inst            , // Decode stage instruction 

   // Pipe interlock bubble //
   // --------------------- //
   input  logic          intrlock_bubble    , // pipe interlock bubbel 

   // Branch IF //
   // --------- //
   output logic          id_branch_taken    , // Branch taken by Fetcher branch prediction
   output logic [32-1:0] id_branch_nt_pc    , // non-taken branch PC 
   input  logic          ex_branch_flush    , // Branch flush indicator from execute stage
   input  logic [32-1:0] ex_branch_pc       , // Branch flush PC

   // Events //
   // ------ //
   input  logic          exc_main_addr_mis  , // exception - main memory address misaligned
   input  logic          exc_main_addr_oob  , // exception - main memory address out-of-bounds
   output logic          exc_inst_addr_mis  , // exception - instruction memory address misaligned
   output logic          exc_inst_addr_oob  , // exception - instruction memory address out-of-bounds

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

// Internal wires //
// -------------- //
logic [07-1:0] opcode            ; 
logic [32-1:0] int_inst          ; 
logic [32-1:0] b_imm             ; 
logic [32-1:0] j_imm             ; 
logic [32-1:0] pc_p4             ; 
logic [32-1:0] pc_pb             ; 
logic [32-1:0] pc_pj             ; 
logic          jump2trap_cond    ; 
logic [32-1:0] pc_next_unmasked  ; 

// Next Program Counter Logic //
// -------------------------- //
assign opcode = int_inst[6:0] ; 
// decode immediates //
assign b_imm = { {20{int_inst[31]}} , int_inst[07] , int_inst[30:25] , int_inst[11:08] ,                           1'b0 } ; 
assign j_imm = { {12{int_inst[31]}} , int_inst[19:12] , int_inst[20] , int_inst[30:25] , int_inst[24:21] ,         1'b0 } ; 
// calculate PC options // 
assign pc_p4 = pc + 4 ; 
assign pc_pb = pc + b_imm ; 
assign pc_pj = pc + j_imm ;
// Drive output branch IF //
assign id_branch_taken = opcode==OP_BRANCH & b_imm[31] ; 
assign id_branch_nt_pc = id_branch_taken ? pc_p4 : pc_pb ; 
// Next PC logic //
assign pc_next_unmasked = ex_branch_flush ? ex_branch_pc       : // FLUSH
                          intrlock_bubble ? pc                 : // BUBBLE
                          opcode==OP_JAL  ? pc_pj              : // JAL PC
                          id_branch_taken ? pc_pb              : // BRANCH PC
                                            pc_p4              ; // PC + 4 
assign pc_next = jump2trap_cond ? cfg_trap_hdlr_addr : // met a trap, jump to handler
                                  pc_next_unmasked   ; // o.w, take the pc_next calculation above

// Instruction memory exceptions logic //
// ----------------------------------- //
assign exc_inst_addr_mis = |(pc_next_unmasked[1:0]) ; 
assign exc_inst_addr_oob = |(pc_next_unmasked[32-1:INST_MEM_BYTE_ADD_W]) ; 
assign jump2trap_cond = exc_inst_addr_mis | exc_inst_addr_oob | exc_main_addr_mis | exc_main_addr_oob ; 

// Memory Interface //
// ---------------- //
assign mem_addr = pc ; 
assign int_inst = ex_branch_flush ? BUBBLE      :
                                    mem_dat_out ; 

// Output instruction //
// ------------------ //
assign id_inst = int_inst ; 

endmodule


//|~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~|//
//|                                               |//
//| 1. Project  :  etcpu                          |//
//| 2. Author   :  Etay Sela                      |//
//| 3. Date     :  2025-02-08                     |//
//| 4. Version  :  v1.0.0                         |//
//|                                               |//
//|~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~|//
