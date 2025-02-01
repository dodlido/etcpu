// ------------------------------------ // 
// Automatically Generated RGF instance // 
// ------------------------------------ // 

etcpu_mng_regs i_etcpu_mng_regs ( 
   // General // 
   // ------- //
   .clk(clk),
   .rst_n(rst_n),
   
   // HW IF to RGF // 
   // ------------ //
   .etcpu_mng_regs_cfg_trap_hdlr_addr(etcpu_mng_regs_cfg_trap_hdlr_addr), // etcpu_mng_regs_cfg_trap_hdlr_addr: HW read port , output(32b)
   .etcpu_mng_regs_exc_inst_addr_mis_hw_next(etcpu_mng_regs_exc_inst_addr_mis_hw_next), // etcpu_mng_regs_exc_inst_addr_mis: HW write port , input(1b)
   .etcpu_mng_regs_exc_inst_addr_oob_hw_next(etcpu_mng_regs_exc_inst_addr_oob_hw_next), // etcpu_mng_regs_exc_inst_addr_oob: HW write port , input(1b)
   .etcpu_mng_regs_exc_main_addr_mis_hw_next(etcpu_mng_regs_exc_main_addr_mis_hw_next), // etcpu_mng_regs_exc_main_addr_mis: HW write port , input(1b)
   .etcpu_mng_regs_exc_main_addr_oob_hw_next(etcpu_mng_regs_exc_main_addr_oob_hw_next), // etcpu_mng_regs_exc_main_addr_oob: HW write port , input(1b)
   .etcpu_mng_regs_epc_val_hw_next(etcpu_mng_regs_epc_val_hw_next), // etcpu_mng_regs_epc_val: HW write port , input(32b)
   .etcpu_mng_regs_epc_val_hw_we(etcpu_mng_regs_epc_val_hw_we), // etcpu_mng_regs_epc_val: HW write enable bit , input(1b)
   .etcpu_mng_regs___intr(etcpu_mng_regs___intr), // etcpu_mng_regs__: agrregation of interrups in regfile , output(1b)

   // APB IF // 
   // ------ //
   .paddr(paddr),
   .pprot(pprot),
   .psel(psel),
   .penable(penable),
   .pwrite(pwrite),
   .pwdata(pwdata),
   .pstrb(pstrb),
   .pwakeup(pwakeup),
   .pready(pready),
   .prdata(prdata),
   .pslverr(pslverr)
);

// ------------------------------------ // 
// Automatically Generated RGF instance // 
// ------------------------------------ // 

//|~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~|//
//|                                               |//
//| 1. Project  :  veri_env                       |//
//| 2. Author   :  Etay Sela                      |//
//| 3. Date     :  2025-01-09                     |//
//| 4. Version  :  v4.2.0                         |//
//|                                               |//
//|~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~|//
