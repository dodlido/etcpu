import cocotb
from models.test_infra import init_test, close_test

@cocotb.test()
async def test_utype(dut):
    '''
    basic test:
        1. lui x1, 7
        2. auipc x2, 12
    '''
    inst_driver, cpu_rst, rgf_sb, mm_sb = await init_test(dut)
    await inst_driver._driver_send('lui x1, 7')
    await inst_driver._load_nops(32)
    await inst_driver._driver_send('auipc x2, 12')
    await close_test(dut, cpu_rst, 300, inst_driver.inst_mem_depth, rgf_sb, mm_sb)