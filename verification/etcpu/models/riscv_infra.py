
from typing import Tuple, List
from math import floor

##############################
### immediate instructions ###
##############################
i_nop = {'opcode': 12, 'params': [], 'imm_type': None, 'funct3': None, 'funct7': None}
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
i_jalr = {'opcode': 25, 'params': ['rd', 'rs1', 'imm'], 'imm_type': 'jtype', 'funct3': 0, 'funct7': None}
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

def add_imm(imm_type: str, param_value: str, running_sum: int)->int:
    '''
    adds to the current running sum the 
    value specified by the given immediate
    '''
    param_int = int(param_value)
    if imm_type=='itype':
        imm = param_int<<20
    elif imm_type=='stype':
        imm = ((param_int % 32) << 7) + (floor(param_int / 32) << 25)
    elif imm_type=='btype':
        imm_12_1 = floor(param_int / 2)
        imm_12_5, imm_4_1 = floor(imm_12_1 / 32), imm_12_1 % 32 
        imm_12, imm_11_5 = floor(imm_12_5 / 128), imm_12_5 % 128
        imm_11, imm_10_5 = floor(imm_11_5 / 64), imm_11_5 % 64
        imm = (imm_11 << 7) + (imm_4_1 << 8) + (imm_10_5 << 25) + (imm_12 << 31)
    elif imm_type=='utype':
        imm = param_int << 12
    else:
        imm_20_1 = floor(param_int / 2)
        imm_20_12, imm_11_1 = floor(imm_20_1 / (2**12)), imm_20_1 % (2**12)
        imm_11, imm_10_1 =  floor(imm_11_1 / (2**11)), imm_11_1 % (2**11)
        imm_20, imm_19_12 =  floor(imm_20_12 / (2**9)), imm_20_12 % (2**9)
        imm = (imm_19_12 << 12) + (imm_11 << 20) + (imm_10_1 << 21) + (imm_20 << 31) 
    return running_sum + imm

def add_functs(running_sum: int, funct3: int=None, funct7: int=None)->int:
    if funct3:
        running_sum += funct3 << 12
    if funct7:
        running_sum += funct7 << 25
    return running_sum

def str2bin(cmd_str: str)->int:
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
