`timescale 1ps/1ps
`define CYCLE 10

module freqDivide_tb;

reg clk, reset_n;
wire ouptutFreq;
integer i = 0;

freqDivide freq_inst(
    .clk(clk),
    .reset_n(reset_n),
    .ouptutFreq(ouptutFreq)
);

always begin
    #(`CYCLE/2) clk = ~clk;
end

initial begin   
    clk = 0;
    reset_n = 1;
    #(`CYCLE/2) reset_n = 1'b0;
    #(`CYCLE/2) reset_n = 1'b1;
    #(1000);
    // test test1
    force freq_inst.next_ptr = {2'b00, 3'd0};
    force freq_inst.ptr = {2'b01, 3'd0};
    #(20);
    force freq_inst.next_ptr = {2'b00, 3'd0};
    force freq_inst.ptr = {2'b11, 3'd0};

    #(20);
    force freq_inst.next_ptr = {2'b11, 3'd0};
    force freq_inst.ptr = {2'b00, 3'd0};
    #(20);
    force freq_inst.next_ptr = {2'b10, 3'd0};
    force freq_inst.ptr = {2'b01, 3'd0};
    #(20);
    force freq_inst.next_ptr = {2'b01, 3'd0};
    force freq_inst.ptr = {2'b10, 3'd0};
end


// test

endmodule
