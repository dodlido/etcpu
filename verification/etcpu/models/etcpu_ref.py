import cocotb.log
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles, ReadOnly
from cocotb_bus.bus import Bus
from cocotb_bus.drivers import BusDriver
from cocotb_bus.monitors import BusMonitor, Monitor
from models.riscv_infra import inst_str2int, inst_int2str, inst_int2rgfexp, inst_int2mmexp, inst_int2pcexp, InstGenerator
import logging

class RGFTrans(object):
    '''
    register file write transaction
        1. Data
        2. Register name
    '''
    def __init__(self, data: int, reg_addr: int):
        self.data = data
        self.reg_addr = reg_addr
    
    def get_log_message(self)->str:
        reg_num = ('x' + str(self.reg_addr)).ljust(3)
        reg_val = (hex(self.data)).ljust(8)
        return f' : {reg_num} <= {reg_val}'
    
    def __eq__(self, other):
        return (self.data == other.data) and (self.reg_addr == other.reg_addr)

class MMTrans(object):
    '''
    Instruction memory transaction
        1. Data
        2. Address
    '''
    def __init__(self, data: int, address: int):
        self.data = data
        self.address = address 
    
    def get_log_message(self)->str:
        log_data = hex(self.data)
        log_addr = hex(self.address)
        return f' : MAIN_MEM[{log_addr}] <= {log_data}'
    
    def __eq__(self, other):
        return self.data==other.data and self.address==other.address

class IMTrans(object):
    '''
    Instruction memory transaction
        1. Data
        2. Address
    '''
    def __init__(self, inst: str | int, address: int):
        if isinstance(inst, str):
            self.inst_str = inst
            self.inst_int = inst_str2int(self.inst_str)
        elif isinstance(inst, int):
            self.inst_int = inst
            self.inst_str = inst_int2str(self.inst_int)
        self.address = address 
    
    def get_log_message(self)->str:
        log_inst = f"{self.inst_str}".ljust(20)
        return f' : {log_inst}                                     @ {hex(self.address)}'

class IMDriver(BusDriver):
    '''
    Instruction write driver
        * gets an instruction
        * keeps internal running address
        * drives the instruction memory write interface
    '''
    _signals = ['wen', 'addr', 'dat']

    def __init__(self, entity, name, clock, inst_mem_depth, **kwargs):
        super().__init__(entity, name, clock, **kwargs)
        self.running_addr = 0 
        self.inst_mem_depth = inst_mem_depth
        self.bus.wen.value = 0 
        self.bus.addr.value = 0
        self.bus.dat.value = 0 
        self.inst_generator = InstGenerator()
        self.inst_generator.solve()

    async def _driver_send(self, cmd: str, sync = True):
        '''
        gets an RV32I command as a string
        drives the command write bus to the instruction memory        
        '''
        # Build the transaction
        trans = IMTrans(cmd, self.running_addr)
        
        # Drive IM with the transaction
        self.bus.wen.value = 1 
        self.bus.addr.value = trans.address
        self.bus.dat.value = trans.inst_int
        # Update running address
        self.running_addr = 0 if ((self.running_addr + 4) >> 2) == self.inst_mem_depth else self.running_addr + 4 

        # Wait for the next clock and disable WEN
        await RisingEdge(self.clock)
        self.bus.wen.value = 0
    
    async def drive_rand_inst(self):
        '''
        drive a random valid RV32I instruction
        '''
        _, rand_inst = self.inst_generator.get()
        await self._driver_send(rand_inst)

    async def _load_nops(self, num_of_nops: int):
        '''
            use num_of_nops=-1 to load the 
            entire instruction memory with nops
        '''
        if num_of_nops == -1:
            for _ in range(self.inst_mem_depth):
                await self._driver_send('nop')
        else:
            for _ in range(num_of_nops):
                await self._driver_send('nop')

class Scoreboard:
    '''
    Generic scoreboard class
        1. add_expected - adds an expected transaction
        2. add_actual - adds an actual transaction
        3. compare - compares two transactions
    '''
    def __init__(self, depth: int, name: str):
        self.expected_trns = []
        self.actual_trns = []
        self.expected_state = [0] * depth
        self.name = name
        self.lock_expected = False

    def add_expected(self, trans):
        if not self.lock_expected:
            self.expected_trns.append(trans)
    
    def add_actual(self, trans):
        self.actual_trns.append(trans)
    
    def compare(self)->bool:
        actual_trns = self.actual_trns.pop(0)
        if len(self.expected_trns)<1:
            cocotb.log.error(f'{self.name.ljust(16)} found actual transaction {actual_trns.get_log_message()} with no matching expected transaction')
            return False
        expected_trns = self.expected_trns.pop(0)
        if (expected_trns == actual_trns):
            cocotb.log.info(f"{self.name.ljust(16)} {expected_trns.get_log_message()} matches expected value")
            return True
        else:
            cocotb.log.error(f"{self.name.ljust(16)} MISMATCH!!\nexpected {expected_trns.get_log_message()} but got {actual_trns.get_log_message()}")
            return False
    
    def is_empty(self):
        if len(self.expected_trns)!=0:
            cocotb.log.error(f'{self.name.ljust(16)} SCOREBOARD NOT EMPTY, {len(self.expected_trns)} remaining expected transactions:')
            for i, trns in enumerate(self.expected_trns):
                cocotb.log.info(f' --> TRNS #{i} {trns.get_log_message()}')
            assert False

class MMScoreboard(Scoreboard):
    '''
    Main memory scoreboard:
        1. Holds the expected state of the main memory
        2. Enables comparing expected and actual writes to main memory
    '''
    def __init__(self, depth):
        super().__init__(depth, 'MMSB')
    def add_actual(self, trans: MMTrans):
        super().add_actual(trans)
    def add_expected(self, trans: MMTrans):
        super().add_expected(trans)
    def compare(self):
        return super().compare()

class RGFScoreboard(Scoreboard):
    '''
    Register File scoreboard:
        1. Holds the expected state of the register file
        2. Enables comparing expected and actual writes to register file
    '''
    def __init__(self):
        super().__init__(32, 'RGFSB')
    def add_actual(self, trans: RGFTrans):
        super().add_actual(trans)
    def add_expected(self, trans: RGFTrans):
        super().add_expected(trans)
    def compare(self):
        return super().compare()

class PCScoreboard(Scoreboard):
    '''
    Program Counter scoreboard:
        1. Holds the expected state of the program counter
        2. Enables comparing expected and actual program counter values
    '''
    def __init__(self):
        self.expected_pc = 0 
    def compare(self, actual_pc)->bool:
        name = 'PCSB'.ljust(16)
        if (self.expected_pc != actual_pc):
            cocotb.log.error(f"{name} MISMATCH!!\nexpected PC={hex(self.expected_pc)} but got PC={hex(actual_pc)}")
            return False
        return True

class EXCScoreboard(Scoreboard):
    def __init__(self, name):
        depth = 5
        name = name.ljust(16)
        super().__init__(depth, name)
    def compare(self):
        actual_trns = self.actual_trns.pop(0)
        if len(self.expected_trns)<1:
            cocotb.log.error(f'{self.name.ljust(16)} EXCEPTION FOUND and not expected')
            return False
        expected_trns = self.expected_trns.pop(0)
        if (expected_trns == actual_trns and actual_trns):
            cocotb.log.info(f"{self.name.ljust(16)} EXCEPTION FOUND as predicted")
            return True
        elif (expected_trns!=actual_trns):
            cocotb.log.error(f"{self.name.ljust(16)} EXCEPTION MISMATCH!! predicted {expected_trns} but got {actual_trns}")
            return False
        return True

class RGFMonitor(Monitor):
    '''
    Register file writes monitor:
        1. Listens to RGF write-enalbe, write address and write data signals
        2. Logs valid write transactions to the CPU's register file
    '''
    def __init__(self, scoreboard: RGFScoreboard, rgf_wen, rgf_wa, rgf_wd, wb_inst, wb_pc, clock, log_level, callback=None, event=None):
        super().__init__(callback, event)
        self.scoreboard = scoreboard
        self.wen = rgf_wen
        self.wa = rgf_wa
        self.wd = rgf_wd
        self.wb_inst = wb_inst
        self.wb_pc = wb_pc
        self.clock = clock
        self.title = 'RGFM'.ljust(16)
        self.log.setLevel(log_level)
    
    async def _monitor_recv(self):
        while True:
            await ReadOnly()
            write_cond = self.wen.value==1 and self.wa!=0
            if write_cond:
                rgf_wr_trans = RGFTrans(int(self.wd.value), int(self.wa.value))
                rgf_wb_inst = IMTrans(int(self.wb_inst.value), int(self.wb_pc.value))
                self.log.info(f'{self.title} {rgf_wr_trans.get_log_message()} \n-->WB instruction{rgf_wb_inst.get_log_message()}')
                self.scoreboard.add_actual(rgf_wr_trans)
                equal = self.scoreboard.compare()
                if not equal:
                    rgf_state_str = 'RGF state at failure point:\n'
                    for i, reg in enumerate(self.scoreboard.expected_state):
                        rgf_state_str += f'x{str(i).ljust(2)} = {hex(reg)}\n'
                    self.log.warning(rgf_state_str)
                    await ClockCycles(self.clock, 5)
                    assert False
                self._recv(rgf_wr_trans)
            await RisingEdge(self.clock)

class IMMonitor(BusMonitor):
    '''
    Instruction memory monitor:
        1. Logs valid write transactions over the inst_mem_wr IF
        2. Fills the IM SB with the instruction LUT
    '''
    _signals = ['wen', 'addr', 'dat']

    def __init__(self, entity, name, clock, log_level, reset=None, reset_n=None, callback=None, event=None, **kwargs):
        self.title = 'IMM'.ljust(16)
        super().__init__(entity, name, clock, reset, reset_n, callback, event, **kwargs)
        self.log.setLevel(log_level)

    async def _monitor_recv(self):
        while True:
            await ReadOnly()
            if self.bus.wen.value==1:
                # Build found transaction
                trans = IMTrans(int(self.bus.dat.value), int(self.bus.addr.value))
                if trans.inst_str!='nop':
                    self.log.debug(f'{self.title} {trans.get_log_message()}')
                    
                self._recv(trans)
            await RisingEdge(self.clock)

class MMMonitor(BusMonitor):
    '''
    Main memory monitor:
        1. Listnes to the write interface to the main memory
    '''
    _signals = ['cs', 'wen', 'addr', 'dat_in']
    
    def __init__(self, entity, name, clock, scoreboard: MMScoreboard, log_level, reset=None, reset_n=None, callback=None, event=None, **kwargs):
        self.title = 'MMM'.ljust(16)
        self.scoreboard = scoreboard
        super().__init__(entity, name, clock, reset, reset_n, callback, event, **kwargs)
        self.log.setLevel(log_level)
    
    async def _monitor_recv(self):
        while True:
            await ReadOnly()
            if self.bus.wen.value==1 and self.bus.cs.value==1:
                trans = MMTrans(int(self.bus.dat_in.value), int(self.bus.addr.value))
                self.log.info(f'{self.title} {trans.get_log_message()}')
                self.scoreboard.add_actual(trans)
                equal = self.scoreboard.compare()
                if not equal:
                    await ClockCycles(self.clock, 5)
                    assert False
                self._recv(trans)
            await RisingEdge(self.clock)

class EXCMonitor(Monitor):
    '''
    Exceptions monitor:
        1. Listens to exception triggers on the IF stage
    '''
    def __init__(self, clock, reset_n, act_exc, exc_sb: EXCScoreboard, log_level, callback=None, event=None):
        super().__init__(callback, event)
        self.clock = clock
        self.reset_n = reset_n
        self.act = act_exc
        self.sb = exc_sb
        self.log.setLevel(log_level)
        self.title = (self.sb.name.rstrip()[:-2] + 'M').ljust(16)
    
    async def _monitor_recv(self):
        while True:
            await ReadOnly()
            if self.reset_n.value!=0:
                if bool(self.act.value):
                    self.log.warning(f'{self.title} exception triggered')
            self._recv(self.act.value)
            await RisingEdge(self.clock)

async def update_exc(clock, mon: EXCMonitor, exc: bool, delay: bool=False)->bool:
    mon.sb.add_expected(exc)
    if delay:
        await ClockCycles(clock, 4)
    mon.sb.add_actual(bool(mon.act.value))
    equal = mon.sb.compare()
    if not equal:
        await ClockCycles(clock, 5)
        assert False
    return bool(mon.act.value)

class PCMonitor(Monitor):
    '''
    Program counter monitor:
        1. Listens to program counter and instruction from DUT
        2. Logs valid instructions
    '''
    def __init__(self, clock, rst_n, pc, inst, inst_mem_depth, intrlock, trap_base,
                  pc_scoreboard: PCScoreboard, rgf_scoreboard: RGFScoreboard, mm_scoreboard: MMScoreboard,
                  inst_mis_mon: EXCMonitor, inst_oob_mon: EXCMonitor, main_mis_mon: EXCMonitor, main_oob_mon: EXCMonitor, 
                    log_level, callback=None, event=None):
        super().__init__(callback, event)
        self.clock = clock
        self.rst_n = rst_n
        self.pc = pc 
        self.inst = inst
        self.inst_mem_depth = inst_mem_depth
        self.pc_scoreboard = pc_scoreboard
        self.rgf_scoreboard = rgf_scoreboard
        self.mm_scoreboard = mm_scoreboard
        self.inst_mis_mon = inst_mis_mon 
        self.inst_oob_mon = inst_oob_mon
        self.main_mis_mon = main_mis_mon
        self.main_oob_mon = main_oob_mon
        self.intrlock = intrlock
        self.trap_base = trap_base 
        self.title = 'PCM'.ljust(16)
        self.log.setLevel(log_level)
    
    async def _monitor_recv(self):
        while True:
            await ReadOnly()
            if self.rst_n.value!=0:
                # Log current instruction
                curr_inst_str = inst_int2str(int(self.inst.value))
                if curr_inst_str!='nop':
                    padded_inst_str = curr_inst_str.ljust(31)
                    self.log.info(f'{self.title}  : current instruction is - {padded_inst_str} @ {hex(int(self.pc.value))}')
                
                # PC Scoreboard update
                equal = self.pc_scoreboard.compare(int(self.pc.value))
                if not equal:
                    await ClockCycles(self.clock, 5)
                    assert False
                next_pc, flush, exc_inst_mis, exc_inst_oob = inst_int2pcexp(
                    int(self.inst.value), self.rgf_scoreboard.expected_state, self.pc_scoreboard.expected_pc, int(self.intrlock.value), self.inst_mem_depth)
                # TODO: this assumes that the pipe interlock implementation is correct
                # and does not try to predict whether a pipe interlock is required
                
                # RGF Scoreboard update
                expected_rgf_wen, expected_rgf_wa, expected_rgf_wd, expected_rgf_next_state = inst_int2rgfexp(
                    int(self.inst.value), self.rgf_scoreboard.expected_state, self.mm_scoreboard.expected_state, self.pc_scoreboard.expected_pc+4)
                if expected_rgf_wen:
                    rgf_wr_trans = RGFTrans(expected_rgf_wd, expected_rgf_wa)
                    self.rgf_scoreboard.add_expected(rgf_wr_trans)
                    self.rgf_scoreboard.expected_state = expected_rgf_next_state.copy()
                
                # Main memory Scoreboard update
                expected_mm_wen, expected_mm_wa, expected_mm_wd, expected_mm_next_state, exc_main_mis, exc_main_oob = inst_int2mmexp(
                    int(self.inst.value), self.rgf_scoreboard.expected_state, self.mm_scoreboard.expected_state)
                if expected_mm_wen:
                    mm_wr_trans = MMTrans(expected_mm_wd, expected_mm_wa)
                    self.mm_scoreboard.add_expected(mm_wr_trans)
                    self.mm_scoreboard.expected_state = expected_mm_next_state.copy()
                
                # update expected exception predictions
                cocotb.start_soon(update_exc(self.clock, self.inst_mis_mon, exc_inst_mis))
                cocotb.start_soon(update_exc(self.clock, self.inst_oob_mon, exc_inst_oob))
                cocotb.start_soon(update_exc(self.clock, self.main_mis_mon, exc_main_mis, True))
                cocotb.start_soon(update_exc(self.clock, self.main_oob_mon, exc_main_oob, True))
                trap = bool(self.inst_mis_mon.act.value) or bool(self.inst_oob_mon.act.value) or bool(self.main_mis_mon.act.value) or bool(self.main_oob_mon.act.value)
                # update program counter
                self.pc_scoreboard.expected_pc = int(self.trap_base.value) if trap else next_pc 
                # If flush, don't monitor the next 2 instructions as they should be flushed
                if flush: 
                   await ClockCycles(self.clock, 2) 
                
            await RisingEdge(self.clock)

