`timescale 1ps/1ps

`define CYCLE 10

module DMA_SIM;

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
// send
parameter integer SEND_NUM                  = 50-1;

//--------------------------------------------------------------------------------------------------------------//
//                                                                                                              //
//      ------------------------------     Signal Declaration BLOCK      ---------------------------------      //
//                                                                                                              //
//--------------------------------------------------------------------------------------------------------------//
// module used
wire slave_final_to_master;
wire write_en;
wire [C_S00_AXIS_TDATA_WIDTH-1:0] slave_to_fifo;
// DMA MASTER SIM
wire slave_to_dma_ready;
reg  m00_axis_tvalid;
reg  [C_S00_AXIS_TDATA_WIDTH-1:0]   m00_axis_tdata;
reg  [C_S00_AXIS_TDATA_WIDTH/8-1:0] m00_axis_tkeep;
reg  m00_axis_tlast;
// DMA SLAVE SIM
wire s00_axis_tvalid;
wire [C_S00_AXIS_TDATA_WIDTH-1:0]   s00_axis_tdata;
wire [C_S00_AXIS_TDATA_WIDTH/8-1:0] s00_axis_tkeep;
wire s00_axis_tlast;
reg  dma_to_master_ready;
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
reg  clk;
reg  reset_n;
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
    .M_AXIS_TVALID(s00_axis_tvalid),
    .M_AXIS_TDATA(s00_axis_tdata),
    .M_AXIS_TKEEP(s00_axis_tkeep),
    .M_AXIS_TREADY(dma_to_master_ready),   // dma to master
    .M_AXIS_TLAST(s00_axis_tlast),
    // fifo
    .empty(empty),
    .fifo_data(fifo_output_data),
    .pop_en(pop_en),
    .receive_finish(slave_final_to_master)
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
    .S_AXIS_TREADY(slave_to_dma_ready),   // slave to dma
    .S_AXIS_TLAST(m00_axis_tlast),
    // fifo
    .empty(empty),
    .full(full),
    .fifo_write(write_en),
    .fifo_data_out(slave_to_fifo),
    .final(slave_final_to_master)
);

// FIFO
axis_fifo_connection#(
    .FIFO_DEPTH(FIFO_DEPTH),
    .FIFO_DATA_WIDTH(FIFO_DATA_WIDTH)
)fifo_inst(
    .clk(clk),
    .reset_n(reset_n),
    .write_en(write_en),      // using tb's fifo control signal to give fifo data first
    .input_data(slave_to_fifo),
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
    m00_axis_tvalid = 0;
    m00_axis_tdata = 0;
    m00_axis_tkeep = 0;
    m00_axis_tlast = 0;
    dma_to_master_ready = 1;
    reset_n = 1;
    // initialize all IP
    #(`CYCLE) reset_n = 0;
    #(`CYCLE) reset_n = 1;
    // start give data;
    for(i = 0; i < SEND_NUM; i = i + 1) begin
        @(posedge clk);
        while(slave_to_dma_ready == 0) begin
            @(posedge clk);
        end
        m00_axis_tvalid = 1;
        m00_axis_tkeep = {C_S00_AXIS_TDATA_WIDTH/8{1'b1}};
        m00_axis_tdata = i + 1;
    end
    // give the last data
    @(posedge clk);
    m00_axis_tkeep = {C_S00_AXIS_TDATA_WIDTH/8{1'b1}};
    m00_axis_tdata = i + 1;
    m00_axis_tlast = 1;
    wait(slave_to_dma_ready == 1);
    @(posedge clk);
    m00_axis_tvalid = 0;
    m00_axis_tlast = 0;
    
    // test
    wait(slave_final_to_master == 1);
    #(`CYCLE*10);
    @(posedge clk) dma_to_master_ready = 0;
    #(`CYCLE*5);   #1 dma_to_master_ready = 1;
    #(`CYCLE);     #1 dma_to_master_ready = 0;
    #(`CYCLE*15);  #1 dma_to_master_ready = 1;
    //
    #(`CYCLE*37);
    @(posedge clk) dma_to_master_ready = 0;
    #(`CYCLE*20)   #1 dma_to_master_ready = 1;
    
end

endmodule
