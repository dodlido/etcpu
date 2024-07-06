package etcpu_pckg;

// Parameters // 
// ---------- // 

parameter REG_S = 32            ; // Register size in bits
parameter REG_N = 32            ; // Number of registers in regfile
parameter REG_W = $clog2(REG_N) ; // Register pointers size in bits

endpackage
