/*
 * Copyright (c) 2024 Damir Gazizullin
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module pwm_peripheral (
    input  wire       clk,      // clock
    input  wire       rst_n,     // reset_n - low to reset
    input wire [7:0]  reg_en_out,
    input wire [7:0]  reg_en_pwm_out,
    input wire [7:0]  reg_out_3_0_pwm_gen_channel,
    input wire [7:0]  reg_out_7_4_pwm_gen_channel,
    input wire [7:0]  reg_pwm_gen_0_ch_0_duty_cycle,
    input wire [7:0]  reg_pwm_gen_0_ch_1_duty_cycle,
    input wire [7:0]  reg_pwm_gen_1_ch_0_duty_cycle,
    input wire [7:0]  reg_pwm_gen_1_ch_1_duty_cycle,
    input wire [7:0]  reg_pwm_gen_1_0_frequency_divider,
    output wire [7:0]  out
);

    // Base PWM speed (reg_pwm_frequency_divider = 4'b0000) is 10^7/(2*255), yielding 19600 (19607.8431372549) Hz
    reg [7:0] pwm_counter_gen_0_ch_0;
    reg [7:0] pwm_counter_gen_0_ch_1;
    reg [7:0] pwm_counter_gen_1_ch_0;
    reg [7:0] pwm_counter_gen_1_ch_1;
    
    // Set up clock divider based on the register value
    // Counter for clock division
    reg [15:0] clk_div_counter_gen_0;
    reg [15:0] clk_div_counter_gen_1;

    wire pwm_signal_gen_0_ch_0 = pwm_counter_gen_0_ch_0 < reg_pwm_gen_0_ch_0_duty_cycle;
    wire pwm_signal_gen_0_ch_1 = pwm_counter_gen_0_ch_1 < reg_pwm_gen_0_ch_1_duty_cycle;
    wire pwm_signal_gen_1_ch_0 = pwm_counter_gen_1_ch_0 < reg_pwm_gen_1_ch_0_duty_cycle;
    wire pwm_signal_gen_1_ch_1 = pwm_counter_gen_1_ch_1 < reg_pwm_gen_1_ch_1_duty_cycle;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pwm_counter_gen_0_ch_0 <= 0;
            pwm_counter_gen_0_ch_1 <= 0;
            pwm_counter_gen_1_ch_0 <= 0;
            pwm_counter_gen_1_ch_1 <= 0;

            clk_div_counter_gen_0 <= 0;
            clk_div_counter_gen_1 <= 0;
        end else begin
            // Increment the clock divider counter for each PWM generator
            clk_div_counter_gen_0 <= clk_div_counter_gen_0 + 1;
            clk_div_counter_gen_1 <= clk_div_counter_gen_1 + 1;
            
            // Check if the clock divider counter has reached the desired value for each PWM generator
            if (clk_div_counter_gen_0 >= 16'h0001 << reg_pwm_gen_1_0_frequency_divider[3:0]) begin
                clk_div_counter_gen_0 <= 0; // Reset the clock divider counter
                pwm_counter_gen_0_ch_0 <= pwm_counter_gen_0_ch_0 + 1;
                pwm_counter_gen_0_ch_1 <= pwm_counter_gen_0_ch_1 + 1;
            end

            if (clk_div_counter_gen_1 >= 16'h0001 << reg_pwm_gen_1_0_frequency_divider[7:4]) begin
                clk_div_counter_gen_1 <= 0; // Reset the clock divider counter
                pwm_counter_gen_1_ch_0 <= pwm_counter_gen_1_ch_0 + 1;
                pwm_counter_gen_1_ch_1 <= pwm_counter_gen_1_ch_1 + 1;
            end
        end
    end

    // Define all PWM signals in an array for easier muxing
    wire [3:0] pwm_signals;
    assign pwm_signals[0] = pwm_signal_gen_0_ch_0;
    assign pwm_signals[1] = pwm_signal_gen_0_ch_1;
    assign pwm_signals[2] = pwm_signal_gen_1_ch_0;
    assign pwm_signals[3] = pwm_signal_gen_1_ch_1;

    // Generate the output using a mux-based approach
    genvar out_ch_iter;
    generate
        for (out_ch_iter = 0; out_ch_iter < 8; out_ch_iter = out_ch_iter + 1) begin : gen_pwm_output
            // Extract the channel select bits based on pin number
            wire [1:0] channel_select = (out_ch_iter < 4) ? 
                                      reg_out_3_0_pwm_gen_channel[(out_ch_iter*2)+1:out_ch_iter*2] : 
                                      reg_out_7_4_pwm_gen_channel[((out_ch_iter-4)*2)+1:(out_ch_iter-4)*2];
            
            // Implement output mux
            wire pin_enable = reg_en_pwm_out[out_ch_iter] & reg_en_out[out_ch_iter];
            wire pwm_out = pwm_signals[channel_select];
            
            // Final output selection
            assign out[out_ch_iter] = pin_enable ? pwm_out : reg_en_out[out_ch_iter];
        end
    endgenerate
endmodule
