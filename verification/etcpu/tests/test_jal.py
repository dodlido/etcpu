import cocotb
from models.test_infra import init_test, close_test

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
