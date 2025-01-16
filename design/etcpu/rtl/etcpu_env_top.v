// 
// etcpu_env_top.v
//

module etcpu_env_top #(INST_MEM_DEPTH=256, MAIN_MEM_DEPTH=32)(
   // General //
   // ------- //
   input logic          clk              , 
   input logic          rst_n_cpu        , 
   input logic          rst_n_env        , 

   // Write instructions //
   // ------------------ //
   input logic          inst_mem_wr_wen  , 
   input logic [32-1:0] inst_mem_wr_addr , 
   input logic [32-1:0] inst_mem_wr_dat    
);

// Internal Wires //
// -------------- //
logic          main_mem_cs               ; 
logic          main_mem_wen              ; 
logic [32-1:0] main_mem_addr             ; 
logic [32-1:0] main_mem_dat_in           ; 
logic [32-1:0] main_mem_dat_out          ; 
logic [32-1:0] inst_mem_rd_addr          ; 
logic [32-1:0] inst_mem_rd_addr_wrapped  ; 
logic [32-1:0] inst_mem_dat_out          ; 
logic [32-1:0] inst_mem_addr             ; 

// CPU core instance //
// ----------------- //
etcpu_top i_etcpu_top (
   // General Signals //
   .clk              (clk              ), // i, [1] X logic  , clock signal
   .rst_n            (rst_n_cpu        ), // i, [1] X logic  , active low reset
   // -------------------- Main Memory Interface ---------------------- // 
   // Input control // 
   .main_mem_cs      (main_mem_cs      ), // o, [1] X logic  , Chip-select
   .main_mem_wen     (main_mem_wen     ), // o, [1] X logic  , Write enable
   .main_mem_addr    (main_mem_addr    ), // o, 32  X logic  , Address
   // Input data // 
   .main_mem_dat_in  (main_mem_dat_in  ), // o, 32  X logic  , Input data (from memory POV)
   // Output data // 
   .main_mem_dat_out (main_mem_dat_out ), // i, 32  X logic  , Output data (from memory POV)
   // ------------ Instruction Memory Read Interface ------------------ // 
   // Input control // 
   .inst_mem_addr    (inst_mem_rd_addr ), // o, 32  X logic  , Address
   // Output data // 
   .inst_mem_dat_out (inst_mem_dat_out ) // i, 32   X logic  , Output data (from memory POV)
);

// Instruction memory //
// ------------------ //
assign inst_mem_rd_addr_wrapped = 32'(inst_mem_rd_addr[$clog2(INST_MEM_DEPTH)+2-1:0]) ; 
assign inst_mem_addr = inst_mem_wr_wen ? inst_mem_wr_addr : inst_mem_rd_addr_wrapped ; 
gen_sp_reg_mem_top #(
   .DAT_W        (32             ), // type: int, default: 8, description: data width in bits
   .DEPTH        (INST_MEM_DEPTH ), // type: int, default: 3, description: 
   .ADD_W        (30             ), // type: int, default: $, description: 
   .BIT_EN_OPT   (1'b0           )  // type: bit, default: 1, description: 
) i_inst_mem (
   // General // 
   .clk     (clk                  ), // i, 0:0   X logic  , clock signal
   .rst_n   (rst_n_env            ), // i, 0:0   X logic  , Async reset. active low
   // Input control // 
   .cs      (1'b1                 ), // i, 0:0   X logic  , Chip-select
   .wen     (inst_mem_wr_wen      ), // i, 0:0   X logic  , Write enable
   .add     (inst_mem_addr[31:2]  ), // i, ADD_W X logic  , Address
   // Input data // 
   .dat_in  (inst_mem_wr_dat      ), // i, DAT_W X logic  , Input data
   .bit_sel (0                    ), // i, DAT_W X logic  , bit-select
   // Output data // 
   .dat_out (inst_mem_dat_out     )  // o, DAT_W X logic  , Output data
);

// Main memory //
// ----------- //
gen_sp_reg_mem_top #(
   .DAT_W        (32              ), // type: int, default: 8, description: data width in bits
   .DEPTH        (MAIN_MEM_DEPTH  ), // type: int, default: 3, description: 
   .ADD_W        (30              ), // type: int, default: $, description: 
   .BIT_EN_OPT   (1'b0            )  // type: bit, default: 1, description: 
) i_main_mem (
   // General // 
   .clk     (clk                  ), // i, 0:0   X logic  , clock signal
   .rst_n   (rst_n_env            ), // i, 0:0   X logic  , Async reset. active low
   // Input control // 
   .cs      (main_mem_cs          ), // i, 0:0   X logic  , Chip-select
   .wen     (main_mem_wen         ), // i, 0:0   X logic  , Write enable
   .add     (main_mem_addr[31:2]  ), // i, ADD_W X logic  , Address
   // Input data // 
   .dat_in  (main_mem_dat_in      ), // i, DAT_W X logic  , Input data
   .bit_sel (0                    ), // i, DAT_W X logic  , bit-select
   // Output data // 
   .dat_out (main_mem_dat_out     )  // o, DAT_W X logic  , Output data
);

endmodule
