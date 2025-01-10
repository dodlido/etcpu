// 
// fetch_top.v 
//

module fetch_top #(
   // Parameter // 
   // --------- //
   parameter INST_MEM_DEPTH = 32 , // Depth of instruction memory 
   parameter INST_MEM_DAT_W = 32 , // Width of instruction [bits]

   // Local Parameters //
   // ---------------- //
   localparam INST_MEM_ADDR_W = $clog2(INST_MEM_DEPTH) + 2 // TODO: temporary Byte-address workaround
)(
   // General Signals //
   // --------------- //
   input  logic                       clk          , // clock signal
   input  logic                       rst_n        , // active low reset

   // Program Counter Register // 
   // ------------------------ //
   input  logic [INST_MEM_ADDR_W-1:0] pc           , // Program counter value
   output logic [INST_MEM_ADDR_W-1:0] pc_next      , // Program counter next value

   // Instruction Register // 
   // -------------------- //
   output logic [INST_MEM_DAT_W -1:0] id_inst      , // Decode stage instruction 

   // Interface to Instructions Write //
   // ------------------------------- //
   input  logic                       inst_wr_we   , // Instruction write IF - we
   input  logic [INST_MEM_ADDR_W-1:0] inst_wr_addr , // Instruction write IF - address
   input  logic [INST_MEM_DAT_W -1:0] inst_wr_dat    // Instruction write IF - data
);

// Internal Wires //
// -------------- //
logic [INST_MEM_ADDR_W-1:0] inst_mem_addr ; 

// Next Program Counter Logic //
// -------------------------- //
assign pc_next = pc + INST_MEM_ADDR_W'(4) ; 

// Instruction Memory //
// ------------------ //
// MUX address to memory // 
assign inst_mem_addr = inst_wr_we ? inst_wr_addr : pc ; // TODO: temoprary assumption that there are no collisons on memory 
// Memory Instance // // TODO: temoprary reg array as instruction memory
gen_sp_reg_mem_top #(
   .DAT_W        (INST_MEM_DAT_W      ), // type: int, default: 8, description: data width in bits
   .DEPTH        (INST_MEM_DEPTH      ), // type: int, default: 3, description: 
   .ADD_W        (INST_MEM_ADDR_W - 2 ), // type: int, default: $, description: // TODO: temporary Byte-address workaround
   .DLY_USER2MEM (0                   ), // type: int, default: 0, description: User to memory delay in cycles
   .DLY_MEM2USER (0                   ), // type: int, default: 0, description: Memory to user delay in cycles
   .LOW_PWR_OPT  (1                   ), // type: bit, default: 1, description: 
   .BIT_EN_OPT   (0                   )  // type: bit, default: 1, description: 
) i_gen_sp_reg_mem_top (
   // General // 
   .clk     (clk                                ), // i, 0:0   X logic  , clock signal
   .rst_n   (rst_n                              ), // i, 0:0   X logic  , Async reset. active low
   // Input control // 
   .cs      (1'b1                               ), // i, 0:0   X logic  , Chip-select
   .wen     (inst_wr_we                         ), // i, 0:0   X logic  , Write enable
   .add     (inst_mem_addr[INST_MEM_ADDR_W-1:2] ), // i, ADD_W X logic  , Address // TODO: temporary Byte-address workaround
   // Input data // 
   .dat_in  (inst_wr_dat                        ), // i, DAT_W X logic  , Input data
   .bit_sel (INST_MEM_DAT_W'(0)                 ), // i, DAT_W X logic  , bit-select
   // Output data // 
   .dat_out (id_inst                            ) // o, DAT_W  X logic  , Output data
);

endmodule


