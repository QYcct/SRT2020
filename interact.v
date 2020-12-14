
module interact(
	input clk,
	input rst_n,
	input rx_valid,
	input [7:0]rx_data,
	input key_isrun,
	input key_isramsey,
	output reg isrun,
	output reg isramsey,
	output reg[3:0] time_address,
	output reg[15:0] time_value,
	output reg tx_valid,
	output reg [3:0]tx_address,
	output reg txbyte_pos //待返回参数的字节位
	);

reg[3:0] state; //状态
reg[3:0] state_d1;
reg[12:0] wait_cnt; //等待时延计数器0-5000,延时0.1ms
reg[3:0] time_address_buffer;
reg[15:0] time_value_buffer;
reg receive_done;


always@(posedge clk)
begin
	if(~rst_n)
		state_d1 <= 4'd0;
	else
		state_d1 <= state;
end
	
always@(posedge clk) //主状态机
begin
	if(~rst_n)
	begin
		tx_valid <= 1'b0;
		tx_address <= 4'd15;
		txbyte_pos <= 1'b1;
		wait_cnt <= 13'd0;
		receive_done <= 1'b1;
		state <= 4'd0;
	end
	else
	begin
		case(state)
		4'd0: //IDEL状态下
		begin
			if(rx_valid) //若接收到command命令
			begin
				tx_valid <= 1'b0;
				tx_address <= 4'd15;
				receive_done <= 1'b0;
				state <= 4'd1;
			end
			else
			begin
				tx_valid <= 1'b0;
				tx_address <= 4'd15;
				receive_done <= 1'b1;
				state <= 4'd0;
			end
		end
		4'd1: //接收到command命令状态下
		begin
			if(~rx_data[7]) //若MSB为0则判断为无效命令
			begin
				tx_address <= 4'd15;
				receive_done <= 1'b1;
				state <= 4'd0;
			end
			else if(rx_data[1:0] == 2'b00) //00:返回当前配置信息
			begin
				tx_address <= 4'd15;
				receive_done <= 1'b1;
				state <= 4'd2;
			end
			else if(rx_data[1:0] == 2'b01) //01:设置run/stop模式
			begin
				tx_address <= 4'd15;
				receive_done <= 1'b1;
				state <= 4'd3;
			end
			else if(rx_data[1:0] == 2'b10) //10:设置ramsey/rabi模式
			begin
				tx_address <= 4'd15;
				receive_done <= 1'b1;
				state <= 4'd4;
			end
			else //11:设置时间参数
			begin
				tx_address <= 4'd15;
				receive_done <= 1'b0;
				state <= 4'd5;
			end
		end
		4'd2: //返回当前配置信息
		begin
			if((tx_address != 4'd8)) //尚未返回所有参数
			begin
				if(txbyte_pos == 1'b0) //若已经返回低字节
				begin
					txbyte_pos <= 1'b1;
					state <= 4'd8; //进入等待状态，等待0.1ms
				end
				else
				begin
					txbyte_pos <= 1'b0;
					tx_address <= tx_address + 4'd1;
					state <= 4'd8; //进入等待状态，等待0.1ms
				end
			end
			else //已返回所有参数
			begin
				txbyte_pos <= 1'b1;
				tx_address <= 4'd15;
				state <= 4'd0;
			end
		end
		4'd3: //设置run/stop模式
		begin
			tx_address <= 4'd15;
			receive_done <= 1'b1;
			state <= 4'd2;
		end
		4'd4: //设置ramsey/rabi模式
		begin
			tx_address <= 4'd15;
			receive_done <= 1'b1;
			state <= 4'd2;
		end
		4'd5:
		begin
			tx_address <= 4'd15;
			receive_done <= 1'b0;
			if(rx_valid) //接收到time_value低字节
				state <= 4'd6;
			else
				state <= 4'd5;
		end
		4'd6:
		begin
			tx_address <= 4'd15;
			receive_done <= 1'b0;
			if(rx_valid) //接收到time_value高字节
				state <= 4'd7;
			else
				state <= 4'd6;
		end
		4'd7:
		begin
			tx_address <= 4'd15;
			receive_done <= 1'b1;
			state <= 4'd2;
		end
		4'd8:
		begin
			if(wait_cnt < 13'd4999)
			begin
				if(wait_cnt <= 13'd4200)
					tx_valid <= 1'b1;
				else //发送完一个字节后停止发送
					tx_valid <= 1'b0;
				wait_cnt <= wait_cnt + 1;
				state <= 4'd8;
			end
			else
			begin
				wait_cnt <= 13'd0;
				state <= 4'd2;
			end
		end
		default:
		begin
			tx_valid <= 1'b0;
			tx_address <= 4'd15;
			state <= 4'd0;
		end
		endcase
	end
end

always@(posedge clk)
begin
	if(~rst_n) //初始状态为stop + ramsey
	begin
		time_address_buffer <= 4'd0;
		time_value_buffer <= 16'd0;
	end
	else
	begin
		case(state)
		4'd0: //IDLE状态
		begin
			time_address_buffer <= 4'd0;
			time_value_buffer <= 16'd0;
		end
		4'd1: //接收到command
		begin
			time_address_buffer <= 4'd0;
			time_value_buffer <= 16'd0;
		end
		4'd2: //发送状态
		begin
			time_address_buffer <= 4'd0;
			time_value_buffer <= 16'd0;
		end
		4'd3: //设置run/stop
		begin
			time_address_buffer <= 4'd0;
			time_value_buffer <= 16'd0;
		end
		4'd4: //设置ramsey/rabi
		begin
			time_address_buffer <= 4'd0;
			time_value_buffer <= 16'd0;
		end
		4'd5: //设置time_address
		begin
			if(state_d1 == 4'd1)
				time_address_buffer <= rx_data[6:3];
		end
		4'd6: //设置time_value低八位
		begin
			if(state_d1 == 4'd5)
				time_value_buffer <= {8'b0000_0000,rx_data};
		end
		4'd7: //设置time_value高八位
		begin
			if(state_d1 == 4'd6)
				time_value_buffer <= {rx_data,time_value_buffer[7:0]};
		end
		4'd8: //等待状态
		;
		default:
		begin
			time_address_buffer <= 4'd0;
			time_value_buffer <= 16'd0;
		end
		endcase
	end
end

always@(posedge clk)
begin
	if(~rst_n)
	begin
		time_address <= 8'd0;
		time_value <= 16'd0;
	end
	else if(receive_done) //完成接收则修改时间配置参数
	begin
		time_address <= time_address_buffer;
		time_value <= time_value_buffer;
	end
	else
	begin
		time_address <= 8'd0;
		time_value <= 16'd0;
	end
end

always@(posedge clk)
begin
	if(~rst_n)
		isrun <= 1'b0;
	else if(state == 4'd3)
		isrun <= rx_data[2];
	else
	begin
		if(key_isrun)
			isrun <= ~isrun;
	end
end

always@(posedge clk)
begin
	if(~rst_n)
		isramsey <= 1'b1;
	else if(state == 4'd4)
		isramsey <= rx_data[2];
	else
	begin
		if(key_isramsey)
			isramsey <= ~isramsey;
	end
end



	
endmodule