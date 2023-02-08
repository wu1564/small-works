`timescale 1ns/1ps

`define CYCLE 10

module M_AXI_STREAM_TB;

localparam integer C_S_AXIS_TDATA_WIDTH	= 24;
localparam integer C_M_AXIS_TDATA_WIDTH = 24;
localparam integer DATA_SEND_NUM        = 32;
localparam integer FIFO_DEPTH           = 32;
localparam integer FIFO_DATA_WIDTH      = 32;

// module
wire S_AXIS_TREADY;
reg [C_S_AXIS_TDATA_WIDTH/8-1:0] S_AXIS_TKEEP;
reg S_AXIS_ACLK;
reg S_AXIS_ARESETN;
reg [C_S_AXIS_TDATA_WIDTH-1 : 0] S_AXIS_TDATA;
reg S_AXIS_TLAST;
reg S_AXIS_TVALID;
// fifo
reg  pop_en;
wire empty;
wire full;
wire fifo_write;
wire [FIFO_DATA_WIDTH-1:0] S_AXIS_FIFO_OUT;
wire [FIFO_DATA_WIDTH-1:0] output_data;      // fifo output
// testbench
integer i = 0, hasData = 0, j = 0;
wire [7:0] give_default_byte;
reg  [C_S_AXIS_TDATA_WIDTH-1:0] combine_out;
// check mem
reg  [C_S_AXIS_TDATA_WIDTH-1:0] mem[0:FIFO_DEPTH-1];

myip_test_v1_0_S00_AXIS #(
    .C_S_AXIS_TDATA_WIDTH(C_S_AXIS_TDATA_WIDTH),
    .FIFO_DATA_WIDTH(FIFO_DATA_WIDTH)
)S_AXIS_INST(
    .S_AXIS_TKEEP(S_AXIS_TKEEP),
    .S_AXIS_ACLK(S_AXIS_ACLK),
    .S_AXIS_ARESETN(S_AXIS_ARESETN),
    .S_AXIS_TREADY(S_AXIS_TREADY),
    .S_AXIS_TDATA(S_AXIS_TDATA),
    .S_AXIS_TLAST(S_AXIS_TLAST),
    .S_AXIS_TVALID(S_AXIS_TVALID),
    // fifo
    .empty(empty),
    .full(full),
    .fifo_write(fifo_write),
    .fifo_data_out(S_AXIS_FIFO_OUT)
);

axis_fifo_connection#(
    .FIFO_DEPTH(FIFO_DEPTH),
    .FIFO_DATA_WIDTH(FIFO_DATA_WIDTH)
)fifo_inst(
    .clk(S_AXIS_ACLK),
    .reset_n(S_AXIS_ARESETN),
    .write_en(fifo_write),
    .input_data(S_AXIS_FIFO_OUT),
    .pop_en(pop_en),
    // control signal
    .full(full),
    .empty(empty),
    .output_data(output_data)
);

initial begin
    S_AXIS_ACLK = 0;
    forever #(`CYCLE/2) S_AXIS_ACLK = ~S_AXIS_ACLK;
end

assign give_default_byte = 8'd1;

initial begin
    S_AXIS_TKEEP = 0;
    S_AXIS_TDATA = 0;
    S_AXIS_TLAST = 0;
    S_AXIS_TVALID = 0;
    S_AXIS_ARESETN = 1;
    for(i = 0; i < FIFO_DEPTH; i = i + 1) begin
        mem[i] = 0;
    end
    pop_en = 0;
    #(`CYCLE) S_AXIS_ARESETN = 0;
    #(`CYCLE) S_AXIS_ARESETN = 1;
    //  test state : the final data is not full
    //  first 15 data and one three bytes
    for(i = 0; i < DATA_SEND_NUM/2; i = i + 1) begin
        sendData({give_default_byte+(i[7:0]),give_default_byte+(i[7:0]),give_default_byte+(i[7:0]),give_default_byte+(i[7:0])},4'hf);
        combine({give_default_byte+(i[7:0]),give_default_byte+(i[7:0]),give_default_byte+(i[7:0]),give_default_byte+(i[7:0])},i[3:0],combine_out);
        mem[i] = combine_out;
    end
    sendLast({give_default_byte,give_default_byte,give_default_byte,give_default_byte},4'b1101);
    combine({give_default_byte+(i[7:0]),give_default_byte+(i[7:0]),give_default_byte+(i[7:0]),give_default_byte+(i[7:0])},4'b1101,combine_out);
    mem[i] = combine_out;

    // test state : full data 
    #(`CYCLE*100);
    #(`CYCLE) S_AXIS_ARESETN = 0;
    #(`CYCLE) S_AXIS_ARESETN = 1;
    for(i = 0; i < DATA_SEND_NUM/2; i = i + 1) begin
        if(i != DATA_SEND_NUM/2-1) begin
            sendData({give_default_byte+(i[7:0]),give_default_byte+(i[7:0]),give_default_byte+(i[7:0]),give_default_byte+(i[7:0])},4'hf);
        end else begin
            sendLast({give_default_byte+(i[7:0]),give_default_byte+(i[7:0]),give_default_byte+(i[7:0]),give_default_byte+(i[7:0])},4'hf);
        end
        combine({give_default_byte+(i[7:0]),give_default_byte+(i[7:0]),give_default_byte+(i[7:0]),give_default_byte+(i[7:0])},4'hf,combine_out);
        mem[i] = combine_out;
    end

    // test state : the data before last is not full and send the full data
    #(`CYCLE*100);
    #(`CYCLE) S_AXIS_ARESETN = 0;
    #(`CYCLE) S_AXIS_ARESETN = 1;
    for(i = 0; i < DATA_SEND_NUM/2; i = i + 1) begin
        sendData({give_default_byte+(i[7:0]),give_default_byte+(i[7:0]),give_default_byte+(i[7:0]),give_default_byte+(i[7:0])},4'hf);
        combine({give_default_byte+(i[7:0]),give_default_byte+(i[7:0]),give_default_byte+(i[7:0]),give_default_byte+(i[7:0])},4'hf,combine_out);
        mem[i] = combine_out;
    end
    sendData({give_default_byte+(i[7:0]),give_default_byte+(i[7:0]),give_default_byte+(i[7:0]),give_default_byte+(i[7:0])},4'h7);
    sendLast({give_default_byte+(i[7:0]),give_default_byte+(i[7:0]),give_default_byte+(i[7:0]),give_default_byte+(i[7:0])},4'hf);

    // test state : the data before last is not full and send the full data
    // test : full the original and send the new byte
    #(`CYCLE*100);
    #(`CYCLE) S_AXIS_ARESETN = 0;
    #(`CYCLE) S_AXIS_ARESETN = 1;
    for(i = 0; i < DATA_SEND_NUM/2; i = i + 1) begin
        sendData({give_default_byte+(i[7:0]),give_default_byte+(i[7:0]),give_default_byte+(i[7:0]),give_default_byte+(i[7:0])},4'hf);
        combine({give_default_byte+(i[7:0]),give_default_byte+(i[7:0]),give_default_byte+(i[7:0]),give_default_byte+(i[7:0])},4'hf,combine_out);
        mem[i] = combine_out;
    end
    sendData({give_default_byte,give_default_byte,give_default_byte,give_default_byte},4'h7);
    sendLast({give_default_byte,give_default_byte,give_default_byte,give_default_byte},4'h3);

    // test state : the data before last is not full and send the full data
    // test : full the original and send the new two byte
    #(`CYCLE*100);
    #(`CYCLE) S_AXIS_ARESETN = 0;
    #(`CYCLE) S_AXIS_ARESETN = 1;
    for(i = 0; i < DATA_SEND_NUM/2; i = i + 1) begin
        sendData({give_default_byte+(i[7:0]),give_default_byte+(i[7:0]),give_default_byte+(i[7:0]),give_default_byte+(i[7:0])},4'hf);
        combine({give_default_byte+(i[7:0]),give_default_byte+(i[7:0]),give_default_byte+(i[7:0]),give_default_byte+(i[7:0])},4'hf,combine_out);
        mem[i] = combine_out;
    end
    sendData({give_default_byte,give_default_byte,give_default_byte,give_default_byte},4'h7);
    sendLast({give_default_byte,give_default_byte,give_default_byte,give_default_byte},4'h7);

    // test state : the data before last is not full and send the full data
    // test : full the original and send the new three byte
    #(`CYCLE*100);
    #(`CYCLE) S_AXIS_ARESETN = 0;
    #(`CYCLE) S_AXIS_ARESETN = 1;
    for(i = 0; i < DATA_SEND_NUM/2; i = i + 1) begin
        sendData({give_default_byte+(i[7:0]),give_default_byte+(i[7:0]),give_default_byte+(i[7:0]),give_default_byte+(i[7:0])},4'hf);
        combine({give_default_byte+(i[7:0]),give_default_byte+(i[7:0]),give_default_byte+(i[7:0]),give_default_byte+(i[7:0])},4'hf,combine_out);
        mem[i] = combine_out;
    end
    sendData({give_default_byte,give_default_byte,give_default_byte,give_default_byte},4'h7);
    sendLast({give_default_byte,give_default_byte,give_default_byte,give_default_byte},4'hf);

    // test state: random
    // test : keep changes everytime
    #(`CYCLE*100);
    #(`CYCLE) S_AXIS_ARESETN = 0;
    #(`CYCLE) S_AXIS_ARESETN = 1;
    for(i = 0; i < DATA_SEND_NUM/2; i = i + 1) begin
        sendData({give_default_byte+(i[7:0]),give_default_byte+(i[7:0]),give_default_byte+(i[7:0]),give_default_byte+(i[7:0])},i[3:0]);
        combine({give_default_byte+(i[7:0]),give_default_byte+(i[7:0]),give_default_byte+(i[7:0]),give_default_byte+(i[7:0])},4'hf,combine_out);
        mem[i] = combine_out;
    end
    sendData({give_default_byte,give_default_byte,give_default_byte,give_default_byte},4'h7);
    sendLast({give_default_byte,give_default_byte,give_default_byte,give_default_byte},4'hf);
end

task sendData;
input [C_S_AXIS_TDATA_WIDTH-1 : 0] inputData;
input [C_S_AXIS_TDATA_WIDTH/8-1:0] datakeep;
begin
    @(posedge S_AXIS_ACLK);
    while(S_AXIS_TREADY == 0) begin
        @(posedge S_AXIS_ACLK);
        $display("The AXI Stream Slave is not ready, Pending...");
    end
    S_AXIS_TVALID = 1;
    S_AXIS_TDATA = inputData;
    S_AXIS_TKEEP = datakeep;
end
endtask

task sendLast;
input [C_S_AXIS_TDATA_WIDTH-1 : 0] inputData;
input [C_S_AXIS_TDATA_WIDTH/8-1:0] datakeep;
begin
    @(posedge S_AXIS_ACLK);
    while(S_AXIS_TREADY == 0) begin
        @(posedge S_AXIS_ACLK);
        $display("The AXI Stream Slave is not ready, Pending...");
    end
    S_AXIS_TVALID = 1;
    S_AXIS_TLAST = 1;
    S_AXIS_TDATA = inputData;
    S_AXIS_TKEEP = datakeep;
    @(posedge S_AXIS_ACLK);
    wait(S_AXIS_TREADY == 1);
    @(posedge S_AXIS_ACLK);
    #1 S_AXIS_TVALID = 0;
    S_AXIS_TLAST = 0;
end
endtask

integer temp = 0;
task combine;
input  [C_S_AXIS_TDATA_WIDTH-1 : 0] inputData;
input  [C_S_AXIS_TDATA_WIDTH/8-1:0] dataKeep;
output [C_S_AXIS_TDATA_WIDTH-1 : 0] combine_out;
begin
    hasData = 0;
    combine_out = 0;
    for(j = 0; j < C_S_AXIS_TDATA_WIDTH/8; j = j + 1) begin
        if(dataKeep[j] == 1) begin
            case(hasData)
                0:          combine_out = {24'd0,inputData[j*8+:8]};
                1:          combine_out = {16'd0,inputData[j*8+:8],combine_out[0+:8]};
                2:          combine_out = {8'd0,inputData[j*8+:8],combine_out[0+:16]};
                3:          combine_out = {inputData[j*8+:8],combine_out[0+:24]};
                default:    combine_out = {24'd0,inputData[j*8+:8]};
            endcase
            hasData = hasData + 1;
        end
    end
end
endtask

endmodule
