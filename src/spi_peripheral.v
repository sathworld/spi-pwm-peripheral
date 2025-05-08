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
    
    // Main shift register for input data
    reg [7:0] shift_reg;
    // Separate register for output data
    reg [7:0] cipo_shift_reg;
    reg [4:0] bit_count;
    
    // Transaction state tracking
    reg transaction_valid;
    reg [6:0] address_reg;
    reg transaction_ready;
    reg transaction_processed;
    
    // Synchronizer registers as packed arrays to save registers
    reg [2:0] nCS_sync;
    reg [2:0] SCLK_sync;
    reg [1:0] COPI_sync;
    
    // Edge detection
    wire sclk_posedge = SCLK_sync[1] & ~SCLK_sync[2];
    wire sclk_negedge = ~SCLK_sync[1] & SCLK_sync[2];
    wire nCS_posedge = nCS_sync[1] & ~nCS_sync[2];
    
    // CIPO output - uses dedicated output shift register
    assign CIPO = (nCS_sync[1] == 1'b0) ? cipo_shift_reg[7] : 1'bZ;
    
    // Combined synchronization process
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            nCS_sync <= 3'b111;
            SCLK_sync <= 3'b000;
            COPI_sync <= 2'b00;
        end else begin
            // Shift in new synchronizer values
            nCS_sync <= {nCS_sync[1:0], nCS};
            SCLK_sync <= {SCLK_sync[1:0], SCLK};
            COPI_sync <= {COPI_sync[0], COPI};
        end
    end
    
    // SPI protocol handling
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg <= 8'b0;
            cipo_shift_reg <= 8'b0;
            bit_count <= 5'b0;
            address_reg <= 7'b0;
            transaction_valid <= 1'b0;
            transaction_ready <= 1'b0;
        end else if (nCS_sync[1] == 1'b0) begin  // CS active
            // Process COPI on rising edge of SCLK
            if (sclk_posedge) begin
                // Shift in new bit at LSB
                shift_reg <= {shift_reg[6:0], COPI_sync[1]};
                bit_count <= bit_count + 1'b1;
                
                // Validate first bit (must be 1 for valid transaction)
                if (bit_count == 5'd0) begin
                    transaction_valid <= (COPI_sync[1] == 1'b1);
                end
                
                // At bit 7, we've received all address bits
                if (bit_count == 5'd7) begin
                    // Store address for validation
                    address_reg <= {shift_reg[5:0], COPI_sync[1]};
                    
                    // Validate address range
                    if ({shift_reg[5:0], COPI_sync[1]} > max_address) begin
                        transaction_valid <= 1'b0;
                    end
                    
                    // Prepare data for read operation based on the address
                    case ({shift_reg[5:0], COPI_sync[1]})
                        7'b0000000: cipo_shift_reg <= reg_en_out;
                        7'b0000001: cipo_shift_reg <= reg_en_pwm_out;
                        7'b0000010: cipo_shift_reg <= reg_out_3_0_pwm_gen_channel;
                        7'b0000011: cipo_shift_reg <= reg_out_7_4_pwm_gen_channel;
                        7'b0000100: cipo_shift_reg <= reg_pwm_gen_0_ch_0_duty_cycle;
                        7'b0000101: cipo_shift_reg <= reg_pwm_gen_0_ch_1_duty_cycle;
                        7'b0000110: cipo_shift_reg <= reg_pwm_gen_1_ch_0_duty_cycle;
                        7'b0000111: cipo_shift_reg <= reg_pwm_gen_1_ch_1_duty_cycle;
                        7'b0001000: cipo_shift_reg <= reg_pwm_gen_1_0_frequency_divider;
                        default:    cipo_shift_reg <= 8'b0; // Invalid address
                    endcase
                end
            end
            
            // Process CIPO on falling edge of SCLK
            if (sclk_negedge) begin
                // Update cipo_shift_reg only after first byte (after bit 8)
                if (bit_count > 5'd8) begin
                    // Shift out next bit for CIPO
                    cipo_shift_reg <= {cipo_shift_reg[6:0], 1'b0};
                end
            end
        end else begin  // CS inactive
            // Handle transaction completion
            if (nCS_posedge && transaction_valid && bit_count >= 5'd16) begin
                transaction_ready <= 1'b1;
            end 
            if (transaction_processed) begin
                transaction_ready <= 1'b0;
                transaction_valid <= 1'b0;
            end
            
            // Reset bit counter for next transaction
            bit_count <= 5'b0;
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
                    default: begin
                        // Invalid address, do nothing
                    end
                endcase
            end
            transaction_processed <= 1'b1;
        end else if (!transaction_ready && transaction_processed) begin
            transaction_processed <= 1'b0;
        end
    end

endmodule