`timescale 1 ns / 1 ps

module myip_new_v1_0_S00_AXIS #
(
    // Users to add parameters here

    // User parameters ends
    // Do not modify the parameters beyond this line

    // AXI4Stream sink: Data Width
    parameter integer C_S_AXIS_TDATA_WIDTH	= 32,
    parameter integer FIFO_DATA_WIDTH       = 32,
    parameter integer FIFO_DEPTH            = 64
)
(
    // Users to add ports here
    input wire [C_S_AXIS_TDATA_WIDTH/8-1:0] S_AXIS_TKEEP,
    // User ports ends
    // Do not modify the ports beyond this line
    // AXI4Stream sink: Clock
    input wire  S_AXIS_ACLK,
    // AXI4Stream sink: Reset
    input wire  S_AXIS_ARESETN,
    // Ready to accept data in
    output wire  S_AXIS_TREADY,
    // Data in
    input wire [C_S_AXIS_TDATA_WIDTH-1 : 0] S_AXIS_TDATA,
    // Byte qualifier
    //input wire [(C_S_AXIS_TDATA_WIDTH/8)-1 : 0] S_AXIS_TSTRB,
    // Indicates boundary of last packet
    input wire  S_AXIS_TLAST,
    // Data is in valid
    input wire  S_AXIS_TVALID,
    //----------------------------------------
    // FIFO
    //control signal
    input  wire empty,
    input  wire full,
    output reg  fifo_write,
    output wire [FIFO_DATA_WIDTH-1:0] fifo_data_out,
    // control signal
    output reg final
);

localparam FIFO_MAX_WIDTH = 4;  // 4 byte
localparam RECEIVE  = 0;
localparam PROCESS  = 1;
localparam OVERFLOW = 2;

wire reach;
wire overflow;
wire receive_done;
wire [2:0] count_done;
reg  lastFlag;
reg  state, next_state;
reg  [2:0] receive_cnt;
reg  [2:0] fifo_keep_cnt;
reg  [7:0] data_byte;
reg  [31:0] fifo_data_keep;
// keep info
reg [C_S_AXIS_TDATA_WIDTH-1:0]   inputData;
reg [C_S_AXIS_TDATA_WIDTH/8-1:0] keep;

always @(*) begin
    case(state) 
        RECEIVE: next_state = (S_AXIS_TVALID) ? PROCESS : RECEIVE;
        PROCESS: begin
            if(receive_done) begin
                next_state = RECEIVE;
            end else begin
                next_state = PROCESS;
            end
        end
        default: next_state = RECEIVE;
    endcase
end

always @(posedge S_AXIS_ACLK or negedge S_AXIS_ARESETN) begin
    if(!S_AXIS_ARESETN) begin
        state <= RECEIVE;
    end else begin
        state <= next_state;
    end
end

// reg [C_S_AXIS_TDATA_WIDTH-1:0]   inputData;
// reg [C_S_AXIS_TDATA_WIDTH/8-1:0] keep;
always @(posedge S_AXIS_ACLK or negedge S_AXIS_ARESETN) begin
    if(!S_AXIS_ARESETN) begin
        keep <= {C_S_AXIS_TDATA_WIDTH/8{1'b0}};
        inputData <= {C_S_AXIS_TDATA_WIDTH{1'b0}};
    end else if(state == RECEIVE) begin
        keep <= S_AXIS_TKEEP;
        inputData <= S_AXIS_TDATA;
    end
end

assign count_done = ((C_S_AXIS_TDATA_WIDTH >> 3) - 1);

assign receive_done = (receive_cnt == count_done);
always @(posedge S_AXIS_ACLK or negedge S_AXIS_ARESETN) begin
    if(!S_AXIS_ARESETN) begin
        receive_cnt <= 3'd0;
    end else begin
        case(state)
            PROCESS: receive_cnt <= receive_cnt + 3'd1;
            default: receive_cnt <= 3'd0;
        endcase
    end
end

assign reach    = (fifo_keep_cnt == FIFO_MAX_WIDTH && receive_done);
assign overflow = (fifo_keep_cnt == FIFO_MAX_WIDTH && (receive_cnt != count_done));

always @(posedge S_AXIS_ACLK or negedge S_AXIS_ARESETN) begin
    if(!S_AXIS_ARESETN) begin
        fifo_keep_cnt <= 3'd0;
    end else if(state == RECEIVE && lastFlag) begin
        fifo_keep_cnt <= 3'd0;
    end else if(reach || overflow) begin
        if(state == PROCESS && keep[receive_cnt] == 1'b1) begin
            fifo_keep_cnt <= 3'd1;
        end else begin
            fifo_keep_cnt <= 3'd0;
        end
    end else if(state == PROCESS && keep[receive_cnt] == 1'b1) begin
        fifo_keep_cnt <= fifo_keep_cnt + 3'd1;
    end
end

always @(*) begin
    if(receive_cnt <= count_done) 
        case(receive_cnt)
            0:          data_byte = inputData[0+:8];
            1:          data_byte = inputData[8+:8];
            2:          data_byte = inputData[16+:8];
            3:          data_byte = inputData[24+:8];
            default:    data_byte = inputData[0+:8];
        endcase
    else begin
        data_byte = 8'd0;
    end
end

always @(posedge S_AXIS_ACLK or negedge S_AXIS_ARESETN) begin
    if(!S_AXIS_ARESETN) begin
        fifo_data_keep <= 32'd0;
    end else if(state == RECEIVE && lastFlag) begin
        fifo_data_keep <= 32'd0;
    end else if(state == PROCESS) begin
        if(overflow) begin
            if(keep[receive_cnt] == 1'b1) begin
                fifo_data_keep <= {24'd0,data_byte};
            end else begin
                fifo_data_keep <= 32'd0;
            end
        end else if(keep[receive_cnt] == 1'b1) begin
            case(fifo_keep_cnt)
                0:       fifo_data_keep <= {24'd0,data_byte};
                1:       fifo_data_keep <= {16'd0,data_byte,fifo_data_keep[0+:8]};
                2:       fifo_data_keep <= { 8'd0,data_byte,fifo_data_keep[0+:16]};
                3:       fifo_data_keep <= {data_byte,fifo_data_keep[0+:24]};
                4:       fifo_data_keep <= {24'd0,data_byte};
                default: fifo_data_keep <= fifo_data_keep;
            endcase
        end
    end
end

always @(posedge S_AXIS_ACLK or negedge S_AXIS_ARESETN) begin
    if(!S_AXIS_ARESETN) begin
        lastFlag <= 1'b0;
    end else if(state == RECEIVE) begin
        if(S_AXIS_TLAST) begin
            lastFlag <= 1'b1;
        end else if(lastFlag && fifo_write) begin
            lastFlag <= 1'b0;
        end
    end
end

//output signals
assign S_AXIS_TREADY = (state == RECEIVE);
assign fifo_data_out = fifo_data_keep;

always @(*) begin
    if(fifo_keep_cnt == FIFO_MAX_WIDTH) begin
        fifo_write = 1'b1;
    end else if(lastFlag) begin
        if(reach || overflow || (fifo_keep_cnt != FIFO_MAX_WIDTH && state == RECEIVE)) begin
            fifo_write = 1'b1;
        end else begin
           fifo_write = 1'b0; 
        end
    end else begin
        fifo_write = 1'b0;
    end
end

always @(posedge S_AXIS_ACLK or negedge S_AXIS_ARESETN) begin
    if(!S_AXIS_ARESETN) begin
        final <= 1'b0;
    end else if(empty) begin
        final <= 1'b0;
    end else if(lastFlag && fifo_write) begin
        final <= 1'b1;
    end
end

// function called clogb2 that returns an integer which has the 
// value of the ceiling of the log base 2.
function integer clogb2 (input integer bit_depth);
    begin
    for(clogb2=0; bit_depth>0; clogb2=clogb2+1)
        bit_depth = bit_depth >> 1;
    end
endfunction

endmodule
