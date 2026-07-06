"""
cocotb testbench skeleton for fifo_sync
Week 7 goal: randomized stimulus + functional coverage on top of the
directed tests already in verification/tb_fifo_sync.v

Run with:  make -f verification/cocotb/Makefile
(requires: pip install cocotb --break-system-packages)
"""

import random
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles


@cocotb.test()
async def randomized_read_write(dut):
    """Drive random write/read sequences and check the FIFO never
    reports full and empty at the same time, and that read order matches
    write order (a simple software reference model / scoreboard)."""

    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())

    # Reset
    dut.rst_n.value = 0
    dut.wr_en.value = 0
    dut.rd_en.value = 0
    dut.wr_data.value = 0
    await ClockCycles(dut.clk, 2)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    # Simple software reference model (a Python list acting as the "golden" FIFO)
    reference_model = []
    depth = 4  # must match DUT's DEPTH parameter

    for _ in range(200):
        do_write = random.random() < 0.5 and len(reference_model) < depth
        do_read  = random.random() < 0.5 and len(reference_model) > 0

        wr_val = random.randint(0, 255)
        dut.wr_en.value = 1 if do_write else 0
        dut.wr_data.value = wr_val
        dut.rd_en.value = 1 if do_read else 0

        await RisingEdge(dut.clk)

        # TODO: check DUT full/empty flags against len(reference_model)
        # TODO: track expected read data and compare against dut.rd_data
        # TODO: add cocotb-coverage or a simple dict-based coverage tracker
        #       for "was full ever hit", "was empty ever hit",
        #       "was simultaneous read+write ever exercised"

        if do_write:
            reference_model.append(wr_val)
        if do_read and reference_model:
            reference_model.pop(0)

    dut._log.info("Randomized test completed - fill in the TODOs above "
                   "with real scoreboard + coverage logic")
