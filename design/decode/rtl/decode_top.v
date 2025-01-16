// 
// decode_top.v 
//

module decode_top ( 
   // General Signals //
   // --------------- //
   input  logic          clk        , // clock signal
   input  logic          rst_n      , // active low reset

   // Write-back Inputs //
   // ----------------- //
   input  logic [32-1:0] wb_inst   , // writeback instruction
   input  logic [32-1:0] wb_dat    , // Regfile write-data from writeback

   // Fetch Inputs //
   // ------------ //
   input  logic [32-1:0] if_inst   , // Input instruction 

   // Execute Outputs // 
   // --------------- //
   output logic [32-1:0] ex_inst   , // Output instruction 
   output logic [32-1:0] ex_dat_a  , // Output A : rd1 
   output logic [32-1:0] ex_dat_b  , // Output B : rd2 or immediate 
   output logic [32-1:0] ex_addr     // Address for store operations : rd2 
);

// Import package //
// -------------- //
import utils_top::* ; 

// Internal Wires //
// -------------- //
// Immediate assembly //
logic [32-1:0] inst    ; // input instruction 
logic [32-1:0] i_imm   ; // I-type immediate
logic [32-1:0] s_imm   ; // S-type immediate
logic [32-1:0] b_imm   ; // B-type immediate
logic [32-1:0] u_imm   ; // U-type immediate
logic [32-1:0] j_imm   ; // J-type immediate
// Immediate select //
logic [ 7-1:0] opcode  ; // opcode
logic [32-1:0] imm     ; // immediate
// Register File // 
logic          rgf_we  ; // Register File, write-enable 
logic [05-1:0] rgf_wa  ; // Register File, write-address
logic [32-1:0] rgf_wd  ; // Register File, write-data
logic [05-1:0] rgf_rs1 ; // Register File, read port #1 address 
logic [05-1:0] rgf_rs2 ; // Register File, read port #2 address 
logic [32-1:0] rgf_rd1 ; // Register File, read port #1 data
logic [32-1:0] rgf_rd2 ; // Register File, read port #2 data

// Immediate assembly unit // 
// ----------------------- //
assign inst  = if_inst ; 
// I-type // 
assign i_imm = { {21{inst[31]}}            , inst[30:25] , inst[24:21] ,               inst[20] } ; 
// S-type //
assign s_imm = { {21{inst[31]}}            , inst[30:25] , inst[11:08] ,               inst[07] } ; 
// B-type //
assign b_imm = { {20{inst[31]}} , inst[07] , inst[30:25] , inst[11:08] ,                   1'b0 } ; 
// U-type //
assign u_imm = { inst[31]                  , inst[30:20] , inst[19:12] ,                  12'b0 } ; 
// J-type //
assign j_imm = { {12{inst[31]}} , inst[19:12] , inst[20] , inst[30:25] , inst[24:21] ,     1'b0 } ; 

// Immediate Select //
// ---------------- //
assign opcode = inst[6:0] ; 
always_comb begin
   case (opcode) 
      OP_LUI    : imm = u_imm ; 
      OP_AUIPC  : imm = u_imm ; 
      OP_STORE  : imm = s_imm ; 
      OP_JAL    : imm = j_imm ; 
      OP_BRANCH : imm = b_imm ; 
      default   : imm = i_imm ; 
   endcase
end

// Register File // 
// ------------- //
// Drive RGF inputs //
assign rgf_we  = ~(wb_inst[6:0]==OP_STORE | wb_inst[6:0]==OP_BRANCH) ; 
assign rgf_wa  = wb_inst[11:7] ; 
assign rgf_wd  = wb_dat        ; 
assign rgf_rs1 = inst[19:15]   ; 
assign rgf_rs2 = inst[24:20]   ; 
// RGF instance // 
decode_regfile i_regfile (
   // General // 
   .clk   (clk     ), // i, [1]        X logic  , clock signal
   .rst_n (rst_n   ), // i, [1]        X logic  , async reset. active low
   // Write IF // 
   .we    (rgf_we  ), // i, [1]        X logic  , write enable. active high
   .wa    (rgf_wa  ), // i, REGS_PTR_W X logic  , address to write port
   .wd    (rgf_wd  ), // i, REG_SIZE   X logic  , write data
   // Read IF // 
   .rs1   (rgf_rs1 ), // i, REGS_PTR_W X logic  , address to read port #1
   .rs2   (rgf_rs2 ), // i, REGS_PTR_W X logic  , address to read port #2
   .rd1   (rgf_rd1 ), // o, REG_SIZE   X logic  , data read port #1
   .rd2   (rgf_rd2 )  // o, REG_SIZE   X logic  , data read port #2
);

// Drive Execute Outputs // 
// --------------------- // 
assign ex_inst   =                             inst    ; 
assign ex_dat_a  =                             rgf_rd1 ;  
assign ex_dat_b  = (opcode==OP_RR) ? rgf_rd2 : imm     ; 
assign ex_addr   =                             rgf_rd2 ; 

endmodule

//|~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~|//
//|                                               |//
//| 1. Project  :  etcpu                          |//
//| 2. Author   :  Etay Sela                      |//
//| 3. Date     :  2025-01-12                     |//
//| 4. Version  :  v0.1.0                         |//
//|                                               |//
//|~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~|//
