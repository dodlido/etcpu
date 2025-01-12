// 
// fetch_top.v 
//

module fetch_top
(
   // Program Counter Register // 
   // ------------------------ //
   input  logic [32-1:0] pc           , // Program counter value
   output logic [32-1:0] pc_next      , // Program counter next value

   // Instruction Register // 
   // -------------------- //
   output logic [32-1:0] id_inst      , // Decode stage instruction 

   // ----------------------------------------------------------------- //
   // ------------------------ Memory Interface ----------------------- // 
   // ----------------------------------------------------------------- //
   // Input control // 
   // ------------- //
   output logic [32-1:0] mem_addr   , // Address  

   // Output data // 
   // ----------- //
   input  logic [32-1:0] mem_dat_out  // Output data (from memory POV)
);

// Next Program Counter Logic //
// -------------------------- //
assign pc_next = pc + 4 ; 

// Memory Interface //
// ---------------- //
assign mem_addr = pc          ; 
assign id_inst  = mem_dat_out ; 


endmodule


