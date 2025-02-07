import cocotb
from models.test_infra import init_test, close_test

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
