// 
// execute_top.v 
//

module execute_top (
   // Decode Inputs // 
   // ------------- //
   input  logic [32-1:0] id_pc           , // Input pc
   input  logic [32-1:0] id_inst         , // Input instruction 
   input  logic [32-1:0] id_dat_a        , // Output A : rd1 
   input  logic [32-1:0] id_dat_b        , // Output B : rd2 or immediate 
   input  logic [32-1:0] id_rd2          , // rd2 

   // Output Forwarding IF to Decode //
   // ------------------------------ //
   output logic          id_fwd_we       , // Forwarded write-enable signal
   output logic [ 5-1:0] id_fwd_dst      , // Forwarded pointer to destination register
   output logic [32-1:0] id_fwd_dat      , // Forwarded data from ALU output

   // Output load condition to bubble //
   // ------------------------------- //
   output logic          ex_load         , // Execute instruction is a load, active high

   // Branch IF //
   // --------- //
   input  logic          id_branch_taken , // Branch taken by Fetcher branch prediction
   input  logic [32-1:0] id_branch_nt_pc , // non-taken branch PC 
   output logic          ex_branch_flush , // Branch flush indicator from execute stage
   output logic [32-1:0] ex_branch_pc    , // Branch flush indicator from execute stage

   // Memory Access Outputs // 
   // --------------------- //
   output logic [32-1:0] ma_inst         , // Output instruction 
   output logic [32-1:0] ma_pc           , // Output PC
   output logic [32-1:0] ma_dat          , // ALU output data
   output logic [32-1:0] ma_rd2            // rd2
);

// imports //
// ------- //
import utils_top::* ; 

// Internal Wires //
// -------------- //
logic inst_branch ;  
logic inst_jalr ;  

// ALU instance //
// ------------ //
execute_alu i_alu (
   .opcode ( id_inst[ 6: 0] ) , 
   .funct3 ( id_inst[14:12] ) , 
   .funct7 ( id_inst[   30] ) ,
   .a      ( id_dat_a       ) , 
   .b      ( id_dat_b       ) , 
   .y      ( ma_dat         )   
);

// Branch flush interface //
// ---------------------- // 
assign inst_branch = id_inst[6:0]==OP_BRANCH ; 
assign inst_jalr = id_inst[6:0]==OP_JALR ; 
execute_branch_flush i_execute_branch_flush (
   .inst_branch ( inst_branch     ),
   .inst_jalr   ( inst_jalr       ),
   .alu_dat_out ( ma_dat          ),
   .funct3      ( id_inst[14:12]  ),
   .br_pred     ( id_branch_taken ),
   .flush       ( ex_branch_flush )
);
assign ex_branch_pc = inst_jalr ? ma_dat : id_branch_nt_pc ; 

// Drive Forwarding Interface //
// -------------------------- //
assign id_fwd_we = ~(id_inst[6:0]==OP_STORE | id_inst[6:0]==OP_BRANCH) ; 
assign id_fwd_dst = id_inst[11:7] ; 
assign id_fwd_dat = ma_dat ; 

// Drive outputs //
// ------------- //
assign ex_load = id_inst[6:0]==OP_LOAD ; 
assign ma_rd2  = id_rd2  ; 
assign ma_inst = ex_branch_flush & inst_branch ? BUBBLE : id_inst ; 
assign ma_pc   = id_pc ; 

endmodule

//|~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~|//
//|                                               |//
//| 1. Project  :  etcpu                          |//
//| 2. Author   :  Etay Sela                      |//
//| 3. Date     :  2025-01-12                     |//
//| 4. Version  :  v0.1.0                         |//
//|                                               |//
//|~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~|//
