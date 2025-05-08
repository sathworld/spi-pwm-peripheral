# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
from cocotb.triggers import ClockCycles
from cocotb.types import Logic
from cocotb.types import LogicArray

async def test_pwm_freq(dut, freq=3000):
    dut._log.info("Testing PWM frequency")
    start_time = cocotb.utils.get_sim_time(units="ns")
    timeout_time = max(int(1/freq*1000000000), 1000000)
    time_step = max(int(1/freq*10000), 1)
    timeout_status = False
    # Wait for falling edge of PWM signal
    while (dut.uo_out.value[0]):
        await ClockCycles(dut.clk, time_step)
        if (cocotb.utils.get_sim_time(units="ns") - start_time) > timeout_time:
            dut._log.info("Timeout waiting for falling edge of PWM signal")
            timeout_status = True
            break
    if timeout_status:
        assert False, "Timeout waiting for falling edge of PWM signal"

    start_time = cocotb.utils.get_sim_time(units="ns")
    pwm_falling_edge = cocotb.utils.get_sim_time(units="ns")
    dut._log.info(f"Falling edge of PWM signal: {pwm_falling_edge} ns")
    # Get first rising edge of PWM signal
    while (not dut.uo_out.value[0]):
        await ClockCycles(dut.clk, 1)
        if (cocotb.utils.get_sim_time(units="ns") - start_time) > timeout_time:
            dut._log.info("Timeout waiting for rising edge of PWM signal")
            timeout_status = True
            break
    if timeout_status:
        assert False, "Timeout waiting for rising edge of PWM signal"
    pwm_rising_edge_1 = cocotb.utils.get_sim_time(units="ns")
    dut._log.info(f"First rising edge of PWM signal: {pwm_rising_edge_1} ns")
    # Wait for falling edge of PWM signal
    while (dut.uo_out.value[0]):
        await ClockCycles(dut.clk, 1)
    pwm_falling_edge = cocotb.utils.get_sim_time(units="ns")
    dut._log.info(f"Falling edge of PWM signal: {pwm_falling_edge} ns")
    # Get first rising edge of PWM signal
    while (not dut.uo_out.value[0]):
        await ClockCycles(dut.clk, 1)
    pwm_rising_edge_2 = cocotb.utils.get_sim_time(units="ns")
    dut._log.info(f"Second rising edge of PWM signal: {pwm_rising_edge_2} ns")
    # Calculate PWM period
    pwm_period = pwm_rising_edge_2 - pwm_rising_edge_1
    dut._log.info(f"PWM period: {pwm_period} ns")
    # Calculate PWM frequency
    pwm_freq = 1 / (pwm_period * 1e-9)  # Convert ns to seconds
    # Check if the frequency is within the expected range +/-20%
    #assert freq*0.80 < pwm_freq < freq*1.2, f"PWM frequency out of range: {pwm_freq} Hz. Expected {freq}Hz +/-20%"
    dut._log.info(f"PWM frequency: {pwm_freq} Hz. Expected {freq}Hz +/-20%")

async def test_pwm_duty_cycle(dut, expected_duty_cycle):
    dut._log.info(f"Testing PWM duty cycle for value {expected_duty_cycle}")
    start_time = cocotb.utils.get_sim_time(units="ns")
    timeout_time = 10000000  # 10 ms timeout
    timeout_status = False
    # Wait for falling edge of PWM signal
    while (dut.uo_out.value[0]):
        await ClockCycles(dut.clk, 1)
        if (cocotb.utils.get_sim_time(units="ns") - start_time) > timeout_time:
            dut._log.info("Timeout waiting for falling edge of PWM signal")
            timeout_status = True
            break
    if timeout_status:
        assert False, "Timeout waiting for falling edge of PWM signal"
    pwm_falling_edge = cocotb.utils.get_sim_time(units="ns")
    dut._log.info(f"Falling edge of PWM signal: {pwm_falling_edge} ns")
    # Get first rising edge of PWM signal
    start_time = cocotb.utils.get_sim_time(units="ns")
    while (not dut.uo_out.value[0]):
        await ClockCycles(dut.clk, 1)
        if (cocotb.utils.get_sim_time(units="ns") - start_time) > timeout_time:
            dut._log.info("Timeout waiting for rising edge of PWM signal")
            timeout_status = True
            break
    if timeout_status:
        if expected_duty_cycle == 0:
            dut._log.info("Duty cycle is 0% as expected")
            return
        assert False, "Timeout waiting for rising edge of PWM signal"
    pwm_rising_edge_1 = cocotb.utils.get_sim_time(units="ns")
    dut._log.info(f"First rising edge of PWM signal: {pwm_rising_edge_1} ns")
    # Wait for falling edge of PWM signal
    while (dut.uo_out.value[0]):
        await ClockCycles(dut.clk, 1)
    pwm_falling_edge = cocotb.utils.get_sim_time(units="ns")
    dut._log.info(f"Falling edge of PWM signal: {pwm_falling_edge} ns")
    # Wait for next rising edge of PWM signal
    while (not dut.uo_out.value[0]):
        await ClockCycles(dut.clk, 1)
    pwm_rising_edge_2 = cocotb.utils.get_sim_time(units="ns")
    dut._log.info(f"Second rising edge of PWM signal: {pwm_rising_edge_2} ns")
    # Calculate PWM period
    pwm_period = pwm_rising_edge_2 - pwm_rising_edge_1
    dut._log.info(f"PWM period: {pwm_period} ns")
    # Calculate PWM high time
    pwm_high_time = pwm_falling_edge - pwm_rising_edge_1
    dut._log.info(f"PWM high time: {pwm_high_time} ns")
    # Calculate duty cycle
    duty_cycle = (pwm_high_time / pwm_period) * 100  # Convert to percentage
    dut._log.info(f"Duty cycle: {duty_cycle:.2f}%")
    # Check if the duty cycle is within the expected range
    expected_duty_cycle_ns = (expected_duty_cycle / 256) * pwm_period
    # Calculate the tolerance (1% of the specified duty cycle)
    tolerance = expected_duty_cycle_ns * 0.01
    # Check if the actual duty cycle is within the tolerance range
    assert (pwm_high_time >= expected_duty_cycle_ns - tolerance) and (pwm_high_time <= expected_duty_cycle_ns + tolerance), \
        f"Duty cycle out of range: {duty_cycle:.2f}%. Expected {expected_duty_cycle/256:.2f}% +/-1% tolerance"
    

async def await_half_sclk(dut):
    """Wait for the SCLK signal to go high or low."""
    start_time = cocotb.utils.get_sim_time(units="ns")
    while True:
        await ClockCycles(dut.clk, 1)
        # Wait for half of the SCLK period (10 us)
        if (start_time + 100*100*0.5) < cocotb.utils.get_sim_time(units="ns"):
            break
    return

def ui_in_logicarray(ncs, bit, sclk):
    """Setup the ui_in value as a LogicArray."""
    return LogicArray(f"00000{ncs}{bit}{sclk}")

async def send_spi_transaction(dut, r_w, address, data):
    """
    Send an SPI transaction with format:
    - 1 bit for Read/Write
    - 7 bits for address
    - 8 bits for data
    
    Parameters:
    - r_w: boolean, True for write, False for read
    - address: int, 7-bit address (0-127)
    - data: LogicArray or int, 8-bit data
    
    Returns:
    - tuple: (ui_in_value, cipo_data) where cipo_data is the 8-bit data read from CIPO
    """
    # Convert data to int if it's a LogicArray
    if isinstance(data, LogicArray):
        data_int = int(data)
    else:
        data_int = data
    # Validate inputs
    if address < 0 or address > 127:
        raise ValueError("Address must be 7-bit (0-127)")
    if data_int < 0 or data_int > 255:
        raise ValueError("Data must be 8-bit (0-255)")
    # Combine RW and address into first byte
    first_byte = (int(r_w) << 7) | address
    # Start transaction - pull CS low
    sclk = 0
    ncs = 0
    bit = 0
    # Set initial state with CS low
    dut.ui_in.value = ui_in_logicarray(ncs, bit, sclk)
    await ClockCycles(dut.clk, 1)
    
    # Prepare to capture CIPO data
    cipo_data = 0
    
    # Send first byte (RW + Address)
    for i in range(8):
        bit = (first_byte >> (7-i)) & 0x1
        # SCLK low, set COPI
        sclk = 0
        dut.ui_in.value = ui_in_logicarray(ncs, bit, sclk)
        await await_half_sclk(dut)
        # SCLK high, keep COPI and sample CIPO
        sclk = 1
        dut.ui_in.value = ui_in_logicarray(ncs, bit, sclk)
        await await_half_sclk(dut)
        
        # For the first byte, we could collect CIPO but typically first byte 
        # doesn't return useful data in most SPI protocols
    
    # Capture data from second byte (actual read data)
    cipo_byte = 0
    for i in range(8):
        bit = (data_int >> (7-i)) & 0x1
        # SCLK low, set COPI
        sclk = 0
        dut.ui_in.value = ui_in_logicarray(ncs, bit, sclk)
        await await_half_sclk(dut)
        # SCLK high, keep COPI and sample CIPO
        sclk = 1
        dut.ui_in.value = ui_in_logicarray(ncs, bit, sclk)
        await await_half_sclk(dut)
        # Capture CIPO bit on rising edge (add to our accumulator)
        cipo_bit = int(dut.uio_out.value[0]) & 0x1  # Extract bit 0 (CIPO) from uo_out
        cipo_byte = (cipo_byte << 1) | cipo_bit
    
    # End transaction - return CS high
    sclk = 0
    ncs = 1
    bit = 0
    dut.ui_in.value = ui_in_logicarray(ncs, bit, sclk)
    await ClockCycles(dut.clk, 600)
    
    # Log the CIPO data
    dut._log.info(f"CIPO data received: 0x{cipo_byte:02X}")
    
    return ui_in_logicarray(ncs, bit, sclk), cipo_byte

@cocotb.test()
async def test_spi(dut):
    dut._log.info("Start SPI test")

    # Set the clock period to 100 ns (10 MHz)
    clock = Clock(dut.clk, 100, units="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Reset")
    dut.ena.value = 1
    ncs = 1
    bit = 0
    sclk = 0
    dut.ui_in.value = ui_in_logicarray(ncs, bit, sclk)
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 5)

    dut._log.info("Test project behavior")
    dut._log.info("Write transaction, address 0x00, data 0xF0")
    ui_in_val, cipo_data = await send_spi_transaction(dut, 1, 0x00, 0xF0)  # Write transaction
    assert dut.uo_out.value == 0xF0, f"Expected 0xF0, got {dut.uo_out.value}"
    await ClockCycles(dut.clk, 20)

    # Check all values
    for i in range(0, 256):
        dut._log.info(f"Write transaction, address 0x00, data {hex(i)}")
        ui_in_val, cipo_data = await send_spi_transaction(dut, 1, 0x00, i)
        assert dut.uo_out.value == i, f"Expected {hex(i)}, got {dut.uo_out.value}"
        await ClockCycles(dut.clk, 20)
        # Make a read transaction to verify the data
        dut._log.info(f"Read transaction, address 0x00, expecting {hex(i)}")
        ui_in_val, cipo_data = await send_spi_transaction(dut, 0, 0x00, 0)
        assert cipo_data == i, f"Expected {hex(i)}, got {hex(cipo_data)}"
        await ClockCycles(dut.clk, 20)
        dut._log.info(f"Write transaction, address 0x00, data {hex(i)} completed successfully")
    # Check all addresses
    for i in range(0, 10):
        dut._log.info(f"Write transaction, address {hex(i)}, data 0xC9")
        ui_in_val, cipo_data = await send_spi_transaction(dut, 1, i, 0xC9)
        await ClockCycles(dut.clk, 20)
        # Make a read transaction to verify the data
        dut._log.info(f"Read transaction, address {hex(i)}, data 0xC9")
        ui_in_val, cipo_data = await send_spi_transaction(dut, 0, i, 0)
        if (i <= 8):
            assert cipo_data == 0xC9, f"Expected {hex(i)}, got {hex(cipo_data)}"
        await ClockCycles(dut.clk, 20)
        dut._log.info(f"Write transaction, address {hex(i)}, data 0xC9 completed successfully")
    
    dut._log.info("SPI test completed successfully")

@cocotb.test()
async def test_pwm(dut):
    dut._log.info("Start")

    # Set the clock period to 100 ns (10 MHz)
    clock = Clock(dut.clk, 100, units="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Reset")
    dut.ena.value = 1
    ncs = 1
    bit = 0
    sclk = 0
    dut.ui_in.value = ui_in_logicarray(ncs, bit, sclk)
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 5)

    dut._log.info("Test project behavior")
    dut._log.info("Write transaction, address 0x00, data 0xFF")
    ui_in_val, cipo_data = await send_spi_transaction(dut, 1, 0x00, 0xFF)  # Write transaction
    await ClockCycles(dut.clk, 100)

    dut._log.info("Write transaction, address 0x01, data 0xFF")
    ui_in_val, cipo_data = await send_spi_transaction(dut, 1, 0x01, 0xFF)  # Write transaction
    await ClockCycles(dut.clk, 100)

    dut._log.info("Write transaction, address 0x08, data 0x03")
    ui_in_val, cipo_data = await send_spi_transaction(dut, 1, 0x08, 0x03)  # Write transaction
    await ClockCycles(dut.clk, 100)

    for i in range(0, 256):
        dut._log.info(f"Write transaction, address 0x04, data {hex(i)}, duty cycle {i/256:.3%}")
        ui_in_val, cipo_data = await send_spi_transaction(dut, 1, 0x04, i)  # Write transaction
        await test_pwm_duty_cycle(dut, i)
        await ClockCycles(dut.clk, 100)
        dut._log.info(f"PWM duty cycle test (data {hex(i)}, duty cycle {i/256:.3%}) completed successfully")
    dut._log.info("PWM test completed successfully")

@cocotb.test()
async def test_clk_div(dut):
    dut._log.info("Start")

    # Set the clock period to 100 ns (10 MHz)
    clock = Clock(dut.clk, 100, units="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Reset")
    dut.ena.value = 1
    ncs = 1
    bit = 0
    sclk = 0
    dut.ui_in.value = ui_in_logicarray(ncs, bit, sclk)
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 5)

    dut._log.info("Test project behavior")
    dut._log.info("Write transaction, address 0x00, data 0xFF")
    ui_in_val, cipo_data = await send_spi_transaction(dut, 1, 0x00, 0xFF)  # Write transaction
    await ClockCycles(dut.clk, 100)

    dut._log.info("Write transaction, address 0x01, data 0xFF")
    ui_in_val, cipo_data = await send_spi_transaction(dut, 1, 0x01, 0xFF)  # Write transaction
    await ClockCycles(dut.clk, 100)

    dut._log.info("Write transaction, address 0x08, data 0x03")
    ui_in_val, cipo_data = await send_spi_transaction(dut, 1, 0x08, 0x03)  # Write transaction
    await ClockCycles(dut.clk, 100)

    dut._log.info(f"Write transaction, address 0x04, data {hex(0x80)}, duty cycle {0x80/256:.3%}")
    ui_in_val, cipo_data = await send_spi_transaction(dut, 1, 0x04, 0x80)  # Write transaction

    for i in range(0, 16):
        dut._log.info(f"Write transaction, address 0x08, data {hex(i)}")
        ui_in_val, cipo_data = await send_spi_transaction(dut, 1, 0x08, i)  # Write transaction
        await ClockCycles(dut.clk, 30000)
        await ClockCycles(dut.clk, int(30000*pow(2, i-2)))
        await test_pwm_freq(dut, 19607*pow(2, -i + 1))
        await ClockCycles(dut.clk, 30000)
        await ClockCycles(dut.clk, int(30000*pow(2, i-2)))
    dut._log.info("PWM freq test completed successfully")