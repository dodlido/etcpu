// 
// memory_access_top.v 
//

module memory_access_top 
(
   // Input from execute stage // 
   // ------------------------ //
   input  logic [32-1:0] ex_inst   , // Output instruction 
   input  logic [32-1:0] ex_dat    , // ALU output data
   input  logic [32-1:0] ex_addr   , // Address for store operations

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
logic [7-1:0] opcode = ex_inst[6:0]  ; 
logic         mem_wen_int ; 
logic         wb_sel_mem  ; 

// Memory write logic //
// ------------------ //
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
assign mem_addr   = ex_addr     ; 
assign mem_dat_in = ex_dat      ; 

endmodule

