module freqDivider(
    clk,
    rst_n,
    freq_out,
    webTest
);
// divide 4 freq

//---------------------------------------------------------------
// Parameter Declaration
//---------------------------------------------------------------
localparam FREQUENCY = 2;

//---------------------------------------------------------------
// Input & Output Declaration
//---------------------------------------------------------------
input clk;
input rst_n;
output reg freq_out;
output webTest;

//---------------------------------------------------------------
// Reg & Wire Declaration
//---------------------------------------------------------------
reg [1:0] cnt;
wire adjustFreq;
// website testing
reg [2:0] cnt_p;
reg [2:0] cnt_n;
reg       clk_p;
reg       clk_n;

//wire adjustFreq;
assign adjustFreq = (cnt == FREQUENCY - 1);

//reg [1:0] cnt;
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        cnt <= 2'd0;
    end else begin
        cnt <= (adjustFreq) ? 2'd0 : cnt + 2'd1;
    end
end

//output reg freq_out;
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        freq_out <= 1'b0;
    end else if(adjustFreq) begin
        freq_out <= ~freq_out;
    end
end

//---------------------------------------------------------------
// Website Testing
//---------------------------------------------------------------

assign webTest = clk_p | clk_n;

always @ (posedge clk or negedge rst_n) begin
    if(!rst_n) 
        cnt_p <= 3'd0;
    else if(cnt_p == 3'd6)
        cnt_p <= 3'd0;
    else 
        cnt_p <= cnt_p + 1'b1;
end

always @ (posedge clk or negedge rst_n) begin
    if(!rst_n)     
        clk_p <= 1'b0;
    else if((cnt_p == 3'd3) || (cnt_p == 3'd6))
        clk_p <= ~ clk_p;
end
//---------------------------------------------

//----------count the negedge------------------

always @ (negedge clk or negedge rst_n) begin
    if(!rst_n) 
        cnt_n <= 3'd0;
    else if(cnt_n == 3'd6) 
        cnt_n <= 3'd0;
    else
        cnt_n <= cnt_n + 1'b1;
end

always @ (negedge clk or negedge rst_n) begin
    if(!rst_n) 
        clk_n <= 1'b0;
    else if((cnt_n == 3'd3) || (cnt_n == 3'd6)) 
        clk_n <= ~clk_n;
end
//----------------------------------------------

endmodule
