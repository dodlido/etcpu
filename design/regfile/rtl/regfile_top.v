module regfile_top #(
   // Local parameters // 
   REG_W = etcpu_pckg::REG_W , // Register pointers width in bits
   REG_N = etcpu_pckg::REG_N , // Number of registers in regfile
   REG_S = etcpu_pckg::REG_S   // Register size in bits
)(
   // General // 
   input wire             clk   , // clock signal
   input wire             rst_n , // async reset, active low
   // Read Controls // 
   input wire [REG_W-1:0] rs1   , // address to read port #1
   input wire [REG_W-1:0] rs2   , // address to read port #2
   // Write Controls // 
   input wire [REG_W-1:0] wa    , // address to write port
   input wire [REG_S-1:0] wd    , // write data
   input wire [      0:0] we    , // write enable, active high
   // Output Data // 
   output reg [REG_S-1:0] rd1   , // data read port #1 
   output reg [REG_S-1:0] rd2     // data read port #2 
);

// Internal wires // 
// -------------- // 

wire [REG_N-1:0][REG_S-1:0] reg_array ; // internal register array
wire [REG_N-1:0]            reg_we_vec; // write-enable signal per register

// Generate register file // 
// ---------------------- //

genvar REG_IDX ; 
generate
   for (REG_IDX=0; REG_IDX<REG_N; REG_IDX++) begin: gen_regfile_loop
      // Write-enable logic per register // 
      assign reg_we_vec[REG_IDX] = we & (wa==REG_IDX[REG_W-1:0]) ; 
      // register instance // 
      base_reg #(.DAT_W(REG_S)) i_base_reg (
         .clk     (clk                ),
         .rst_n   (rst_n              ),
         .en      (reg_we_vec[REG_IDX]),
         .data_in (wd                 ),
         .data_out(reg_array[REG_IDX] )
      );
   end
endgenerate

// Read-ports MUXs // 
// --------------- // 

assign rd1 = reg_array[rs1] ; 
assign rd2 = reg_array[rs2] ; 





endmodule