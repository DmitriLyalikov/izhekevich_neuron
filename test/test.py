# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: MIT

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
import struct

@cocotb.test()
async def test_project(dut):
  dut._log.info("Start")
  
  # Our example module doesn't use clock and reset, but we show how to use them here anyway.
  clock = Clock(dut.clk, 10, units="us")
  cocotb.start_soon(clock.start())

  # Reset
  dut._log.info("Reset")
  dut.ena.value = 1
  dut.ui_in.value = 0
  dut.uio_in.value = 0
  dut.rst_n.value = 0
  await ClockCycles(dut.clk, 10)
  dut.rst_n.value = 1

  # Set the input values, wait one clock cycle, and check the output
  dut._log.info("Test")
  dut.ui_in.value = 20
  dut.uio_in.value = 30

  await ClockCycles(dut.clk, 1)

  assert dut.uo_out.value

@cocotb.test()
async def test_reset(dut):
  clock = Clock(dut.clk, 10, units="us")
  cocotb.start_soon(clock.start())

  dut._log.info("Reset")
  dut.ena.value = 1
  dut.ui_in.value = 0
  dut.uio_in.value = 0
  dut.rst_n.value = 0
  await ClockCycles(dut.clk, 1)
  assert dut.uo_out.value
  dut._log.info("Done")


@cocotb.test()
async def test_spike(dut):
  clock = Clock(dut.clk, 500000, units="us")
  cocotb.start_soon(clock.start())

  dut._log.info("Reset")
  dut.ena.value = 1
  dut.rst_n.value = 0
  await ClockCycles(dut.clk, 1)
  dut.rst_n.value = 1
  dut.uio_in.value = 175
  dut.ui_in.value = 10
  dut._log.info(dut.uo_out.value.integer)
  await ClockCycles(dut.clk, 1)
  assert dut.uo_out.value.integer > 30 
  dut._log.info(dut.uo_out.value.integer)
  # iterate through 250 clock cycles and log uo_out
  for i in range(500):
    await ClockCycles(dut.clk, 1)
    dut._log.info(int8_to8b_signed(dut.uo_out.value.integer))

  dut._log.info("Done")


def int8_to8b_signed(value):
  if value > 127:
    return value - 256
  else:
    return value