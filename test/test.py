# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: MIT

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
import struct

"""
 * @brief Izhikevich neuron model test bench
 * Tests:
    - Reset: Ensures that the neuron is reset correctly


"""

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
  dut._log.info(int8_to8b_signed(dut.uo_out.value.integer))
  dut.rst_n.value = 1
  dut.uio_in.value = 175
  dut.ui_in.value = 255
  await ClockCycles(dut.clk, 1)
  assert dut.uo_out.value.integer > 30 
  # iterate through 250 clock cycles and log uo_out
  for i in range(500):
    await ClockCycles(dut.clk, 1)
    dut._log.info(int8_to8b_signed(dut.uo_out.value.integer))

  dut._log.info("Done")


@cocotb.test()
async def test_sweep(dut):
  clock = Clock(dut.clk, 500000, units="us")
  cocotb.start_soon(clock.start())

  dut._log.info("Reset")
  # Enable tile
  dut.ena.value = 1
  # Reset is active low
  dut.rst_n.value = 0  
  await ClockCycles(dut.clk, 1)
  dut._log.info(int8_to8b_signed(dut.uo_out.value.integer))
  # Sweep through input current, a, and b parameters and log uo_out for 100 cycles. 
  # Save these to test_sweep.log in format:
  # clk uo_out ui_in a, b
  for input_current in range(255):
    # a and b are 4-bit integers and are packed into uio_in as: [a[0:3], b[0:3]]
    for a in range(16):
      for b in range(16):
        dut.ui_in.value = input_current
        dut.uio_in.value = (a << 4) | b
        await ClockCycles(dut.clk, 1)
        dut._log.info(f"{int8_to8b_signed(dut.ui_in.integer)} {a} {b} {int8_to8b_signed(dut.uo_out.value.integer)}")
        # Reset the neuron
        dut.rst_n.value = 0
        await ClockCycles(dut.clk, 1)
        dut.rst_n.value = 1
      

# Convenience function to convert to our IO format (8-bit signed)
def int8_to8b_signed(value):
  if value > 127:
    return value - 256
  else:
    return value