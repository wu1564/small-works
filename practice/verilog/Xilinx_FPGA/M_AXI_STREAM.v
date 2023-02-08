`timescale 1 ns / 1 ps

module myip_new_v1_0_M00_AXIS #
(
    // Users to add parameters here

    // User parameters ends
    // Do not modify the parameters beyond this line

    // Width of S_AXIS address bus. The slave accepts the read and write addresses of width C_M_AXIS_TDATA_WIDTH.
    parameter integer C_M_AXIS_TDATA_WIDTH	= 32
)(
    // Users to add ports here
    output wire [(C_M_AXIS_TDATA_WIDTH/8)-1 : 0] M_AXIS_TKEEP,
    // User ports ends
    // Do not modify the ports beyond this line
    // Global ports
    input wire  M_AXIS_ACLK,
    // 
    input wire  M_AXIS_ARESETN,
    // Master Stream Ports. TVALID indicates that the master is driving a valid transfer, A transfer takes place when both TVALID and TREADY are asserted. 
    output reg  M_AXIS_TVALID,
    // TDATA is the primary payload that is used to provide the data that is passing across the interface from the master.
    output wire [C_M_AXIS_TDATA_WIDTH-1 : 0] M_AXIS_TDATA,    
    // TLAST indicates the boundary of a packet.
    output reg  M_AXIS_TLAST,
    // TREADY indicates that the slave can accept a transfer in the current cycle.
    input wire  M_AXIS_TREADY,
    // fifo
    input  wire empty,
    input  wire [C_M_AXIS_TDATA_WIDTH-1 : 0] fifo_data,
    output reg  pop_en,  
    // info from slave side
    input  wire receive_finish
);

localparam IDLE = 0;
localparam SEND = 1;

reg state, next_state;

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
always @(*) begin
    if(empty) begin
        M_AXIS_TLAST = M_AXIS_TVALID;
    end else begin
        M_AXIS_TLAST = 1'b0;
    end
end

/*
always @(posedge M_AXIS_ACLK or negedge M_AXIS_ARESETN) begin
    if(!M_AXIS_ARESETN) begin
        M_AXIS_TLAST <= 1'b0;
    end else if((empty && M_AXIS_TREADY) || receive_finish) begin
        M_AXIS_TLAST <= 1'b0;
    end else if(empty) begin
        M_AXIS_TLAST <= 1'b1;
    end
end
*/
always @(posedge M_AXIS_ACLK or negedge M_AXIS_ARESETN) begin
    if(!M_AXIS_ARESETN) begin
        M_AXIS_TVALID <= 1'b0;
    end else if(empty && M_AXIS_TREADY) begin
        M_AXIS_TVALID <= 1'b0;
    end else if(receive_finish) begin
        M_AXIS_TVALID <= 1'b1;
    end
end

assign M_AXIS_TKEEP = {C_M_AXIS_TDATA_WIDTH/8{1'b1}};

always @(*) begin
    if(receive_finish || (M_AXIS_TVALID && M_AXIS_TREADY)) begin
        pop_en = M_AXIS_TREADY;
    end else begin
        pop_en = 1'b0;
    end
end

/*
always @(posedge M_AXIS_ACLK or negedge M_AXIS_ARESETN) begin
    if(!M_AXIS_ARESETN) begin
        pop_en <= 1'b0;
    end else if(receive_finish || M_AXIS_TREADY) begin
        pop_en <= 1'b1;
    end else if(!M_AXIS_TREADY || empty) begin
        pop_en <= 1'b0;
    end
end

always @(posedge M_AXIS_ACLK or negedge M_AXIS_ARESETN) begin
    if(!M_AXIS_ARESETN) begin
        M_AXIS_TDATA <= 0;
    end else if(pop_en) begin
        M_AXIS_TDATA <= fifo_data;
    end
end
*/

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
