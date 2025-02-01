import os
import sys
tools_dir = os.environ["tools_dir"]
sys.path.append(tools_dir)
from regen.reg_classes import *

# Configurable trap handler address
addr = CfgField('addr', 'trap handler configurable address, PC will jump here in case a non-aligned address instruction memory access is attempted', 32)
cfg_trap_hdlr = Register('cfg_trap_hdlr', 'Configurable trap handler base address', fields=[addr])

# Misaligned address exception
inst_addr_mis = IntrField('inst_addr_mis', 'misaligned address interrupt, asserted if a non-aligned address instruction memory access is attempted')
main_addr_mis = IntrField('main_addr_mis', 'misaligned address interrupt, asserted if a non-aligned address main memory access is attempted')
inst_addr_oob = IntrField('inst_addr_oob', 'out-of-bounds address interrupt, asserted if an out-of-bounds address instruction memory access is attempted')
main_addr_oob = IntrField('main_addr_oob', 'out-of-bounds address interrupt, asserted if an out-of-bounds address main memory access is attempted')

exc = Register('exc', 'exception register', fields=[inst_addr_mis, inst_addr_oob, main_addr_mis, main_addr_oob])

# epc register 
epc_per = AccessPermissions()
epc_per.set_sts()
epc_fld = Field('val', 'Exception Program Counter - holds the return address for the trap handler', epc_per, width=32, we=True)
epc_reg = Register('epc', 'Exception Program Counter', fields=[epc_fld])

# regfile
etcpu_mng_regs = RegFile('etcpu_mng_regs', 'ETCPU management registers', [cfg_trap_hdlr, exc, epc_reg])