import cocotb
from models.test_infra import init_test, close_test

@cocotb.test()
async def test_interlock_scenario(dut):
    '''
    test pipe interlock scenario:
        1. addi x1, x0, 7 
        2. sw   x1, 0(x0)
        3. nop X 5 
        4. lw x2, 0(x0)
        5. add x3, x2, x2
    '''
    inst_driver, cpu_rst, rgf_sb, mm_sb = await init_test(dut)
    await inst_driver._driver_send('addi x1, x0, 7')
    await inst_driver._driver_send('sw x1, 0(x0)')
    await inst_driver._load_nops(5)
    await inst_driver._driver_send('lw x2, 0(x0)')
    await inst_driver._driver_send('add x3, x2, x2')
    await close_test(dut, cpu_rst, 30, inst_driver.inst_mem_depth, rgf_sb, mm_sb)
