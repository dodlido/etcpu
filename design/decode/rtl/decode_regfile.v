module decode_regfile #(
   // Parameters // 
   // ---------- // 
   parameter REGS_PTR_W =  5 , // Register pointers width in bits
   parameter REGS_NUM   = 32 , // Number of registers in regfile
   parameter REG_SIZE   = 32   // Register size in bits
)(
   // General // 
   // ------- // 
   input  logic                  clk   , // clock signal
   input  logic                  rst_n , // async reset, active low

   // Write IF // 
   // -------- // 
   input  logic                  we    , // write enable, active high
   input  logic [REGS_PTR_W-1:0] wa    , // address to write port
   input  logic [REG_SIZE  -1:0] wd    , // write data

   // Read IF // 
   // ------- //
   input  logic [REGS_PTR_W-1:0] rs1   , // address to read port #1
   input  logic [REGS_PTR_W-1:0] rs2   , // address to read port #2
   output logic [REG_SIZE  -1:0] rd1   , // data read port #1 
   output logic [REG_SIZE  -1:0] rd2     // data read port #2 
);

// Internal Registers // 
// ------------------ // 
logic [REGS_NUM-1:0][REG_SIZE-1:0] reg_array  ; // internal register array

// Internal Wires // 
// -------------- // 
logic [REGS_NUM-1:0]               reg_we_vec ; // write-enable signal per register

// Generate register file // 
// ---------------------- //
genvar REG_IDX ; 
generate
   for (REG_IDX=0; REG_IDX<REGS_NUM; REG_IDX++) begin: gen_regfile_loop
      // Write-enable logic per register // 
      // ------------------------------- //
      assign reg_we_vec[REG_IDX] = we & (wa == REG_IDX[REGS_PTR_W-1:0]) & (REG_IDX!=0) ; // writing to X0 is diabled

      // Register Instance // 
      // ----------------- //
      always_ff @(posedge clk) 
         if (!rst_n) // reset 
            reg_array[REG_IDX] <= REG_SIZE'(0) ; 
         else if (reg_we_vec[REG_IDX]) // sample if we is active
            reg_array[REG_IDX] <= wd ; 
   end
endgenerate

// Read-ports MUXs // 
// --------------- // 
assign rd1 = reg_array[rs1] ; 
assign rd2 = reg_array[rs2] ; 

endmodule

//|~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~|//
//|                                               |//
//| 1. Project  :  etcpu                          |//
//| 2. Author   :  Etay Sela                      |//
//| 3. Date     :  2025-01-12                     |//
//| 4. Version  :  v0.1.0                         |//
//|                                               |//
//|~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~|//
