import cocotb
from models.test_infra import init_test, close_test

@cocotb.test()
async def test_exc_main_mis(dut):
    '''
    test main memory mis-aligned address exception:
        1. addi x1, x0, 7 
        2. addi x2, x0, 4
        3. sub  x3, x1, x2
        4. sw x3, 4(x2)
        5. lw x4, 2(x2)  
    '''
    inst_driver, cpu_rst, rgf_sb, mm_sb = await init_test(dut)
    await inst_driver._driver_send('addi x1, x0, 7')
    await inst_driver._driver_send('addi x2, x0, 4')
    await inst_driver._driver_send('sub x3, x1, x2')
    await inst_driver._driver_send('sw x3, 4(x2)')
    await inst_driver._driver_send('lw x4, 2(x2)')
    await close_test(dut, cpu_rst, 30, inst_driver.inst_mem_depth, rgf_sb, mm_sb)
