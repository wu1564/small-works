`timescale 1ps/1ps
`define CYCLE 10

module axis_tb;

//--------------------------------------------------------------------------------------------------------------//
//                                                                                                              //
//      ----------------------------------    Parameter BLOCK    -----------------------------------------      //
//                                                                                                              //
//--------------------------------------------------------------------------------------------------------------//
// axis master
parameter integer C_M00_AXIS_TDATA_WIDTH    = 32;
// axis slave
parameter integer C_S00_AXIS_TDATA_WIDTH    = 32;
// fifo
parameter integer FIFO_DATA_WIDTH           = 32;
parameter integer FIFO_DEPTH                = 64;

//--------------------------------------------------------------------------------------------------------------//
//                                                                                                              //
//      ------------------------------     Signal Declaration BLOCK      ---------------------------------      //
//                                                                                                              //
//--------------------------------------------------------------------------------------------------------------//
// AXIS MASTER
wire m00_axis_tvalid;
wire [C_S00_AXIS_TDATA_WIDTH-1:0]   m00_axis_tdata;
wire [C_S00_AXIS_TDATA_WIDTH/8-1:0] m00_axis_tkeep;
wire m00_axis_tlast;
// AXIS SLAVE
wire s00_axis_tready;
// FIFO
wire empty;
wire full;
wire pop_en;
wire fifo_write;
wire [FIFO_DATA_WIDTH-1:0] fifo_output_data;
wire [FIFO_DATA_WIDTH-1:0] S_AXIS_FIFO_OUT;
wire final;
// TESTBENCH USED
integer i = 0;
wire fifo_write_control_tb;
wire [FIFO_DATA_WIDTH-1:0] fifo_data_tb;
reg  clk;
reg  reset_n;
reg  fifo_write_control;
reg  freeze;
reg  [FIFO_DATA_WIDTH-1:0] fifo_data_control;
//

//--------------------------------------------------------------------------------------------------------------//
//                                                                                                              //
//      ----------------------------------     MODULE BLOCK      -----------------------------------------      //
//                                                                                                              //
//--------------------------------------------------------------------------------------------------------------//
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

// AXIS SLAVE
myip_new_v1_0_S00_AXIS #(
    .C_S_AXIS_TDATA_WIDTH(C_S00_AXIS_TDATA_WIDTH),
    .FIFO_DATA_WIDTH(FIFO_DATA_WIDTH),
    .FIFO_DEPTH(FIFO_DEPTH)
)S_AXIS_INST(
    .S_AXIS_ACLK(clk),
    .S_AXIS_ARESETN(reset_n),
    .S_AXIS_TVALID(m00_axis_tvalid),
    .S_AXIS_TKEEP(m00_axis_tkeep),
    .S_AXIS_TDATA(m00_axis_tdata),
    .S_AXIS_TREADY(s00_axis_tready),    // freeze this signal to let mater wait
    .S_AXIS_TLAST(m00_axis_tlast),
    // fifo
    .empty(empty),
    .full(full),
    .fifo_write(fifo_write),
    .fifo_data_out(S_AXIS_FIFO_OUT),
    .final(final)
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

//--------------------------------------------------------------------------------------------------------------//
//                                                                                                              //
//        --------------------------------     TESTBECH BLOCK      ---------------------------------------      //
//                                                                                                              //
//--------------------------------------------------------------------------------------------------------------//
initial begin
    clk = 0; 
    forever #(`CYCLE/2) clk = ~clk;
end

initial begin
    fifo_write_control = 0;
    fifo_data_control  = 0;
    freeze  = 1;
    reset_n = 1;
    // initialize all ip
    #(`CYCLE) reset_n = 0;
    #(`CYCLE) reset_n = 1;

    // freeze the master state and let the master wait the slave
    force s00_axis_tready = 0;
    for(i = 0; i < FIFO_DEPTH/2-1; i = i + 1) begin     // give fifo data first
        @(posedge clk);
        fifo_write_control = 1;
        fifo_data_control  = i + 1;
    end
    // send the last data
    @(posedge clk);
    release s00_axis_tready;
    force m00_axis_tvalid = 1;
    force m00_axis_tdata = 32'hffffffff;
    force m00_axis_tkeep = 4'h7;
    force m00_axis_tlast = 1;

    @(posedge clk) freeze = 0;// release s00_axis_tready;
    release m00_axis_tvalid;
    release m00_axis_tdata;
    release m00_axis_tkeep;
    release m00_axis_tlast;
    // give back the control privilege to the slave side
    // release s00_axis_tready;
end

assign fifo_write_control_tb = (freeze) ? fifo_write_control : fifo_write;
assign fifo_data_tb          = (freeze) ? fifo_data_control  : S_AXIS_FIFO_OUT;

endmodule
