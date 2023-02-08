module axis_fifo_connection#(
    // fifo depth
    parameter integer FIFO_DEPTH            = 16,
    parameter integer FIFO_DATA_WIDTH       = 32
)(
    input wire clk,
    input wire reset_n,
    // axis slave
    input wire write_en,
    input wire [FIFO_DATA_WIDTH-1:0] input_data,
    // axis master
    input wire pop_en,
    // control signal
    output full,
    output empty,
    output reg [FIFO_DATA_WIDTH-1:0] output_data
);

localparam integer FIFO_DEPTH_BIT = clogb2(FIFO_DEPTH);

integer i;
wire collision;
wire write_condition;
wire read_condition;
reg  [FIFO_DEPTH_BIT-1:0] read_pointer;
reg  [FIFO_DEPTH_BIT-1:0] write_pointer;
reg  [FIFO_DEPTH_BIT-1:0] count;
reg  [FIFO_DATA_WIDTH-1:0] fifo_mem [0:FIFO_DEPTH-1];

assign collision = (write_en && pop_en && write_pointer == read_pointer);
assign write_condition = (!full && write_en && !collision);
assign read_condition = (!empty && pop_en && !collision);

always @(posedge clk or negedge reset_n) begin
    if(!reset_n) begin
        read_pointer <= 0;
    end else if(read_pointer == FIFO_DEPTH-1 && read_condition) begin
        read_pointer <= 0;
    end else if(read_condition) begin
        read_pointer <= read_pointer + 1;
    end
end

always @(posedge clk or negedge reset_n) begin
    if(!reset_n) begin
        write_pointer <= 0;
    end else if(write_pointer == FIFO_DEPTH-1 && write_condition) begin
        write_pointer <= 0;
    end else if(write_condition) begin
        write_pointer <= write_pointer + 1;
    end
end

always @(posedge clk or negedge reset_n) begin
    if(!reset_n) begin
        count <= 0;
    end else if(write_en && pop_en && !collision) begin
        count <= count;
    end else if(write_condition) begin
        count <= count + 1;
    end else if(read_condition) begin
        count <= count - 1;
    end
end

always @(posedge clk or negedge reset_n) begin
    if(!reset_n) begin
        for(i = 0; i < FIFO_DEPTH; i = i + 1) begin
            fifo_mem[i] <= {FIFO_DATA_WIDTH{1'b0}};
        end
    end else if(write_condition) begin
        fifo_mem[write_pointer] <= input_data;
    end
end

// output signal
assign full = (count == FIFO_DEPTH);
assign empty = (count == 0);

always @(posedge clk or negedge reset_n) begin
    if(!reset_n) begin
        output_data <= {FIFO_DATA_WIDTH{1'b0}};
    end else if(read_condition) begin
        output_data <= fifo_mem[read_pointer];
    end 
end

function integer clogb2 (input integer bit_depth);
    begin
    for(clogb2=0; bit_depth>0; clogb2=clogb2+1)
        bit_depth = bit_depth >> 1;
    end
endfunction

endmodule
