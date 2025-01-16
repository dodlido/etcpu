import json
from pathlib import Path
from collections import deque
import cocotb
from cocotb.wavedrom import trace
from cocotb.clock import Clock
import cocotb.utils
from cocotb.triggers import RisingEdge, ClockCycles
import random
from cocotb.binary import BinaryValue
from models.riscv_infra import str2bin
from cocotb_bus.bus import Bus
from cocotb_bus.drivers import BusDriver

# Reset DUT
async def reset_dut(clock, rst_n, cycles):
    rst_n.value = 0
    for _ in range(cycles):
        await RisingEdge(clock)
    rst_n.value = 1
    rst_n._log.debug("Reset complete")

# Instruction driver
class InstWrDriver(BusDriver):
    '''
    Instruction write driver
        * gets an instruction
        * keeps internal running address
        * drives the instruction memory write interface
    '''
    _signals = ['wen', 'addr', 'dat']

    def __init__(self, entity, name, clock, inst_mem_depth, **kwargs):
        super().__init__(entity, name, clock, **kwargs)
        self.running_addr = 0 
        self.inst_mem_depth = inst_mem_depth
        self.bus.wen.value = 0 
        self.bus.addr.value = 0
        self.bus.dat.value = 0 
    
    async def _driver_send(self, cmd: str, sync = True):
        '''
        gets an RV32I command as a string
        drives the command write bus to the instruction memory        
        '''
        self.bus.wen.value = 1 
        self.bus.addr.value = self.running_addr
        self.bus.dat.value = str2bin(cmd)
        self.running_addr = 0 if ((self.running_addr + 4) >> 2) == self.inst_mem_depth else self.running_addr + 4 
        await RisingEdge(self.clock)
        self.bus.wen.value = 0
    
    async def _load_nops(self, num_of_nops: int):
        '''
            use num_of_nops=-1 to load the 
            entire instruction memory with nops
        '''
        if num_of_nops == -1:
            num_of_nops == self.inst_mem_depth
        for _ in range(num_of_nops):
            await self._driver_send('nop')

async def basic_test(inst_driver: InstWrDriver):
    '''
    basic test:
        1. addi x1, x0, 7 
        2. addi x2, x0, 4
        3. sub  x3, x1, x2
        4. sw x3, 4(x2)
        5. lw x4, 4(x2)  
    '''
    await inst_driver._driver_send('addi x1, x0, 7')
    await inst_driver._driver_send('addi x2, x0, 4')
    await inst_driver._load_nops(5)
    await inst_driver._driver_send('sub x3, x1, x2')
    await inst_driver._load_nops(5)
    await inst_driver._driver_send('sw x3, 4(x2)')
    await inst_driver._load_nops(5)
    await inst_driver._driver_send('lw x4, 4(x2)')

async def test_data_hazard(inst_driver: InstWrDriver):
    '''
    test RAW data hazard case:
        1. addi x1, x0, 7 
        2. addi x1, x1, 4
    '''
    await inst_driver._driver_send('addi x1, x0, 7')
    await inst_driver._driver_send('addi x1, x1, 4')

@cocotb.test()
async def test_wrapper(dut):
    
    # 1. Declare driver 
    inst_driver = InstWrDriver(dut, 'inst_mem_wr', dut.clk, 256)
    
    # 2. Start clock
    await cocotb.start(Clock(dut.clk, 1, 'ns').start())
    
    # 3. Reset to CPU, hold it active for a long time
    cpu_rst = cocotb.start_soon(reset_dut(dut.clk, dut.rst_n_cpu, int(1.2*inst_driver.inst_mem_depth)))
    
    # 4. Wait for environment reset to complete
    await cocotb.start_soon(reset_dut(dut.clk, dut.rst_n_env, 10))

    # 5. Fill instruction memory with NOPS
    await inst_driver._load_nops(-1)

    ######################################
    ########### Test Case Here ###########
    ######################################
    await test_data_hazard(inst_driver)
    ######################################
    ########### Test Case Ends ###########
    ######################################

    # 6. Wait for CPU reset to end
    await cpu_rst

    # 7. Wait some cycles for instruction to occur
    for _ in range(64):
        await RisingEdge(dut.clk)

    