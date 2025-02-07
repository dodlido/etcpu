import random
import cocotb
from models.test_infra import init_test, close_test

@cocotb.test()
async def test_rand(dut, inst_num=None, avoid_exceptions=True):
    '''
    test rand_inst:
        random set of instructions
    '''
    inst_driver, cpu_rst, rgf_sb, mm_sb = await init_test(dut, avoid_exceptions)
    # initialize all registers with some random integer
    for i in range(32):
        await inst_driver._driver_send(f'addi x{i}, x0, {random.randint(0,2**12-1)}')
    # fill the rest of the instruction memory with random instructions
    inst_num = inst_driver.inst_mem_depth-32-1-5 if not inst_num else inst_num
    for _ in range(inst_num):
        await inst_driver.drive_rand_inst()
    # make sure we jump to head
    await inst_driver._driver_send(f'jal x0, -{int(inst_num << 2)}')
    for _ in range(5):
        await inst_driver._driver_send('nop')
    await close_test(dut, cpu_rst, 1000, inst_driver.inst_mem_depth, rgf_sb, mm_sb)
