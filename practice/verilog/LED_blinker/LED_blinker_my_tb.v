`timescale 1ns / 1ps
module LED_blinker_my_tb;
// internal signals declarations
parameter clock_period = 40;

reg clock, enable;
reg switch_1, switch_2, reset_n;
wire led_drive;
integer i;

// Unit Under Test port map
LED_blinker_my UUT (
    .clock(clock),  
    .enable(enable),
    .switch_1(switch_1),    
    .switch_2(switch_2),   
    .reset_n(reset_n),
    .led_drive(led_drive)
);

// generate a 25-kHz clock signal
initial clock <= 1'b0;

always begin
    #(clock_period/ 2) clock <= 1'b0;
    #(clock_period/ 2) clock <= 1'b1;
end

initial begin
    enable <= 1'b0; 
    reset_n = 1'b0;
    repeat (5) @(negedge clock);
    reset_n = 1'b1;
    {switch_1,switch_2} = 2'b00;
    repeat (5) @(negedge clock) enable <= 1'b0;
    for (i = 0; i < 50; i = i + 1) begin
        enable <=1'b1;
        {switch_1, switch_2} <= i[1:0];
        repeat (12000) @(negedge clock);
        enable <= 1'b0;
        repeat(10) @(negedge clock);
    end
end

initial #6000000 $finish;
initial $monitor ( $realtime, "ns %h %h %h %h %h %h \n", clock, enable, switch_1, switch_2, reset_n, led_drive);

endmodule
