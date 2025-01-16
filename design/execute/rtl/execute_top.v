// 
// execute_top.v 
//

module execute_top (
   // Decode Inputs // 
   // ------------- //
   input  logic [32-1:0] ex_inst    , // Input instruction 
   input  logic [32-1:0] ex_dat_a   , // Output A : rd1 
   input  logic [32-1:0] ex_dat_b   , // Output B : rd2 or immediate 
   input  logic [32-1:0] ex_rd2     , // rd2 

   // Output Forwarding IF to Decode //
   // ------------------------------ //
   output logic          id_fwd_we  , // Forwarded write-enable signal
   output logic [ 5-1:0] id_fwd_dst , // Forwarded pointer to destination register
   output logic [32-1:0] id_fwd_dat , // Forwarded data from ALU output

   // Memory Access Outputs // 
   // --------------------- //
   output logic [32-1:0] ma_inst    , // Output instruction 
   output logic [32-1:0] ma_dat     , // ALU output data
   output logic [32-1:0] ma_rd2       // rd2
);

// imports //
// ------- //
import utils_top::* ; 

// ALU instance //
// ------------ //
execute_alu i_alu (
   .opcode ( ex_inst[ 6: 0] ) , 
   .funct3 ( ex_inst[14:12] ) , 
   .funct7 ( ex_inst[   30] ) ,
   .a      ( ex_dat_a       ) , 
   .b      ( ex_dat_b       ) , 
   .y      ( ma_dat         )   
);

// Drive Forwarding Interface //
// -------------------------- //
assign id_fwd_we = ~(ex_inst[6:0]==OP_STORE | ex_inst[6:0]==OP_BRANCH) ; 
assign id_fwd_dst = ex_inst[11:7] ; 
assign id_fwd_dat = ma_dat ; 

// Drive outputs //
// ------------- //
assign ma_rd2  = ex_rd2  ; 
assign ma_inst = ex_inst ; 

endmodule

//|~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~|//
//|                                               |//
//| 1. Project  :  etcpu                          |//
//| 2. Author   :  Etay Sela                      |//
//| 3. Date     :  2025-01-12                     |//
//| 4. Version  :  v0.1.0                         |//
//|                                               |//
//|~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~|//
