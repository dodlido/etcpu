package utils_top;

// Register File Dimenstions // 
// ------------------------- // 
parameter REG_SIZE   = 32               ; // Register size in [bits]
parameter REGS_NUM   = 32               ; // Number of registers in regfile
parameter REGS_PTR_W = $clog2(REGS_NUM) ; // Register pointers size in [bits] 

// OP CODES //
// -------- //
parameter                     OP_CODE_W = 7          ; // Opcode width [bits]
parameter bit [OP_CODE_W-1:0] OP_LUI    = 7'b0110111 ; // LUI opcode               , U-Type
parameter bit [OP_CODE_W-1:0] OP_AUIPC  = 7'b0010111 ; // AUIPC opcode             , U-Type
parameter bit [OP_CODE_W-1:0] OP_IMM    = 7'b0010011 ; // Immediate opcode         , I-Type
parameter bit [OP_CODE_W-1:0] OP_RR     = 7'b0110011 ; // Register-register opcode , R-Type
parameter bit [OP_CODE_W-1:0] OP_FENCE  = 7'b0001111 ; // Fence opcode             , TODO
parameter bit [OP_CODE_W-1:0] OP_CSR    = 7'b1110011 ; // CSR opcode               , TODO
parameter bit [OP_CODE_W-1:0] OP_LOAD   = 7'b0000011 ; // Load opcode              , I-Type
parameter bit [OP_CODE_W-1:0] OP_STORE  = 7'b0100011 ; // Store opcode             , S-Type
parameter bit [OP_CODE_W-1:0] OP_JAL    = 7'b1101111 ; // JAL opcode               , J-Type
parameter bit [OP_CODE_W-1:0] OP_JALR   = 7'b1100111 ; // JALR opcode              , I-type
parameter bit [OP_CODE_W-1:0] OP_BRANCH = 7'b1100011 ; // Branches opcode          , B-type

endpackage
