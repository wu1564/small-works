module LED_blinker_my (
    input clock, enable, switch_1, switch_2, reset_n,
    output led_drive 
);

// input clock is 25 kHz
parameter cnt_100Hz_m = 250; // modulus for 100 Hz
parameter cnt_50Hz_m = 2; // modulus for 50 Hz
parameter cnt_10Hz_m = 5; // modulus for 10 Hz
parameter cnt_1Hz_m = 10; // modulus for 1 Hz

reg [ 7: 0 ] cnt_100Hz; // modulo-250 counter
reg [ 0: 0 ] cnt_50Hz; // modulo-2 counter
reg [ 2: 0 ] cnt_10Hz; // modulo-5 counter
reg [ 3: 0 ] cnt_1Hz; // modulo-10 counter
wire cnt_100Hz_cout_50;
wire cnt_50Hz_cout_50;
wire cnt_10Hz_cout_50;
wire cnt_1Hz_cout_50;

// One bit select
reg LED_select;
wire cnt_100Hz_cout_en , cnt_50Hz_cout_en , cnt_10Hz_cout_en , cnt_1Hz_cout_en;

// modulo-250 counter --- generate 100-Hz output
assign cnt_100Hz_cout_50 = (cnt_100Hz >= cnt_100Hz_m >> 1);
assign cnt_100Hz_cout_en = (cnt_100Hz == cnt_100Hz_m - 1);
always @(posedge clock or negedge reset_n) begin
    if (!reset_n) cnt_100Hz <= 0;
    else i f (cnt_100Hz_cout_en) cnt_100Hz <= 0;
    else cnt_100Hz <= cnt_100Hz + 1;
end

// modulo-2 counter --- generate 50-Hz output
assign cnt_50Hz_cout_50 = (cnt_50Hz >= cnt_50Hz_m >> 1);
assign cnt_50Hz_cout_en = (cnt_50Hz == cnt_50Hz_m - 1);

always @(negedge cnt_100Hz_cout_en or negedge reset_n) begin
    if ( ! reset_n) cnt_50Hz <= 0;
    else i f (cnt_50Hz_cout_en) cnt_50Hz <= 0;
    else cnt_50Hz <= cnt_50Hz + 1;
end

// modulo-5 counter --- generate 10-Hz output
assign cnt_10Hz_cout_50 = (cnt_10Hz >= cnt_10Hz_m >> 1);
assign cnt_10Hz_cout_en = (cnt_10Hz == cnt_10Hz_m - 1);
always @(negedge cnt_50Hz_cout_en or negedge reset_n) begin
    if(!reset_n) cnt_10Hz <= 0;
    else i f (cnt_10Hz_cout_en) cnt_10Hz <= 0;
    else cnt_10Hz <= cnt_10Hz + 1;
end

// modulo-10 counter --- generate 1-Hz output
assign cnt_1Hz_cout_50 = (cnt_1Hz >= cnt_1Hz_m >> 1);
assign cnt_1Hz_cout_en = (cnt_1Hz == cnt_1Hz_m - 1);
always @(negedge cnt_10Hz_cout_en or negedge reset_n) begin
    if (!reset_n) cnt_1Hz <= 0;
    else if (cnt_1Hz_cout_en) cnt_1Hz <= 0;
    else cnt_1Hz <= cnt_1Hz + 1;
end

// create a multiplexer based on switch inputs
always @(∗) begin
case ({switch_1 , switch_2}) // concatenation Operator { }
    2'b00: LED_select = cnt_100Hz_cout_50;
    2'b01: LED_select = cnt_50Hz_cout_50;
    2'b10: LED_select = cnt_10Hz_cout_50;
    2'b11: LED_select = cnt_1Hz_cout_50;
endcase
end
assign led_drive = LED_select & enable;

endmodule
