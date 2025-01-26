
1. JALR implementation is wrong: next pc address is not:
    curr_pc + rd1 + imm
but instead:
    rd1 + imm
