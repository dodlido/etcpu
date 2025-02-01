// 
// etcpu_top.v 
//

module etcpu_top #(
   // Parameters //
   // ---------- //
   parameter  int INST_MEM_BYTE_ADD_W =  8 , // Instruction memory Byte address width [bits]
   parameter  int MAIN_MEM_BYTE_ADD_W =  8 , // Main memory Byte address width [bits]
   parameter  int APB_ADD_W           =  3 , // APB's address bus width [bits]
   parameter  int APB_DAT_W           = 32 , // APB's data bus width [bits]
   // Derived parameters //
   // ------------------ //
   localparam int APB_STRB_W     = int'(APB_DAT_W/8)   // APB's strobe bus width [bits]
)(
   // General Signals //
   // --------------- //
   input  logic                  clk                , // clock signal
   input  logic                  rst_n              , // active low reset

   // APB4 slave for management // 
   // ------------------------- //
   input  logic [APB_ADD_W -1:0] mng_apb4_s_paddr   ,
   input  logic [3         -1:0] mng_apb4_s_pprot   , 
   input  logic                  mng_apb4_s_psel    ,
   input  logic                  mng_apb4_s_penable ,
   input  logic                  mng_apb4_s_pwrite  ,
   input  logic [APB_DAT_W -1:0] mng_apb4_s_pwdata  ,
   input  logic [APB_STRB_W-1:0] mng_apb4_s_pstrb   ,
   input  logic                  mng_apb4_s_pwakeup ,
   output logic                  mng_apb4_s_pready  ,
   output logic [APB_DAT_W -1:0] mng_apb4_s_prdata  ,
   output logic                  mng_apb4_s_pslverr ,

   // Exceptions //
   // ---------- //
   output logic                  exc_evnt_agg       , // an aggregation of all CPU exceptions

   // -------------------- Main Memory Interface ---------------------- // 
   // ----------------------------------------------------------------- //
   // Input control // 
   // ------------- //
   output logic                  main_mem_cs        , // Chip-select 
   output logic                  main_mem_wen       , // Write enable
   output logic [32-1:0]         main_mem_addr      , // Address  
   // Input data // 
   // ---------- //
   output logic [32-1:0]         main_mem_dat_in    , // Input data (from memory POV)
   // Output data // 
   // ----------- //
   input  logic [32-1:0]         main_mem_dat_out   , // Output data (from memory POV)

   // ------------ Instruction Memory Read Interface ------------------ // 
   // ----------------------------------------------------------------- //
   // Input control // 
   // ------------- //
   output logic [32-1:0]         inst_mem_addr      , // Address  
   // Output data // 
   // ----------- //
   input  logic [32-1:0]         inst_mem_dat_out     // Output data (from memory POV)
);

// Internal Wires //
// -------------- //
// Configurations //
logic [32-1:0] cfg_trap_hdlr_addr      ;
// Events // 
logic          exc_inst_addr_mis       ; 
logic          exc_inst_addr_oob       ;
logic          exc_main_addr_mis       ;
logic          exc_main_addr_oob       ;
// IF --> IF // 
logic [32-1:0] pc_next                 ; 
// IF --> ID //
logic [32-1:0] if2id_inst_next         ; 
// MA --> WB // 
logic [32-1:0] ma2wb_pc_next           ; 
logic [32-1:0] ma2wb_inst_next         ;
logic [32-1:0] ma2wb_dat_next          ;
// ID --> EX //
logic [32-1:0] id2ex_pc_next           ; 
logic [32-1:0] id2ex_inst_next         ; 
logic [32-1:0] id2ex_dat_a_next        ;
logic [32-1:0] id2ex_dat_b_next        ;
logic [32-1:0] id2ex_rd2_next          ;
// EX --> MA //
logic [32-1:0] ex2ma_pc_next           ; 
logic [32-1:0] ex2ma_inst_next         ;
logic [32-1:0] ex2ma_rd2_next          ;
logic [32-1:0] ex2ma_dat_next          ;
// FWD EX --> ID // 
logic [32-1:0] ex2id_fwd_dat           ;
logic [05-1:0] ex2id_fwd_dst           ;
logic          ex2id_fwd_we            ;
// FWD MA --> ID // 
logic [32-1:0] ma2id_fwd_dat           ;
logic [05-1:0] ma2id_fwd_dst           ;
logic          ma2id_fwd_we            ;
// BUBBLE ID --> IR, PC //
logic          ex_load                 ;
logic          intrlock_bubble         ;
// Pipe Flush //
logic          branch_flush            ;
logic [32-1:0] branch_flush_pc         ;
logic          if2id_branch_taken_next ; 
logic [32-1:0] if2id_branch_nt_pc_next ; 
logic          id2ex_branch_taken_next ; 
logic [32-1:0] id2ex_branch_nt_pc_next ; 

// Internal Registers //
// ------------------ //
logic [32-1:0] pc                 ; 
// IF --> ID //
logic [32-1:0] if2id_pc           ; 
logic [32-1:0] if2id_inst         ; 
// MA --> WB // 
logic [32-1:0] ma2wb_pc           ; 
logic [32-1:0] ma2wb_inst         ;
logic [32-1:0] ma2wb_dat          ;
// ID --> EX //
logic [32-1:0] id2ex_inst         ; 
logic [32-1:0] id2ex_dat_a        ;
logic [32-1:0] id2ex_dat_b        ;
logic [32-1:0] id2ex_rd2          ;
logic [32-1:0] id2ex_pc           ; 
// EX --> MA //
logic [32-1:0] ex2ma_inst         ;
logic [32-1:0] ex2ma_rd2          ;
logic [32-1:0] ex2ma_dat          ;
logic [32-1:0] ex2ma_pc           ; 
// Pipe Flush //
logic          if2id_branch_taken ; 
logic [32-1:0] if2id_branch_nt_pc ; 
logic          id2ex_branch_taken ; 
logic [32-1:0] id2ex_branch_nt_pc ; 

// Fetch Stage // 
// ----------- //
fetch_top #(.INST_MEM_BYTE_ADD_W(INST_MEM_BYTE_ADD_W)) i_fetch_top (
   // Configurations //
   .cfg_trap_hdlr_addr (cfg_trap_hdlr_addr      ), // i, 32  X logic  , congifurable trap handler base address
   // Program Counter Register // 
   .pc                 (pc                      ), // i, 32  X logic  , Program counter value
   .pc_next            (pc_next                 ), // o, 32  X logic  , Program counter next value
   // Instruction Register // 
   .id_inst            (if2id_inst_next         ), // o, 32  X logic  , Decode stage instruction
   // Pipe interlock bubble //
   .intrlock_bubble    (intrlock_bubble         ), // i, [1] X logic  , bubble due to pipe interlock                
   // Branch Flush IF //
   .id_branch_taken    (if2id_branch_taken_next ),
   .id_branch_nt_pc    (if2id_branch_nt_pc_next ),
   .ex_branch_flush    (branch_flush            ),
   .ex_branch_pc       (branch_flush_pc         ),
   // Events // 
   .exc_main_addr_mis  (exc_main_addr_mis       ), // i, [1] X logic , exception - main memory address misaligned
   .exc_main_addr_oob  (exc_main_addr_oob       ), // i, [1] X logic , exception - main memory address out-of-bounds
   .exc_inst_addr_mis  (exc_inst_addr_mis       ), // o, [1] X logic  , exception - instruction address misaligned
   .exc_inst_addr_oob  (exc_inst_addr_oob       ), // o, [1] X logic  , exception - instruction address out-of-bounds
   // ------------------------ Memory Interface ----------------------- // 
   // Input control // 
   .mem_addr          (inst_mem_addr           ), // o, 32  X logic  , Address
   // Output data // 
   .mem_dat_out       (inst_mem_dat_out        )  // i, 32  X logic  , Output data (from memory POV)
);

// Decode Stage //
// ------------ //
decode_top i_decode_top (
   // General Signals //
   .clk             (clk                     ), // i, [1] X logic  , clock signal
   .rst_n           (rst_n                   ), // i, [1] X logic  , active low reset
   // Execute Forwarding //
   .ex_fwd_we       (ex2id_fwd_we            ), // i, [1] X logic  , forwarded write enable from execute stage
   .ex_fwd_dst      (ex2id_fwd_dst           ), // i,  5  X logic  , forwarded destination register from execute stage
   .ex_fwd_dat      (ex2id_fwd_dat           ), // i, 32  X logic  , forwarded data from execute stage
   // Memory Access Forwarding //
   .ma_fwd_we       (ma2id_fwd_we            ), // i, [1] X logic  , forwarded write enable from memory access stage
   .ma_fwd_dst      (ma2id_fwd_dst           ), // i,  5  X logic  , forwarded destination register from memory access stage
   .ma_fwd_dat      (ma2id_fwd_dat           ), // i, 32  X logic  , forwarded data from memory access stage
   // Write-back Inputs //
   .wb_pc           (ma2wb_pc                ), // o, 32  X logic  , Output pc
   .wb_inst         (ma2wb_inst              ), // i, 32  X logic  , writeback instruction
   .wb_dat          (ma2wb_dat               ), // i, 32  X logic  , Regfile write-data from writeback
   // Fetch Inputs //
   .if_pc           (if2id_pc                ), // i, 32  X logic  , Input pc
   .if_inst         (if2id_inst              ), // i, 32  X logic  , Input instruction
   // Pipe interlock bubble //
   .ex_load         (ex_load                 ), // i, [1] X logic  , execute instruction is LOAD
   .intrlock_bubble (intrlock_bubble         ), // o, [1] X logic  , bubble due to pipe interlock                
   // Branch Flush IF //
   .if_branch_taken (if2id_branch_taken      ),
   .if_branch_nt_pc (if2id_branch_nt_pc      ),
   .ex_branch_taken (id2ex_branch_taken_next ),
   .ex_branch_nt_pc (id2ex_branch_nt_pc_next ),
   .ex_branch_flush (branch_flush            ),
   // Execute Outputs // 
   .ex_pc           (id2ex_pc_next           ), // o, 32 X logic   , Output pc
   .ex_inst         (id2ex_inst_next         ), // o, 32  X logic  , Output instruction
   .ex_dat_a        (id2ex_dat_a_next        ), // o, 32  X logic  , Output A : rd1
   .ex_dat_b        (id2ex_dat_b_next        ), // o, 32  X logic  , Output B : rd2 or immediate
   .ex_rd2          (id2ex_rd2_next          )  // o, 32  X logic  , Address for store operations : rd2
);

// Execute Stage //
// ------------- //
execute_top i_execute_top (
   // Decode Inputs // 
   .id_pc           (id2ex_pc           ), // i, 32 X logic  , Input pc
   .id_inst         (id2ex_inst         ), // i, 32 X logic  , Input instruction
   .id_dat_a        (id2ex_dat_a        ), // i, 32 X logic  , Output A : rd1
   .id_dat_b        (id2ex_dat_b        ), // i, 32 X logic  , Output B : rd2 or immediate
   .id_rd2          (id2ex_rd2          ), // i, 32 X logic  , Address for store operations : rd2
   // Execute Forwarding //
   .id_fwd_we       (ex2id_fwd_we       ), // i, [1] X logic  , forwarded write enable from execute stage
   .id_fwd_dst      (ex2id_fwd_dst      ), // i,  5  X logic  , forwarded destination register from execute stage
   .id_fwd_dat      (ex2id_fwd_dat      ), // i, 32  X logic  , forwarded data from execute stage
   // Pipe interlock bubble //
   .ex_load         (ex_load            ), // o, [1] X logic  , execute instruction is LOAD
   // Branch Flush IF //
   .id_branch_taken (id2ex_branch_taken ),
   .id_branch_nt_pc (id2ex_branch_nt_pc ),
   .ex_branch_flush (branch_flush       ),
   .ex_branch_pc    (branch_flush_pc    ),
   // Memory Access Outputs // 
   .ma_pc           (ex2ma_pc_next      ), // o, 32 X logic  , Output pc
   .ma_inst         (ex2ma_inst_next    ), // o, 32 X logic  , Output instruction
   .ma_dat          (ex2ma_dat_next     ), // o, 32 X logic  , ALU output data
   .ma_rd2          (ex2ma_rd2_next     )  // o, 32 X logic  , Address for store operations
);

// Memory Access Stage //
// ------------------- //
memory_access_top #(.MAIN_MEM_BYTE_ADD_W(MAIN_MEM_BYTE_ADD_W)) i_memory_access_top (
   // Input from execute stage // 
   .ex_pc             (ex2ma_pc         ), // i, 32         X logic  , Input pc
   .ex_inst           (ex2ma_inst       ), // i, 32         X logic  , Output instruction
   .ex_dat            (ex2ma_dat        ), // i, 32         X logic  , ALU output data
   .ex_rd2            (ex2ma_rd2        ), // i, 32         X logic  , Address for store operations
   // Output to write back stage // 
   .wb_dat            (ma2wb_dat_next   ), // o, 32         X logic  , writeback data
   .wb_inst           (ma2wb_inst_next  ), // o, 32         X logic  , writeback instruction
   .wb_pc             (ma2wb_pc_next    ), // o, 32         X logic  , Output pc
   // Memory Access Forwarding //
   .id_fwd_we         (ma2id_fwd_we     ), // i, [1] X logic  , forwarded write enable from memory access stage
   .id_fwd_dst        (ma2id_fwd_dst    ), // i,  5  X logic  , forwarded destination register from memory access stage
   .id_fwd_dat        (ma2id_fwd_dat    ), // i, 32  X logic  , forwarded data from memory access stage
   // Events // 
   .exc_main_addr_mis (exc_main_addr_mis), // o, [1] X logic , exception - main memory address misaligned
   .exc_main_addr_oob (exc_main_addr_oob), // o, [1] X logic , exception - main memory address out-of-bounds
   // ------------------------ Memory Interface ----------------------- // 
   // Input control // 
   .mem_cs            (main_mem_cs      ), // o, [1]        X logic  , Chip-select
   .mem_wen           (main_mem_wen     ), // o, [1]        X logic  , Write enable
   .mem_addr          (main_mem_addr    ), // o, MEM_ADDR_W X logic  , Address
   // Input data // 
   .mem_dat_in        (main_mem_dat_in  ), // o, 32         X logic  , Input data (from memory POV)
   // Output dat // 
   .mem_dat_out       (main_mem_dat_out )  // i, 32         X logic  , Output data (from memory POV)
);

// FFs // 
// --- //
// PC register //
always_ff @(posedge clk) if (!rst_n) pc                 <=    0 ;                                                       else pc <= 32'(pc_next[INST_MEM_BYTE_ADD_W-1:0])   ; 
// PC value always takes the LSbits of pc_next determined by INST_MEM_DEPTH
// parameter. This is done to allow working with smaller instruction address
// space thus saving test time
// IF --> ID // 
always_ff @(posedge clk) if (!rst_n) if2id_pc           <=    0 ;                                                       else if2id_pc           <= pc                      ; 
always_ff @(posedge clk) if (!rst_n) if2id_inst         <=    0 ;  else if (intrlock_bubble) if2id_inst <= if2id_inst ; else if2id_inst         <= if2id_inst_next         ; 
always_ff @(posedge clk) if (!rst_n) if2id_branch_taken <= 1'b0 ;                                                       else if2id_branch_taken <= if2id_branch_taken_next ; 
always_ff @(posedge clk) if (!rst_n) if2id_branch_nt_pc <=    0 ;                                                       else if2id_branch_nt_pc <= if2id_branch_nt_pc_next ; 
// ID --> EX // 
always_ff @(posedge clk) if (!rst_n) id2ex_inst         <=    0 ;                                                       else id2ex_inst         <= id2ex_inst_next         ; 
always_ff @(posedge clk) if (!rst_n) id2ex_dat_a        <=    0 ;                                                       else id2ex_dat_a        <= id2ex_dat_a_next        ; 
always_ff @(posedge clk) if (!rst_n) id2ex_dat_b        <=    0 ;                                                       else id2ex_dat_b        <= id2ex_dat_b_next        ; 
always_ff @(posedge clk) if (!rst_n) id2ex_rd2          <=    0 ;                                                       else id2ex_rd2          <= id2ex_rd2_next          ; 
always_ff @(posedge clk) if (!rst_n) id2ex_pc           <=    0 ;                                                       else id2ex_pc           <= id2ex_pc_next           ; 
always_ff @(posedge clk) if (!rst_n) id2ex_branch_taken <= 1'b0 ;                                                       else id2ex_branch_taken <= id2ex_branch_taken_next ; 
always_ff @(posedge clk) if (!rst_n) id2ex_branch_nt_pc <=    0 ;                                                       else id2ex_branch_nt_pc <= id2ex_branch_nt_pc_next ; 
// EX --> MA // 
always_ff @(posedge clk) if (!rst_n) ex2ma_pc           <=    0 ;                                                       else ex2ma_pc           <= ex2ma_pc_next           ; 
always_ff @(posedge clk) if (!rst_n) ex2ma_inst         <=    0 ;                                                       else ex2ma_inst         <= ex2ma_inst_next         ; 
always_ff @(posedge clk) if (!rst_n) ex2ma_rd2          <=    0 ;                                                       else ex2ma_rd2          <= ex2ma_rd2_next          ; 
always_ff @(posedge clk) if (!rst_n) ex2ma_dat          <=    0 ;                                                       else ex2ma_dat          <= ex2ma_dat_next          ; 
// MA --> WB // 
always_ff @(posedge clk) if (!rst_n) ma2wb_pc           <=    0 ;                                                       else ma2wb_pc           <= ma2wb_pc_next           ; 
always_ff @(posedge clk) if (!rst_n) ma2wb_inst         <=    0 ;                                                       else ma2wb_inst         <= ma2wb_inst_next         ; 
always_ff @(posedge clk) if (!rst_n) ma2wb_dat          <=    0 ;                                                       else ma2wb_dat          <= ma2wb_dat_next          ; 

// Management registers //
// -------------------- // 
etcpu_mng_regs i_etcpu_mng_regs ( 
   // General // 
   // ------- //
   .clk   (clk   ),
   .rst_n (rst_n ),
   
   // HW IF to RGF // 
   // ------------ //
   .etcpu_mng_regs_cfg_trap_hdlr_addr        (cfg_trap_hdlr_addr ), // etcpu_mng_regs_cfg_trap_hdlr_addr: HW read port     , output(32b)
   .etcpu_mng_regs_exc_inst_addr_mis_hw_next (exc_inst_addr_mis  ), // etcpu_mng_regs_exc_inst_addr_mis: HW write port     , input(1b)
   .etcpu_mng_regs_exc_inst_addr_oob_hw_next (exc_inst_addr_oob  ), // etcpu_mng_regs_exc_inst_addr_oob: HW write port     , input(1b)
   .etcpu_mng_regs_exc_main_addr_mis_hw_next (exc_main_addr_mis  ), // etcpu_mng_regs_exc_main_addr_mis: HW write port     , input(1b)
   .etcpu_mng_regs_exc_main_addr_oob_hw_next (exc_main_addr_oob  ), // etcpu_mng_regs_exc_main_addr_oob: HW write port     , input(1b)
   .etcpu_mng_regs_epc_val_hw_next           (pc                 ), // etcpu_mng_regs_epc_val: HW write port , input(32b)
   .etcpu_mng_regs_epc_val_hw_we             (exc_evnt_agg       ), // etcpu_mng_regs_epc_val: HW write enable bit , input(1b)
   .etcpu_mng_regs___intr                    (exc_evnt_agg       ), // etcpu_mng_regs__intr: agrregation of CPU exceptions , output(1b)

   // APB IF // 
   // ------ //
   .paddr   (mng_apb4_s_paddr   ),
   .pprot   (mng_apb4_s_pprot   ),
   .psel    (mng_apb4_s_psel    ),
   .penable (mng_apb4_s_penable ),
   .pwrite  (mng_apb4_s_pwrite  ),
   .pwdata  (mng_apb4_s_pwdata  ),
   .pstrb   (mng_apb4_s_pstrb   ),
   .pwakeup (mng_apb4_s_pwakeup ),
   .pready  (mng_apb4_s_pready  ),
   .prdata  (mng_apb4_s_prdata  ),
   .pslverr (mng_apb4_s_pslverr )
);

endmodule

//|~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~|//
//|                                               |//
//| 1. Project  :  etcpu                          |//
//| 2. Author   :  Etay Sela                      |//
//| 3. Date     :  2025-01-12                     |//
//| 4. Version  :  v0.1.0                         |//
//|                                               |//
//|~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~|//
