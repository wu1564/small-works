`timescale 1ps/1ps

`define CYCLE 10

module axis_master_last_tb;

parameter integer C_M00_AXIS_TDATA_WIDTH = 32;
parameter integer FIFO_DATA_WIDTH        = 32;
parameter integer FIFO_DEPTH             = 32;

reg clk;
reg reset_n;

wire m00_axis_tvalid;
wire [C_M00_AXIS_TDATA_WIDTH-1:0] m00_axis_tdata;
wire [C_M00_AXIS_TDATA_WIDTH/8-1:0] m00_axis_tkeep;
wire m00_axis_tlast;
reg  s00_axis_tready;   // tb used as slave
reg  final;
// fifo
wire empty;
wire full;
wire pop_en;
wire [FIFO_DATA_WIDTH-1:0] fifo_output_data;
reg  fifo_write_control_tb;
reg  [FIFO_DATA_WIDTH-1:0] fifo_data_tb;
// TB
integer i = 0;

// AXIS MASTER
myip_new_v1_0_M00_AXIS #(
    .C_M_AXIS_TDATA_WIDTH(C_M00_AXIS_TDATA_WIDTH)
)M_AXIS_SENDER(
    .M_AXIS_ACLK(clk),
    .M_AXIS_ARESETN(reset_n),
    .M_AXIS_TVALID(m00_axis_tvalid),
    .M_AXIS_TDATA(m00_axis_tdata),
    .M_AXIS_TKEEP(m00_axis_tkeep),
    .M_AXIS_TREADY(s00_axis_tready),
    .M_AXIS_TLAST(m00_axis_tlast),
    // fifo
    .empty(empty),
    .fifo_data(fifo_output_data),
    .pop_en(pop_en),
    .receive_finish(final)
);

// FIFO
axis_fifo_connection#(
    .FIFO_DEPTH(FIFO_DEPTH),
    .FIFO_DATA_WIDTH(FIFO_DATA_WIDTH)
)fifo_inst(
    .clk(clk),
    .reset_n(reset_n),
    .write_en(fifo_write_control_tb),      // using tb's fifo control signal to give fifo data first
    .input_data(fifo_data_tb),          
    .pop_en(pop_en),
    // control signal
    .full(full),
    .empty(empty),
    .output_data(fifo_output_data)
);

initial begin
    clk = 0;
    forever #(`CYCLE/2) clk = ~clk;
end

initial begin
    final = 0;
    fifo_write_control_tb = 0;
    fifo_data_tb = 0;
    s00_axis_tready = 0;
    reset_n = 1;
    #(`CYCLE) reset_n = 0;
    #(`CYCLE) reset_n = 1;   
    // send data
    for(i = 0; i < FIFO_DEPTH/2; i = i + 1) begin
        @(posedge clk);
        fifo_write_control_tb = 1;
        fifo_data_tb = 5 + i;
    end
    // last data
    @(posedge clk);
    final = 1;
    fifo_data_tb = 32'hffffffff;
    fifo_write_control_tb = 0;
    @(posedge clk) s00_axis_tready = 1;
    final = 0;

    // stop receiving data 
    #(`CYCLE*5);
    @(posedge clk) s00_axis_tready = 0;
    // receive again
    #(`CYCLE*20) s00_axis_tready = 1;

    // second round : test the slave does't receive the last data
    #(`CYCLE*50) s00_axis_tready = 0;
    for(i = 0; i < FIFO_DEPTH/2; i = i + 1) begin
        @(posedge clk);
        fifo_write_control_tb = 1;
        fifo_data_tb = 5 + i;
    end
    // last data
    @(posedge clk);
    final = 1;
    fifo_data_tb = 32'hffffffff;
    fifo_write_control_tb = 0;
    @(posedge clk)  final = 0;
    s00_axis_tready = 1;
    #(`CYCLE*14);
    #1 s00_axis_tready = 0;
    #(`CYCLE*24);
    #1 s00_axis_tready = 1;
    #(`CYCLE*2);
    #1 s00_axis_tready = 0;
    #(`CYCLE*20);
    #1 s00_axis_tready = 1;
end

endmodule
