import json
from pathlib import Path
from typing import Tuple
import logging
import cocotb
from cocotb.clock import Clock
import cocotb.regression
import cocotb.utils
from cocotb.triggers import RisingEdge
from models.etcpu_ref import *
from regen.apb_infra import *

def load_registers_dict(json_path: Path):
    with open(json_path, 'r') as file:
        return json.load(file)
rgf_dict = load_registers_dict('/home/etay-sela/design/veri_home/cpuws/etcpu/verification/etcpu/registers/etcpu_mng_regs.json')

async def reset_dut(clock, rst_n, cycles):
    rst_n.value = 0
    for _ in range(cycles):
        await RisingEdge(clock)
    rst_n.value = 1
    rst_n._log.debug("Reset complete")

async def cfg_cpu(driver: APBMasterDriver, trap_base_addr: int):
    trans_trap_hdlr_base = APBTransaction('etcpu_mng_regs_cfg_trap_hdlr_addr', rgf_dict, trap_base_addr, True)
    await driver._driver_send(trans_trap_hdlr_base)

async def init_test(dut)->Tuple[IMDriver, any]:

    # 0. logging level
    log_level = logging.INFO

    # 1. Declare Instruction Driver
    apb_driver = APBMasterDriver(dut, 'mng_apb4_s', dut.clk)
    inst_driver = IMDriver(dut, 'inst_mem_wr', dut.clk, dut.INST_MEM_DEPTH.value)
    
    # 2. Start clock
    await cocotb.start(Clock(dut.clk, 1, 'ns').start())
    
    # 3. Reset to CPU, hold it active for a long time
    cpu_rst = cocotb.start_soon(reset_dut(dut.clk, dut.rst_n_cpu, int(2.2*inst_driver.inst_mem_depth)))
    
    # 4. Wait for environment reset to complete
    await cocotb.start_soon(reset_dut(dut.clk, dut.rst_n_env, 10))

    # 5. Configure CPU
    await cfg_cpu(apb_driver, int((dut.INST_MEM_DEPTH.value - 10)*4))

    # 6. Fill instruction memory with NOPS
    await inst_driver._load_nops(-1)

    # 7. Start monitors and scoreboards
    pc_scoreboard, rgf_scoreboard, mm_scoreboard = PCScoreboard(), RGFScoreboard(), MMScoreboard(dut.MAIN_MEM_DEPTH.value)
    exc_inst_mis_sb, exc_inst_oob_sb, exc_main_mis_sb, exc_main_oob_sb = EXCScoreboard('INST_MIS_SB'), EXCScoreboard('INST_OOB_SB'), EXCScoreboard('MAIN_MIS_SB'), EXCScoreboard('MAIN_OOB_SB')
    exc_inst_mis_mon= EXCMonitor(dut.clk, dut.rst_n_cpu, dut.i_etcpu_top.exc_inst_addr_mis, exc_inst_mis_sb, log_level)
    exc_inst_oob_mon= EXCMonitor(dut.clk, dut.rst_n_cpu, dut.i_etcpu_top.exc_inst_addr_oob, exc_inst_oob_sb, log_level)
    exc_main_mis_mon= EXCMonitor(dut.clk, dut.rst_n_cpu, dut.i_etcpu_top.exc_main_addr_mis, exc_main_mis_sb, log_level)
    exc_main_oob_mon= EXCMonitor(dut.clk, dut.rst_n_cpu, dut.i_etcpu_top.exc_main_addr_oob, exc_main_oob_sb, log_level)
    inst_monitor = IMMonitor(dut, 'inst_mem_wr', dut.clk, log_level)
    main_mem_monitor = MMMonitor(dut, 'main_mem', dut.clk, mm_scoreboard, log_level)
    rgf_monitor = RGFMonitor(
        rgf_scoreboard, 
        dut.i_etcpu_top.i_decode_top.i_regfile.we, dut.i_etcpu_top.i_decode_top.i_regfile.wa, dut.i_etcpu_top.i_decode_top.i_regfile.wd,
        dut.i_etcpu_top.i_decode_top.wb_inst, dut.i_etcpu_top.i_decode_top.wb_pc, 
        dut.clk, log_level
    )
    pc_monitor = PCMonitor(
        dut.clk, dut.rst_n_cpu, dut.i_etcpu_top.pc, dut.i_etcpu_top.if2id_inst_next,
        inst_driver.inst_mem_depth, dut.i_etcpu_top.intrlock_bubble, dut.i_etcpu_top.cfg_trap_hdlr_addr,
        pc_scoreboard, rgf_scoreboard, mm_scoreboard,
        exc_inst_mis_mon, exc_inst_oob_mon, exc_main_mis_mon, exc_main_oob_mon, log_level
    )
    return inst_driver, cpu_rst, rgf_scoreboard, mm_scoreboard

async def close_test(dut, cpu_rst, max_runtime, mem_depth, rgf_sb: RGFScoreboard, mm_sb: MMScoreboard):

    # 0. Wait for CPU reset to end
    await cpu_rst

    # 1. Kill the test after some time or edge of instruction memory reached
    for _ in range(max_runtime):
        if dut.inst_mem_rd_addr.value==((mem_depth << 2)-4):
            cocotb.logging.shutdown()
            break
        await RisingEdge(dut.clk)
    
    # 2. Lock scoreboards from adding new expected transactions
    rgf_sb.lock_expected = True
    mm_sb.lock_expected = True

    # 3. Wait for actual remaining transactions to propagate
    await ClockCycles(dut.clk, 4)

    # 4. Make sure that all scoreboards are empty
    rgf_sb.is_empty()
    mm_sb.is_empty()

@cocotb.test()
async def test_basic(dut):
    '''
    basic test:
        1. addi x1, x0, 7 
        2. addi x2, x0, 4
        3. sub  x3, x1, x2
        4. sw x3, 4(x2)
        5. lw x4, 4(x2)  
    '''
    inst_driver, cpu_rst, rgf_sb, mm_sb = await init_test(dut)
    await inst_driver._driver_send('addi x1, x0, 7')
    await inst_driver._driver_send('addi x2, x0, 4')
    await inst_driver._load_nops(5)
    await inst_driver._driver_send('sub x3, x1, x2')
    await inst_driver._load_nops(5)
    await inst_driver._driver_send('sw x3, 4(x2)')
    await inst_driver._load_nops(5)
    await inst_driver._driver_send('lw x4, 4(x2)')
    await close_test(dut, cpu_rst, 30, inst_driver.inst_mem_depth, rgf_sb, mm_sb)

@cocotb.test()
async def test_data_hazard(dut):
    '''
    test RAW data hazard case:
        1. addi x1, x0, 7 
        2. addi x1, x1, 4
    '''
    inst_driver, cpu_rst, rgf_sb, mm_sb = await init_test(dut)
    await inst_driver._driver_send('addi x1, x0, 7')
    await inst_driver._driver_send('addi x1, x1, 4')
    await close_test(dut, cpu_rst, 30, inst_driver.inst_mem_depth, rgf_sb, mm_sb)

@cocotb.test()
async def test_interlock_scenario(dut):
    '''
    test pipe interlock scenario:
        1. addi x1, x0, 7 
        2. sw   x1, 0(x0)
        3. nop X 5 
        4. lw x2, 0(x0)
        5. add x3, x2, x2
    '''
    inst_driver, cpu_rst, rgf_sb, mm_sb = await init_test(dut)
    await inst_driver._driver_send('addi x1, x0, 7')
    await inst_driver._driver_send('sw x1, 0(x0)')
    await inst_driver._load_nops(5)
    await inst_driver._driver_send('lw x2, 0(x0)')
    await inst_driver._driver_send('add x3, x2, x2')
    await close_test(dut, cpu_rst, 30, inst_driver.inst_mem_depth, rgf_sb, mm_sb)

@cocotb.test()
async def test_jal(dut):
    '''
    test jal instruction:
        1. nop X 5 
        2. addi x1, x1, 1
        3. jal x2, -4
    '''
    inst_driver, cpu_rst, rgf_sb, mm_sb = await init_test(dut)
    await inst_driver._load_nops(5) # 0x0, 0x4, 0x8, 0xc, 0x10
    await inst_driver._driver_send('addi x1, x1, 1') # 0x14
    await inst_driver._driver_send('jal x2, -4') # 0x18
    # Those instructions should never happen:
    await inst_driver._driver_send('addi x6, x0, 7') # 0x1c
    await inst_driver._driver_send('addi x17, x0, 137') # 0x20
    await close_test(dut, cpu_rst, 30, inst_driver.inst_mem_depth, rgf_sb, mm_sb)

@cocotb.test()
async def test_jalr(dut):
    '''
    test jalr instruction:
        1. nop X 5 (@0x0,4,8,c,10)
        2. addi x5, x0, 10 (@14)
        2. addi x1, x1, 1 (@18)
        4. jalr x2, x5, -14 (@1c)
    '''
    inst_driver, cpu_rst, rgf_sb, mm_sb = await init_test(dut)
    await inst_driver._load_nops(5) # 0x0, 0x4, 0x8, 0xc, 0x10
    await inst_driver._driver_send('addi x5, x0, 10') # 0x14
    await inst_driver._driver_send('addi x1, x1, 1') # 0x18 
    await inst_driver._driver_send('jalr x2, x5, 14') # 0x1c 
    # Those instructions should never happen:
    await inst_driver._driver_send('addi x6, x0, 7') # 0x20
    await inst_driver._driver_send('addi x17, x0, 137') # 0x24
    await close_test(dut, cpu_rst, 30, inst_driver.inst_mem_depth, rgf_sb, mm_sb)

@cocotb.test()
async def test_bne(dut):
    '''
    test jalr instruction:
        1. nop X 5
        2. addi x5, x0, 3
        3. addi x1, x1, 1  <--| 
        4. bne x1, x5, -4  >--| X 2 ==> |
        5. addi x6, x0, 7  <-------------
        5. addi x17, x0, 137
    '''
    inst_driver, cpu_rst, rgf_sb, mm_sb = await init_test(dut)
    await inst_driver._load_nops(5) # 0x0, 0x4, 0x8, 0xc, 0x10
    await inst_driver._driver_send('addi x5, x0, 3') # 0x14
    await inst_driver._driver_send('addi x1, x1, 1') # 0x18 
    await inst_driver._driver_send('bne x1, x5, -4') # 0x1c 
    # Those instructions should happen after the loop:
    await inst_driver._driver_send('addi x6, x0, 7') # 0x20
    await inst_driver._driver_send('addi x17, x0, 137') # 0x24
    await close_test(dut, cpu_rst, 30, inst_driver.inst_mem_depth, rgf_sb, mm_sb)

@cocotb.test()
async def test_srai(dut):
    '''
    test srai direct test:
        1. addi x24, x24, 3
        2. nop X5 
        3. srai x22, x24, 0
    '''
    inst_driver, cpu_rst, rgf_sb, mm_sb = await init_test(dut)
    await inst_driver._driver_send('addi x24, x24, 3')
    await inst_driver._load_nops(5) 
    await inst_driver._driver_send('srai x22, x24, 0')
    await close_test(dut, cpu_rst, 300, inst_driver.inst_mem_depth, rgf_sb, mm_sb)

@cocotb.test()
async def test_srl(dut):
    '''
    test srai direct test:
        1. addi x27, x23, 10
        2. nop X5 
        3. srl x11, x27, x10
    '''
    inst_driver, cpu_rst, rgf_sb, mm_sb = await init_test(dut)
    await inst_driver._driver_send('addi x27, x23, 10')
    await inst_driver._load_nops(5) 
    await inst_driver._driver_send('srl x11, x27, x10')
    await close_test(dut, cpu_rst, 300, inst_driver.inst_mem_depth, rgf_sb, mm_sb)

@cocotb.test()
async def test_exc_main_mis(dut):
    '''
    test main memory mis-aligned address exception:
        1. addi x1, x0, 7 
        2. addi x2, x0, 4
        3. sub  x3, x1, x2
        4. sw x3, 4(x2)
        5. lw x4, 2(x2)  
    '''
    inst_driver, cpu_rst, rgf_sb, mm_sb = await init_test(dut)
    await inst_driver._driver_send('addi x1, x0, 7')
    await inst_driver._driver_send('addi x2, x0, 4')
    await inst_driver._driver_send('sub x3, x1, x2')
    await inst_driver._driver_send('sw x3, 4(x2)')
    await inst_driver._driver_send('lw x4, 2(x2)')
    await close_test(dut, cpu_rst, 30, inst_driver.inst_mem_depth, rgf_sb, mm_sb)

@cocotb.test()
async def test_rand_inst(dut):
    '''
    test rand_inst:
        random set of instructions
    '''
    inst_driver, cpu_rst, rgf_sb, mm_sb = await init_test(dut)
    for _ in range(inst_driver.inst_mem_depth):
        await inst_driver.drive_rand_inst()
    await close_test(dut, cpu_rst, 2000, inst_driver.inst_mem_depth, rgf_sb, mm_sb)
