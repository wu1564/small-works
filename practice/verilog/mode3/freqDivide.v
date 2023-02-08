module freqDivide (
    input  clk,
    input  reset_n,
    output ouptutFreq
);
    
reg [1:0] cnt;
reg freq1, freq2;

always @(posedge clk or negedge reset_n) begin
    if(!reset_n) begin
        cnt <= 2'd0;
    end else begin
        cnt <= (cnt == 2'd2) ? 2'd0 : cnt + 2'd1;
    end
end

always @(posedge clk or negedge reset_n) begin
    if(!reset_n) begin
        freq1 <= 1'b0;
    end else if(cnt == 2'd1 || cnt == 2'd2) begin
        freq1 <= ~freq1;
    end
end

always @(negedge clk or negedge reset_n) begin
    if(!reset_n) begin
        freq2 <= 1'b0;
    end else if(cnt == 2'd1 || cnt == 2'd2) begin
        freq2 <= ~freq2;
    end
end

assign ouptutFreq = freq1 | freq2;

// test for the mid
reg [5-1:0] next_ptr, ptr;
always @(posedge clk or negedge reset_n) begin
    if(!reset_n) begin
        next_ptr <= 4'd0;
    end else begin
        next_ptr <= next_ptr + 4'd1;
    end
end

always @(posedge clk or negedge reset_n) begin
    if(!reset_n) begin
        ptr <= 4'd0;
    end else begin
        ptr <= (cnt == 2'd2) ? ptr + 4'd1 : ptr;
    end
end

wire test1 = ({!next_ptr[4], !next_ptr[3], next_ptr[2:0]} == ptr);
wire test2 = ({!next_ptr[4:3], next_ptr[2:0]} == ptr);
wire test3 = ({2'd0, next_ptr[2:0]} == ptr);
endmodule
