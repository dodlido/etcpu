
from typing import Tuple, List
from math import floor

##############################
### immediate instructions ###
##############################
i_lui = {'opcode': 13, 'params': ['rd', 'imm'], 'imm_type': 'utype', 'funct3': None, 'funct7': None}
i_auipc = {'opcode': 5, 'params': ['rd', 'imm'], 'imm_type': 'utype', 'funct3': None, 'funct7': None}
i_addi = {'opcode': 4, 'params': ['rd', 'rs1', 'imm'], 'imm_type': 'itype', 'funct3': 0, 'funct7': None}
i_slti = {'opcode': 4, 'params': ['rd', 'rs1', 'imm'], 'imm_type': 'itype', 'funct3': 2, 'funct7': None}
i_sltiu = {'opcode': 4, 'params': ['rd', 'rs1', 'imm'], 'imm_type': 'itype', 'funct3': 3, 'funct7': None}
i_xori = {'opcode': 4, 'params': ['rd', 'rs1', 'imm'], 'imm_type': 'itype', 'funct3': 4, 'funct7': None}
i_ori = {'opcode': 4, 'params': ['rd', 'rs1', 'imm'], 'imm_type': 'itype', 'funct3': 6, 'funct7': None}
i_andi = {'opcode': 4, 'params': ['rd', 'rs1', 'imm'], 'imm_type': 'itype', 'funct3': 7, 'funct7': None}
i_slli = {'opcode': 4, 'params': ['rd', 'rs1', 'imm'], 'imm_type': 'itype', 'funct3': 1, 'funct7': 0}
i_srli = {'opcode': 4, 'params': ['rd', 'rs1', 'imm'], 'imm_type': 'itype', 'funct3': 5, 'funct7': 0}
i_srai = {'opcode': 4, 'params': ['rd', 'rs1', 'imm'], 'imm_type': 'itype', 'funct3': 5, 'funct7': 32}
######################################
### register-register instructions ###
######################################
i_nop = {'opcode': 12, 'params': [], 'imm_type': None, 'funct3': None, 'funct7': None}
i_add = {'opcode': 12, 'params': ['rd', 'rs1', 'rs2'], 'imm_type': None, 'funct3': 0, 'funct7': 0}
i_sub = {'opcode': 12, 'params': ['rd', 'rs1', 'rs2'], 'imm_type': None, 'funct3': 0, 'funct7': 32}
i_sll = {'opcode': 12, 'params': ['rd', 'rs1', 'rs2'], 'imm_type': None, 'funct3': 1, 'funct7': 0}
i_slt = {'opcode': 12, 'params': ['rd', 'rs1', 'rs2'], 'imm_type': None, 'funct3': 2, 'funct7': 0}
i_sltu = {'opcode': 12, 'params': ['rd', 'rs1', 'rs2'], 'imm_type': None, 'funct3': 3, 'funct7': 0}
i_xor = {'opcode': 12, 'params': ['rd', 'rs1', 'rs2'], 'imm_type': None, 'funct3': 4, 'funct7': 0}
i_srl = {'opcode': 12, 'params': ['rd', 'rs1', 'rs2'], 'imm_type': None, 'funct3': 5, 'funct7': 0}
i_sra = {'opcode': 12, 'params': ['rd', 'rs1', 'rs2'], 'imm_type': None, 'funct3': 5, 'funct7': 32}
i_or = {'opcode': 12, 'params': ['rd', 'rs1', 'rs2'], 'imm_type': None, 'funct3': 6, 'funct7': 0}
i_and = {'opcode': 12, 'params': ['rd', 'rs1', 'rs2'], 'imm_type': None, 'funct3': 7, 'funct7': 0}
###############################
### load,store instructions ###
###############################
i_lb = {'opcode': 0, 'params': ['rd', 'ptr'], 'imm_type': 'itype', 'funct3': 0, 'funct7': None}
i_lh = {'opcode': 0, 'params': ['rd', 'ptr'], 'imm_type': 'itype', 'funct3': 1, 'funct7': None}
i_lw = {'opcode': 0, 'params': ['rd', 'ptr'], 'imm_type': 'itype', 'funct3': 2, 'funct7': None}
i_lbu = {'opcode': 0, 'params': ['rd', 'ptr'], 'imm_type': 'itype', 'funct3': 4, 'funct7': None}
i_lhu = {'opcode': 0, 'params': ['rd', 'ptr'], 'imm_type': 'itype', 'funct3': 5, 'funct7': None}
i_sb = {'opcode': 8, 'params': ['rs2', 'ptr'], 'imm_type': 'stype', 'funct3': 0, 'funct7': None}
i_sh = {'opcode': 8, 'params': ['rs2', 'ptr'], 'imm_type': 'stype', 'funct3': 1, 'funct7': None}
i_sw = {'opcode': 8, 'params': ['rs2', 'ptr'], 'imm_type': 'stype', 'funct3': 2, 'funct7': None}
######################################
### control transafer instructions ###
######################################
i_jal = {'opcode': 27, 'params': ['rd', 'imm'], 'imm_type': 'jtype', 'funct3': None, 'funct7': None}
i_jalr = {'opcode': 25, 'params': ['rd', 'rs1', 'imm'], 'imm_type': 'itype', 'funct3': 0, 'funct7': None}
i_beq = {'opcode': 24, 'params': ['rs1', 'rs2', 'imm'], 'imm_type': 'btype', 'funct3': 0, 'funct7': None}
i_bne = {'opcode': 24, 'params': ['rs1', 'rs2', 'imm'], 'imm_type': 'btype', 'funct3': 1, 'funct7': None}
i_blt = {'opcode': 24, 'params': ['rs1', 'rs2', 'imm'], 'imm_type': 'btype', 'funct3': 4, 'funct7': None}
i_bge = {'opcode': 24, 'params': ['rs1', 'rs2', 'imm'], 'imm_type': 'btype', 'funct3': 5, 'funct7': None}
i_bltu = {'opcode': 24, 'params': ['rs1', 'rs2', 'imm'], 'imm_type': 'btype', 'funct3': 6, 'funct7': None}
i_bgeu = {'opcode': 24, 'params': ['rs1', 'rs2', 'imm'], 'imm_type': 'btype', 'funct3': 7, 'funct7': None}
inst_dict_of_dicts = {
    'nop': i_nop,
    'lui': i_lui,
    'auipc': i_auipc,
    'addi': i_addi,
    'slti': i_slti,
    'sltiu': i_sltiu,
    'xori': i_xori,
    'ori': i_ori,
    'andi': i_andi,
    'slli': i_slli,
    'srli': i_srli,
    'srai': i_srai,
    'add': i_add,
    'sub': i_sub,
    'sll': i_sll,
    'slt': i_slt,
    'sltu': i_sltu,
    'xor': i_xor,
    'srl': i_srl,
    'sra': i_sra,
    'or': i_or,
    'and': i_and,
    'lb': i_lb,
    'lh': i_lh,
    'lw': i_lw,
    'lbu': i_lbu,
    'lhu': i_lhu,
    'sb': i_sb,
    'sh': i_sh,
    'sw': i_sw,
    'jal': i_jal,
    'jalr': i_jalr,
    'beq': i_beq,
    'bne': i_bne,
    'blt': i_blt,
    'bge': i_bge,
    'bltu': i_bltu,
    'bgeu': i_bgeu,
}

def get_inst_dict(inst: str)->dict:
    '''
    get an instruction string and returns the relevant dictionary
    '''
    # Validate instruction 
    if not inst in inst_dict_of_dicts:
        print(f'Error: instruction {inst} not found in dictionary')
        exit(2)
    
    # Return the correct dictionary
    return inst_dict_of_dicts[inst]

def split_inst(cmd_str: str)->Tuple[str, str]:
    '''
    gets a command and returns:
        1. inst (str) - the provided instruction
        2. parameters (str) - the command without the instruction
    '''
    inst = cmd_str.split()[0]
    parameters = cmd_str[len(inst):]
    return inst, parameters

def get_params_list(inst_dict: dict, params: str)->List[str]:
    '''
    validates the parameters of the instruction, 
    exits if instruction is invalid
    '''
    # handle nop instuction
    if len(inst_dict['params'])==0:
        return []
    
    # compare parameters numbers
    act_params_num = params.count(',') + 1
    exp_params_num = len(inst_dict['params'])
    if act_params_num!=exp_params_num:
        print(f'Error: number of parameters {params} did not match the expected number ({inst_dict["params"]})')
        exit(2)
    
    # Return parameters list
    params_list = params.split(',')
    params_list = [s.strip() for s in params_list]
    return params_list

def add_opcode(inst_dict: dict, running_sum: int)->int:
    '''
    adds to the current running sum the 
    opcode value of the instruction
    '''
    return running_sum + (inst_dict['opcode'] << 2)

def add_param(inst_dict: dict, param_type: str, param_value: str, running_sum: int)->int:
    '''
    adds to the current running sum the 
    value specified by the given parameter
    '''
    if param_type=='imm':
        running_sum = add_imm(inst_dict['imm_type'], param_value, running_sum)
    elif param_type=='ptr':
        imm, rs1 = param_value.split('(')[0], param_value.split('(')[1].strip(')')
        running_sum = add_imm(inst_dict['imm_type'], imm, running_sum)
        running_sum = add_reg(rs1, 15, running_sum)
    else:
        offset = 7 if param_type=='rd' else (15 if param_type=='rs1' else 20)
        running_sum = add_reg(param_value, offset, running_sum)
    return running_sum
    
def add_reg(param_value: str, offset: int, running_sum: int)->int:
    '''
    adds to the current running sum the 
    value specified by the given immediate
    '''
    reg_idx = int(param_value[1:])
    return running_sum + (reg_idx << offset)

def int_to_twos_complement(num, bit_length):
    # Handle negative numbers by adjusting to two's complement
    if num < 0:
        num = (1 << bit_length) + num
    
    # Convert the number to binary and pad to the specified bit length
    bin_repr = format(num, f'0{bit_length}b')
    
    # Convert the string representation of the binary number to a list of 1's and 0's
    return [int(bit) for bit in bin_repr]

def twos_complement_to_int(arr):
    # Replace the sign bit (most significant bit) with 0
    arr[0] = 0
    
    # Convert the modified array back into a binary string
    bin_repr = ''.join(str(bit) for bit in arr)
    
    # Convert the binary string to an integer
    return int(bin_repr, 2)

def int_to_binary_array(n: int) -> list:
    # Convert the integer to a binary string and strip off the '0b' prefix
    binary_str = bin(n)[2:]
    
    # Pad the binary string with leading zeros to make sure it's 32 bits long
    binary_str = binary_str.zfill(32)
    
    # Convert the string into a list of characters ('0' or '1') and return it
    return [int(bit) for bit in binary_str][::-1]

def binary_array_to_int(binary_array: list) -> int:
    # Initialize the result to 0
    result = 0
    
    # Iterate over the binary array (in reversed order, so least significant bit first)
    for i, bit in enumerate(binary_array):
        # Shift the current result left by 1 and add the current bit
        result |= bit << i
    
    return result

def binary_array_to_int_reversed_2s_complement(binary_array: list) -> int:
    # Initialize the result to 0
    result = 0
    n = len(binary_array)  # Length of the array
    
    # Iterate over the binary array (in reversed order, so least significant bit first)
    for i, bit in enumerate(binary_array):
        # Shift the current result left by 1 and add the current bit
        result |= bit << i
    
    # If the sign bit (most significant bit) is 1, it's a negative number in 2's complement
    if binary_array[-1] == 1:  # Check if the last bit (sign bit) is 1
        # To convert from 2's complement, subtract 2^n from the result
        result -= (1 << n)  # Subtract 2^n (where n is the length of the array)
    
    return result

def add_imm(imm_type: str, param_value: str, running_sum: int)->int:
    '''
    adds to the current running sum the 
    value specified by the given immediate
    '''
    param_int = int(param_value)
    if imm_type=='itype':
        param_abs = twos_complement_to_int(int_to_twos_complement(param_int, 12))
        imm = param_abs<<20
    elif imm_type=='stype':
        param_abs = twos_complement_to_int(int_to_twos_complement(param_int, 12))
        imm = ((param_abs % 32) << 7) + (floor(param_abs / 32) << 25)
    elif imm_type=='btype':
        param_abs = twos_complement_to_int(int_to_twos_complement(param_int, 13))
        imm_12_1 = floor(param_abs / 2)
        imm_12_5, imm_4_1 = floor(imm_12_1 / 16), imm_12_1 % 16 
        imm_11_5 = imm_12_5 % 128
        imm_11, imm_10_5 = floor(imm_11_5 / 64), imm_11_5 % 64
        imm = (imm_11 << 7) + (imm_4_1 << 8) + (imm_10_5 << 25)
    elif imm_type=='utype':
        param_abs = twos_complement_to_int(int_to_twos_complement(param_int, 32))
        imm = floor(param_abs / (2**12))
    else: # jtype 
        param_abs = twos_complement_to_int(int_to_twos_complement(param_int, 21))
        imm_19_12, imm_11_0 = floor(param_abs / (2**12)), param_abs % (2**12)
        imm_11_1 = floor(imm_11_0 / (2))
        imm_11, imm_10_1 =  floor(imm_11_1 / (2**10)), imm_11_1 % (2**10)
        imm = (imm_19_12 << 12) + (imm_11 << 20) + (imm_10_1 << 21)
    if param_int<0:
        imm += 1<<31
    return running_sum + imm

def add_functs(running_sum: int, funct3: int=None, funct7: int=None)->int:
    if funct3:
        running_sum += funct3 << 12
    if funct7:
        running_sum += funct7 << 25
    return running_sum

def inst_str2int(cmd_str: str)->int:
    '''
    converts a string containing an RV32I command to a binary instruction
    command_str is a RISCV RV32I valid command, for example:
            addi rd, rs1, imm
    the output is the binary code representing the given command
    '''
    # 0. strip string of whitespaces
    cmd_str = cmd_str.strip()

    # 1. get instruction and parameters
    inst_str, parameters = split_inst(cmd_str)

    # 2. get instruction dictionary
    inst_dict = get_inst_dict(inst_str)

    # 3. get parameters list
    params_list = get_params_list(inst_dict, parameters)

    # 4. add oppcode to cmd_bin
    cmd_bin = add_opcode(inst_dict, 3) # inst[1:0] is fixed to 2'b11

    # 5. go over parametrs list adding each one to cmd_bin
    for i, param_value in enumerate(params_list):
        cmd_bin = add_param(inst_dict, inst_dict['params'][i], param_value, cmd_bin)
    
    # 6. add funct3, funct7
    cmd_bin = add_functs(cmd_bin, inst_dict['funct3'], inst_dict['funct7'])

    return cmd_bin

def inst_int2str(cmd_int: int)->str:
    inst_bin_arr = int_to_binary_array(cmd_int)
    opcode = binary_array_to_int(inst_bin_arr[2:7])
    funct3 = binary_array_to_int(inst_bin_arr[12:15])
    rd = binary_array_to_int(inst_bin_arr[7:12])
    rs1 = binary_array_to_int(inst_bin_arr[15:20])
    rs2 = binary_array_to_int(inst_bin_arr[20:25])
    funct7 = binary_array_to_int(inst_bin_arr[25:])
    rtype, stype, jtype, itype, btype, utype  = [12], [8], [27], [0, 25, 4], [24], [13, 5]
    # Rtype Instruction
    if opcode in rtype: 
        if funct3==i_add['funct3'] and funct7==i_add['funct7']:
            if rd==0: # this is actually a NOP
                return 'nop'
            else:
                return f'add x{rd}, x{rs1}, x{rs2}'
        elif funct3==i_sub['funct3'] and funct7==i_sub['funct7']:
            return f'sub x{rd}, x{rs1}, x{rs2}'
        elif funct3==i_sll['funct3'] and funct7==i_sll['funct7']:
            return f'sll x{rd}, x{rs1}, x{rs2}'
        elif funct3==i_slt['funct3'] and funct7==i_slt['funct7']:
            return f'slt x{rd}, x{rs1}, x{rs2}'
        elif funct3==i_sltu['funct3'] and funct7==i_sltu['funct7']:
            return f'sltu x{rd}, x{rs1}, x{rs2}'
        elif funct3==i_xor['funct3'] and funct7==i_xor['funct7']:
            return f'xor x{rd}, x{rs1}, x{rs2}'
        elif funct3==i_srl['funct3'] and funct7==i_srl['funct7']:
            return f'srl x{rd}, x{rs1}, x{rs2}'
        elif funct3==i_sra['funct3'] and funct7==i_sra['funct7']:
            return f'sra x{rd}, x{rs1}, x{rs2}'
        elif funct3==i_or['funct3'] and funct7==i_or['funct7']:
            return f'or x{rd}, x{rs1}, x{rs2}'
        elif funct3==i_and['funct3'] and funct7==i_and['funct7']:
            return f'and x{rd}, x{rs1}, x{rs2}'
        else:
            print(f'error, found a non-supported f3+f7 combo for R-type inst: funct3={funct3}, funct7={funct7}')
            exit(1)
    # Stype instruction
    elif opcode in stype:
        imm = binary_array_to_int_reversed_2s_complement(inst_bin_arr[7:12] + inst_bin_arr[25:])
        if funct3==i_sb['funct3']:
            inst_str = 'sb '
        elif funct3==i_sh['funct3']:
            inst_str = 'sh '
        elif funct3==i_sw['funct3']:
            inst_str = 'sw '
        else:
            print(f'error, found a non-supported f3 for S-type inst: funct3={funct3}')
            exit(1)
        return inst_str + f'x{rs2}, {imm}(x{rs1})'
    # Jtype inst
    elif opcode in jtype:
        imm = binary_array_to_int_reversed_2s_complement([0] + inst_bin_arr[21:31] + [inst_bin_arr[20]] + inst_bin_arr[12:20] + [inst_bin_arr[31]])
        return f'jal x{rd}, {imm}'
    # Itype inst
    elif opcode in itype:
        imm = binary_array_to_int_reversed_2s_complement(inst_bin_arr[20:])
        if opcode==4: # register-immediate calculations
            if funct3==i_addi['funct3']:
                return f'addi x{rd}, x{rs1}, {imm}'
            elif funct3==i_slti['funct3']:
                return f'slti x{rd}, x{rs1}, {imm}'
            elif funct3==i_xori['funct3']:
                return f'xori x{rd}, x{rs1}, {imm}'
            elif funct3==i_ori['funct3']:
                return f'ori x{rd}, x{rs1}, {imm}'
            elif funct3==i_andi['funct3']:
                return f'andi x{rd}, x{rs1}, {imm}'
            elif funct3==i_slli['funct3'] and funct7==i_slli['funct7']:
                return f'slli x{rd}, x{rs1}, {imm}'
            elif funct3==i_srli['funct3'] and funct7==i_srli['funct7']:
                return f'srli x{rd}, x{rs1}, {imm}'
            elif funct3==i_srai['funct3'] and funct7==i_srai['funct7']:
                return f'srai x{rd}, x{rs1}, {imm}'
            else:
                print(f'error, found a non-existing funct3=({funct3}) and funct7=({funct7}) combination for register-immediate operation')
                exit(1)
        elif opcode==0:
            if funct3==i_lb['funct3']:
                return f'lb x{rd}, {imm}(x{rs1})'
            elif funct3==i_lh['funct3']:
                return f'lh x{rd}, {imm}(x{rs1})'
            elif funct3==i_lw['funct3']:
                return f'lw x{rd}, {imm}(x{rs1})'
            else:
                print(f'error, found a non-supported funct3=({funct3}) option for load instruction')
                exit(1)
        elif opcode==25:
            return f'jalr x{rd}, x{rs1}, {imm}'
        else:
            print(f'error, found a non-supported opcode for i-type inst: opcode={opcode}')
            exit(1)
    # Btype inst
    elif opcode in btype:
        imm = binary_array_to_int_reversed_2s_complement([0] + inst_bin_arr[8:12] + inst_bin_arr[25:31] + [inst_bin_arr[7]] + [inst_bin_arr[31]])
        if funct3==i_beq['funct3']:
            inst_str = 'beq '
        elif funct3==i_bge['funct3']:
            inst_str = 'bge '
        elif funct3==i_bgeu['funct3']:
            inst_str = 'bgeu '
        elif funct3==i_blt['funct3']:
            inst_str = 'blt '
        elif funct3==i_bltu['funct3']:
            inst_str = 'bltu '
        elif funct3==i_bne['funct3']:
            inst_str = 'bne '
        else:
            print(f'error, found a non-supported f3 for B-type inst: funct3={funct3}')
            exit(1)
        return inst_str + f'x{rs1}, x{rs2}, {imm}'
    # Utype inst
    elif opcode in utype:
        imm = binary_array_to_int_reversed_2s_complement([0,0,0,0,0,0,0,0,0,0,0,0] + inst_bin_arr[12:])
        if opcode==i_lui['opcode']:
            return f'lui x{rd}, {imm}'
        elif opcode==i_auipc['opcode']:
            return f'auipc x{rd}, {imm}'
        else:
            print(f'error, found a non-supported opcode for u-type inst: opcode={opcode}')
            exit(1)
    # Non-supported opcode
    else:
        print(f'error, found a non-supported opcode {opcode}')
        exit(2)

def inst_int2rgfexp(cmd_int: int, rgf_state: List[int], mm_state: List[int], next_pc: int)->Tuple[bool, int, int, List[int]]:
    '''
    This function gets lists of the current RGF and main memory states and a RV32I command and returns:
        1. wen (bool) - write-enable signal to the RGF
        2. wa (int) - pointer to the register that should be written
        3. wd (int) - write data to the register that should be written
        4. rgf_next_state (List[int]) - next state of the register file as a result of the write
    '''
    inst_bin_arr = int_to_binary_array(cmd_int)
    opcode = binary_array_to_int(inst_bin_arr[2:7])
    funct3 = binary_array_to_int(inst_bin_arr[12:15])
    wa = binary_array_to_int(inst_bin_arr[7:12])
    rs1 = binary_array_to_int(inst_bin_arr[15:20])
    rs2 = binary_array_to_int(inst_bin_arr[20:25])
    funct7 = binary_array_to_int(inst_bin_arr[25:])
    rgf_next_state = rgf_state.copy() 
    rtype, stype, jtype, itype, btype, utype  = [12], [8], [27], [0, 25, 4], [24], [13, 5]
    # Rtype Instruction
    if opcode in rtype: 
        wen = True
        if funct3==i_add['funct3'] and funct7==i_add['funct7']:
            if wa==0: 
                wen = False # this is actually a NOP
                wd = 0
            else:
                wd = rgf_state[rs1] + rgf_state[rs2]
        elif funct3==i_sub['funct3'] and funct7==i_sub['funct7']:
            wd = rgf_state[rs1] - rgf_state[rs2]
        elif funct3==i_sll['funct3'] and funct7==i_sll['funct7']:
            wd = rgf_state[rs1] << rgf_state[rs2]
        elif funct3==i_slt['funct3'] and funct7==i_slt['funct7']:
            wd = 1 if (rgf_state[rs1] < rgf_state[rs2]) else 0
        elif funct3==i_sltu['funct3'] and funct7==i_sltu['funct7']:
            rs1_arr = int_to_binary_array(rgf_state[rs1])
            rs2_arr = int_to_binary_array(rgf_state[rs2])
            rs1_signbit = rs1_arr[31]
            rs2_signbit = rs2_arr[31]
            rs1_abs_val = binary_array_to_int(rs1_arr[:31])
            rs2_abs_val = binary_array_to_int(rs2_arr[:31])
            if rs1_signbit==rs2_signbit:
                wd = 1 if (rs1_abs_val < rs2_abs_val) else 0 
            else:
                wd = 1 if rs1_signbit==1 else 0 
        elif funct3==i_xor['funct3'] and funct7==i_xor['funct7']:
            wd = rgf_state[rs1] ^ rgf_state[rs2]
        elif funct3==i_srl['funct3'] and funct7==i_srl['funct7']:
            wd = (rgf_state[rs1] & 0xFFFFFFFF) >> rgf_state[rs2]
        elif funct3==i_sra['funct3'] and funct7==i_sra['funct7']:
            wd = rgf_state[rs1] >> rgf_state[rs2]
        elif funct3==i_or['funct3'] and funct7==i_or['funct7']:
            wd = rgf_state[rs1] | rgf_state[rs2]
        elif funct3==i_and['funct3'] and funct7==i_and['funct7']:
            wd = rgf_state[rs1] & rgf_state[rs2]
        else:
            print(f'error, found a non-supported f3+f7 combo for R-type inst: funct3={funct3}, funct7={funct7}')
            exit(1)
    # Itype Instruction
    elif opcode in itype:
        imm = binary_array_to_int_reversed_2s_complement(inst_bin_arr[20:])
        wen = True
        if opcode==4: # register-immediate calculations
            if funct3==i_addi['funct3']:
                wd = rgf_state[rs1] + imm
            elif funct3==i_slti['funct3']:
                wd = 1 if (rgf_state[rs1] < imm) else 0 
            elif funct3==i_xori['funct3']:
                wd = rgf_state[rs1] ^ imm 
            elif funct3==i_ori['funct3']:
                wd = rgf_state[rs1] | imm 
            elif funct3==i_andi['funct3']:
                wd = rgf_state[rs1] & imm 
            elif funct3==i_slli['funct3'] and funct7==i_slli['funct7']:
                wd = rgf_state[rs1] << imm 
            elif funct3==i_srli['funct3'] and funct7==i_srli['funct7']:
                wd = (rgf_state[rs1] & 0xFFFFFFFF) >> imm 
            elif funct3==i_srai['funct3'] and funct7==i_srai['funct7']:
                wd = rgf_state[rs1] >> imm 
            else:
                print(f'error, found a non-existing funct3=({funct3}) and funct7=({funct7}) combination for register-immediate operation')
                exit(1)
        elif opcode==0:
            addr = (rgf_state[rs1] + imm) >> 2
            word = mm_state[addr]
            if funct3==i_lb['funct3']:
                byte = word % (2**8)
                wd = byte
            elif funct3==i_lh['funct3']:
                half_word = word % (2**16)
                wd = half_word
            elif funct3==i_lw['funct3']:
                wd = word
            else:
                print(f'error, found a non-supported funct3=({funct3}) option for load instruction')
                exit(1)
        elif opcode==25:
            wd = next_pc
        else:
            print(f'error, found a non-supported opcode for i-type inst: opcode={opcode}')
            exit(1)
    # Jtype Instruction
    elif opcode in jtype:
        wen = True
        wd = next_pc
    # Utype Instruction
    elif opcode in utype:
        print('Utype is not supported yet because I am lazy')
        exit(1)
    # Stype or Btype Instructions - no RGF write
    elif opcode in stype or opcode in btype:
        wen = False
        wa = 0 
        wd = 0
    # Non-supported opcode
    else:
        print(f'error, found a non-supported opcode {opcode}')
        exit(1) 
    # update the written register if there is any
    if wen:
        rgf_next_state[wa] = wd
    return wen, wa, wd, rgf_next_state

def inst_int2mmexp(cmd_int: int, rgf_state: List[int], mm_state: List[int])->Tuple[bool, int, int, List[int]]:
    '''
    This function gets lists of the current RGF and main memory states and a RV32I command and returns:
        1. wen (bool) - write-enable signal
        2. wa (int) - memory write address
        3. wd (int) - memory write data
        4. mm_next_state (List[int]) - next state of the main memory as a result of the write
    '''
    inst_bin_arr = int_to_binary_array(cmd_int)
    opcode = binary_array_to_int(inst_bin_arr[2:7])
    rs1 = binary_array_to_int(inst_bin_arr[15:20])
    rs2 = binary_array_to_int(inst_bin_arr[20:25])
    stype_imm = binary_array_to_int_reversed_2s_complement(inst_bin_arr[7:12] + inst_bin_arr[25:])
    mm_next_state = mm_state.copy() 
    
    # update the output write interface and mem next state
    wa = (rgf_state[rs1] + stype_imm)
    wd = rgf_state[rs2]
    wen = 1 if opcode==8 else 0
    if wen:
        virt_addr = wa >> 2
        mm_next_state[virt_addr] = wd 
   
    return wen, wa, wd, mm_next_state

def inst_int2pcexp(cmd_int: int, rgf_state: List[int], curr_pc: int, intrlock: int, mem_depth: int)->Tuple[int, bool]:
    '''
    This function gets lists of the current RGF and main memory states and a RV32I command and returns:
        1. next_pc (int) - next program counter value
        2. flush (bool) - True if the expected branch prediction should fail and a flush should occur
    '''
    if intrlock==1:
        return curr_pc, False
    jtype, btype = 27, 24
    inst_bin_arr = int_to_binary_array(cmd_int)
    opcode = binary_array_to_int(inst_bin_arr[2:7])
    funct3 = binary_array_to_int(inst_bin_arr[12:15])
    rs1 = binary_array_to_int(inst_bin_arr[15:20])
    rs2 = binary_array_to_int(inst_bin_arr[20:25])
    rs1_arr = int_to_binary_array(rgf_state[rs1])
    rs2_arr = int_to_binary_array(rgf_state[rs2])
    rs1_signbit = rs1_arr[31]
    rs2_signbit = rs2_arr[31]
    rs1_abs_val = binary_array_to_int(rs1_arr[:31])
    rs2_abs_val = binary_array_to_int(rs2_arr[:31])
    if opcode == jtype:
        imm = binary_array_to_int_reversed_2s_complement([0] + inst_bin_arr[21:31] + [inst_bin_arr[20]] + inst_bin_arr[12:20] + [inst_bin_arr[31]])
        next_pc = curr_pc + imm
        flush = False
    elif opcode == i_jalr['opcode'] and funct3 == i_jalr['funct3']:
        imm = binary_array_to_int_reversed_2s_complement(inst_bin_arr[20:])
        next_pc = rgf_state[rs1] + imm
        flush = True
    elif opcode == btype:
        imm = binary_array_to_int_reversed_2s_complement([0] + inst_bin_arr[8:12] + inst_bin_arr[25:31] + [inst_bin_arr[7]] + [inst_bin_arr[31]])
        branch_predictor_guess = (imm < 0)
        if funct3==i_beq['funct3']:
            branch_actually_taken = (rgf_state[rs1]==rgf_state[rs2])
        elif funct3==i_bge['funct3']:
            branch_actually_taken = (rgf_state[rs1]>=rgf_state[rs2])
        elif funct3==i_bgeu['funct3']:
            if rs1_signbit==rs2_signbit:
                branch_actually_taken = True if (rs1_abs_val >= rs2_abs_val) else False 
            else:
                branch_actually_taken = True if rs1_signbit==0 else False 
        elif funct3==i_blt['funct3']:
            branch_actually_taken = (rgf_state[rs1]<rgf_state[rs2])
        elif funct3==i_bltu['funct3']:
            if rs1_signbit==rs2_signbit:
                branch_actually_taken = True if (rs1_abs_val < rs2_abs_val) else False 
            else:
                branch_actually_taken = True if rs1_signbit==1 else False 
        elif funct3==i_bne['funct3']:
            branch_actually_taken = (rgf_state[rs1]!=rgf_state[rs2])
        else:
            print(f'error, found a non-supported f3 for B-type inst: funct3={funct3}')
            exit(1)
        next_pc = curr_pc + imm if branch_actually_taken else curr_pc + 4
        flush = branch_actually_taken != branch_predictor_guess
    else:
        next_pc = curr_pc + 4 
        flush = False
    
    next_pc = next_pc % mem_depth

    return next_pc, flush
