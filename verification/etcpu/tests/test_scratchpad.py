import cocotb
from models.test_infra import init_test, close_test

@cocotb.test()
async def test_scratchpad(dut):
    '''
    scratchpad test - reproduce some errors in a direct test
    '''
    inst_driver, cpu_rst, rgf_sb, mm_sb = await init_test(dut)
    await inst_driver._load_nops(int(0x298/4))
    await inst_driver._driver_send('jal x25, 144')
    await inst_driver._load_nops(int(140/4))
    await inst_driver._driver_send('ori x9, x25, 120')
    await inst_driver._load_nops(1)
    await inst_driver._driver_send('addi x9, x19, 1550')
    await close_test(dut, cpu_rst, 1000, inst_driver.inst_mem_depth, rgf_sb, mm_sb)