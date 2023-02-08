module divider_module #(
    parameter WIDTH = 8
)(
    clk,
    rst_n,
    start,
    dividend,
    divisor,
    done,
    q, // asine_temp
    r
);

//-----------------------------------------------------------
// Input/Output
//-----------------------------------------------------------
input  clk;
input  rst_n;
input  start;
input  [WIDTH-1:0] dividend;
input  [WIDTH-1:0] divisor;
output reg done;
output reg [WIDTH-1:0] q;
output reg [WIDTH-1:0] r;

//-----------------------------------------------------------
// Reg/Wire
//-----------------------------------------------------------
reg [32:0] cnt;
reg [WIDTH-1:0] compareDividend;
wire [WIDTH-1:0] shiftedDividend;
wire [WIDTH-1:0] minus_divisor;
wire [WIDTH-1:0] adder_out;
wire doneFlag;

//wire doneFlag;
assign doneFlag = (cnt == WIDTH-1);

//wire [7:0] shiftedDividend;
assign shiftedDividend = {compareDividend[WIDTH-2:0],dividend[(WIDTH-1)-cnt]};

//wire [7:0] minus_divisor;
assign minus_divisor = (~divisor) + 1'b1;

//wire [7:0] adder_out;
assign adder_out = shiftedDividend + minus_divisor;

//reg [3:0] cnt;
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        cnt <= 0;
    end else if(doneFlag || !start) begin
        cnt <= 0;
    end else if(start) begin
        cnt <= cnt + 1;
    end 
end

//reg [7:0] compareDividend;
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        compareDividend <= {WIDTH{1'b0}};
    end else if(start) begin
        if(shiftedDividend >= divisor) begin
            compareDividend <= adder_out;
        end else begin
            compareDividend <= shiftedDividend;
        end
    end else begin
        compareDividend <= {WIDTH{1'b0}};
    end
end

//output [7:0] q;
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        q <= {WIDTH{1'b0}};
    end else if(start) begin
        if(shiftedDividend >= divisor) begin
            q <= {q[WIDTH-1:0],1'b1};
        end else begin
            q <= {q[WIDTH-1:0],1'b0};
        end 
    end else begin
        q <= {WIDTH{1'b0}};
    end 
end

//output reg done;
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        done <= 1'b0;
    end else if(doneFlag)begin
        done <= 1'b1;
    end else begin
        done <= 1'b0;
    end
end

//output [7:0] r;
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        r <= {WIDTH{1'b0}};
    end else if(doneFlag) begin
        if(shiftedDividend >= divisor) begin
            r <= adder_out;
        end else begin
            r <= shiftedDividend;
        end
    end else if(!start) begin
        r <= {WIDTH{1'b0}};
    end 
end

endmodule
