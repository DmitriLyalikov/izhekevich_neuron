# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: MIT

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
import struct
import enum

"""
 * @brief Izhikevich neuron model test bench
 * Tests:
    - Reset: Ensures that the neuron is reset correctly
  /** 
    | Behavior                    | A   | B    | C   | D   |
    | --------------------------- | --- | ---- | --- | --- |
   0| RS (Regular Spiking)        | .02 | .02  | -65 | 8   |
   1| IB (Intrinsically Bursting) | .02 | .02  | -55 | 4   |
   2| CH (Chattering)             | .02 | .02  | -50 | 2   |
   3| FS (Fast Spiking)           | 0.1 | 0.2  | -65 | 2   |
   4| TC (Thalamo-Cortical)       | .02 | 0.25 | -65 | .05 |
   5| RZ (Resonator)              | 0.1 | 0.25 | -65 | 2   |
   6| LTS (Low Threshold Spiking) | .02 | 0.25 | -65 | 2   |
"""


abcd_params = {
  0: ("Regular-Spiking", 0.02, .02, -65, 8), # Regular spiking
  1: ("Intrinsically-Bursting", 0.02, .02, -55, 4), # Intrinsically bursting
  2: ("Chattering", 0.02, .02, -50, 2), # Chattering
  3: ("Fast-Spiking", 0.1, 0.2, -65, 2), # Fast spiking
  4: ("Thalamo-Cortical", 0.02, 0.25, -65, 0.05), # Thalamo-cortical
  5: ("Resonator",0.1, 0.25, -65, 2), # Resonator
  6: ("LTS", 0.02, 0.25, -65, 2), # Low threshold spiking
}


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
  # Create log if it doesn't exist
  log = open("test_sweep.log", "w")
  log.write("clk uo_out ui_in a b\n")

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
  # Step through current at in 25 increments
  for firing_mode in range(0, 6):
    # a and b are 4-bit integers and are packed into uio_in as: [a[0:3], b[0:3]]
    dut.ui_in.value = 100
    dut.uio_in.value = firing_mode
    for i in range(100):
      await ClockCycles(dut.clk, 1)
      dut._log.info(f"{40} {abcd_params[firing_mode]} {int8_to8b_signed(dut.uo_out.value.integer)}")
      log.write(f"{i} {int8_to8b_signed(dut.uo_out.value.integer)} \n")
      # Reset the neuron
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 1)
    dut.rst_n.value = 1
  log.close()

# Convenience function to convert to our IO format (8-bit signed)
def int8_to8b_signed(value):
  def binary_to_decimal(binary):
    # Check if the number is negative
    is_negative = binary & 0b10000000 != 0

    # Extract integer and fractional parts
    integer_part = (binary & 0b01000000) >> 6
    fraction_part = binary & 0b00111111

    # Calculate the decimal value
    decimal_value = integer_part + (fraction_part / 64)

    # Convert to negative if necessary
    if is_negative:
        decimal_value *= -1

    return decimal_value * 100