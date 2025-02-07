import cocotb
from models.test_infra import init_test, close_test

@cocotb.test()
async def test_bne(dut):
    '''
    test jalr instruction:
        1. nop X 5
        2. addi x5, x0, 3
        3. addi x1, x1, 1  <--| 
        4. bne x1, x5, -4  >--| X 2 ==> |
        5. addi x6, x0, 7  <-------------
        5. addi x17, x0, 137
    '''
    inst_driver, cpu_rst, rgf_sb, mm_sb = await init_test(dut)
    await inst_driver._load_nops(5) # 0x0, 0x4, 0x8, 0xc, 0x10
    await inst_driver._driver_send('addi x5, x0, 3') # 0x14
    await inst_driver._driver_send('addi x1, x1, 1') # 0x18 
    await inst_driver._driver_send('bne x1, x5, -4') # 0x1c 
    # Those instructions should happen after the loop:
    await inst_driver._driver_send('addi x6, x0, 7') # 0x20
    await inst_driver._driver_send('addi x17, x0, 137') # 0x24
    await close_test(dut, cpu_rst, 30, inst_driver.inst_mem_depth, rgf_sb, mm_sb)
