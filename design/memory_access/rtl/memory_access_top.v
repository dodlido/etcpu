// 
// memory_access_top.v 
//

module memory_access_top 
(
   // Input from execute stage // 
   // ------------------------ //
   input  logic [32-1:0] ex_inst   , // Output instruction 
   input  logic [32-1:0] ex_dat    , // ALU output data
   input  logic [32-1:0] ex_rd2    , // Address for store operations

   // Output Forwarding IF to Decode //
   // ------------------------------ //
   output logic          id_fwd_we  , // Forwarded write-enable signal
   output logic [ 5-1:0] id_fwd_dst , // Forwarded pointer to destination register
   output logic [32-1:0] id_fwd_dat , // Forwarded data from ALU output

   // Output to write back stage // 
   // -------------------------- //
   output logic [32-1:0] wb_dat    , // writeback data
   output logic [32-1:0] wb_inst   , // writeback instruction

   // ----------------------------------------------------------------- //
   // ------------------------ Memory Interface ----------------------- // 
   // ----------------------------------------------------------------- //
   // Input control // 
   // ------------- //
   output logic          mem_cs     , // Chip-select 
   output logic          mem_wen    , // Write enable
   output logic [32-1:0] mem_addr   , // Address  

   // Input data // 
   // ---------- //
   output logic [32-1:0] mem_dat_in , // Input data (from memory POV)

   // Output data // 
   // ----------- //
   input  logic [32-1:0] mem_dat_out  // Output data (from memory POV)

);

// Import package //
// -------------- //
import utils_top::* ; 

// Internal Wires //
// -------------- //
logic [7-1:0] opcode      ; 
logic         mem_wen_int ; 
logic         wb_sel_mem  ; 

// Memory write logic //
// ------------------ //
assign opcode = ex_inst[6:0] ;
assign mem_wen_int = opcode==OP_STORE ; // write enable in store instructions only

// WB select logic //
// --------------- //
assign wb_sel_mem = opcode==OP_LOAD ; 
assign wb_dat = wb_sel_mem ? mem_dat_out : ex_dat ; 
assign wb_inst = ex_inst ; 

// Memory interface //
// ---------------- //
assign mem_cs     = 1'b1        ; 
assign mem_wen    = mem_wen_int ; 
assign mem_addr   = ex_dat      ; 
assign mem_dat_in = ex_rd2      ; 

// Drive Forwarding Interface //
// -------------------------- //
assign id_fwd_we = ~(wb_inst[6:0]==OP_STORE | wb_inst[6:0]==OP_BRANCH) ; 
assign id_fwd_dst = wb_inst[11:7] ; 
assign id_fwd_dat = wb_dat ; 

endmodule

//|~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~|//
//|                                               |//
//| 1. Project  :  etcpu                          |//
//| 2. Author   :  Etay Sela                      |//
//| 3. Date     :  2025-01-12                     |//
//| 4. Version  :  v0.1.0                         |//
//|                                               |//
//|~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~|//
