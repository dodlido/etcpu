// 
// decode_top.v 
//

module decode_top ( 
   // General Signals //
   // --------------- //
   input  logic          clk        , // clock signal
   input  logic          rst_n      , // active low reset

   // Data Forwarding //
   // --------------- //
   // execute // 
   input  logic          ex_fwd_we  , // Forwarded write-enable signal
   input  logic [ 5-1:0] ex_fwd_dst , // Forwarded pointer to destination register
   input  logic [32-1:0] ex_fwd_dat , // Forwarded data from ALU output
   // memory access //
   input  logic          ma_fwd_we  , // Forwarded write-enable signal
   input  logic [ 5-1:0] ma_fwd_dst , // Forwarded pointer to destination register
   input  logic [32-1:0] ma_fwd_dat , // Forwarded data from memory access phase

   // Write-back Inputs //
   // ----------------- //
   input  logic [32-1:0] wb_inst    , // writeback instruction
   input  logic [32-1:0] wb_dat     , // Regfile write-data from writeback

   // Fetch Inputs //
   // ------------ //
   input  logic [32-1:0] if_inst    , // Input instruction 

   // Execute Outputs // 
   // --------------- //
   output logic [32-1:0] ex_inst    , // Output instruction 
   output logic [32-1:0] ex_dat_a   , // Output A : rd1 
   output logic [32-1:0] ex_dat_b   , // Output B : rd2 or immediate 
   output logic [32-1:0] ex_rd2       // rd2 
);

// Import package //
// -------------- //
import utils_top::* ; 

// Internal Wires //
// -------------- //
// Immediate assembly //
logic [32-1:0] inst           ; // input instruction 
logic [32-1:0] i_imm          ; // I-type immediate
logic [32-1:0] s_imm          ; // S-type immediate
logic [32-1:0] b_imm          ; // B-type immediate
logic [32-1:0] u_imm          ; // U-type immediate
logic [32-1:0] j_imm          ; // J-type immediate
// Immediate select //        
logic [ 7-1:0] opcode         ; // opcode
logic [32-1:0] imm            ; // immediate
// Register File // 
logic          rgf_we         ; // Register File, write-enable 
logic [05-1:0] rgf_wa         ; // Register File, write-address
logic [32-1:0] rgf_wd         ; // Register File, write-data
logic [05-1:0] rgf_rs1        ; // Register File, read port #1 address 
logic [05-1:0] rgf_rs2        ; // Register File, read port #2 address 
logic [32-1:0] rgf_rd1        ; // Register File, read port #1 data
logic [32-1:0] rgf_rd2        ; // Register File, read port #2 data
logic [32-1:0] fwd_rd1        ; // Register File, read port #1 data
logic [32-1:0] fwd_rd2        ; // Register File, read port #2 data
// data forwarding //
logic [32-1:0] wb_fwd_dat     ; 
logic [05-1:0] wb_fwd_dst     ; 
logic          wb_fwd_we      ; 
logic          fwd_rd1_ex_sel ;
logic          fwd_rd1_ma_sel ;
logic          fwd_rd1_wb_sel ;
logic          fwd_rd1_no_fwd ;  
logic          fwd_rd2_ex_sel ;
logic          fwd_rd2_ma_sel ;
logic          fwd_rd2_wb_sel ;
logic          fwd_rd2_no_fwd ;  

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

// Data Forwarding //
// --------------- //
// writeback decoding //
assign wb_fwd_we  = rgf_we ; 
assign wb_fwd_dst = rgf_wa ; 
assign wb_fwd_dat = rgf_wd ; 
// MUXs control logic // 
assign fwd_rd1_ex_sel = ex_fwd_we & ex_fwd_dst==rgf_rs1 ; 
assign fwd_rd1_ma_sel = ma_fwd_we & ma_fwd_dst==rgf_rs1 & ~fwd_rd1_ex_sel ; 
assign fwd_rd1_wb_sel = wb_fwd_we & wb_fwd_dst==rgf_rs1 & ~fwd_rd1_ex_sel & ~fwd_rd1_ma_sel ; 
assign fwd_rd1_no_fwd = ~fwd_rd1_ex_sel & ~fwd_rd1_ma_sel & ~fwd_rd1_wb_sel ;  
assign fwd_rd2_ex_sel = ex_fwd_we & ex_fwd_dst==rgf_rs2 ; 
assign fwd_rd2_ma_sel = ma_fwd_we & ma_fwd_dst==rgf_rs2 & ~fwd_rd2_ex_sel ; 
assign fwd_rd2_wb_sel = wb_fwd_we & wb_fwd_dst==rgf_rs2 & ~fwd_rd2_ex_sel & ~fwd_rd2_ma_sel ; 
assign fwd_rd2_no_fwd = ~fwd_rd2_ex_sel & ~fwd_rd2_ma_sel & ~fwd_rd2_wb_sel ;  
// MUX logic // 
assign fwd_rd1 = ({32{fwd_rd1_ex_sel}} & ex_fwd_dat) | ({32{fwd_rd1_ma_sel}} & ma_fwd_dat) | ({32{fwd_rd1_wb_sel}} & wb_fwd_dat) | ({32{fwd_rd1_no_fwd}} & rgf_rd1) ; 
assign fwd_rd2 = ({32{fwd_rd2_ex_sel}} & ex_fwd_dat) | ({32{fwd_rd2_ma_sel}} & ma_fwd_dat) | ({32{fwd_rd2_wb_sel}} & wb_fwd_dat) | ({32{fwd_rd2_no_fwd}} & rgf_rd2) ; 

// Drive Execute Outputs // 
// --------------------- // 
assign ex_inst   =                             inst    ; 
assign ex_dat_a  =                             fwd_rd1 ;  
assign ex_dat_b  = (opcode==OP_RR) ? fwd_rd2 : imm     ; 
assign ex_rd2    =                             fwd_rd2 ; 

endmodule

//|~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~|//
//|                                               |//
//| 1. Project  :  etcpu                          |//
//| 2. Author   :  Etay Sela                      |//
//| 3. Date     :  2025-01-12                     |//
//| 4. Version  :  v0.1.0                         |//
//|                                               |//
//|~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~|//
