`timescale 1ps/1ps
`define CYCLE 10

module fifo_test;

localparam integer C_M_AXIS_TDATA_WIDTH = 32;
// slave
localparam integer C_S_AXIS_TDATA_WIDTH	= 32;
// fifo depth
localparam integer FIFO_DEPTH = 8;

integer i;
reg  clk;
reg  reset_n;
reg  write_en;
reg  [C_S_AXIS_TDATA_WIDTH-1:0] input_data;
reg  pop_en;
wire full;
wire empty;
wire [C_S_AXIS_TDATA_WIDTH-1:0] output_data;

axis_fifo_connection #(
    .C_M_AXIS_TDATA_WIDTH(C_M_AXIS_TDATA_WIDTH),
    .C_S_AXIS_TDATA_WIDTH(C_S_AXIS_TDATA_WIDTH),
    .FIFO_DEPTH(FIFO_DEPTH)
)fifo_inst(
    .clk(clk),
    .reset_n(reset_n),
    .write_en(write_en),
    .input_data(input_data),
    .pop_en(pop_en),
    .full(full),
    .empty(empty),
    .output_data(output_data)
);

initial begin
    clk = 0;
    forever begin
         #(`CYCLE/2) clk = ~clk;
    end
end

initial begin
    pop_en = 0;
    write_en = 0;
    reset_n = 1;
    #(`CYCLE * 10);
    reset_n = 0;    
    #(`CYCLE * 10) reset_n = 1;
    // continuous giving data
    for(i = 0; i < FIFO_DEPTH; i = i + 1) begin
        writeFIFO(32'd100 + i);
    end
    // test give the oversize data
    writeFIFO(32'd999);

    // continuous pop out
    for(i = 0; i < FIFO_DEPTH; i = i + 1) begin
        popOut;
    end
    // test pop the oversize data
    popOut;

    //continuous write and read
    for(i = 0; i < FIFO_DEPTH; i = i + 1) begin
       writeFIFO(32'd5 + i * 3);
       #(`CYCLE);
       popOut;
    end

    // test read and write samutaneously
    for(i = 0; i < FIFO_DEPTH; i = i + 1) begin
        input_data = 32'd1 + i;
        write_en = 1;
        pop_en = 1;
        #(`CYCLE);
        #1 write_en = 0;
        pop_en = 0;
    end

    // test give some data first and write and read data samutaneously again
    writeFIFO(32'd9);
    writeFIFO(32'd99);
    writeFIFO(32'd999);
    #1;
    for(i = 0; i < FIFO_DEPTH; i = i + 1) begin
        input_data = 32'd99 + i;
        write_en = 1;
        pop_en = 1;
        #(`CYCLE);
        #1 write_en = 0;
        pop_en = 0;
    end
end

task writeFIFO;
input [C_S_AXIS_TDATA_WIDTH-1:0] inputNum;
begin
    @(posedge clk);
    input_data = inputNum;
    write_en = 1;
    @(posedge clk);
    write_en = 0;
    #(`CYCLE * 5);
end
endtask

task popOut;
begin
    @(posedge clk);
    pop_en = 1;
    @(posedge clk);
    pop_en = 0;
end
endtask

endmodule
