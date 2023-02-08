module LED_blinker_my(
    input clock, enable, switch_1, switch_2, reset_n,
    output led_drive
);

// input clock is 25 kHz, all counters are cascaded in the order
// shown below
parameter cnt_100Hz_m = 250; // modulus for 100 Hz
parameter cnt_50Hz_m = 2; // modulus for 50 Hz
parameter cnt_10Hz_m = 5; // modulus for 10 Hz
parameter cnt_1Hz_m = 10; // modulus for 1 Hz

wire [ 7: 0 ] cnt_100Hz; // modulo-250 counter
wire cnt_50Hz; // modulo-2 counter
wire [ 2: 0 ] cnt_10Hz; // modulo-5 counter
wire [ 3: 0 ] cnt_1Hz; // modulo-10 counter
// one bit select
reg LED_select;
// instantiate the modulo_r_counter four times and cascade them together
// to form the derired counters
wire cnt_100Hz_cout_en, cnt_50Hz_cout_en, cnt_10Hz_cout_en, count_en_out2;

modulo_r_counter #(
    cnt_100Hz_m, 8
) mod_250_cnt( 
    .clk(clock),
    .reset_n(reset_n),
    .cout_50(cnt_100Hz_cout_50),
    .cout_en(cnt_100Hz_cout_en),
    .qout(cnt_100Hz)
);

modulo_r_counter #(
    cnt_50Hz_m, 1
) mod_2_cnt ( 
    .clk(cnt_100Hz_cout_en), 
    .reset_n(reset_n),
    .cout_50(cnt_50Hz_cout_50),
    .cout_en(cnt_50Hz_cout_en),
    .qout(cnt_50Hz)
);

modulo_r_counter #(
    cnt_10Hz_m, 3
) mod_5_cnt ( 
    .clk(cnt_50Hz_cout_en), 
    .reset_n(reset_n),
    .cout_50(cnt_10Hz_cout_50),
    .cout_en(cnt_10Hz_cout_en), 
    .qout(cnt_10Hz)
);

modulo_r_counter #(
    cnt_1Hz_m, 4
) mod_10_cnt(
    .clk(cnt_10Hz_cout_en), 
    .reset_n(reset_n),
    .cout_50(cnt_1Hz_cout_50),
    .cout_en(count_en_out2), 
    .qout(cnt_1Hz)
);

// create a multiplexer based on switch inputs
always @(*) begin
    case ({switch_1, switch_2}) // concatenation Operator { }
        2'b00: LED_select = cnt_100Hz_cout_50;
        2'b01: LED_select = cnt_50Hz_cout_50;
        2'b10: LED_select = cnt_10Hz_cout_50;
        2'b11: LED_select = cnt_1Hz_cout_50;
    endcase
end

assign led_drive = LED_select & enable;

endmodule

// a modulo-R binary counter with asynchronous reset and
// enable control.The output is a 50% duty cycle
module modulo_r_counter #(
    parameter R = 10, // default modulus
    parameter N = 4
)( // N = log2 R
    input clk, reset_n,
    output cout_50, // 50% duty-cycle output
    output cout_en, // carry-out to enable the next stage
    output reg [N-1:0] qout
);
    // the body of the modulo r binary counter
    assign cout_50 = (qout >= R >> 1);
    assign cout_en = (qout == R - 1);
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) qout <= 0;
        else if (cout_en) qout <= 0;
        else qout <= qout + 1;
    end
endmodule
