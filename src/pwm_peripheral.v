/*
 * Copyright (c) 2024 Damir Gazizullin
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module pwm_peripheral (
    input  wire       clk,      // clock
    input  wire       rst_n,     // reset_n - low to reset
    input  reg [7:0]  reg_en_out,
    input  reg [7:0]  reg_en_pwm_out,
    input  reg [7:0]  reg_out_3_0_pwm_chanel,
    input  reg [7:0]  reg_out_7_4_pwm_chanel,
    input  reg [7:0]  reg_pwm_gen_1_duty_cycle,
    input  reg [7:0]  reg_pwm_gen_2_duty_cycle,
    input  reg [7:0]  reg_pwm_gen_3_duty_cycle,
    input  reg [7:0]  reg_pwm_gen_4_duty_cycle,
    input  reg [3:0]  reg_pwm_frequency_divider,
    output reg [7:0]  out
);

    // Base PWM speed (reg_pwm_frequency_divider = 4'b0000) is 10^7/(2*255), yielding 3921 (3921.5686274510) Hz
    reg [7:0] pwm_counter;
    
    // Set up clock divider based on the register value
    // Counter for clock division
    reg [15:0] clk_div_counter;

    
    wire pwm_signal_1 = pwm_counter < reg_pwm_gen_1_duty_cycle;
    wire pwm_signal_2 = pwm_counter < reg_pwm_gen_2_duty_cycle;
    wire pwm_signal_3 = pwm_counter < reg_pwm_gen_3_duty_cycle;
    wire pwm_signal_4 = pwm_counter < reg_pwm_gen_4_duty_cycle;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 0;
            pwm_counter <= 0;
            clk_div_counter <= 0;
        end else begin
            // Increment the clock divider counter
            clk_div_counter <= clk_div_counter + 1;
            // Check if the clock divider counter has reached the desired value
            if (clk_div_counter == 15'h0001 << reg_pwm_frequency_divider) begin
                clk_div_counter <= 0; // Reset the clock divider counter
                pwm_counter <= pwm_counter + 1;
            end else if (pwm_counter == 8'hFF) begin
                pwm_counter <= 0;
            end
            // Check if the PWM is enabled for each channel
            // Check if the PWM is enabled for channel 0
            if (reg_en_pwm_out[0] & reg_en_out[0]) begin
                // Connect the PWM channel 0 to the output based on the register values (00 for channel 1, 01 for channel 2, etc.)
                case (reg_out_3_0_pwm_chanel[1:0])
                    2'b00: out[0] <= pwm_signal_1;
                    2'b01: out[0] <= pwm_signal_2;
                    2'b10: out[0] <= pwm_signal_3;
                    2'b11: out[0] <= pwm_signal_4;
                    default: out[0] <= 1'b0; // Default case to avoid latches
                endcase
            end else begin
                out[0] <= reg_en_out[0]; // If not enabled, set to the value of reg_en_out[0]
            end

            // Check if the PWM is enabled for channel 1
            if (reg_en_pwm_out[1] & reg_en_out[1]) begin
                // Connect the PWM channel 1 to the output based on the register values
                case (reg_out_3_0_pwm_chanel[3:2])
                    2'b00: out[1] <= pwm_signal_1;
                    2'b01: out[1] <= pwm_signal_2;
                    2'b10: out[1] <= pwm_signal_3;
                    2'b11: out[1] <= pwm_signal_4;
                    default: out[1] <= 1'b0; // Default case to avoid latches
                endcase
            end else begin
                out[1] <= reg_en_out[1]; // If not enabled, set to the value of reg_en_out[1]
            end

            // Check if the PWM is enabled for channel 2
            if (reg_en_pwm_out[2] & reg_en_out[2]) begin
                // Connect the PWM channel 2 to the output based on the register values
                case (reg_out_3_0_pwm_chanel[5:4])
                    2'b00: out[2] <= pwm_signal_1;
                    2'b01: out[2] <= pwm_signal_2;
                    2'b10: out[2] <= pwm_signal_3;
                    2'b11: out[2] <= pwm_signal_4;
                    default: out[2] <= 1'b0; // Default case to avoid latches
                endcase
            end else begin
                out[2] <= reg_en_out[2]; // If not enabled, set to the value of reg_en_out[2]
            end

            // Check if the PWM is enabled for channel 3
            if (reg_en_pwm_out[3] & reg_en_out[3]) begin
                // Connect the PWM channel 3 to the output based on the register values
                case (reg_out_3_0_pwm_chanel[7:6])
                    2'b00: out[3] <= pwm_signal_1;
                    2'b01: out[3] <= pwm_signal_2;
                    2'b10: out[3] <= pwm_signal_3;
                    2'b11: out[3] <= pwm_signal_4;
                    default: out[3] <= 1'b0; // Default case to avoid latches
                endcase
            end else begin
                out[3] <= reg_en_out[3]; // If not enabled, set to the value of reg_en_out[3]
            end

            // Check if the PWM is enabled for channel 4
            if (reg_en_pwm_out[4] & reg_en_out[4]) begin
                // Connect the PWM channel 4 to the output based on the register values
                case (reg_out_7_4_pwm_chanel[1:0])
                    2'b00: out[4] <= pwm_signal_1;
                    2'b01: out[4] <= pwm_signal_2;
                    2'b10: out[4] <= pwm_signal_3;
                    2'b11: out[4] <= pwm_signal_4;
                    default: out[4] <= 1'b0; // Default case to avoid latches
                endcase
            end else begin
                out[4] <= reg_en_out[4]; // If not enabled, set to the value of reg_en_out[4]
            end

            // Check if the PWM is enabled for channel 5
            if (reg_en_pwm_out[5] & reg_en_out[5]) begin
                // Connect the PWM channel 5 to the output based on the register values
                case (reg_out_7_4_pwm_chanel[3:2])
                    2'b00: out[5] <= pwm_signal_1;
                    2'b01: out[5] <= pwm_signal_2;
                    2'b10: out[5] <= pwm_signal_3;
                    2'b11: out[5] <= pwm_signal_4;
                    default: out[5] <= 1'b0; // Default case to avoid latches
                endcase
            end else begin
                out[5] <= reg_en_out[5]; // If not enabled, set to the value of reg_en_out[5]
            end

            // Check if the PWM is enabled for channel 6
            if (reg_en_pwm_out[6] & reg_en_out[6]) begin
                // Connect the PWM channel 6 to the output based on the register values
                case (reg_out_7_4_pwm_chanel[5:4])
                    2'b00: out[6] <= pwm_signal_1;
                    2'b01: out[6] <= pwm_signal_2;
                    2'b10: out[6] <= pwm_signal_3;
                    2'b11: out[6] <= pwm_signal_4;
                    default: out[6] <= 1'b0; // Default case to avoid latches
                endcase
            end else begin
                out[6] <= reg_en_out[6]; // If not enabled, set to the value of reg_en_out[6]
            end

            // Check if the PWM is enabled for channel 7
            if (reg_en_pwm_out[7] & reg_en_out[7]) begin
                // Connect the PWM channel 7 to the output based on the register values
                case (reg_out_7_4_pwm_chanel[7:6])
                    2'b00: out[7] <= pwm_signal_1;
                    2'b01: out[7] <= pwm_signal_2;
                    2'b10: out[7] <= pwm_signal_3;
                    2'b11: out[7] <= pwm_signal_4;
                    default: out[7] <= 1'b0; // Default case to avoid latches
                endcase
            end else begin
                out[7] <= reg_en_out[7]; // If not enabled, set to the value of reg_en_out[7]
            end
        end
    end
endmodule
