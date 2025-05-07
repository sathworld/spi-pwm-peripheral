/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_sathworld_spi_pwm_peripheral (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  assign uio_oe = 8'hFF; // Set all IOs to output mode
  assign uio_out[6:0] = 7'b0000000; // Set all IOs to low

  wire [7:0] wire_en_out;
  wire [7:0] wire_en_pwm_out;
  wire [7:0] wire_out_3_0_pwm_chanel;
  wire [7:0] wire_out_7_4_pwm_chanel;
  wire [7:0] wire_pwm_gen_0_duty_cycle;
  wire [7:0] wire_pwm_gen_1_duty_cycle;
  wire [7:0] wire_pwm_gen_2_duty_cycle;
  wire [7:0] wire_pwm_gen_3_duty_cycle;
  wire [7:0] wire_pwm_gen_1_0_frequency_divider;
  wire [7:0] wire_pwm_gen_3_2_frequency_divider;

  spi_peripheral spi_peripheral_inst (
    .nCS(ui_in[2]),
    .SCLK(ui_in[0]),
    .COPI(ui_in[1]),
    .CIPO(uio_out[7]),
    .clk(clk),
    .rst_n(rst_n),
    .reg_en_out(wire_en_out),
    .reg_en_pwm_out(wire_en_pwm_out),
    .reg_out_3_0_pwm_chanel(wire_out_3_0_pwm_chanel),
    .reg_out_7_4_pwm_chanel(wire_out_7_4_pwm_chanel),
    .reg_pwm_gen_0_duty_cycle(wire_pwm_gen_0_duty_cycle),
    .reg_pwm_gen_1_duty_cycle(wire_pwm_gen_1_duty_cycle),
    .reg_pwm_gen_2_duty_cycle(wire_pwm_gen_2_duty_cycle),
    .reg_pwm_gen_3_duty_cycle(wire_pwm_gen_3_duty_cycle),
    .reg_pwm_gen_1_0_frequency_divider(wire_pwm_gen_1_0_frequency_divider),
    .reg_pwm_gen_3_2_frequency_divider(wire_pwm_gen_3_2_frequency_divider)
  );

  pwm_peripheral pwm_peripheral_inst (
    .clk(clk),
    .rst_n(rst_n),
    .reg_en_out(wire_en_out),
    .reg_en_pwm_out(wire_en_pwm_out),
    .reg_out_3_0_pwm_chanel(wire_out_3_0_pwm_chanel),
    .reg_out_7_4_pwm_chanel(wire_out_7_4_pwm_chanel),
    .reg_pwm_gen_0_duty_cycle(wire_pwm_gen_0_duty_cycle),
    .reg_pwm_gen_1_duty_cycle(wire_pwm_gen_1_duty_cycle),
    .reg_pwm_gen_2_duty_cycle(wire_pwm_gen_2_duty_cycle),
    .reg_pwm_gen_3_duty_cycle(wire_pwm_gen_3_duty_cycle),
    .reg_pwm_gen_1_0_frequency_divider(wire_pwm_gen_1_0_frequency_divider),
    .reg_pwm_gen_3_2_frequency_divider(wire_pwm_gen_3_2_frequency_divider),
    .out(uo_out)
  );

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, ui_in[7:3], uio_in[7:0], 1'b0};


endmodule
