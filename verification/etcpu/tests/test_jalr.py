import cocotb
from models.test_infra import init_test, close_test

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
