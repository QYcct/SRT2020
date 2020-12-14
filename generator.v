
module generator(
	input clk,
	input rst_n,
	input isrun, //run/stop
	input isramsey, //ramsey/rabi
	input [3:0]time_address,
	input [15:0]time_value,
	input [3:0]tx_address,
	input txbyte_pos,
	output reg[7:0] tx_data,
	output reg[3:0] led,
	output reg[7:0] signal
	);


reg clk_1kHz; //1kHz时钟
reg[15:0] cnt_1kHz;

reg[15:0] coolingtime;
reg[15:0] closecooling;
reg[15:0] pumpingtime;
reg[15:0] openpump;
reg[15:0] closepump;
reg[15:0] afterpump;
reg[15:0] rfpulse;
reg[15:0] freetime;
reg[15:0] counterstart;
reg[15:0] counttime;

reg[15:0] time_cnt;


reg[15:0] data_return;


always@(posedge clk)
begin
	if(~rst_n)
		cnt_1kHz <= 16'd0;
	else if(cnt_1kHz == 16'd49_999)
		cnt_1kHz <= 16'd0;
	else
		cnt_1kHz <= cnt_1kHz + 1;
end

/*产生1kHz时钟*/
always@(posedge clk)
begin
	if(~rst_n)
		clk_1kHz <= 1'b0;
	else if(cnt_1kHz <16'd25_000)
		clk_1kHz <= 1'b0;
	else
		clk_1kHz <= 1'b1;
end

always@(*)
begin
	if(~rst_n)
		data_return <= 16'b0000_0000_0000_0000;
	else
	case(tx_address)
	4'd0:
		data_return <= coolingtime;
	4'd1:
		data_return <= closecooling;
	4'd2:
		data_return <= pumpingtime;
	4'd3:
		data_return <= afterpump;
	4'd4:
		data_return <= rfpulse;
	4'd5:
		data_return <= freetime;
	4'd6:
		data_return <= counterstart;
	4'd7:
		data_return <= counttime;
	4'd8:
		data_return <= {14'b0000_0000_0000_00,isramsey,isrun};
	default:
		data_return <= 16'b0000_0000_0000_0000;
		
	endcase
end

always@(*)
begin
	if(~rst_n)
		tx_data <= 8'b0000_0000;
	else if(txbyte_pos == 1'b0)
		tx_data <= data_return[7:0];
	else
		tx_data <= data_return[15:8];
end


/*时间配置*/
always@(posedge clk)
begin
	if(~rst_n)
	begin
		coolingtime <= 16'd0;
		closecooling <= 16'd0;
		pumpingtime <= 16'd100;
		openpump <= 16'd5;
		closepump <= 16'd5;
		afterpump <= 16'd10;
		rfpulse <= 16'd60;
		freetime <= 16'd500;
		counterstart <= 16'd5;
		counttime <= 16'd410;
	end
	else
		case(time_address)
		4'd0:
		;
		4'd1:
			coolingtime <= time_value;
		4'd2:
			closecooling <= time_value;
		4'd3:
			pumpingtime <= time_value;
		4'd4:
			openpump <= time_value;
		4'd5:
			closepump <= time_value;
		4'd6:
			afterpump <= time_value;
		4'd7:
			rfpulse <= time_value;
		4'd8:
			freetime <= time_value;
		4'd9:
			counterstart <= time_value;
		4'd10:
			counttime <= time_value;
		default:
		begin
			coolingtime <= 16'd0;
			closecooling <= 16'd0;
			pumpingtime <= 16'd100;
			openpump <= 16'd5;
			closepump <= 16'd5;
			afterpump <= 16'd10;
			rfpulse <= 16'd60;
			freetime <= 16'd500;
			counterstart <= 16'd5;
			counttime <= 16'd410;
		end
		endcase
		
end


/*信号产生逻辑*/
always@(posedge clk_1kHz)
begin
	if(~rst_n)
	begin
		led <= 4'd0;
		signal <= 6'b11111111;
		time_cnt <= 16'd0;
	end
	else if(~isrun)
	begin
		led <= 4'd0;
		signal <= 6'b11111111;
		time_cnt <= 16'd0;
	end
	else 
		if(time_cnt>=16'd0 && 
				time_cnt<coolingtime)
		begin
			led <= 4'd1;
			signal <= 6'b11111011;
			time_cnt <= time_cnt + 16'd1;
		end
		else if(time_cnt>=coolingtime &&
				time_cnt<(coolingtime+closecooling))
		begin
			led <= 4'd2;
			signal <= 6'b11111111;
			time_cnt <= time_cnt + 16'd1;
		end
		else if(time_cnt>=coolingtime+closecooling &&
				time_cnt<(coolingtime+closecooling+pumpingtime))
		begin
			led <= 4'd3;
			signal <= 6'b11010111;
			time_cnt <= time_cnt + 16'd1;
		end
		else if(time_cnt>=coolingtime+closecooling+pumpingtime &&
				time_cnt<(coolingtime+closecooling+pumpingtime+afterpump))
		begin
			led <= 4'd4;
			signal <= 6'b11111111;
			time_cnt <= time_cnt + 16'd1;
		end
		else if(time_cnt>=coolingtime+closecooling+pumpingtime+afterpump &&
				time_cnt<(coolingtime+closecooling+pumpingtime+afterpump+rfpulse))
		begin
			led <= 4'd5;
			signal <= 6'b11111110;
			time_cnt <= time_cnt + 16'd1;
		end
		else if(time_cnt>=coolingtime+closecooling+pumpingtime+afterpump+rfpulse)
			if(isramsey)
				if(time_cnt>=coolingtime+closecooling+pumpingtime+afterpump+rfpulse &&
				   time_cnt<(coolingtime+closecooling+pumpingtime+afterpump+rfpulse+freetime))
				begin
					led <= 4'd6;
					signal <= 6'b11111111;
					time_cnt <= time_cnt + 16'd1;
				end
				else if(time_cnt>=coolingtime+closecooling+pumpingtime+afterpump+rfpulse+freetime &&
						time_cnt<(coolingtime+closecooling+pumpingtime+afterpump+rfpulse+freetime+rfpulse))
				begin
					led <= 4'd7;
					signal <= 6'b11111110;
					time_cnt <= time_cnt + 16'd1;
				end
				else if(time_cnt>=coolingtime+closecooling+pumpingtime+afterpump+rfpulse+freetime+rfpulse &&
						time_cnt<(coolingtime+closecooling+pumpingtime+afterpump+rfpulse+freetime+rfpulse+counterstart))
				begin
					led <= 4'd8;
					signal <= 6'b11101111;
					time_cnt <= time_cnt + 16'd1;
				end
				else if(time_cnt>=coolingtime+closecooling+pumpingtime+afterpump+rfpulse+freetime+rfpulse+counterstart &&
						time_cnt<(coolingtime+closecooling+pumpingtime+afterpump+rfpulse+freetime+rfpulse+counterstart+counttime))
				begin
					led <= 4'd9;
					signal <= 6'b11001101;
					time_cnt <= time_cnt + 16'd1;
				end
				else
				begin
					led <= 4'd1;
					time_cnt <= 16'd0;
				end
			else
				if(time_cnt>=coolingtime+closecooling+pumpingtime+afterpump+rfpulse &&
				   time_cnt<(coolingtime+closecooling+pumpingtime+afterpump+rfpulse+counterstart))
				begin
					led <= 4'd8;
					signal <= 6'b11101111;
					time_cnt <= time_cnt + 16'd1;
				end
				else if(time_cnt>=coolingtime+closecooling+pumpingtime+afterpump+rfpulse+counterstart &&
						time_cnt<(coolingtime+closecooling+pumpingtime+afterpump+rfpulse+counterstart+counttime))
				begin
					led <= 4'd9;
					signal <= 6'b11001101;
					time_cnt <= time_cnt + 16'd1;
				end
				else
				begin
					led <= 4'd1;
					time_cnt <= 16'd0;
				end
		else
		begin
			led <= 4'd1;
			time_cnt <= 16'd0;
		end	
end
	
endmodule