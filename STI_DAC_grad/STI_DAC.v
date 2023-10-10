module STI_DAC(

    input			clk, reset,
    input			load, pi_msb, pi_low, pi_end,
    input	[15:0]	pi_data,
    input	[1:0]	pi_length,
    input			pi_fill,

    output  so_data, so_valid,
    output reg oem_finish, odd1_wr, odd2_wr, odd3_wr, odd4_wr, even1_wr, even2_wr, even3_wr, even4_wr,
    output reg [4:0] oem_addr,
    output reg [7:0] oem_dataout
  );

  //==============================================================================
  reg [31:0]out_buffer;
  reg [4:0] out_len;
  reg [2:0]cs;
  reg first_round;

  wire rst=reset;

  parameter LOAD=0, EX=1, STORE=2,PAD=3;
  integer i;
  always @(posedge clk,posedge rst)
  begin
    if(rst)
    begin
      cs<=LOAD;
    end
    else
    begin
      case (cs)
        LOAD:
        begin
          cs<=(pi_end)? PAD:(load)?EX:LOAD;
        end
        EX:
        begin
          cs<=STORE;
        end
        STORE:
        begin
          cs<=(out_len==0)? LOAD:STORE;
        end
      endcase
    end
  end

  reg [4:0] out_len_temp;

  always @(*)
  begin
    case (pi_length)
      0:
        out_len_temp=7;
      1:
        out_len_temp=15;
      2:
        out_len_temp=23;
      3:
        out_len_temp=31;
    endcase
  end

  reg[7:0]out_buffer_8,rev_8;
  reg[23:0]out_buffer_24,rev_24;
  reg[15:0]out_buffer_16,rev_16;
  reg[31:0]out_buffer_32,rev_32;

  reg[31:0]out_buffer_sb;
  always @(*)
  begin
    out_buffer_8 = (pi_low)? out_buffer[15:8] : out_buffer[7:0];
    out_buffer_24 = (pi_fill)? {out_buffer,8'd0} : {8'd0,out_buffer};
    out_buffer_16 = out_buffer;
    out_buffer_32 = (pi_fill)? {out_buffer,16'd0} : {16'd0,out_buffer};

    for (i = 0; i < 8; i = i + 1)
    begin
      rev_8[i] = out_buffer_8[7 - i];
    end
    for (i = 0; i < 16; i = i + 1)
    begin
      rev_16[i] = out_buffer_16[15 - i];
    end
    for (i = 0; i < 24; i = i + 1)
    begin
      rev_24[i] = out_buffer_24[23 - i];
    end
    for (i = 0; i < 32; i = i + 1)
    begin
      rev_32[i] = out_buffer_32[31 - i];
    end
  end
  always @(*)
  begin
    case (out_len)
      7:
      begin
        out_buffer_sb = (pi_msb)?{out_buffer_8,24'd0}:{rev_8,24'd0};
      end
      15:
      begin
        out_buffer_sb = (pi_msb)?{out_buffer_16,16'd0}:{rev_16,16'd0};
      end
      23:
      begin
        out_buffer_sb = (pi_msb)?{out_buffer_24,8'd0}:{rev_24,8'd0};
      end
      31:
      begin
        out_buffer_sb = (pi_msb)?out_buffer_32:rev_32;
      end
      default:
        out_buffer_sb = 0;
    endcase
  end

  always @(posedge clk,posedge rst)
  begin
    if(rst)
    begin
      out_buffer<=0;
      out_len   <=0;
    end
    else
    begin
      case (cs)
        LOAD:
        begin
          out_buffer<=pi_data;
          out_len<=out_len_temp;
        end
        EX:
        begin
          out_buffer<=out_buffer_sb;
        end
        STORE:
        begin
          out_buffer<=out_buffer<<1;
          out_len<=out_len-1;
        end
      endcase
    end
  end

  //DAC
  reg [7:0]addr;
  reg [3:0]cnt;
  reg o1,e1,o2,e2,o3,e3,o4,e4;
  always @(*)
  begin
    case (addr[3:0])
      0,2,4,6,9,11,13,15:
      begin
        {o1,o2,o3,o4,e1,e2,e3,e4}=8'b1111_0000;
      end
      default:
      begin
        {o1,o2,o3,o4,e1,e2,e3,e4}=8'b0000_1111;
      end
    endcase
  end
  always @(posedge clk,posedge rst)
  begin
    if(rst)
    begin
      odd1_wr <= 0;
      even1_wr<= 0;
      odd2_wr <= 0;
      even2_wr<= 0;
      odd3_wr <= 0;
      even3_wr<= 0;
      odd4_wr <= 0;
      even4_wr<= 0;
    end
    else if(cnt==7)
    begin
      odd1_wr <= o1&& (addr<8'h40) ;
      even1_wr<= e1&& (addr<8'h40) ;
      odd2_wr <= o2&& (addr>=8'h40&&addr<8'h80) ;
      even2_wr<= e2&& (addr>=8'h40&&addr<8'h80) ;
      odd3_wr <= o3&& (addr>=8'h80&&addr<8'hc0) ;
      even3_wr<= e3&& (addr>=8'h80&&addr<8'hc0) ;
      odd4_wr <= (o4&& (addr>=8'hc0));
      even4_wr<= (e4&& (addr>=8'hc0));
    end
    else
    begin
      odd1_wr <= 0;
      even1_wr<= 0;
      odd2_wr <= 0;
      even2_wr<= 0;
      odd3_wr <= 0;
      even3_wr<= 0;
      odd4_wr <= 0;
      even4_wr<= 0;
    end
  end


  always @(posedge clk ,posedge rst)
  begin
    if(rst)
    begin
      cnt  <=0;
      addr <=0;
      oem_addr <=0;
      first_round<=1;
    end
    else if(so_valid||cs==PAD)
    begin
      first_round<=0;
      cnt  <=(cnt==7)? 0 :cnt+1;
      addr <=(cnt==7)?addr+1:addr;
      oem_addr <=(addr>1&&!addr[0]&&cnt==0? oem_addr+1:oem_addr);
    end
  end

  always @(negedge clk ,posedge rst)//負緣可讓data提前到，避免wr_en正緣時data一起到
  begin
    if(rst)
    begin
      oem_dataout<=0;
    end
    else if(so_valid)
    begin
      oem_dataout<={oem_dataout[6:0],so_data};
    end
    else if(cs==PAD)
    begin
      oem_dataout<=0;
    end
  end

  always @(posedge clk ,posedge rst)
  begin
    if(rst)
    begin
      oem_finish<=0;
    end
    else if(odd4_wr&addr==0)
    begin
      oem_finish<=1;
    end
  end

  assign so_data = out_buffer[31];//從第31bit開始輸出
  assign so_valid = cs==STORE;
endmodule

