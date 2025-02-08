# ETCPU

## About

1. RV32I RISCV core design implemented in verilog
2. Verification environment for an RV32I RISCV core implemented in python utilizing cocotb

## Core Description

1. Interfaces:
   1. Basic read master for reading instructions from instruction memory 
   2. Basic read\write master for reading and writing data to a general memory
   3. APB4 interface for access to management registers (configurations, statuses, interrupts, etc..)
   4. Exceptions - an aggregation pulse of all CPU exceptions, user can use APB interface to interagete which exception ocurred
2. Supports:
   1. Integer computational instructions
   2. Control transfer instructions
   3. Load and store instructions
3. Does not currently support:
   1. Memory ordering instructions
   2. Environment call and breakpoints
   3. HINTs are ignored
4. RAW Data hazards handled by data-forwarding
5. Exception handling:
   1. Detection of misaligned and out-of-bounds addressing on both instruction and general memories
   2. After detcting an exception the core transfers control to a configurable trap address
6. Parameterizable depths to both instruction and general memory
7. [Management register file](./verification/etcpu/registers/) described in [regen](https://github.com/dodlido/veri_env.git)

## Environment Description

1. Directed at a [wrapper](./design/etcpu/rtl/etcpu_env_top.v) containing:
   1. Instance of the core
   2. Instruction memory
   3. General memory
2. Written in python utilizig the cocotb framework
3. Easy to write tests in assembly-like psuedo-code:
   ```python
   import cocotb
   from models.test_infra import init_test, close_test

   @cocotb.test()
   async def test_data_hazard(dut):
       '''
       test RAW data hazard case:
           1. addi x1, x0, 7 
           2. addi x1, x1, 4
       '''
       inst_driver, cpu_rst, rgf_sb, mm_sb = await init_test(dut) # Generic initialization phase
       await inst_driver._driver_send('addi x1, x0, 7') # actual instruction #1
       await inst_driver._driver_send('addi x1, x1, 4') # actual instruction #2
       await close_test(dut, cpu_rst, 30, inst_driver.inst_mem_depth, rgf_sb, mm_sb) # Generic closing phase
   ```
4. Support for random test with several simulation arguments options:
   1. Number of instructions in test
   2. Probabilities of each instruction type
   3. Exception avoidance 
5. All supported instructions contain monitors and checkers, including control transfer, exceptions and an empty-scoreboard-check at end of test
6. Easy, free-flowing simulation if you are using the [veri-env homebrewed cad-suite](https://github.com/dodlido/veri_env.git)

## TODOs

1. Provide memory interfaces with a flow-control mechanism to stall the pipe
2. Support memory-ordering, environment calls, breakpoints and HINTs
3. Functional coverage
4. Core debug mode option
