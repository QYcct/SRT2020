
module top(
	input clk, //50MHz
	input rst_n,
	input key_isrun,
	input key_isramsey,
	input key_co,
	input rx_pin,
	output [3:0]led,
	output [7:0]signal,
	output tx_pin,
	output reg st_clk
);

wire isrun_h; //检测key_isrun的上升沿
wire isramsey_h; //检测key_isramsey的上升沿
wire co_cooling;
reg is_co;
wire cooling;
wire isrun;
wire isramsey;
wire[3:0] time_address;
wire[15:0] time_value;

wire[7:0] signal_1;
wire rx_ready = 1'b1;
wire[7:0] rx_data;
wire rx_valid;
wire tx_valid;
wire[7:0] tx_data;
wire[3:0] tx_address;
wire txbyte_pos;

always@(posedge clk)
begin
	if(~rst_n)
		is_co <= 1'b0;
	else if(co_cooling)
		is_co <= ~is_co;
	else
		is_co <= is_co;
end

assign  cooling = is_co?1'b1:signal_1[2];
assign signal = {signal_1[7:3],cooling,signal_1[1:0]};

/*按键消抖，上升沿*/
ax_debounce u1(.clk(clk),.rst(~rst_n),.button_in(key_isrun),.button_posedge(isrun_h));
ax_debounce u2(.clk(clk),.rst(~rst_n),.button_in(key_isramsey),.button_posedge(isramsey_h));
ax_debounce u3(.clk(clk),.rst(~rst_n),.button_in(key_co),.button_posedge(co_cooling));
/*uart*/
uart_rx u4(clk,rst_n,rx_data,rx_valid,rx_ready,rx_pin);
uart_tx u5(clk, rst_n,tx_data,tx_valid,tx_ready,tx_pin);

interact u6(clk,rst_n,rx_valid,rx_data,isrun_h,isramsey_h,isrun,isramsey,time_address,time_value,tx_valid,tx_address,txbyte_pos);

generator u7(clk,rst_n,isrun,isramsey,time_address,time_value,tx_address,txbyte_pos,tx_data,led,signal_1);



endmodule