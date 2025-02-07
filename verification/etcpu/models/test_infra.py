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

async def init_test(dut, avoid_exceptions=True)->Tuple[IMDriver, any]:

    # 0. logging level
    log_level, avoid_exceptions = logging.INFO, True

    # 1. Declare Instruction Driver
    apb_driver = APBMasterDriver(dut, 'mng_apb4_s', dut.clk)
    opcode_probs = {
        'itype': 16, 
        'rtype': 8, 
        'store': 4,
        'load': 2, 
        'jalr': 1,
        'jal': 1, 
        'btype': 1
    }
    inst_driver = IMDriver(dut, 'inst_mem_wr', dut.clk, dut.INST_MEM_DEPTH.value, dut.MAIN_MEM_DEPTH.value, opcode_probs, avoid_exceptions)
    
    # 2. Start clock
    await cocotb.start(Clock(dut.clk, 1, 'ns').start())
    
    # 3. Reset to CPU, hold it active for a long time
    cpu_rst = cocotb.start_soon(reset_dut(dut.clk, dut.rst_n_cpu, int(2.2*inst_driver.inst_mem_depth)))
    
    # 4. Wait for environment reset to complete
    await cocotb.start_soon(reset_dut(dut.clk, dut.rst_n_env, 10))

    # 5. Configure CPU
    await cfg_cpu(apb_driver, 0x80)

    # 6. Fill instruction memory with NOPS
    await inst_driver._load_nops(-1)

    # 7. Start scoreboards and monitors
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
            break
        await RisingEdge(dut.clk)
    
    # 2. Lock scoreboards from adding new expected transactions
    rgf_sb.lock_expected = True
    mm_sb.lock_expected = True
    cocotb.log.info('Test Manage       : Locking Scoreboards')

    # 3. Wait for actual remaining transactions to propagate
    await ClockCycles(dut.clk, 4)

    # 4. Make sure that all scoreboards are empty
    rgf_sb.is_empty()
    mm_sb.is_empty()

    cocotb.logging.shutdown()