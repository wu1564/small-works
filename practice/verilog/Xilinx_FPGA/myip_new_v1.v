
`timescale 1 ns / 1 ps

module myip_new_v1_0 #
(
    // Users to add parameters here
    parameter integer FIFO_DATA_WIDTH = 32,
    parameter integer FIFO_DEPTH      = 64,
    // User parameters ends
    // Do not modify the parameters beyond this line

    // Parameters of Axi Slave Bus Interface S00_AXI
    parameter integer C_S00_AXI_DATA_WIDTH	= 32,
    parameter integer C_S00_AXI_ADDR_WIDTH	= 4,

    // Parameters of Axi Slave Bus Interface S00_AXIS
    parameter integer C_S00_AXIS_TDATA_WIDTH	= 32,

    // Parameters of Axi Master Bus Interface M00_AXIS
    parameter integer C_M00_AXIS_TDATA_WIDTH	= 32,       // fixed don't touch
    parameter integer C_M00_AXIS_START_COUNT	= 32
)
(
    // Users to add ports here
    input wire [C_S00_AXIS_TDATA_WIDTH/8-1:0] s00_axis_tkeep,
    output wire [C_M00_AXIS_TDATA_WIDTH/8-1:0] m00_axis_tkeep,
    // User ports ends
    // Do not modify the ports beyond this line


    // Ports of Axi Slave Bus Interface S00_AXI
    input wire  s00_axi_aclk,
    input wire  s00_axi_aresetn,
    input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
    input wire [2 : 0] s00_axi_awprot,
    input wire  s00_axi_awvalid,
    output wire  s00_axi_awready,
    input wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
    input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
    input wire  s00_axi_wvalid,
    output wire  s00_axi_wready,
    output wire [1 : 0] s00_axi_bresp,
    output wire  s00_axi_bvalid,
    input wire  s00_axi_bready,
    input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
    input wire [2 : 0] s00_axi_arprot,
    input wire  s00_axi_arvalid,
    output wire  s00_axi_arready,
    output wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
    output wire [1 : 0] s00_axi_rresp,
    output wire  s00_axi_rvalid,
    input wire  s00_axi_rready,

    // Ports of Axi Slave Bus Interface S00_AXIS
    input wire  s00_axis_aclk,
    input wire  s00_axis_aresetn,
    output wire  s00_axis_tready,
    input wire [C_S00_AXIS_TDATA_WIDTH-1 : 0] s00_axis_tdata,
    //input wire [(C_S00_AXIS_TDATA_WIDTH/8)-1 : 0] s00_axis_tstrb,
    input wire  s00_axis_tlast,
    input wire  s00_axis_tvalid,

    // Ports of Axi Master Bus Interface M00_AXIS
    input wire  m00_axis_aclk,
    input wire  m00_axis_aresetn,
    output wire  m00_axis_tvalid,
    output wire [C_M00_AXIS_TDATA_WIDTH-1 : 0] m00_axis_tdata,
    //output wire [(C_M00_AXIS_TDATA_WIDTH/8)-1 : 0] m00_axis_tstrb,
    output wire  m00_axis_tlast,
    input wire  m00_axis_tready
);

// Instantiation of Axi Bus Interface S00_AXI
myip_new_v1_0_S00_AXI # ( 
    .C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
    .C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
) myip_new_v1_0_S00_AXI_inst (
    .S_AXI_ACLK(s00_axi_aclk),
    .S_AXI_ARESETN(s00_axi_aresetn),
    .S_AXI_AWADDR(s00_axi_awaddr),
    .S_AXI_AWPROT(s00_axi_awprot),
    .S_AXI_AWVALID(s00_axi_awvalid),
    .S_AXI_AWREADY(s00_axi_awready),
    .S_AXI_WDATA(s00_axi_wdata),
    .S_AXI_WSTRB(s00_axi_wstrb),
    .S_AXI_WVALID(s00_axi_wvalid),
    .S_AXI_WREADY(s00_axi_wready),
    .S_AXI_BRESP(s00_axi_bresp),
    .S_AXI_BVALID(s00_axi_bvalid),
    .S_AXI_BREADY(s00_axi_bready),
    .S_AXI_ARADDR(s00_axi_araddr),
    .S_AXI_ARPROT(s00_axi_arprot),
    .S_AXI_ARVALID(s00_axi_arvalid),
    .S_AXI_ARREADY(s00_axi_arready),
    .S_AXI_RDATA(s00_axi_rdata),
    .S_AXI_RRESP(s00_axi_rresp),
    .S_AXI_RVALID(s00_axi_rvalid),
    .S_AXI_RREADY(s00_axi_rready)
);

// Instantiation of Axi Bus Interface S00_AXIS
// myip_new_v1_0_S00_AXIS # ( 
// 	.C_S_AXIS_TDATA_WIDTH(C_S00_AXIS_TDATA_WIDTH)
// ) myip_new_v1_0_S00_AXIS_inst (
// 	.S_AXIS_ACLK(s00_axis_aclk),
// 	.S_AXIS_ARESETN(s00_axis_aresetn),
// 	.S_AXIS_TREADY(s00_axis_tready),
// 	.S_AXIS_TDATA(s00_axis_tdata),
// 	.S_AXIS_TSTRB(s00_axis_tstrb),
// 	.S_AXIS_TLAST(s00_axis_tlast),
// 	.S_AXIS_TVALID(s00_axis_tvalid)
// );

// Instantiation of Axi Bus Interface M00_AXIS
// myip_new_v1_0_M00_AXIS # ( 
// 	.C_M_AXIS_TDATA_WIDTH(C_M00_AXIS_TDATA_WIDTH),
// 	.C_M_START_COUNT(C_M00_AXIS_START_COUNT)
// ) myip_new_v1_0_M00_AXIS_inst (
// 	.M_AXIS_ACLK(m00_axis_aclk),
// 	.M_AXIS_ARESETN(m00_axis_aresetn),
// 	.M_AXIS_TVALID(m00_axis_tvalid),
// 	.M_AXIS_TDATA(m00_axis_tdata),
// 	.M_AXIS_TSTRB(m00_axis_tstrb),
// 	.M_AXIS_TLAST(m00_axis_tlast),
// 	.M_AXIS_TREADY(m00_axis_tready)
// );

// Add user logic here
// 
// fifo signal
wire empty;
wire full;
wire pop_en;
wire fifo_write;
wire [FIFO_DATA_WIDTH-1:0] fifo_output_data;
wire [FIFO_DATA_WIDTH-1:0] S_AXIS_FIFO_OUT;
wire final;
// AXIS SLAVE
myip_new_v1_0_S00_AXIS #(
    .C_S_AXIS_TDATA_WIDTH(C_S00_AXIS_TDATA_WIDTH),
    .FIFO_DATA_WIDTH(FIFO_DATA_WIDTH),
    .FIFO_DEPTH(FIFO_DEPTH)
)S_AXIS_INST(
    .S_AXIS_ACLK(s00_axis_aclk),
    .S_AXIS_ARESETN(s00_axis_aresetn),
    .S_AXIS_TKEEP(s00_axis_tkeep),
    .S_AXIS_TREADY(s00_axis_tready),
    .S_AXIS_TDATA(s00_axis_tdata),
    .S_AXIS_TLAST(s00_axis_tlast),
    .S_AXIS_TVALID(s00_axis_tvalid),
    // fifo
    .empty(empty),
    .full(full),
    .fifo_write(fifo_write),
    .fifo_data_out(S_AXIS_FIFO_OUT),
    .final(final)
);

// AXIS MASTER
myip_new_v1_0_M00_AXIS #(
    .C_M_AXIS_TDATA_WIDTH(C_M00_AXIS_TDATA_WIDTH)
)M_AXIS_SENDER(
    .M_AXIS_ACLK(m00_axis_aclk),
    .M_AXIS_ARESETN(m00_axis_aresetn),
    .M_AXIS_TVALID(m00_axis_tvalid),
    .M_AXIS_TDATA(m00_axis_tdata),
    .M_AXIS_TKEEP(m00_axis_tkeep),
    .M_AXIS_TLAST(m00_axis_tlast),
    .M_AXIS_TREADY(m00_axis_tready),
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
    .clk(s00_axis_aclk),
    .reset_n(s00_axis_aresetn),
    .write_en(fifo_write),
    .input_data(S_AXIS_FIFO_OUT),
    .pop_en(pop_en),
    // control signal
    .full(full),
    .empty(empty),
    .output_data(fifo_output_data)
);    
// User logic ends

endmodule
