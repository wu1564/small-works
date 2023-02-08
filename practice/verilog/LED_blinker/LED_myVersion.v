module LED_blinker_my(
    // input
    clock,
    reset_n,
    enable,
    switch_1,
    switch_2,
    // output
    led_drive
);

localparam CNT_100HZ    = 125;
localparam CNT_50HZ     = 250;
localparam CNT_10HZ     = 1250;
localparam CNT_1HZ      = 12500;

input clock;
input reset_n;
input enable;
input switch_1;
input switch_2;
output led_drive;

wire edgeDetect;
wire switching0;
wire switching1;
wire change;
reg  ledDrive;
reg  [1:0] detect[0:1];
reg  [13:0] count_done;
reg  [13:0] cnt;

always @(*) begin
    case({switch_1,switch_2})
        0: count_done = CNT_100HZ;
        1: count_done = CNT_50HZ;
        2: count_done = CNT_10HZ;
        3: count_done = CNT_1HZ;
        default: count_done = 14'd0;
    endcase
end

always @(posedge clock or negedge reset_n) begin
    if(!reset_n) begin
        cnt <= 14'd0;
    end else begin
        cnt <= (change || edgeDetect) ? 14'd0 : cnt + 14'd1;
    end
end

assign change = (cnt >= count_done - 14'd1);
assign led_drive = ledDrive & enable;

always @(posedge clock or negedge reset_n) begin
    if(!reset_n) begin
        ledDrive <= 1'b0;
    end else if(change) begin
        ledDrive <= ~ledDrive;
    end
end

//                              negedge                             posedge
assign switching0 = ((detect[0][1] & ~detect[0][0]) || (~detect[0][1] & detect[0][0]));
assign switching1 = ((detect[1][1] & ~detect[1][0]) || (~detect[1][1] & detect[1][0]));
assign edgeDetect = switching0 | switching1;

//edge detect
//reg  [1:0] detect[0:1];
always @(posedge clock or negedge reset_n) begin
    if(!reset_n) begin
        detect[0] <= 2'd0;
        detect[1] <= 2'd0;
    end else begin
        detect[0] <= {detect[0][0],switch_1};
        detect[1] <= {detect[1][0],switch_2};
    end
end

endmodule
