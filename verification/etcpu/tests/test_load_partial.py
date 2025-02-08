import cocotb
from models.test_infra import init_test, close_test

@cocotb.test()
async def test_load_partial(dut):
    '''
    basic test:
        1. addi x1, x0, 375 
        2. sw x1, 0(x0)
        3. lb x2, 0(x0)  
    '''
    inst_driver, cpu_rst, rgf_sb, mm_sb = await init_test(dut)
    await inst_driver._driver_send('lui x1, 372')
    await inst_driver._driver_send('addi x1, x1, 284')
    await inst_driver._driver_send('sw x1, 0(x0)')
    await inst_driver._load_nops(5)
    await inst_driver._driver_send('lb x2, 0(x0)')
    await inst_driver._driver_send('lh x3, 0(x0)')
    await inst_driver._driver_send('lw x4, 0(x0)')
    await close_test(dut, cpu_rst, 30, inst_driver.inst_mem_depth, rgf_sb, mm_sb)