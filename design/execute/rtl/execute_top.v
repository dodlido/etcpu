// 
// execute_top.v 
//

module execute_top (
   // Decode Inputs // 
   // ------------- //
   input  logic [32-1:0] ex_inst   , // Input instruction 
   input  logic [32-1:0] ex_dat_a  , // Output A : rd1 
   input  logic [32-1:0] ex_dat_b  , // Output B : rd2 or immediate 
   input  logic [32-1:0] ex_addr   , // Address for store operations : rd2 

   // Memory Access Outputs // 
   // --------------------- //
   output logic [32-1:0] ma_inst   , // Output instruction 
   output logic [32-1:0] ma_dat    , // ALU output data
   output logic [32-1:0] ma_addr     // Address for store operations
);

// ALU instance //
// ------------ //
execute_alu i_alu (
   .opcode ( ex_inst[ 6: 0] ) , 
   .funct3 ( ex_inst[14:12] ) , 
   .funct7 ( ex_inst[   30] ) ,
   .a      ( ex_dat_a       ) , 
   .b      ( ex_dat_b       ) , 
   .y      ( ma_dat         )   
);

// Drive outputs //
// ------------- //
assign ma_addr = ex_addr ; 
assign ma_inst = ex_inst ; 

endmodule
