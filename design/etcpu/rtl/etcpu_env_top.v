// 
// etcpu_env_top.v
//

//module etcpu_env_top #(INST_MEM_DEPTH=1024, MAIN_MEM_DEPTH=32)(
module etcpu_env_top #(
   // Parameters //
   // ---------- //
   parameter  int INST_MEM_DEPTH = 512 , // Instruction memory depth
   parameter  int MAIN_MEM_DEPTH =  64 , // Main memory depth
   parameter  int APB_ADD_W      =   4 , // APB's address bus width [bits]
   parameter  int APB_DAT_W      =  32 , // APB's data bus width [bits]
   // Derived parameters //
   // ------------------ //
   localparam int APB_STRB_W     = int'(APB_DAT_W/8)   // APB's strobe bus width [bits]
)(
   // General //
   // ------- //
   input logic                   clk                , 
   input logic                   rst_n_cpu          , 
   input logic                   rst_n_env          , 

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


   // Write instructions //
   // ------------------ //
   input logic                   inst_mem_wr_wen    , 
   input logic [32         -1:0] inst_mem_wr_addr   , 
   input logic [32         -1:0] inst_mem_wr_dat    ,  

   // Exceptions //
   // ---------- //
   output logic                  etcpu_exc_evnt       // an aggregation of all CPU exceptions 
);

// Localparamers // 
// ------------- //
localparam INST_MEM_BYTE_ADD_W = $clog2(INST_MEM_DEPTH) + 2 ; 
localparam MAIN_MEM_BYTE_ADD_W = $clog2(MAIN_MEM_DEPTH) + 2 ; 

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
etcpu_top #(
   .INST_MEM_BYTE_ADD_W(INST_MEM_BYTE_ADD_W),
   .MAIN_MEM_BYTE_ADD_W(MAIN_MEM_BYTE_ADD_W),
   .APB_ADD_W          (APB_ADD_W          ),
   .APB_DAT_W          (APB_DAT_W          ) 
) i_etcpu_top (
   // General Signals //
   .clk                (clk                ), // i, [1] X logic  , clock signal
   .rst_n              (rst_n_cpu          ), // i, [1] X logic  , active low reset
   // APB IF // 
   .mng_apb4_s_paddr   (mng_apb4_s_paddr   ),
   .mng_apb4_s_pprot   (mng_apb4_s_pprot   ),
   .mng_apb4_s_psel    (mng_apb4_s_psel    ),
   .mng_apb4_s_penable (mng_apb4_s_penable ),
   .mng_apb4_s_pwrite  (mng_apb4_s_pwrite  ),
   .mng_apb4_s_pwdata  (mng_apb4_s_pwdata  ),
   .mng_apb4_s_pstrb   (mng_apb4_s_pstrb   ),
   .mng_apb4_s_pwakeup (mng_apb4_s_pwakeup ),
   .mng_apb4_s_pready  (mng_apb4_s_pready  ),
   .mng_apb4_s_prdata  (mng_apb4_s_prdata  ),
   .mng_apb4_s_pslverr (mng_apb4_s_pslverr ),
   // Exceptions //
   .exc_evnt_agg       (etcpu_exc_evnt     ), // o, [1] X logic  , aggregation of all CPU exceptions
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
assign inst_mem_rd_addr_wrapped = 32'(inst_mem_rd_addr[INST_MEM_BYTE_ADD_W-1:0]) ; 
assign inst_mem_addr = inst_mem_wr_wen ? inst_mem_wr_addr : inst_mem_rd_addr_wrapped ; 
gen_sp_reg_mem_top #(
   .DAT_W        (32                      ), // type: int, default: 8, description: data width in bits
   .DEPTH        (INST_MEM_DEPTH          ), // type: int, default: 3, description: 
   .ADD_W        (INST_MEM_BYTE_ADD_W - 2 ), // type: int, default: $, description: 
   .BIT_EN_OPT   (1'b0                    )  // type: bit, default: 1, description: 
) i_inst_mem (
   // General // 
   .clk     (clk                                    ), // i, 0:0   X logic  , clock signal
   .rst_n   (rst_n_env                              ), // i, 0:0   X logic  , Async reset. active low
   // Input control // 
   .cs      (1'b1                                   ), // i, 0:0   X logic  , Chip-select
   .wen     (inst_mem_wr_wen                        ), // i, 0:0   X logic  , Write enable
   .add     (inst_mem_addr[INST_MEM_BYTE_ADD_W-1:2] ), // i, ADD_W X logic  , Address
   // Input data // 
   .dat_in  (inst_mem_wr_dat                        ), // i, DAT_W X logic  , Input data
   .bit_sel (0                                      ), // i, DAT_W X logic  , bit-select
   // Output data // 
   .dat_out (inst_mem_dat_out                       )  // o, DAT_W X logic  , Output data
);

// Main memory //
// ----------- //
gen_sp_reg_mem_top #(
   .DAT_W        (32                      ), // type: int, default: 8, description: data width in bits
   .DEPTH        (MAIN_MEM_DEPTH          ), // type: int, default: 3, description: 
   .ADD_W        (MAIN_MEM_BYTE_ADD_W - 2 ), // type: int, default: $, description: 
   .BIT_EN_OPT   (1'b0                    )  // type: bit, default: 1, description: 
) i_main_mem (
   // General // 
   .clk     (clk                                    ), // i, 0:0   X logic  , clock signal
   .rst_n   (rst_n_env                              ), // i, 0:0   X logic  , Async reset. active low
   // Input control // 
   .cs      (main_mem_cs                            ), // i, 0:0   X logic  , Chip-select
   .wen     (main_mem_wen                           ), // i, 0:0   X logic  , Write enable
   .add     (main_mem_addr[MAIN_MEM_BYTE_ADD_W-1:2] ), // i, ADD_W X logic  , Address
   // Input data // 
   .dat_in  (main_mem_dat_in                        ), // i, DAT_W X logic  , Input data
   .bit_sel (0                                      ), // i, DAT_W X logic  , bit-select
   // Output data // 
   .dat_out (main_mem_dat_out                       )  // o, DAT_W X logic  , Output data
);

endmodule
