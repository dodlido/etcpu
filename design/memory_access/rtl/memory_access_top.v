// 
// memory_access_top.v 
//

module memory_access_top #(
   // Parameters //
   // ---------- //
   parameter MAIN_MEM_BYTE_ADD_W = 8 // Byte address width of main memory [bits]
)(
   // Input from execute stage // 
   // ------------------------ //
   input  logic [32-1:0] ex_pc              , // Input pc
   input  logic [32-1:0] ex_inst            , // Output instruction 
   input  logic [32-1:0] ex_dat             , // ALU output data
   input  logic [32-1:0] ex_rd2             , // Address for store operations

   // Output Forwarding IF to Decode //
   // ------------------------------ //
   output logic          id_fwd_we          , // Forwarded write-enable signal
   output logic [ 5-1:0] id_fwd_dst         , // Forwarded pointer to destination register
   output logic [32-1:0] id_fwd_dat         , // Forwarded data from ALU output

   // Output to write back stage // 
   // -------------------------- //
   output logic [32-1:0] wb_dat             , // writeback data
   output logic [32-1:0] wb_inst            , // writeback instruction
   output logic [32-1:0] wb_pc              , // Output pc

   // Events //
   // ------ //
   output logic          exc_main_addr_mis  , // exception - main memory address misaligned
   output logic          exc_main_addr_oob  , // exception - main memory address out-of-bounds

   // ----------------------------------------------------------------- //
   // ------------------------ Memory Interface ----------------------- // 
   // ----------------------------------------------------------------- //
   // Input control // 
   // ------------- //
   output logic          mem_cs      , // Chip-select 
   output logic          mem_wen     , // Write enable
   output logic [32-1:0] mem_addr    , // Address  

   // Input data // 
   // ---------- //
   output logic [32-1:0] mem_dat_in  , // Input data (from memory POV)

   // Output data // 
   // ----------- //
   input  logic [32-1:0] mem_dat_out  // Output data (from memory POV)

);

// Import package //
// -------------- //
import utils_top::* ; 

// Internal Wires //
// -------------- //
logic [ 7-1:0] opcode       ; 
logic [ 3-1:0] f3           ; 
logic          mem_wen_int  ; 
logic          wb_sel_mem   ; 
logic          wb_sel_pc    ; 
logic [ 4-1:0] mem_byte_en  ; // Byte enable to support partial store
logic [32-1:0] mem_dat_mask ; // Byte enable to support partial store

// Memory write logic //
// ------------------ //
assign opcode = ex_inst[6:0] ;
assign mem_wen_int = opcode==OP_STORE ; // write enable in store instructions only
assign f3 = ex_inst[14:12] ; 
assign mem_byte_en = (f3==3'h0 | f3==3'h4) ? 4'b0001 : // Store/Load Byte
                     (f3==3'h1 | f3==3'h5) ? 4'b0011 : // Store/Load Half
                                             4'b1111 ; // Store Word
genvar BYTE_IDX ; 
generate
   for (BYTE_IDX=0; BYTE_IDX<4; BYTE_IDX++) begin: gen_mask_loop
      assign mem_dat_mask[BYTE_IDX*8 +: 8] = {8{mem_byte_en[BYTE_IDX]}} ; 
   end
endgenerate

// WB select logic //
// --------------- //
assign wb_sel_mem = opcode==OP_LOAD ; 
assign wb_sel_pc = opcode==OP_JAL | opcode==OP_JALR ; 
assign wb_dat = wb_sel_mem ? (mem_dat_out & mem_dat_mask) : wb_sel_pc ? (wb_pc + 4) : ex_dat ; 
assign wb_inst = exc_main_addr_mis | exc_main_addr_oob ? BUBBLE : ex_inst ; 
assign wb_pc = ex_pc ; 

// Memory interface //
// ---------------- //
assign mem_cs      = 1'b1 ; 
assign mem_wen     = mem_wen_int & ~(exc_main_addr_mis | exc_main_addr_oob) ; 
assign mem_addr    = ex_dat ; 
assign mem_dat_in  = ex_rd2 & mem_dat_mask ; 

// Drive Forwarding Interface //
// -------------------------- //
assign id_fwd_we = ~(wb_inst[6:0]==OP_STORE | wb_inst[6:0]==OP_BRANCH) ; 
assign id_fwd_dst = wb_inst[11:7] ; 
assign id_fwd_dat = wb_sel_pc ? (wb_pc + 4) : wb_dat ; 

// Exceptions logic // 
// ---------------- //
assign exc_main_addr_mis = (mem_wen_int | wb_sel_mem) & (|(mem_addr[1:0])) ; 
assign exc_main_addr_oob = (mem_wen_int | wb_sel_mem) & (|(mem_addr[32-1:MAIN_MEM_BYTE_ADD_W])) ; 

endmodule

//|~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~|//
//|                                               |//
//| 1. Project  :  etcpu                          |//
//| 2. Author   :  Etay Sela                      |//
//| 3. Date     :  2025-02-08                     |//
//| 4. Version  :  v1.0.0                         |//
//|                                               |//
//|~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~|//
