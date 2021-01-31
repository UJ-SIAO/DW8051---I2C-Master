`timescale 1ns/10ps
module I2C_tb();

parameter       clkx8 = 27.08;  // 48*64=3.072 MHZ,325/12=27.08
reg clk;
reg rst_n;
reg [7:0]sfr_addr;
reg [7:0]I2C_data_in;
reg sfr_wr;
wire I2C_sfr_cs;
wire [7:0]I2C_data_out;
   wire	i2c_sda;
   wire	i2c_scl;
   pullup(i2c_sda);
   pullup(i2c_scl);
I2C U0(
			.clk(clk),
			.rst_n(rst_n),
			.SDA(i2c_sda),
			.SCL(i2c_scl),
            // sfr bus:
           		.sfr_addr(sfr_addr),
		    	.I2C_sfr_cs(I2C_sfr_cs),
		    	.I2C_data_out(I2C_data_out),
		    	.I2C_data_in(I2C_data_in),
		    	.sfr_wr(sfr_wr)
);
 M24AA256 u10(
    .A0(1'b0), 
    .A1(1'b0), 
    .A2(1'b0), 
    .WP(1'b0), 
    .SDA(i2c_sda), 
    .SCL(i2c_scl), 
    .RESET(~rst_n)
    );  
 

  always
   begin
      #(clkx8/2) clk <= 1'b1 ;
      #(clkx8/2) clk <= 1'b0 ;
   end 


initial
begin
	rst_n=1;
	sfr_wr=0;
      #(clkx8*2);
	rst_n=0;
      #(clkx8*2);
	rst_n=1;
	sfr_addr=8'h9C;
      	I2C_data_in=8'ha0;
	sfr_wr=1;
      #25
	sfr_wr=0;
      #(clkx8*4);
	sfr_addr=8'h9C;
      	I2C_data_in=8'h00;
	sfr_wr=1;
      #25
	sfr_wr=0;
      #(clkx8*4);
	sfr_addr=8'h9C;
      	I2C_data_in=8'h00;
	sfr_wr=1;
      #25
	sfr_wr=0;
      #(clkx8*4);
	sfr_addr=8'h9C;
      	I2C_data_in=8'h12;
	sfr_wr=1;
      #25
	sfr_wr=0;
      #(clkx8*4);
	sfr_addr=8'h9A;
      	I2C_data_in=8'h11;
	sfr_wr=1;
      #25
	sfr_wr=0;
 /*     #(clkx8*4);
	sfr_addr=8'h9A;
      	I2C_data_in=8'h20;
	sfr_wr=1;
      #25
	sfr_wr=0;*/
      #(clkx8*1000);

$stop;
end
initial
  begin
  $monitor("time=%3d memory_000=0x%x memory_001=0x%x",$time,u10.MemoryByte_000[7:0],u10.MemoryByte_001[7:0]);
  end

endmodule;
