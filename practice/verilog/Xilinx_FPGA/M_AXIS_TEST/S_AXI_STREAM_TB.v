`timescale 1ns/1ps
`define CYCLE 10

module S_AXI_STREAM_TB;

localparam C_M_AXIS_TDATA_WIDTH = 32;
localparam FIFO_DEPTH           = 32;
localparam FIFO_DATA_WIDTH      = 32;

reg M_AXIS_ACLK;
reg M_AXIS_ARESETN;
reg M_AXIS_TREADY;
wire M_AXIS_TVALID;
wire [C_M_AXIS_TDATA_WIDTH-1:0] M_AXIS_TDATA;
wire [C_M_AXIS_TDATA_WIDTH/8-1:0] M_AXIS_TKEEP;
wire M_AXIS_TLAST;
// fifo
reg write_en;
reg  [C_M_AXIS_TDATA_WIDTH-1:0] fifo_input_data;
wire empty;
wire full;
wire [C_M_AXIS_TDATA_WIDTH-1:0] output_data;
//
integer i = 0, index = 0;
reg [C_M_AXIS_TDATA_WIDTH-1:0] mem[0:FIFO_DEPTH-1];

myip_test_v1_0_M00_AXIS #(
    .C_M_AXIS_TDATA_WIDTH(C_M_AXIS_TDATA_WIDTH)
)M_AXIS_SENDER(
    .M_AXIS_ACLK(M_AXIS_ACLK),
    .M_AXIS_ARESETN(M_AXIS_ARESETN),
    .M_AXIS_TVALID(M_AXIS_TVALID),
    .M_AXIS_TDATA(M_AXIS_TDATA),
    .M_AXIS_TKEEP(M_AXIS_TKEEP),
    .M_AXIS_TLAST(M_AXIS_TLAST),
    .M_AXIS_TREADY(M_AXIS_TREADY),
    // fifo
    .empty(empty),
    .fifo_data(output_data),
    .pop_en(pop_en)
);

axis_fifo_connection#(
    // fifo depth
    .FIFO_DEPTH(FIFO_DEPTH),
    .FIFO_DATA_WIDTH(FIFO_DATA_WIDTH)
)AXIS_FIFO(
    .clk(M_AXIS_ACLK),
    .reset_n(M_AXIS_ARESETN),
    .write_en(write_en),
    .input_data(fifo_input_data),
    .pop_en(pop_en),
    .full(full),
    .empty(empty),
    .output_data(output_data)
);

initial begin
    M_AXIS_ACLK = 0;
    forever #(`CYCLE/2) M_AXIS_ACLK = ~M_AXIS_ACLK;
end

initial begin
    fifo_input_data = 0;
    M_AXIS_TREADY  = 0;
    M_AXIS_ARESETN = 1;
    #(`CYCLE) M_AXIS_ARESETN = 0;
    #(`CYCLE) M_AXIS_ARESETN = 1;
    for(i = 0; i < FIFO_DEPTH; i = i + 1) begin
        @(posedge M_AXIS_ACLK);
        write_en = 1;
        fifo_input_data = i + 1;
    end
    @(posedge M_AXIS_ACLK);
    #1 write_en = 0;
    #(`CYCLE*10) M_AXIS_TREADY = 1;
    #(`CYCLE)    M_AXIS_TREADY = 0;
    #(`CYCLE*7)  M_AXIS_TREADY = 1;
    #(`CYCLE)    M_AXIS_TREADY = 0;
    #(`CYCLE*3)  M_AXIS_TREADY = 1;
end

// memeory store
initial begin
    forever begin
        @(posedge M_AXIS_ACLK);
        if(M_AXIS_TVALID) begin
            mem[index] = M_AXIS_TDATA;
            index = index + 1;
        end
    end
end

endmodule
