import cocotb
from cocotb.clock import Clock
import cocotb.regression
import cocotb.utils
from cocotb.triggers import RisingEdge, ClockCycles
from models.etcpu_ref import *

# Reset DUT
async def reset_dut(clock, rst_n, cycles):
    rst_n.value = 0
    for _ in range(cycles):
        await RisingEdge(clock)
    rst_n.value = 1
    rst_n._log.debug("Reset complete")

async def init_test(dut)->IMDriver:
    # 1. Declare Instruction Driver
    inst_driver = IMDriver(dut, 'inst_mem_wr', dut.clk, 256)
    
    # 2. Start clock
    await cocotb.start(Clock(dut.clk, 1, 'ns').start())
    
    # 3. Reset to CPU, hold it active for a long time
    cpu_rst = cocotb.start_soon(reset_dut(dut.clk, dut.rst_n_cpu, int(1.2*inst_driver.inst_mem_depth)))
    
    # 4. Wait for environment reset to complete
    await cocotb.start_soon(reset_dut(dut.clk, dut.rst_n_env, 10))

    # 5. Fill instruction memory with NOPS
    await inst_driver._load_nops(-1)

    # 6. Start monitors and scoreboards
    pc_scoreboard, rgf_scoreboard, mm_scoreboard = PCScoreboard(), RGFScoreboard(), MMScoreboard(32)
    inst_monitor = IMMonitor(dut, 'inst_mem_wr', dut.clk)
    main_mem_monitor = MMMonitor(dut, 'main_mem', dut.clk)
    rgf_monitor = RGFMonitor(
        rgf_scoreboard, 
        dut.i_etcpu_top.i_decode_top.i_regfile.we,
        dut.i_etcpu_top.i_decode_top.i_regfile.wa,
        dut.i_etcpu_top.i_decode_top.i_regfile.wd,
        dut.i_etcpu_top.i_decode_top.wb_inst, 
        dut.i_etcpu_top.i_decode_top.wb_pc, 
        dut.clk
    )
    pc_monitor = PCMonitor(
        dut.clk,
        dut.rst_n_cpu,
        dut.i_etcpu_top.pc,
        dut.i_etcpu_top.if2id_inst_next,
        dut.i_etcpu_top.intrlock_bubble,
        pc_scoreboard,
        rgf_scoreboard,
        mm_scoreboard
    )
    return inst_driver, cpu_rst

async def close_test(dut, cpu_rst, max_runtime, mem_depth):
    # 6. Wait for CPU reset to end
    await cpu_rst

    # 7. Kill the test after some time or edge of instruction memory reached
    for _ in range(max_runtime):
        if dut.inst_mem_rd_addr.value==(mem_depth << 2):
            break
        await RisingEdge(dut.clk)

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
    inst_driver, cpu_rst = await init_test(dut)
    await inst_driver._driver_send('addi x1, x0, 7')
    await inst_driver._driver_send('addi x2, x0, 4')
    await inst_driver._load_nops(5)
    await inst_driver._driver_send('sub x3, x1, x2')
    await inst_driver._load_nops(5)
    await inst_driver._driver_send('sw x3, 4(x2)')
    await inst_driver._load_nops(5)
    await inst_driver._driver_send('lw x4, 4(x2)')
    await close_test(dut, cpu_rst, 30, inst_driver.inst_mem_depth)

@cocotb.test()
async def test_data_hazard(dut):
    '''
    test RAW data hazard case:
        1. addi x1, x0, 7 
        2. addi x1, x1, 4
    '''
    inst_driver, cpu_rst = await init_test(dut)
    await inst_driver._driver_send('addi x1, x0, 7')
    await inst_driver._driver_send('addi x1, x1, 4')
    await close_test(dut, cpu_rst, 30, inst_driver.inst_mem_depth)

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
    inst_driver, cpu_rst = await init_test(dut)
    await inst_driver._driver_send('addi x1, x0, 7')
    await inst_driver._driver_send('sw x1, 0(x0)')
    await inst_driver._load_nops(5)
    await inst_driver._driver_send('lw x2, 0(x0)')
    await inst_driver._driver_send('add x3, x2, x2')
    await close_test(dut, cpu_rst, 30, inst_driver.inst_mem_depth)

@cocotb.test()
async def test_jal(dut):
    '''
    test jal instruction:
        1. nop X 5 
        2. addi x1, x1, 1
        3. jal x2, -4
    '''
    inst_driver, cpu_rst = await init_test(dut)
    await inst_driver._load_nops(5) # 0x0, 0x4, 0x8, 0xc, 0x10
    await inst_driver._driver_send('addi x1, x1, 1') # 0x14
    await inst_driver._driver_send('jal x2, -4') # 0x18
    # Those instructions should never happen:
    await inst_driver._driver_send('addi x6, x0, 7') # 0x1c
    await inst_driver._driver_send('addi x17, x0, 137') # 0x20
    await close_test(dut, cpu_rst, 30, inst_driver.inst_mem_depth)

# @cocotb.test()
async def test_jalr(dut):
    '''
    test jalr instruction:
        1. nop X 5
        2. addi x5, x0, 10
        2. addi x1, x1, 1
        4. jalr x2, x5, -14
    '''
    inst_driver, cpu_rst = await init_test(dut)
    await inst_driver._load_nops(5) # 0x0, 0x4, 0x8, 0xc, 0x10
    await inst_driver._driver_send('addi x5, x0, 10') # 0x14
    await inst_driver._driver_send('addi x1, x1, 1') # 0x18 
    await inst_driver._driver_send('jalr x2, x5, -14') # 0x1c 
    # Those instructions should never happen:
    await inst_driver._driver_send('addi x6, x0, 7') # 0x20
    await inst_driver._driver_send('addi x17, x0, 137') # 0x24
    await close_test(dut, cpu_rst, 30, inst_driver.inst_mem_depth)

# @cocotb.test()
async def test_bne(dut):
    '''
    test jalr instruction:
        1. nop X 5
        2. addi x5, x0, 3
        2. addi x1, x1, 1
        4. bne x1, x5, -4
    '''
    inst_driver, cpu_rst = await init_test(dut)
    await inst_driver._load_nops(5) # 0x0, 0x4, 0x8, 0xc, 0x10
    await inst_driver._driver_send('addi x5, x0, 3') # 0x14
    await inst_driver._driver_send('addi x1, x1, 1') # 0x18 
    await inst_driver._driver_send('bne x1, x5, -4') # 0x1c 
    # Those instructions should happen after the loop:
    await inst_driver._driver_send('addi x6, x0, 7') # 0x20
    await inst_driver._driver_send('addi x17, x0, 137') # 0x24
    await close_test(dut, cpu_rst, 30, inst_driver.inst_mem_depth)

