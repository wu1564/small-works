`timescale 1 ps/ 1 ps
module divider_module_simulation();

parameter WIDTH = 8;

reg clk;
reg rst_n;
reg start;
reg [WIDTH-1:0] dividend;
reg [WIDTH-1:0] divisor;
wire done;
wire [WIDTH-1:0] q;
wire [WIDTH-1:0] r;

divider_module #(
    .WIDTH(WIDTH)
)divider_int(
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .dividend(dividend),
    .divisor(divisor),
    .done(done),
    .q(q), // asine_temp
    .r(r)
);

initial begin
    clk = 0;
    forever begin
        #10 clk = ~clk;
    end
end

/*****************************/
initial begin 
    rst_n = 0; 
    #10; 
    rst_n = 1;
    showMsg;
end 
/*****************************/

always @ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        dividend <= {WIDTH{1'b0}};
        divisor <= {WIDTH{1'b0}};
        start <= 1'b0;
    end else begin
        divisor <= 8;
        if(done) begin
            start <= 1'b0;
            dividend <= dividend + 1;
        end else begin
            start <= 1'b1;
        end
    end
end

task showMsg;
begin
    while(1) begin
        @(posedge clk);
        if(done) begin
            $display("Dividend : %3d Divisor : %3d Q : %3d    R : %3d", dividend, divisor,q, r);
        end
    end
end
endtask


endmodule
