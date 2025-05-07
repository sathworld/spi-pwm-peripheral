module spi_peripheral (
    input  wire       nCS,
    input  wire       SCLK,
    input  wire       COPI,
    output wire       CIPO,      // SPI output data
    input  wire       clk,       // clock
    input  wire       rst_n,     // reset_n - low to reset
    output reg [7:0]  reg_en_out,
    output reg [7:0]  reg_en_pwm_out,
    output reg [7:0]  reg_out_3_0_pwm_gen_channel,
    output reg [7:0]  reg_out_7_4_pwm_gen_channel,
    output reg [7:0]  reg_pwm_gen_0_ch_0_duty_cycle,
    output reg [7:0]  reg_pwm_gen_0_ch_1_duty_cycle,
    output reg [7:0]  reg_pwm_gen_1_ch_0_duty_cycle,
    output reg [7:0]  reg_pwm_gen_1_ch_1_duty_cycle,
    output reg [7:0]  reg_pwm_gen_1_0_frequency_divider
);

    localparam max_address = 7'd8; // Maximum address for 9 registers (0x00 to 0x08)
    
    // Use an 8-bit shift register for both address and data
    reg [7:0] shift_reg;
    reg [3:0] bit_count;
    
    // Transaction state tracking
    reg transaction_valid;
    reg [6:0] address_reg;
    reg transaction_ready;
    reg transaction_processed;
    
    // Synchronizer registers as packed arrays to save registers
    reg [1:0] nCS_sync;
    reg [2:0] SCLK_sync;
    reg [1:0] COPI_sync;
    
    // Edge detection
    wire sclk_posedge = SCLK_sync[1] & ~SCLK_sync[2];
    wire nCS_posedge = nCS_sync[0] & ~nCS_sync[1];
    
    // CIPO output - uses shift register MSB
    assign CIPO = (nCS_sync[1] == 1'b0) ? shift_reg[7] : 1'bZ;
    
    // Combined synchronization process
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            nCS_sync <= 2'b11;
            SCLK_sync <= 3'b000;
            COPI_sync <= 2'b00;
        end else begin
            // Shift in new synchronizer values
            nCS_sync <= {nCS_sync[0], nCS};
            SCLK_sync <= {SCLK_sync[1:0], SCLK};
            COPI_sync <= {COPI_sync[0], COPI};
        end
    end
    
    // SPI protocol handling
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg <= 8'b0;
            bit_count <= 4'b0;
            address_reg <= 7'b0;
            transaction_valid <= 1'b0;
            transaction_ready <= 1'b0;
        end else if (nCS_sync[1] == 1'b0) begin  // CS active
            if (sclk_posedge) begin
                // Shift in new bit at LSB
                shift_reg <= {shift_reg[6:0], COPI_sync[1]};
                bit_count <= bit_count + 1'b1;
                
                // Validate first bit (must be 1 for valid transaction)
                if (bit_count == 4'd0) begin
                    transaction_valid <= (COPI_sync[1] == 1'b1);
                end
                
                // At bit 7, we've received all address bits
                if (bit_count == 4'd7) begin
                    // Store address for validation
                    address_reg <= shift_reg[6:0];
                    
                    // Load data for read operation based on complete address
                    case (shift_reg[6:0])
                        7'b0000000: shift_reg <= reg_en_out;
                        7'b0000001: shift_reg <= reg_en_pwm_out;
                        7'b0000010: shift_reg <= reg_out_3_0_pwm_gen_channel;
                        7'b0000011: shift_reg <= reg_out_7_4_pwm_gen_channel;
                        7'b0000100: shift_reg <= reg_pwm_gen_0_ch_0_duty_cycle;
                        7'b0000101: shift_reg <= reg_pwm_gen_0_ch_1_duty_cycle;
                        7'b0000110: shift_reg <= reg_pwm_gen_1_ch_0_duty_cycle;
                        7'b0000111: shift_reg <= reg_pwm_gen_1_ch_1_duty_cycle;
                        7'b0001000: shift_reg <= reg_pwm_gen_1_0_frequency_divider;
                        default:    shift_reg <= 8'b0; // Invalid address
                    endcase
                    
                    // Validate address range
                    if (shift_reg[6:0] > max_address) begin
                        transaction_valid <= 1'b0;
                    end
                end
                // For bits 8-15, keep shifting data for read, or collect incoming data for write
                else if (bit_count > 4'd7 && bit_count < 4'd15) begin
                    // For read operations, shift to provide next bit on CIPO
                    // For write operations, shift in new data from COPI
                    shift_reg <= {shift_reg[6:0], COPI_sync[1]};
                end
            end
        end else begin  // CS inactive
            // Handle transaction completion
            if (nCS_posedge && transaction_valid && bit_count == 4'd16) begin
                transaction_ready <= 1'b1;
            end else if (transaction_processed) begin
                transaction_ready <= 1'b0;
            end
            
            // Reset bit counter for next transaction
            bit_count <= 4'b0;
            if (nCS_posedge) begin
                transaction_valid <= 1'b0;
            end
        end
    end
    
    // Register update process
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_en_out <= 8'b0;
            reg_en_pwm_out <= 8'b0;
            reg_out_3_0_pwm_gen_channel <= 8'b0;
            reg_out_7_4_pwm_gen_channel <= 8'b0;
            reg_pwm_gen_0_ch_0_duty_cycle <= 8'b0;
            reg_pwm_gen_0_ch_1_duty_cycle <= 8'b0;
            reg_pwm_gen_1_ch_0_duty_cycle <= 8'b0;
            reg_pwm_gen_1_ch_1_duty_cycle <= 8'b0;
            reg_pwm_gen_1_0_frequency_divider <= 8'b0;
            transaction_processed <= 1'b0;
        end else if (transaction_ready && !transaction_processed) begin
            // Only update registers for valid addresses
            if (address_reg <= max_address) begin
                case (address_reg)
                    7'b0000000: reg_en_out <= shift_reg;
                    7'b0000001: reg_en_pwm_out <= shift_reg;
                    7'b0000010: reg_out_3_0_pwm_gen_channel <= shift_reg;
                    7'b0000011: reg_out_7_4_pwm_gen_channel <= shift_reg;
                    7'b0000100: reg_pwm_gen_0_ch_0_duty_cycle <= shift_reg;
                    7'b0000101: reg_pwm_gen_0_ch_1_duty_cycle <= shift_reg;
                    7'b0000110: reg_pwm_gen_1_ch_0_duty_cycle <= shift_reg;
                    7'b0000111: reg_pwm_gen_1_ch_1_duty_cycle <= shift_reg;
                    7'b0001000: reg_pwm_gen_1_0_frequency_divider <= shift_reg;
                endcase
            end
            transaction_processed <= 1'b1;
        end else if (!transaction_ready && transaction_processed) begin
            transaction_processed <= 1'b0;
        end
    end

endmodule