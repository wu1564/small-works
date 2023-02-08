`timescale 1 ns / 1 ps

module myip_test_v1_0_M00_AXIS #
(
    // Users to add parameters here

    // User parameters ends
    // Do not modify the parameters beyond this line

    // Width of S_AXIS address bus. The slave accepts the read and write addresses of width C_M_AXIS_TDATA_WIDTH.
    parameter integer C_M_AXIS_TDATA_WIDTH	= 32
)(
    // Users to add ports here

    // User ports ends
    // Do not modify the ports beyond this line
    // Global ports
    input wire  M_AXIS_ACLK,
    // 
    input wire  M_AXIS_ARESETN,
    // Master Stream Ports. TVALID indicates that the master is driving a valid transfer, A transfer takes place when both TVALID and TREADY are asserted. 
    output wire  M_AXIS_TVALID,
    // TDATA is the primary payload that is used to provide the data that is passing across the interface from the master.
    output wire [C_M_AXIS_TDATA_WIDTH-1 : 0] M_AXIS_TDATA,
    // TSTRB is the byte qualifier that indicates whether the content of the associated byte of TDATA is processed as a data byte or a position byte.
    output wire [(C_M_AXIS_TDATA_WIDTH/8)-1 : 0] M_AXIS_TKEEP,
    // TLAST indicates the boundary of a packet.
    output wire  M_AXIS_TLAST,
    // TREADY indicates that the slave can accept a transfer in the current cycle.
    input wire  M_AXIS_TREADY,
    // fifo
    input wire empty,
    input wire [C_M_AXIS_TDATA_WIDTH-1 : 0] fifo_data,
    output wire pop_en    
);

localparam IDLE = 0;
localparam SEND = 1;

reg [1:0] state, next_state;

always @(*) begin
    case(state)
        IDLE:       next_state = (!empty && M_AXIS_TREADY) ? SEND : IDLE;
        default:    next_state = IDLE;
    endcase
end

always @(posedge M_AXIS_ACLK or negedge M_AXIS_ARESETN) begin
    if(!M_AXIS_ARESETN) begin
        state <= IDLE;
    end else begin
        state <= next_state;
    end
end

//output signals
assign M_AXIS_TLAST = 1'b0; // test
assign M_AXIS_TKEEP = {C_M_AXIS_TDATA_WIDTH/8{1'b1}};
assign M_AXIS_TVALID = (state == SEND);
assign pop_en = (!empty && M_AXIS_TREADY && state == IDLE);
assign M_AXIS_TDATA = fifo_data;

// function called clogb2 that returns an integer which has the                      
// value of the ceiling of the log base 2.                                           
function integer clogb2 (input integer bit_depth);                                   
    begin                                                                              
    for(clogb2=0; bit_depth>0; clogb2=clogb2+1)                                      
        bit_depth = bit_depth >> 1;                                                    
    end                                                                                
endfunction                                                                          
                                                                  
endmodule
