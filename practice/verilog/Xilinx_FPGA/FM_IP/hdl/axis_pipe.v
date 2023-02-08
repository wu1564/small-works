`timescale 1ns / 1ps

module axis_pipe #(
           parameter DATA_WIDTH = 8,
           parameter DEPTH_BIT_NUM = 4
       )(
           input clk,
           input reset_n,
           input w_en,
           input r_en,
           input [DATA_WIDTH-1:0]din,
           input [DATA_WIDTH/8-1:0] din_keep,
           output reg [DATA_WIDTH-1:0]dout,
           output reg [DATA_WIDTH/8-1:0] dout_keep,
           output empty,
           output full
       );

function integer clogb2 (input integer bit_depth);
    begin
        for(clogb2=0; bit_depth>0; clogb2=clogb2+1)
            bit_depth = bit_depth >> 1;
    end
endfunction

initial begin
    if(DATA_WIDTH!=8 && DATA_WIDTH!=16 && DATA_WIDTH!=32) begin
        $display("Error at axis_pipe. DATA_WIDTH cannot be %d", DATA_WIDTH);
        $display("Finish here.");
        $finish;
    end
end

localparam integer DEPTH = 1 << DEPTH_BIT_NUM;
localparam [DATA_WIDTH+DEPTH_BIT_NUM-1: 0] MEM_SIZE = DATA_WIDTH*DEPTH;
reg [MEM_SIZE-1:0] mem;
reg [clogb2(DEPTH*8-1)-1:0]   counter;
reg [clogb2(DATA_WIDTH/8-1):0] read_byte_num;

assign empty = (counter==0);
assign full = (counter>=MEM_SIZE/8);

integer keep_ptr;
always @(*) begin
    read_byte_num = 0;
    for(keep_ptr=0; keep_ptr<DATA_WIDTH/8; keep_ptr=keep_ptr+1) begin
        read_byte_num = read_byte_num + (din_keep[keep_ptr] ? 1 : 0);
    end
end

always@(posedge clk) begin
    if(!reset_n)
        counter <= 1'd0;
    else if(!empty & r_en & !full & w_en) // read/write at same time
        counter <= counter + read_byte_num - (DATA_WIDTH>>3);
    else if(!full & w_en)                 // write
        counter <= counter + read_byte_num;
    else if(!empty & r_en)                // read
        if(counter<(DATA_WIDTH>>3))
            counter <= 0;
        else
            counter <= counter - (DATA_WIDTH>>3);
    else
        counter <= counter;
end

always@(posedge clk) begin
    if(!reset_n)
        dout <= {DATA_WIDTH{1'b0}};
    else if(!empty & r_en)
        if(counter<(DATA_WIDTH>>3))
            dout <= mem[0 +: DATA_WIDTH];
        else
            dout <= mem[counter*8-1 -: DATA_WIDTH];
    else
        dout <= dout;
end
//應該是在最後一筆存到FIFO後，FIFO沒把keep的pipe資料處理好(counter少1
//input
//00323130
//2f2e2d2c
//wrong output-1
//2e2d2c32
//00003130
//output
//00333231
//302f2e2d

reg [DATA_WIDTH/8-1:0] dout_keep_tmp;
always@(*)  begin
    if((counter>0) && (counter<DATA_WIDTH>>3)) begin
        for(keep_ptr=0; keep_ptr<DATA_WIDTH/8; keep_ptr=keep_ptr+1) begin
            dout_keep_tmp[keep_ptr] = (counter>keep_ptr);
        end
    end
    else begin
        for(keep_ptr=0; keep_ptr<DATA_WIDTH/8; keep_ptr=keep_ptr+1) begin
            dout_keep_tmp[keep_ptr] = 1'b1;
        end
    end
end
always@(posedge clk) begin
    if(!reset_n)
        dout_keep <= {DATA_WIDTH/8{1'b0}};
    else if(!empty & r_en) begin
        if((counter>0) && (counter<(DATA_WIDTH>>3))) begin
            dout_keep <= dout_keep_tmp;
        end
        else begin
            for(keep_ptr=0; keep_ptr<DATA_WIDTH/8; keep_ptr=keep_ptr+1) begin
                dout_keep[keep_ptr] <= 1'b1;
            end
        end
    end
    else
        dout_keep <= dout_keep;
end

always@(posedge clk) begin
    if(!reset_n) begin
        mem <={MEM_SIZE{1'b0}};
    end
    else begin
        if(!full & w_en) begin
            case(read_byte_num)
                1: begin
                    mem <= {mem[MEM_SIZE-8*1-1 : 0], din[0 +: 8*1]};
                end
                2: begin
                    mem <= {mem[MEM_SIZE-8*2-1 : 0], din[0 +: 8*2]};
                end
                3: begin
                    mem <= {mem[MEM_SIZE-8*3-1 : 0], din[0 +: 8*3]};
                end
                4: begin
                    mem <= {mem[MEM_SIZE-8*4-1 : 0], din[0 +: 8*4]};
                end
            endcase
        end
    end
end
endmodule
