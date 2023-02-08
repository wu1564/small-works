`timescale 1ps/1ps
`define CYCLE 10
module freqDividerTb;

reg clk;
reg rst_n;
wire freq_out;
wire webTest;

reg temp = 0;
reg index = 0;
reg signal = 0;

freqDivider fq(
    .clk(clk),
    .rst_n(rst_n),
    .freq_out(freq_out),
    .webTest(webTest)
);

initial begin
    clk = 0;
    forever #(`CYCLE/2) clk = ~clk;
end

initial begin
    rst_n = 1'b1;
    #(`CYCLE/2) rst_n = 1'b0;
    @(posedge clk) rst_n = 1'b1;
    #(`CYCLE * 10)
    $display("Check");
    showFreq(0);
    $display("Finished myTest");
    showFreq(1);
    $display("Finished webTest");
end

// check design
integer i, freq = 0, original_freq = 0;
task showFreq;
input integer sel;
begin
    original_freq = 0;
    freq = 0;
    $display("Start...");
    case (sel)
        0: temp = freq_out;  
        1: temp = webTest;
        default: temp = 0;
    endcase 
    @(posedge clk);
    for(i = 0; i < 100; i = i + 1) begin
        original_freq = original_freq + 1;
        case (sel)
            0:  begin
                    if(temp != freq_out) freq = freq + 1;
                    temp = freq_out;  
                end
            1:  begin
                    if(temp != webTest) freq = freq + 1;
                    temp = webTest;
                end
            default:begin
            end
        endcase
        @(posedge clk);
    end
    $display("Original : %3d divider : %3d", original_freq, freq / 2);
end
endtask

endmodule
