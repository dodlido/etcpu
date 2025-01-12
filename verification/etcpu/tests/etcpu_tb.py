import json
from pathlib import Path
from collections import deque
import cocotb
from cocotb.wavedrom import trace
from cocotb.clock import Clock
import cocotb.utils
from cocotb_bus.bus import Bus
from cocotb.triggers import RisingEdge, ClockCycles
import random
from cocotb.binary import BinaryValue

running_address = 0 

# Reset DUT
async def reset_dut(clock, rst_n, cycles):
    rst_n.value = 0
    for _ in range(cycles):
        await RisingEdge(clock)
    rst_n.value = 1
    rst_n._log.debug("Reset complete")

# Drive ADDI command 
async def drive_addi(clock, wen, addr, data, rd_val: int, rs1_val: int, imm_val: int):
    global running_address
    wen.value = 1
    addr.value = running_address
    imm, rs1, funct3, rd, op = imm_val << 20, rs1_val << 15, 0 << 12, rd_val << 7, 19
    inst = imm | rs1 | funct3 | rd | op
    inst = BinaryValue(inst, n_bits=32)
    data.value = inst
    await RisingEdge(clock)
    wen.value = 0 
    running_address += 4 
    
# Drive NOP
async def drive_nop(clock, wen, addr, data):
    global running_address
    wen.value = 1
    addr.value = running_address
    funct7, rs2, rs1, funct3, rd, op = 0 << 25, 0 << 20, 0 << 15, 0 << 12, 0 << 7, 51
    inst = funct7 | rs2 | rs1 | funct3 | rd | op
    inst = BinaryValue(inst, n_bits=32)
    data.value = inst
    await RisingEdge(clock)
    wen.value = 0 
    running_address += 4 

# Main test
@cocotb.test()
async def basic_test(dut):

    # Start clock
    await cocotb.start(Clock(dut.clk, 1, 'ns').start())

    # Reset to CPU, hold it active for a long time
    cpu_rst = cocotb.start_soon(reset_dut(dut.clk, dut.rst_n_cpu, 100))

    # Wait for environment reset to complete
    await cocotb.start_soon(reset_dut(dut.clk, dut.rst_n_env, 10))

    # Write addi instruction
    await cocotb.start_soon(drive_addi(dut.clk, dut.inst_mem_wr_wen, dut.inst_mem_wr_addr, dut.inst_mem_wr_dat, 1, 1, 1))

    # Write a lot of nops
    for _ in range(5):
        await cocotb.start_soon(drive_nop(dut.clk, dut.inst_mem_wr_wen, dut.inst_mem_wr_addr, dut.inst_mem_wr_dat))

    # Wait for CPU reset to end
    await cpu_rst

    # Wait some cycles for instruction to happen
    for _ in range(50):
        await RisingEdge(dut.clk)
    