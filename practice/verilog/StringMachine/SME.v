module SME(
    // Input signals
    clk,
    rst_n,
    chardata,
    isstring,
    ispattern,
    // Output signals
    out_valid,
    match,
    match_index
);

//----------------------------------------------------------------------
// Parameter Declaration
//----------------------------------------------------------------------
// State Machine
localparam IDLE     = 0;
localparam PROCESS  = 1;
localparam OUT      = 2;
// ASCII Code
localparam SPACE     = 8'h20;
localparam ANY       = 8'h2E;   // .
localparam STR_START = 8'h5E;   // ^
localparam STR_END   = 8'h24;   // $

//----------------------------------------------------------------------
// Input & Output 
//----------------------------------------------------------------------
// Input signals
input clk;
input rst_n;
input [7:0] chardata;
input isstring;
input ispattern;
// Output signals
output reg match;
output reg [4:0] match_index;
output reg out_valid;

//----------------------------------------------------------------------
// Reg & Wire
//----------------------------------------------------------------------
integer i;
// state machine
reg [1:0] state, next_state;
// store String 
reg [4:0] str_legnth;
reg [7:0] str[0:31];
// store pattern
reg head_flag;
reg tail_flag;
reg [7:0] pattern[0:7];
reg [3:0] pattern_length;
// compare
wire compare_last;
wire head_tail;
wire all_match;
wire [7:0] compare_out;
wire [7:0] compare_in1[0:7], compare_in2[0:7];
reg  final_check;

//----------------------------------------------------------------------
// State Machine
//----------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) state <= IDLE;
    else state <= next_state;
end

always @(*) begin
    case (state)
        IDLE:       next_state = (pattern_length != 4'd0 && ~ispattern) ? PROCESS : IDLE;
        PROCESS:    next_state = (final_check || compare_last) ? OUT : PROCESS;
        default:    next_state = IDLE;
    endcase
end

//----------------------------------------------------------------------
// Store String
//----------------------------------------------------------------------
// store String 
// reg [4:0] str_legnth;
// reg [7:0] str[0:31];
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        str_legnth <= 5'd0;
        for (i = 0; i < 32; i = i + 1) begin
            str[i] <= 8'd0;
        end
    end else if(isstring) begin
        str_legnth <= str_legnth + 5'd1;
        str[str_legnth] <= chardata;
    end else if(state == OUT) begin
        str_legnth <= 5'd0;
    end
end

//----------------------------------------------------------------------
// Store Pattern
//----------------------------------------------------------------------
// reg head_flag;
// reg tail_flag;
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        head_flag <= 1'b0;
        tail_flag <= 1'b0;        
    end else if(ispattern) begin
        if(chardata == STR_START) begin
            head_flag <= 1'b1;
        end
        if(chardata == STR_END) begin
            tail_flag <= 1'b1;
        end
    end else if(state == OUT) begin
        tail_flag <= 1'b0;
        head_flag <= 1'b0;
    end
end

// reg [7:0] pattern[0:7];
// reg [3:0] pattern_length;
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        pattern_length <= 4'd0;
        for(i = 0; i < 8; i = i + 1) begin
            pattern[i] <= ANY;
        end
    end else if(ispattern) begin
        if(chardata != STR_START && chardata != STR_END) begin
            pattern_length <= pattern_length + 4'd1;
        end
        pattern[pattern_length] <= chardata;
    end else if(state == OUT) begin 
        pattern_length <= 4'd0;
        for(i = 0; i < 8; i = i + 1) begin
            pattern[i] <= ANY;
        end
    end
end

//----------------------------------------------------------------------
// Compare
//----------------------------------------------------------------------
assign all_match = &compare_out;

genvar compareIndex;
generate
    for(compareIndex = 0; compareIndex < 8; compareIndex = compareIndex + 1) begin
        assign compare_in1[compareIndex] = str[match_index+compareIndex];
        assign compare_in2[compareIndex] = pattern[compareIndex];
        assign compare_out[compareIndex] = (compare_in2[compareIndex] == ANY || compare_in1[compareIndex] == compare_in2[compareIndex]) ? 1'b1 : 1'b0;
    end
endgenerate

assign head_tail = head_flag & tail_flag;

always @(*) begin
    if(all_match) begin
        case(1'b1)
            head_tail:  begin
                            if(match_index == 5'd0) begin
                                final_check = (str[match_index+pattern_length] == SPACE) ? 1'b1 : 1'b0;
                            end else if(compare_last) begin
                                final_check = (str[match_index-1] == SPACE) ? 1'b1 : 1'b0;
                            end else begin
                                final_check = (str[match_index+pattern_length] == SPACE && str[match_index-1] == SPACE) ? 1'b1 : 1'b0;
                            end
                        end
            head_flag:  begin
                            if(match_index == 5'd0 || (match_index != 5'd0 && str[match_index-1] == SPACE)) begin
                                final_check = 1'b1;
                            end else begin
                                final_check = 1'b0;
                            end
                        end
            tail_flag:  begin
                            if(compare_last || str[match_index+pattern_length] == SPACE) begin
                                final_check = 1'b1;
                            end else begin
                                final_check = 1'b0;
                            end
                        end
            default:    final_check = all_match;
        endcase
    end else begin
        final_check = 1'b0;
    end
end

//wire compare_last;
assign compare_last = (match_index == (str_legnth - {1'b0,pattern_length}));

//----------------------------------------------------------------------
// Output Signal
//----------------------------------------------------------------------
// output reg match;
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        match <= 1'b0;
    end else if(state == OUT) begin
        match <= final_check;
    end
end

// output reg [4:0] match_index;
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        match_index <= 5'd0;
    end else begin
        case(state)
            PROCESS:    match_index <= (final_check || compare_last) ? match_index : match_index + 5'd1;
            OUT:        match_index <= match_index;
            default:    match_index <= 5'd0;          
        endcase
    end
end

// output reg out_valid;
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        out_valid <= 1'b0;
    end else begin
        out_valid <= (state == OUT) ? 1'b1 : 1'b0;
    end
end

endmodule
