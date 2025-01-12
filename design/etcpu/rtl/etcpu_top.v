// 
// etcpu_top.v 
//

module etcpu_top (
   // General Signals //
   // --------------- //
   input  logic          clk              , // clock signal
   input  logic          rst_n            , // active low reset
   // ----------------------------------------------------------------- //
   // -------------------- Main Memory Interface ---------------------- // 
   // ----------------------------------------------------------------- //
   // Input control // 
   // ------------- //
   output logic          main_mem_cs      , // Chip-select 
   output logic          main_mem_wen     , // Write enable
   output logic [32-1:0] main_mem_addr    , // Address  
   // Input data // 
   // ---------- //
   output logic [32-1:0] main_mem_dat_in  , // Input data (from memory POV)
   // Output data // 
   // ----------- //
   input  logic [32-1:0] main_mem_dat_out , // Output data (from memory POV)
   // ----------------------------------------------------------------- //
   // ------------ Instruction Memory Read Interface ------------------ // 
   // ----------------------------------------------------------------- //
   // Input control // 
   // ------------- //
   output logic [32-1:0] inst_mem_addr    , // Address  
   // Output data // 
   // ----------- //
   input  logic [32-1:0] inst_mem_dat_out   // Output data (from memory POV)
);

// Internal Wires //
// -------------- //
// IF --> IF // 
logic [32-1:0] pc_next          ; 
// IF --> ID //
logic [32-1:0] if2id_inst_next  ; 
// MA --> WB // 
logic [32-1:0] ma2wb_inst_next  ;
logic [32-1:0] ma2wb_dat_next   ;
// ID --> EX //
logic [32-1:0] id2ex_inst_next  ; 
logic [32-1:0] id2ex_dat_a_next ;
logic [32-1:0] id2ex_dat_b_next ;
logic [32-1:0] id2ex_addr_next  ;
// EX --> MA //
logic [32-1:0] ex2ma_inst_next  ;
logic [32-1:0] ex2ma_addr_next  ;
logic [32-1:0] ex2ma_dat_next   ;

// Internal Registers //
// ------------------ //
// IF --> IF // 
logic [32-1:0] pc          ; 
// IF --> ID //
logic [32-1:0] if2id_inst  ; 
// MA --> WB // 
logic [32-1:0] ma2wb_inst  ;
logic [32-1:0] ma2wb_dat   ;
// ID --> EX //
logic [32-1:0] id2ex_inst  ; 
logic [32-1:0] id2ex_dat_a ;
logic [32-1:0] id2ex_dat_b ;
logic [32-1:0] id2ex_addr  ;
// EX --> MA //
logic [32-1:0] ex2ma_inst  ;
logic [32-1:0] ex2ma_addr  ;
logic [32-1:0] ex2ma_dat   ;

// Fetch Stage // 
// ----------- //
fetch_top i_fetch_top (
   // Program Counter Register // 
   .pc          (pc              ), // i, 32  X logic  , Program counter value
   .pc_next     (pc_next         ), // o, 32  X logic  , Program counter next value
   // Instruction Register // 
   .id_inst     (if2id_inst_next ), // o, 32  X logic  , Decode stage instruction
   // ------------------------ Memory Interface ----------------------- // 
   // Input control // 
   .mem_addr    (inst_mem_addr   ), // o, 32  X logic  , Address
   // Output data // 
   .mem_dat_out (inst_mem_dat_out)  // i, 32  X logic  , Output data (from memory POV)
);

// Decode Stage //
// ------------ //
decode_top i_decode_top (
   // General Signals //
   .clk      (clk              ), // i, [1] X logic  , clock signal
   .rst_n    (rst_n            ), // i, [1] X logic  , active low reset
   // Write-back Inputs //
   .wb_inst  (ma2wb_inst       ), // i, 32  X logic  , writeback instruction
   .wb_dat   (ma2wb_dat        ), // i, 32  X logic  , Regfile write-data from writeback
   // Fetch Inputs //
   .if_inst  (if2id_inst       ), // i, 32  X logic  , Input instruction
   // Execute Outputs // 
   .ex_inst  (id2ex_inst_next  ), // o, 32  X logic  , Output instruction
   .ex_dat_a (id2ex_dat_a_next ), // o, 32  X logic  , Output A : rd1
   .ex_dat_b (id2ex_dat_b_next ), // o, 32  X logic  , Output B : rd2 or immediate
   .ex_addr  (id2ex_addr_next  )  // o, 32  X logic  , Address for store operations : rd2
);

// Execute Stage //
// ------------- //
execute_top i_execute_top (
   // Decode Inputs // 
   .ex_inst  (id2ex_inst      ), // i, 32 X logic  , Input instruction
   .ex_dat_a (id2ex_dat_a     ), // i, 32 X logic  , Output A : rd1
   .ex_dat_b (id2ex_dat_b     ), // i, 32 X logic  , Output B : rd2 or immediate
   .ex_addr  (id2ex_addr      ), // i, 32 X logic  , Address for store operations : rd2
   // Memory Access Outputs // 
   .ma_inst  (ex2ma_inst_next ), // o, 32 X logic  , Output instruction
   .ma_dat   (ex2ma_dat_next  ), // o, 32 X logic  , ALU output data
   .ma_addr  (ex2ma_addr_next )  // o, 32 X logic  , Address for store operations
);

// Memory Access Stage //
// ------------------- //
memory_access_top i_memory_access_top (
   // Input from execute stage // 
   .ex_inst     (ex2ma_inst       ), // i, 32         X logic  , Output instruction
   .ex_dat      (ex2ma_dat        ), // i, 32         X logic  , ALU output data
   .ex_addr     (ex2ma_addr       ), // i, 32         X logic  , Address for store operations
   // Output to write back stage // 
   .wb_dat      (ma2wb_dat_next   ), // o, 32         X logic  , writeback data
   .wb_inst     (ma2wb_inst_next  ), // o, 32         X logic  , writeback instruction
   // ------------------------ Memory Interface ----------------------- // 
   // Input control // 
   .mem_cs      (main_mem_cs      ), // o, [1]        X logic  , Chip-select
   .mem_wen     (main_mem_wen     ), // o, [1]        X logic  , Write enable
   .mem_addr    (main_mem_addr    ), // o, MEM_ADDR_W X logic  , Address
   // Input data // 
   .mem_dat_in  (main_mem_dat_in  ), // o, 32         X logic  , Input data (from memory POV)
   // Output dat // 
   .mem_dat_out (main_mem_dat_out )  // i, 32         X logic  , Output data (from memory POV)
);

// FFs // 
// --- //
always_ff @(posedge clk) if (!rst_n) pc          <= 0 ; else pc          <= pc_next          ; 
always_ff @(posedge clk) if (!rst_n) if2id_inst  <= 0 ; else if2id_inst  <= if2id_inst_next  ; 
always_ff @(posedge clk) if (!rst_n) ma2wb_inst  <= 0 ; else ma2wb_inst  <= ma2wb_inst_next  ; 
always_ff @(posedge clk) if (!rst_n) ma2wb_dat   <= 0 ; else ma2wb_dat   <= ma2wb_dat_next   ; 
always_ff @(posedge clk) if (!rst_n) id2ex_inst  <= 0 ; else id2ex_inst  <= id2ex_inst_next  ; 
always_ff @(posedge clk) if (!rst_n) id2ex_dat_a <= 0 ; else id2ex_dat_a <= id2ex_dat_a_next ; 
always_ff @(posedge clk) if (!rst_n) id2ex_dat_b <= 0 ; else id2ex_dat_b <= id2ex_dat_b_next ; 
always_ff @(posedge clk) if (!rst_n) id2ex_addr  <= 0 ; else id2ex_addr  <= id2ex_addr_next  ; 
always_ff @(posedge clk) if (!rst_n) ex2ma_inst  <= 0 ; else ex2ma_inst  <= ex2ma_inst_next  ; 
always_ff @(posedge clk) if (!rst_n) ex2ma_addr  <= 0 ; else ex2ma_addr  <= ex2ma_addr_next  ; 
always_ff @(posedge clk) if (!rst_n) ex2ma_dat   <= 0 ; else ex2ma_dat   <= ex2ma_dat_next   ; 

endmodule
