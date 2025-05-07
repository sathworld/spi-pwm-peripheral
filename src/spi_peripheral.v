
module spi_peripheral (
    input  wire       nCS,
    input  wire       SCLK,
    input  wire       COPI,
    output wire       CIPO,      // SPI output data
    input  wire       clk,      // clock
    input  wire       rst_n,     // reset_n - low to reset
    output reg [7:0] reg_en_out,
    output reg [7:0] reg_en_pwm_out,
    output reg [7:0] reg_out_3_0_pwm_chanel,
    output reg [7:0] reg_out_7_4_pwm_chanel,
    output reg [7:0] reg_pwm_gen_1_duty_cycle,
    output reg [7:0] reg_pwm_gen_2_duty_cycle,
    output reg [7:0] reg_pwm_gen_3_duty_cycle,
    output reg [7:0] reg_pwm_gen_4_duty_cycle,
    output reg [3:0] reg_pwm_frequency_divider
);

    localparam max_address = 7'd8; // Maximum address for 9 registers (0x00 to 0x08)
    
    reg is_transacion_valid;
    reg [6:0] address;
    reg [7:0] data_to_be_stored;

    reg [4:0] num_of_clk_cycles;


    // Synchronizer registers for SPI signals
    reg nCS_sync1, nCS_sync2;
    reg SCLK_sync1, SCLK_sync2, SCLK_sync3;
    reg COPI_sync1, COPI_sync2;
    
    // Edge detection for SCLK and nCS
    wire sclk_posedge;
    reg nCS_sync3;
    wire nCS_posedge;
    
    // Transaction completion tracking
    reg transaction_ready;      // Set when transaction is ready
    reg transaction_processed;  // Set when transaction is processed
    reg [6:0] validated_address;
    reg [7:0] validated_data;
    
    // Synchronize SPI inputs to the clk domain
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            nCS_sync1 <= 1'b1;
            nCS_sync2 <= 1'b1;
            nCS_sync3 <= 1'b1;
            SCLK_sync1 <= 1'b0;
            SCLK_sync2 <= 1'b0;
            SCLK_sync3 <= 1'b0;
            COPI_sync1 <= 1'b0;
            COPI_sync2 <= 1'b0;
        end else begin
            nCS_sync1 <= nCS;
            nCS_sync2 <= nCS_sync1;
            nCS_sync3 <= nCS_sync2;
            SCLK_sync1 <= SCLK;
            SCLK_sync2 <= SCLK_sync1;
            SCLK_sync3 <= SCLK_sync2;
            COPI_sync1 <= COPI;
            COPI_sync2 <= COPI_sync1;
        end
    end
    
    // Detect SCLK positive edge and nCS rising edge in the clk domain
    assign sclk_posedge = SCLK_sync2 & ~SCLK_sync3;
    assign nCS_posedge = nCS_sync2 & ~nCS_sync3;
    // Generate CIPO output - use bit position from lower bits of num_of_clk_cycles
    assign CIPO = (nCS_sync2 == 1'b0) ? validated_data[7 - (num_of_clk_cycles[2:0])] : 1'bZ;

    // Process SPI protocol in the clk domain
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            address <= 8'b0;
            data_to_be_stored <= 8'b0;
            num_of_clk_cycles <= 5'b0;
            is_transacion_valid <= 1'b0;
            transaction_ready <= 1'b0;
            validated_address <= 7'b0;
            validated_data <= 8'b0;
        end else if (nCS_sync2 == 1'b0) begin
            if (sclk_posedge) begin
                if (num_of_clk_cycles < 5'd8) begin
                    address[7 - num_of_clk_cycles] <= COPI_sync2;
                    num_of_clk_cycles <= num_of_clk_cycles + 1'b1;
                    
                    // Check if first bit is 0
                    if (num_of_clk_cycles == 5'd0 && COPI_sync2 == 1'b0) begin
                        is_transacion_valid <= 1'b0;
                    end else if (num_of_clk_cycles == 5'd0) begin
                        is_transacion_valid <= 1'b1; // Start with valid, may change later
                    end

                    // When 7 bits of address are collected (before 8th bit)
                    if (num_of_clk_cycles == 5'd7) begin
                        // Load validated_data with the register value to be transmitted
                        case ({address[6:1], COPI_sync2}) // Use bits 6:1 plus incoming bit 0
                            7'b0000000: validated_data <= reg_en_out;
                            7'b0000010: validated_data <= reg_en_pwm_out;
                            7'b0000100: validated_data <= reg_out_3_0_pwm_chanel;
                            7'b0000110: validated_data <= reg_out_7_4_pwm_chanel;
                            7'b0001000: validated_data <= reg_pwm_gen_1_duty_cycle;
                            7'b0001010: validated_data <= reg_pwm_gen_2_duty_cycle;
                            7'b0001100: validated_data <= reg_pwm_gen_3_duty_cycle;
                            7'b0001110: validated_data <= reg_pwm_gen_4_duty_cycle;
                            7'b0010000: validated_data <= {4'b0000, reg_pwm_frequency_divider};
                            default:    validated_data <= 8'b0; // Default for invalid addresses
                        endcase
                    end

                end else if (num_of_clk_cycles < 5'd16) begin
                    // Check address value when all 7 address bits after the first bit are received
                    if (num_of_clk_cycles == 5'd8) begin
                        if (address[6:0] > max_address) begin
                            is_transacion_valid <= 1'b0;
                        end
                    end
                    data_to_be_stored[15 - num_of_clk_cycles] <= COPI_sync2;
                    num_of_clk_cycles <= num_of_clk_cycles + 1'b1;
                end
            end
        end else begin
            // When nCS goes high (transaction ends), validate the complete transaction
            if (nCS_posedge && is_transacion_valid && num_of_clk_cycles == 5'd16) begin
                transaction_ready <= 1'b1;
                validated_address <= address[6:0];
                validated_data <= data_to_be_stored;
            end else if (transaction_processed) begin
                // Clear ready flag once processed
                transaction_ready <= 1'b0;
                validated_data <= 8'b0;
            end
            
            // Reset for next transaction
            is_transacion_valid <= 1'b0;
            num_of_clk_cycles <= 5'b0;
        end
    end

    // Update registers only after the complete transaction has finished and been validated
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_en_out <= 8'b0;
            reg_en_pwm_out <= 8'b0;
            reg_out_3_0_pwm_chanel <= 8'b0;
            reg_out_7_4_pwm_chanel <= 8'b0;
            reg_pwm_gen_1_duty_cycle <= 8'b0;
            reg_pwm_gen_2_duty_cycle <= 8'b0;
            reg_pwm_gen_3_duty_cycle <= 8'b0;
            reg_pwm_gen_4_duty_cycle <= 8'b0;
            reg_pwm_frequency_divider <= 4'b0;
            transaction_processed <= 1'b0;
        end else if (transaction_ready && !transaction_processed) begin
            // Transaction is complete and valid, now we can safely update registers
            case (validated_address[6:0])
                7'b0000000: reg_en_out <= validated_data;
                7'b0000001: reg_en_pwm_out <= validated_data;
                7'b0000010: reg_out_3_0_pwm_chanel <= validated_data;
                7'b0000011: reg_out_7_4_pwm_chanel <= validated_data;
                7'b0000100: reg_pwm_gen_1_duty_cycle <= validated_data;
                7'b0000101: reg_pwm_gen_2_duty_cycle <= validated_data;
                7'b0000110: reg_pwm_gen_3_duty_cycle <= validated_data;
                7'b0000111: reg_pwm_gen_4_duty_cycle <= validated_data;
                7'b0001000: reg_pwm_frequency_divider <= validated_data[3:0];
                default: begin
                    // Invalid address, do nothing or handle error
                end
            endcase
        // Set the processed flag
        transaction_processed <= 1'b1;
        end else if (!transaction_ready && transaction_processed) begin
            // Reset processed flag when ready flag is cleared
            transaction_processed <= 1'b0;
        end
    end

endmodule