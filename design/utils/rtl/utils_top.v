package utils_top;

// OP CODES //
// -------- //
parameter bit [7-1:0] OP_LUI    = 7'b0110111 ; // LUI opcode               , U-Type
parameter bit [7-1:0] OP_AUIPC  = 7'b0010111 ; // AUIPC opcode             , U-Type
parameter bit [7-1:0] OP_IMM    = 7'b0010011 ; // Immediate opcode         , I-Type
parameter bit [7-1:0] OP_RR     = 7'b0110011 ; // Register-register opcode , R-Type
parameter bit [7-1:0] OP_FENCE  = 7'b0001111 ; // Fence opcode             , TODO
parameter bit [7-1:0] OP_CSR    = 7'b1110011 ; // CSR opcode               , TODO
parameter bit [7-1:0] OP_LOAD   = 7'b0000011 ; // Load opcode              , I-Type
parameter bit [7-1:0] OP_STORE  = 7'b0100011 ; // Store opcode             , S-Type
parameter bit [7-1:0] OP_JAL    = 7'b1101111 ; // JAL opcode               , J-Type
parameter bit [7-1:0] OP_JALR   = 7'b1100111 ; // JALR opcode              , I-type
parameter bit [7-1:0] OP_BRANCH = 7'b1100011 ; // Branches opcode          , B-type

// ALU FUNC CODES //
// -------------- //
// R-type //
parameter bit [4-1:0] ALU_ADD   = 4'b0000 ; // {func7 , func3[2:0]} 
parameter bit [4-1:0] ALU_SUB   = 4'b1000 ; // {func7 , func3[2:0]} 
parameter bit [4-1:0] ALU_AND   = 4'b0111 ; // {func7 , func3[2:0]} 
parameter bit [4-1:0] ALU_OR    = 4'b0110 ; // {func7 , func3[2:0]} 
parameter bit [4-1:0] ALU_XOR   = 4'b0100 ; // {func7 , func3[2:0]} 
parameter bit [4-1:0] ALU_SLT   = 4'b0010 ; // {func7 , func3[2:0]} 
parameter bit [4-1:0] ALU_SLTU  = 4'b0011 ; // {func7 , func3[2:0]} 
// B-type //
parameter bit [3-1:0] ALU_BEQ   =  3'b000 ; // func3[2:0]
parameter bit [3-1:0] ALU_BNE   =  3'b001 ; // func3[2:0]
parameter bit [3-1:0] ALU_BLT   =  3'b100 ; // func3[2:0]
parameter bit [3-1:0] ALU_BGE   =  3'b101 ; // func3[2:0]
parameter bit [3-1:0] ALU_BGEU  =  3'b111 ; // func3[2:0]
// I-type //
parameter bit [3-1:0] ALU_ADDI  =  3'b000 ; // func3[2:0]
parameter bit [4-1:0] ALU_SLLI  = 4'b0001 ; // {func7 , func3[2:0]} 
parameter bit [3-1:0] ALU_SLTI  =  3'b010 ; // func3[2:0]
parameter bit [3-1:0] ALU_SLTIU =  3'b011 ; // func3[2:0]
parameter bit [3-1:0] ALU_XORI  =  3'b100 ; // func3[2:0]
parameter bit [4-1:0] ALU_SRLI  = 4'b0101 ; // {func7 , func3[2:0]} 
parameter bit [4-1:0] ALU_SRAI  = 4'b1101 ; // {func7 , func3[2:0]} 
parameter bit [3-1:0] ALU_ORI   =  3'b110 ; // func3[2:0]
parameter bit [3-1:0] ALU_ANDI  =  3'b111 ; // func3[2:0]

endpackage
