module I2C (
			clk,
			rst_n,
			SDA,
			SCL,
            // sfr bus:
            sfr_addr,
		    I2C_sfr_cs,
		    I2C_data_out,
		    I2C_data_in,
		    sfr_wr
);

input clk;
input rst_n;

input [7:0]sfr_addr;
input sfr_wr;
input [7:0]I2C_data_in;

inout SDA;
output SCL;

output [7:0]I2C_data_out;
output I2C_sfr_cs;


reg SDA_out=1;
reg SCL;
//reg [7:0]Data;

reg isout=1;
reg [31:0]bit_count;
reg [31:0]cnt_freq;
reg [31:0]step_count;

wire Control_cs;
wire Status_cs;
wire RWData_cs;
wire Control_wr;
wire Status_wr;
wire RWData_wr;
reg [31:0]temp_data;
wire write;
wire read;
wire I2C_star;
wire I2C_stop;


reg action;
reg [2:0]state;
reg [2:0]next_state;


parameter	idle=0;
parameter	star=1;
parameter   control_btye=2;
parameter   address_high=3;
parameter   address_low=4;
parameter   Data=5; 
parameter   wait_ack=6; 
parameter   stop=7;  	



assign SDA=isout ? SDA_out : 1'bz;

assign Control_cs = (sfr_addr==8'h9A) ? 1 : 0;
assign Status_cs  = (sfr_addr==8'h9B) ? 1 : 0;
assign RWData_cs  = (sfr_addr==8'h9C) ? 1 : 0;
assign I2C_sfr_cs = Control_cs | Status_cs | RWData_cs;
assign Control_wr = sfr_wr &  Control_cs;
assign Status_wr  = sfr_wr &  Status_cs;
assign RWData_wr  = sfr_wr &  RWData_cs;
assign write 	  = Control_wr ? I2C_data_in[0] : 0;
assign read 	  = Control_wr ? I2C_data_in[1] : 0;
assign I2C_star	  = Control_wr ? I2C_data_in[4] : 0;
assign I2C_stop   = Control_wr ? I2C_data_in[5] : 0;

always@(posedge clk or negedge rst_n)begin
	if(!rst_n) 
		temp_data<=0;
	else begin
		if(RWData_wr)begin
			temp_data[7:0]<=I2C_data_in;
			temp_data[15:8]<=temp_data[7:0];
			temp_data[23:16]<=temp_data[15:8];
			temp_data[31:24]<=temp_data[23:16];
		end
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		cnt_freq<=0;
	else begin
		if(action) begin
			if(cnt_freq==99)
				cnt_freq<=0;
			else
				cnt_freq<=cnt_freq+1;
		end
		else begin
			cnt_freq<=0;
		end
			
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		SCL<=1;
	else begin
		if(action) begin
			if(cnt_freq<50)
				SCL<=1;
			else
				SCL<=0;
		end
		else
			SCL<=1;
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		state<=idle;
	else begin
		if(state==idle)begin
			if(I2C_star)begin
				state<=next_state;
			end
		end
		else if(state==star)begin
			if(cnt_freq==40)
				state<=next_state;
		end
		else if(state==control_btye)begin
			if(bit_count==8 && cnt_freq==83)
				state<=next_state;
		end
		else if(state==address_high)begin
			if(bit_count==8 && cnt_freq==83)
				state<=next_state;
		end
		else if(state==address_low)begin
			if(bit_count==8 && cnt_freq==83)
				state<=next_state;
		end
		else if(state==Data)begin
			if(bit_count==8 && cnt_freq==83)
				state<=next_state;
		end
		else if(state==wait_ack)begin
			if(cnt_freq==83)
				state<=next_state;
		end
		else if(state==stop)begin
			if(cnt_freq==0)
				state<=next_state;
		end
		else if(I2C_stop)
			state<=idle;
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		next_state<=star;
		isout<=1;
		SDA_out<=1;
		step_count<=0;
	end
	else begin
		case(state)
			idle:begin
					next_state<=star;
					SDA_out<=1;
					isout<=1;
					step_count<=0;
				end
			star:begin
					next_state<=control_btye;
					isout<=1;
					SDA_out<=0;
					step_count<=1;
			end
			control_btye:begin
						next_state<=wait_ack;
						isout<=1;
							if(cnt_freq>=65 && bit_count<8)begin
								SDA_out<=temp_data[31-bit_count];
							end
						step_count<=2;
			end
			address_high:begin
						next_state<=wait_ack;
						isout<=1;
							if(cnt_freq>=65 && bit_count<8)begin
								SDA_out<=temp_data[23-bit_count];
							end
						step_count<=3;
			end
			address_low:begin
						next_state<=wait_ack;
						isout<=1;
							if(cnt_freq>=65 && bit_count<8)begin
								SDA_out<=temp_data[15-bit_count];
							end
						step_count<=4;
			end
			Data:begin
						next_state<=wait_ack;
						isout<=1;
							if(cnt_freq>=65 && bit_count<8)begin
								SDA_out<=temp_data[7-bit_count];
							end
						step_count<=5;
			end
			wait_ack:begin
						next_state<=	(step_count==2) ? address_high :
										(step_count==3) ? address_low  :
										(step_count==4) ? Data		 :
										(step_count==5) ? stop		 : idle;
						isout<=0;
			end
			stop:begin
						next_state<=idle;
						isout<= (cnt_freq>=83) ? 1 : 0;
						SDA_out<=(cnt_freq==0) ? 1 : 0;
						step_count<=6;
			end
		endcase
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		action<=0;
	else begin
		if(state==star)
			action<=1;
		else if(state==idle)
			action<=0;
		else if(state==stop && cnt_freq==99)
			action<=0;
		else
			action<=action;
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		bit_count<=0;
	else begin
		if(state==control_btye)begin
			if(cnt_freq==99)begin
				if(bit_count==8)
					bit_count<=0;
				else
					bit_count<=bit_count+1;
			end
		end
		else if(state==address_high)begin
			if(cnt_freq==99)begin
				if(bit_count==8)
					bit_count<=0;
				else
					bit_count<=bit_count+1;
			end
		end
		else if(state==address_low)begin
			if(cnt_freq==99)begin
				if(bit_count==8)
					bit_count<=0;
				else
					bit_count<=bit_count+1;
			end
		end
		else if(state==Data)begin
			if(cnt_freq==99)begin
				if(bit_count==8)
					bit_count<=0;
				else
					bit_count<=bit_count+1;
			end
		end
		else if(state==wait_ack)begin
			bit_count<=0;
		end
	end
end






endmodule
  