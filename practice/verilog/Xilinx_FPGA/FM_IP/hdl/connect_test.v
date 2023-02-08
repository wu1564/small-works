`timescale 1ns / 1ps

module connect_test #(
           parameter C_S00_AXI_DATA_WIDTH = 32,
           parameter C_S00_AXIS_TDATA_WIDTH = 32,
           parameter C_M00_AXIS_TDATA_WIDTH = 32
       )(
           input clk,
           input reset_n,
           //AXI Lite Slave
           input [C_S00_AXI_DATA_WIDTH-1 : 0] AXI_Lite_input0,
           input [C_S00_AXI_DATA_WIDTH-1 : 0] AXI_Lite_input1,
           input [C_S00_AXI_DATA_WIDTH-1 : 0] AXI_Lite_input2,
           input [C_S00_AXI_DATA_WIDTH-1 : 0] AXI_Lite_input3,
           //AXIS Slave
           output reg rx_ready,
           input rx_valid,
           input rx_last,
           input [C_S00_AXIS_TDATA_WIDTH-1 : 0] rx_data,
           input [(C_S00_AXIS_TDATA_WIDTH/8)-1 : 0] rx_keep,
           //AXIS Master
           input tx_ready,
           output reg tx_valid,
           output reg tx_last,
           output reg [C_M00_AXIS_TDATA_WIDTH-1:0] tx_data,
           output reg [(C_M00_AXIS_TDATA_WIDTH/8)-1 : 0] tx_keep
       );

function integer clogb2 (input integer bit_depth);
    begin
        for(clogb2=0; bit_depth>0; clogb2=clogb2+1)
            bit_depth = bit_depth >> 1;
    end
endfunction

// Bool Define
localparam TRUE  = 1'b1;
localparam FALSE = 1'b0;

// FIFO Define
reg w_en;
reg r_en;
reg [C_S00_AXI_DATA_WIDTH-1:0] din;
reg [C_S00_AXI_DATA_WIDTH/8-1:0] din_keep;
wire [C_S00_AXI_DATA_WIDTH-1:0] dout;
wire [C_S00_AXI_DATA_WIDTH/8-1:0] dout_keep;
wire empty;
wire full;

/*
fifo #(
         .DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
         .DEPTH_BIT_NUM(2)
     )fifo_inst(
         .clk(clk),
         .reset_n(reset_n),
         .w_en(w_en),
         .r_en(r_en),
         .din(din),
         .dout(dout),
         .empty(empty),
         .full(full)
     );
*/
axis_pipe #(
              .DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
              .DEPTH_BIT_NUM(2)
          )axis_pipe_inst(
              .clk(clk),
              .reset_n(reset_n),
              .w_en(w_en),
              .r_en(r_en),
              .din(din),
              .din_keep(din_keep),
              .dout(dout),
              .dout_keep(dout_keep),
              .empty(empty),
              .full(full)
          );
/*********************/
/*   State Define    */
/*********************/
// FSM
localparam  IDLE = 1'd0,
            SEND_STREAM = 1'b1;

/*********************/
/*  reg/wire Define  */
/*********************/
// FSM
reg cur_state, nxt_state;
//  - Start Control
wire start_signal;
//  - Finish Control
wire finish_signal;

// FIFO
wire push_signal;
wire pop_signal;

// AXI Protocol Control
// - Last Signal Control
reg got_last_flag;
// - Receive Control
//output reg rx_ready;
// - Transmit Control
reg tx_en;
//output reg tx_valid;
//output reg tx_last;
//output reg [C_M00_AXIS_TDATA_WIDTH-1:0] tx_data;
//output reg [(C_M00_AXIS_TDATA_WIDTH/8)-1:0] tx_keep;

/*********************/
/*   Hardware Logic  */
/*********************/
// FSM
//  - cur_state
always @(posedge clk) begin
    if(!reset_n) begin
        cur_state <= IDLE;
    end
    else begin
        cur_state <= nxt_state;
    end
end
//  - nxt_state
always @(*) begin
    if(!reset_n) begin
        nxt_state = IDLE;
    end
    else begin
        case(cur_state)
            IDLE : begin
                if(start_signal)
                    nxt_state = SEND_STREAM;
                else
                    nxt_state = IDLE;
            end
            SEND_STREAM : begin
                if(finish_signal)
                    nxt_state = IDLE;
                else
                    nxt_state = SEND_STREAM;
            end
            default : begin
                // Do nothing. No other unused state.
            end
        endcase
    end
end
//  - Start Control
assign start_signal = (AXI_Lite_input0==32'd4) && (AXI_Lite_input1==32'd3) && (AXI_Lite_input2==32'd2) && (AXI_Lite_input3==32'd1);
//  - Finish Control
assign finish_signal = (tx_last && tx_ready && tx_valid);

// FIFO
//  # FIFO push receive data.
assign push_signal = !full && rx_valid;
//  # FIFO pop stored data.
assign pop_signal = !empty && tx_ready;

//  - FIFO Write Control
always @(posedge clk) begin
    if(!reset_n) begin
        w_en <= 1'b0;
        din <= {C_S00_AXI_DATA_WIDTH{1'b0}};
    end
    else begin
        if(full) begin
            w_en <= w_en;
            din <= din;
            din_keep <= din_keep;
        end
        else if(push_signal) begin
            w_en <= 1'b1;
            din <= rx_data;
            din_keep <= rx_keep;
        end
        else begin
            w_en <= 1'b0;
        end
    end
end
//  - FIFO Read Control
always @(*) begin
    if(start_signal) begin
        r_en = pop_signal;
    end
    else begin
        r_en = 1'b0;
    end
end


// AXI Protocol Control
// - Last Signal Control
// - # Already receive the last data from S_AXIS
always @(posedge clk) begin
    if(!reset_n) begin
        got_last_flag <= 1'b0;
    end
    else begin
        if(finish_signal)
            got_last_flag <= 1'b0;
        else if(rx_last)
            got_last_flag <= 1'b1;
    end
end

// - Receive Control
// - # Ready to receive the next data from S_AXIS
always @(*) begin
    if(cur_state==SEND_STREAM) begin
        rx_ready = !full;
    end
    else begin
        rx_ready = 1'b0;
    end
end

// - Transmit Control
// - # Ready to transmit the next data to M_AXIS
always @(posedge clk) begin
    if(!reset_n) begin
        tx_en <= 1'b0;
    end
    else begin
        if(cur_state==SEND_STREAM) begin
            if(tx_ready)
                tx_en <= pop_signal;
        end
        else begin
            tx_en <= 1'b0;
        end
    end
end
// - # Transmit state.
always @(*) begin
    case (cur_state)
        SEND_STREAM: begin
            if(tx_en) begin
                tx_valid = 1'b1;
                tx_last = (got_last_flag && empty && !w_en) ? 1'b1 : 1'b0;
                tx_keep = dout_keep;
            end
            else begin
                tx_valid = 1'b0;
                tx_last = 1'b0;
                tx_keep = {(C_M00_AXIS_TDATA_WIDTH/8){1'b1}};
            end
        end
        default : begin
            tx_valid = 1'b0;
            tx_last = 1'b0;
            tx_keep = {(C_M00_AXIS_TDATA_WIDTH/8){1'b1}};
        end
    endcase
end
// - # Transmit data.
always @(*) begin
    tx_data = dout + {4{8'b1}};
end

endmodule
