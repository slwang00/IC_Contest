module  FAS (data_valid, data, clk, rst, fir_d, fir_valid, fft_valid, done, freq,
               fft_d1, fft_d2, fft_d3, fft_d4, fft_d5, fft_d6, fft_d7, fft_d8,
               fft_d9, fft_d10, fft_d11, fft_d12, fft_d13, fft_d14, fft_d15, fft_d0);
  input clk, rst;
  input data_valid;
  input [15:0] data;

  output fir_valid, fft_valid;
  output [15:0] fir_d;
  output reg [31:0] fft_d1, fft_d2, fft_d3, fft_d4, fft_d5, fft_d6, fft_d7, fft_d8;
  output reg [31:0] fft_d9, fft_d10, fft_d11, fft_d12, fft_d13, fft_d14, fft_d15, fft_d0;
  output reg done;
  output reg [3:0] freq;

  reg  [319:0]x;

  wire fir_done;
  FIR FIR(.clk(clk),.rst(rst),
          .data_valid(data_valid),
          .data(data),
          .fir_valid(fir_valid),
          .done(fir_done),
          .fir_d(fir_d),
          .fir_x(x));

  FFT FFT(.clk(clk),.rst(rst),
          .ready(fir_done),
          .fir_x(x),
          .fft_valid(fft_valid),
          .fft_d1(fft_d1), .fft_d2 (fft_d2) , .fft_d3 (fft_d3 ), .fft_d4 (fft_d4) ,
          .fft_d5(fft_d5 ) ,.fft_d6(fft_d6),  .fft_d7(fft_d7),  .fft_d8(fft_d8),
          .fft_d9(fft_d9), .fft_d10(fft_d10), .fft_d11(fft_d11), .fft_d12(fft_d12),
          .fft_d13(fft_d13),.fft_d14(fft_d14),.fft_d15(fft_d15),.fft_d0(fft_d0));

  ANA ANA( .clk(clk),.rst(rst),.fft_valid(fft_valid),
           .fft_d1(fft_d1), .fft_d2 (fft_d2) , .fft_d3 (fft_d3 ), .fft_d4 (fft_d4) ,
           .fft_d5(fft_d5 ) ,.fft_d6(fft_d6),  .fft_d7(fft_d7),  .fft_d8(fft_d8),
           .fft_d9(fft_d9), .fft_d10(fft_d10), .fft_d11(fft_d11), .fft_d12(fft_d12),
           .fft_d13(fft_d13),.fft_d14(fft_d14),.fft_d15(fft_d15),.fft_d0(fft_d0),
           .freq(freq),
           .done(done));
endmodule


module FIR (
    input clk,rst,
    input data_valid,
    input [15:0]data,
    output reg fir_valid,
    output reg  done,
    output [15:0]fir_d,
    output reg [319:0]fir_x
  );

  reg first_round;
  reg[6:0]cnt;
  reg signed[15:0]buffer[31:0];

  wire signed [19:0]fir_c[31:0];
  reg signed [11:-24]fir_out[36:0];
  reg [3:-16]x[0:15];


  //建table時不能用always，信號會全部都是unknow
  assign fir_c[0]=20'hFFF9E ;
  assign fir_c[1]=20'hFFF86 ;
  assign fir_c[2]=20'hFFFA7 ;
  assign fir_c[3]=20'h0003B ;
  assign fir_c[4]=20'h0014B ;
  assign fir_c[5]=20'h0024A ;
  assign fir_c[6]=20'h00222 ;
  assign fir_c[7]=20'hFFFE4 ;
  assign fir_c[8]=20'hFFBC5 ;
  assign fir_c[9]=20'hFF7CA ;
  assign fir_c[10]=20'hFF74E ;
  assign fir_c[11]=20'hFFD74 ;
  assign fir_c[12]=20'h00B1A ;
  assign fir_c[13]=20'h01DAC ;
  assign fir_c[14]=20'h02F9E ;
  assign fir_c[15]=20'h03AA9 ;
  assign fir_c[16]=20'h03AA9 ;
  assign fir_c[17]=20'h02F9E ;
  assign fir_c[18]=20'h01DAC ;
  assign fir_c[19]=20'h00B1A ;
  assign fir_c[20]=20'hFFD74 ;
  assign fir_c[21]=20'hFF74E ;
  assign fir_c[22]=20'hFF7CA ;
  assign fir_c[23]=20'hFFBC5 ;
  assign fir_c[24]=20'hFFFE4 ;
  assign fir_c[25]=20'h00222 ;
  assign fir_c[26]=20'h0024A ;
  assign fir_c[27]=20'h0014B ;
  assign fir_c[28]=20'h0003B ;
  assign fir_c[29]=20'hFFFA7 ;
  assign fir_c[30]=20'hFFF86 ;
  assign fir_c[31]=20'hFFF9E ;

  integer i;
  parameter INIT = 0,FIR =1;
  reg cs;


  always @(posedge clk ,posedge rst)
  begin
    if(rst)
    begin
      cs<=0;
      cnt<=0;
      done<=0;
      fir_valid<=0;
    end
    else
    begin
      case (cs)
        INIT:
        begin
          cs<=cnt==32? FIR:INIT;
          cnt<=cnt==32?0:cnt+1;
          fir_valid<=cnt==32;
        end
        FIR:
        begin
          cnt<=cnt==15?0:cnt+1;
          done<=cnt==15;
        end
      endcase
    end
  end

  always @(posedge clk ,posedge rst)
  begin
    if(rst)
    begin
      for (i =0 ;i<32 ;i=i+1 )
      begin
        buffer[i-1]<=0;
      end
    end
    else
    begin
      buffer[31]<=data;
      for (i =1 ;i<32 ;i=i+1 )
      begin
        buffer[i-1]<=buffer[i];//newer data is stored in big index
      end
    end
  end

  always @(*)
  begin
    fir_out[0] = 0;
    for (i=0;i<32 ;i=i+4)//Q8.8*Q4.16=Q12.24
    begin
      fir_out[i+4] = fir_out[i] + (buffer[i]*fir_c[31-i]+buffer[i+1]*fir_c[30-i])+(buffer[i+2]*fir_c[29-i]+buffer[i+3]*fir_c[28-i]);
    end
  end

  always @(posedge clk,posedge rst)
  begin
    if(rst)
    begin
      for (i = 0;i<16 ;i=i+1 )
      begin
        x[i]<=0;
      end
    end
    else if(fir_valid)
    begin
      x[15]<=fir_d<<8;//捨去末8位=>變Q8.8
      for (i = 1;i<16 ;i=i+1 )
      begin
        x[i-1]<=x[i];
      end
    end
  end
  assign fir_d = (fir_out[32][3])? {fir_out[32][-8+:16]+1}:{fir_out[32][-8+:16]};
  //Q12.24  ，用向0 rounding的方式(不用會錯)， 所以若為正，捨去小數，若為負，去掉小數+1(二補數+1是越往0靠近)

  always @(*)
  begin
    fir_x[20*0+:20]=x[0];
    fir_x[20*1+:20]=x[1];
    fir_x[20*2+:20]=x[2];
    fir_x[20*3+:20]=x[3];
    fir_x[20*4+:20]=x[4];
    fir_x[20*5+:20]=x[5];
    fir_x[20*6+:20]=x[6];
    fir_x[20*7+:20]=x[7];
    fir_x[20*8+:20]=x[8];
    fir_x[20*9+:20]=x[9];
    fir_x[20*10+:20]=x[10];
    fir_x[20*11+:20]=x[11];
    fir_x[20*12+:20]=x[12];
    fir_x[20*13+:20]=x[13];
    fir_x[20*14+:20]=x[14];
    fir_x[20*15+:20]=x[15];
  end

endmodule

module FFT (
    input clk,rst,
    input ready,
    input [319:0]fir_x,
    output fft_valid,
    output reg [31:0]fft_d1, fft_d2, fft_d3, fft_d4, fft_d5, fft_d6, fft_d7, fft_d8,
    fft_d9, fft_d10, fft_d11, fft_d12, fft_d13, fft_d14, fft_d15, fft_d0
  );

`include "../sim/dat/Imag_Value_Ref.dat"
`include "../sim/dat/Real_Value_Ref.dat"

  reg[3:0]cs;
  parameter FFT_1=0,FFT_2=1,FFT_3=2,FFT_4=3,FFT_DONE=4,ALL_DONE= 5 ;
  reg signed [7:-32]fft_1_real[0:15];
  reg signed [7:-32]fft_2_real[0:15];
  reg signed [7:-32]fft_3_real[0:15];
  reg signed [7:-32]fft_4_real[0:15];

  reg signed [7:-32]fft_1_imag[0:15];
  reg signed [7:-32]fft_2_imag[0:15];
  reg signed [7:-32]fft_3_imag[0:15];
  reg signed [7:-32]fft_4_imag[0:15];

  reg signed [3:-16]real_1[0:15];
  reg signed [3:-16]real_2[0:15];
  reg signed [3:-16]real_3[0:15];
  reg signed [3:-16]real_4[0:15];
  reg signed [3:-16]imag_1[0:15];
  reg signed [3:-16]imag_2[0:15];
  reg signed [3:-16]imag_3[0:15];
  reg signed [3:-16]imag_4[0:15];

  wire signed [3:-16] fft_real [7:0];
  wire signed [3:-16] fft_imag [7:0];

  reg signed [19:0]x[15:0];

  assign  fft_real[0] = w_real_0;
  assign  fft_real[1] = w_real_1;
  assign  fft_real[2] = w_real_2;
  assign  fft_real[3] = w_real_3;
  assign  fft_real[4] = w_real_4;
  assign  fft_real[5] = w_real_5;
  assign  fft_real[6] = w_real_6;
  assign  fft_real[7] = w_real_7;

  assign  fft_imag[0] = w_imag_0;
  assign  fft_imag[1] = w_imag_1;
  assign  fft_imag[2] = w_imag_2;
  assign  fft_imag[3] = w_imag_3;
  assign  fft_imag[4] = w_imag_4;
  assign  fft_imag[5] = w_imag_5;
  assign  fft_imag[6] = w_imag_6;
  assign  fft_imag[7] = w_imag_7;

  integer i;
  always @(*)
  begin
    x[0]=fir_x[20*0+:20];
    x[1]=fir_x[20*1+:20];
    x[2]=fir_x[20*2+:20];
    x[3]=fir_x[20*3+:20];
    x[4]=fir_x[20*4+:20];
    x[5]=fir_x[20*5+:20];
    x[6]=fir_x[20*6+:20];
    x[7]=fir_x[20*7+:20];
    x[8]=fir_x[20*8+:20];
    x[9]=fir_x[20*9+:20];
    x[10]=fir_x[20*10+:20];
    x[11]=fir_x[20*11+:20];
    x[12]=fir_x[20*12+:20];
    x[13]=fir_x[20*13+:20];
    x[14]=fir_x[20*14+:20];
    x[15]=fir_x[20*15+:20];
  end
  always @(posedge clk ,posedge rst)
  begin
    if(rst)
    begin
      cs <= FFT_1;
    end
    else
    begin
      case (cs)
        FFT_1:
          cs<=ready?FFT_2:FFT_1;
        FFT_DONE:
          cs<=FFT_1;
        default:
          cs<=cs+1;
      endcase
    end
  end

  assign fft_valid = cs==FFT_DONE;


  always @(posedge clk,posedge rst)
  begin
    if(rst)
    begin
      for (i = 0;i<16 ;i=i+1 )
      begin
        fft_1_real[i] <= 0;
        fft_1_imag[i] <= 0;
      end
      for (i = 0;i<16 ;i=i+1 )
      begin
        fft_2_real[i] <= 0;
        fft_2_imag[i] <= 0;
      end
      for (i = 0;i<16 ;i=i+1 )
      begin
        fft_3_real[i] <= 0;
        fft_3_imag[i] <= 0;
      end
      for (i = 0;i<16 ;i=i+1 )
      begin
        fft_4_real[i] <= 0;
        fft_4_imag[i] <= 0;
      end
    end
    // FFT_1
    else
    begin
      for (i = 0;i<8 ;i=i+1 )
      begin
        fft_1_real[i] <= (x[i]+x[i+8])<<16;
        fft_1_imag[i] <= 0;
      end
      for (i = 0;i<8 ;i=i+1 )
      begin
        fft_1_real[i+8] <= (x[i]-x[i+8])*fft_real[i];//Q4.16*Q4.16=Q8.32
        fft_1_imag[i+8] <= (x[i]-x[i+8])*fft_imag[i];
      end



      // FFT_2
      for (i = 0;i<4 ;i=i+1 )
      begin
        fft_2_real[i] <= (real_1[i]+real_1[i+4])<<16;
        fft_2_imag[i] <= 0;
      end
      for (i = 0;i<4 ;i=i+1 )
      begin
        fft_2_real[i+4] <= (real_1[i]-real_1[i+4])*fft_real[i*2];
        fft_2_imag[i+4] <= (real_1[i]-real_1[i+4])*fft_imag[i*2];
      end
      for (i = 8;i<12 ;i=i+1 )
      begin
        fft_2_real[i] <= ((real_1[i]+real_1[i+4]))<<16;
        fft_2_imag[i] <= ((imag_1[i]+imag_1[i+4]))<<16;
      end
      for (i = 8;i<12 ;i=i+1 )
      begin
        fft_2_real[i+4] <= (real_1[i]-real_1[i+4])*fft_real[(i-8)*2] + (imag_1[i+4]-imag_1[i])*fft_imag[(i-8)*2];
        fft_2_imag[i+4] <= (real_1[i]-real_1[i+4])*fft_imag[(i-8)*2] + (imag_1[i]-imag_1[i+4])*fft_real[(i-8)*2];
      end



      // FFT_3
      fft_3_real[0] <=  (real_2[0]+real_2[2])<<16;
      fft_3_imag[0] <=  (imag_2[0]+imag_2[2])<<16;
      fft_3_real[1] <=  (real_2[1]+real_2[3])<<16;
      fft_3_imag[1] <=  (imag_2[1]+imag_2[3])<<16;
      fft_3_real[2] <=  (real_2[0]-real_2[2])*fft_real[0]+(imag_2[2]-imag_2[0])*fft_imag[0];
      fft_3_imag[2] <=  (real_2[0]-real_2[2])*fft_imag[0]+(imag_2[0]-imag_2[2])*fft_real[0];
      fft_3_real[3] <=  (real_2[1]-real_2[3])*fft_real[4]+(imag_2[3]-imag_2[1])*fft_imag[4];
      fft_3_imag[3] <=  (real_2[1]-real_2[3])*fft_imag[4]+(imag_2[1]-imag_2[3])*fft_real[4];

      fft_3_real[4] <=  (real_2[4]+real_2[6])<<16;
      fft_3_imag[4] <=  (imag_2[4]+imag_2[6])<<16;
      fft_3_real[5] <=  (real_2[5]+real_2[7])<<16;
      fft_3_imag[5] <=  (imag_2[5]+imag_2[7])<<16;
      fft_3_real[6] <=  (real_2[4]-real_2[6])*fft_real[0]+(imag_2[6]-imag_2[4])*fft_imag[0];
      fft_3_imag[6] <=  (real_2[4]-real_2[6])*fft_imag[0]+(imag_2[4]-imag_2[6])*fft_real[0];
      fft_3_real[7] <=  (real_2[5]-real_2[7])*fft_real[4]+(imag_2[7]-imag_2[5])*fft_imag[4];
      fft_3_imag[7] <=  (real_2[5]-real_2[7])*fft_imag[4]+(imag_2[5]-imag_2[7])*fft_real[4];

      fft_3_real[8] <=  (real_2[8]+real_2[10])<<16;
      fft_3_imag[8] <=  (imag_2[8]+imag_2[10])<<16;
      fft_3_real[9] <=  (real_2[9]+real_2[11])<<16;
      fft_3_imag[9] <=  (imag_2[9]+imag_2[11])<<16;
      fft_3_real[10] <=  (real_2[8]-real_2[10])*fft_real[0]+(imag_2[10]-imag_2[8])*fft_imag[0];
      fft_3_imag[10] <=  (real_2[8]-real_2[10])*fft_imag[0]+(imag_2[8]-imag_2[10])*fft_real[0];
      fft_3_real[11] <=  (real_2[9]-real_2[11])*fft_real[4]+(imag_2[11]-imag_2[9])*fft_imag[4];
      fft_3_imag[11] <=  (real_2[9]-real_2[11])*fft_imag[4]+(imag_2[9]-imag_2[11])*fft_real[4];

      fft_3_real[12] <=  (real_2[12]+real_2[14])<<16;
      fft_3_imag[12] <=  (imag_2[12]+imag_2[14])<<16;
      fft_3_real[13] <=  (real_2[13]+real_2[15])<<16;
      fft_3_imag[13] <=  (imag_2[13]+imag_2[15])<<16;
      fft_3_real[14] <=  (real_2[12]-real_2[14])*fft_real[0]+(imag_2[14]-imag_2[12])*fft_imag[0];
      fft_3_imag[14] <=  (real_2[12]-real_2[14])*fft_imag[0]+(imag_2[12]-imag_2[14])*fft_real[0];
      fft_3_real[15] <=  (real_2[13]-real_2[15])*fft_real[4]+(imag_2[15]-imag_2[13])*fft_imag[4];
      fft_3_imag[15] <=  (real_2[13]-real_2[15])*fft_imag[4]+(imag_2[13]-imag_2[15])*fft_real[4];



      // FFT_4
      fft_4_real[0] <= (real_3[0]+real_3[1])<<16;
      fft_4_imag[0] <= (imag_3[0]+imag_3[1])<<16;
      fft_4_real[1] <= (real_3[0]-real_3[1])*fft_real[0] + (imag_3[1]-imag_3[0])*fft_imag[0];
      fft_4_imag[1] <= (real_3[0]-real_3[1])*fft_imag[0] + (imag_3[0]-imag_3[1])*fft_real[0];

      fft_4_real[2] <= (real_3[2]+real_3[3])<<16;
      fft_4_imag[2] <= (imag_3[2]+imag_3[3])<<16;
      fft_4_real[3] <= (real_3[2]-real_3[3])*fft_real[0] + (imag_3[3]-imag_3[2])*fft_imag[0];
      fft_4_imag[3] <= (real_3[2]-real_3[3])*fft_imag[0] + (imag_3[2]-imag_3[3])*fft_real[0];

      fft_4_real[4] <= (real_3[4]+real_3[5])<<16;
      fft_4_imag[4] <= (imag_3[4]+imag_3[5])<<16;
      fft_4_real[5] <= (real_3[4]-real_3[5])*fft_real[0] + (imag_3[5]-imag_3[4])*fft_imag[0];
      fft_4_imag[5] <= (real_3[4]-real_3[5])*fft_imag[0] + (imag_3[4]-imag_3[5])*fft_real[0];

      fft_4_real[6] <= (real_3[6]+real_3[7])<<16;
      fft_4_imag[6] <= (imag_3[6]+imag_3[7])<<16;
      fft_4_real[7] <= (real_3[6]-real_3[7])*fft_real[0] + (imag_3[7]-imag_3[6])*fft_imag[0];
      fft_4_imag[7] <= (real_3[6]-real_3[7])*fft_imag[0] + (imag_3[6]-imag_3[7])*fft_real[0];

      fft_4_real[8] <= (real_3[8]+real_3[9])<<16;
      fft_4_imag[8] <= (imag_3[8]+imag_3[9])<<16;
      fft_4_real[9] <= (real_3[8]-real_3[9])*fft_real[0] + (imag_3[9]-imag_3[8])*fft_imag[0];
      fft_4_imag[9] <= (real_3[8]-real_3[9])*fft_imag[0] + (imag_3[8]-imag_3[9])*fft_real[0];

      fft_4_real[10] <= (real_3[10]+real_3[11])<<16;
      fft_4_imag[10] <= (imag_3[10]+imag_3[11])<<16;
      fft_4_real[11] <= (real_3[10]-real_3[11])*fft_real[0] + (imag_3[11]-imag_3[10])*fft_imag[0];
      fft_4_imag[11] <= (real_3[10]-real_3[11])*fft_imag[0] + (imag_3[10]-imag_3[11])*fft_real[0];

      fft_4_real[12] <= (real_3[12]+real_3[13])<<16;
      fft_4_imag[12] <= (imag_3[12]+imag_3[13])<<16;
      fft_4_real[13] <= (real_3[12]-real_3[13])*fft_real[0] + (imag_3[13]-imag_3[12])*fft_imag[0];
      fft_4_imag[13] <= (real_3[12]-real_3[13])*fft_imag[0] + (imag_3[12]-imag_3[13])*fft_real[0];

      fft_4_real[14] <= (real_3[14]+real_3[15])<<16;
      fft_4_imag[14] <= (imag_3[14]+imag_3[15])<<16;
      fft_4_real[15] <= (real_3[14]-real_3[15])*fft_real[0] + (imag_3[15]-imag_3[14])*fft_imag[0];
      fft_4_imag[15] <= (real_3[14]-real_3[15])*fft_imag[0] + (imag_3[14]-imag_3[15])*fft_real[0];

    end
  end


  always@(*)
  begin
    for (i = 0;i<16 ;i=i+1 )
    begin
      real_1[i] = fft_1_real[i][3:-16];
      imag_1[i] = fft_1_imag[i][3:-16];
    end
    for (i = 0;i<16 ;i=i+1 )
    begin
      real_2[i] = fft_2_real[i][3:-16];
      imag_2[i] = fft_2_imag[i][3:-16];
    end
    for (i = 0;i<16 ;i=i+1 )
    begin
      real_3[i] = fft_3_real[i][3:-16];
      imag_3[i] = fft_3_imag[i][3:-16];
    end
    fft_d0  = {fft_4_real[0][7:-8],fft_4_imag[0][7:-8]};
    fft_d8  = {fft_4_real[1][7:-8],fft_4_imag[1][7:-8]};
    fft_d4  = {fft_4_real[2][7:-8],fft_4_imag[2][7:-8]};
    fft_d12 = {fft_4_real[3][7:-8],fft_4_imag[3][7:-8]};
    fft_d2  = {fft_4_real[4][7:-8],fft_4_imag[4][7:-8]};
    fft_d10 = {fft_4_real[5][7:-8],fft_4_imag[5][7:-8]};
    fft_d6  = {fft_4_real[6][7:-8],fft_4_imag[6][7:-8]};
    fft_d14 = {fft_4_real[7][7:-8],fft_4_imag[7][7:-8]};
    fft_d1  = {fft_4_real[8][7:-8],fft_4_imag[8][7:-8]};
    fft_d9  = {fft_4_real[9][7:-8],fft_4_imag[9][7:-8]};
    fft_d5  = {fft_4_real[10][7:-8],fft_4_imag[10][7:-8]};
    fft_d13 = {fft_4_real[11][7:-8],fft_4_imag[11][7:-8]};
    fft_d3  = {fft_4_real[12][7:-8],fft_4_imag[12][7:-8]};
    fft_d11 = {fft_4_real[13][7:-8],fft_4_imag[13][7:-8]};
    fft_d7  = {fft_4_real[14][7:-8],fft_4_imag[14][7:-8]};
    fft_d15 = {fft_4_real[15][7:-8],fft_4_imag[15][7:-8]};
  end
endmodule

module ANA (
    input clk,rst,fft_valid,
    input [31:0]fft_d1, fft_d2, fft_d3, fft_d4, fft_d5, fft_d6, fft_d7, fft_d8,
    fft_d9, fft_d10, fft_d11, fft_d12, fft_d13, fft_d14, fft_d15, fft_d0,
    output reg[3:0]freq,
    output reg done
  );

  reg cs ;
  reg[3:0]cnt;
  reg signed[15:0]fft_real[15:0];
  reg signed[15:0]fft_imag[15:0];

  parameter IDLE =0,COMP=1 ;

  integer i;
  always @(posedge clk ,posedge rst)
  begin
    if(rst)
    begin
      cs <= IDLE;
      cnt<=1;
      done<=0;
    end
    else
    begin
      case (cs)
        IDLE:
        begin
          cs<=fft_valid?COMP:IDLE;
          cnt<=1;
          done<=0;
        end

        COMP:
        begin
          cs<=cnt==15? IDLE:COMP;
          cnt<=cnt+1;
          done<=cnt==15;
        end

      endcase
    end
  end
  always @(posedge clk ,posedge rst)
  begin
    if(rst)
    begin
      for (i =0 ;i<16 ;i=i+1 )
      begin
        fft_real[i] <= 0;
        fft_imag[i] <= 0;
      end
    end
    else if(fft_valid)
    begin
      fft_real[0] <= fft_d0[31:16];
      fft_real[1] <= fft_d1[31:16];
      fft_real[2] <= fft_d2[31:16];
      fft_real[3] <= fft_d3[31:16];
      fft_real[4] <= fft_d4[31:16];
      fft_real[5] <= fft_d5[31:16];
      fft_real[6] <= fft_d6[31:16];
      fft_real[7] <= fft_d7[31:16];
      fft_real[8] <= fft_d8[31:16];
      fft_real[9] <= fft_d9[31:16];
      fft_real[10]<= fft_d10[31:16];
      fft_real[11]<= fft_d11[31:16];
      fft_real[12]<= fft_d12[31:16];
      fft_real[13]<= fft_d13[31:16];
      fft_real[14]<= fft_d14[31:16];
      fft_real[15]<= fft_d15[31:16];
      fft_imag[0] <= fft_d0[15:0];
      fft_imag[1] <= fft_d1[15:0];
      fft_imag[2] <= fft_d2[15:0];
      fft_imag[3] <= fft_d3[15:0];
      fft_imag[4] <= fft_d4[15:0];
      fft_imag[5] <= fft_d5[15:0];
      fft_imag[6] <= fft_d6[15:0];
      fft_imag[7] <= fft_d7[15:0];
      fft_imag[8] <= fft_d8[15:0];
      fft_imag[9] <= fft_d9[15:0];
      fft_imag[10]<= fft_d10[15:0];
      fft_imag[11]<= fft_d11[15:0];
      fft_imag[12]<= fft_d12[15:0];
      fft_imag[13]<= fft_d13[15:0];
      fft_imag[14]<= fft_d14[15:0];
      fft_imag[15]<= fft_d15[15:0];
    end
  end
  wire [7:-32]temp1 = fft_real[freq]*fft_real[freq] + fft_imag[freq]*fft_imag[freq];//不能直接在()內做相乘後相加再比較，拉出來外面先接線就不會錯
  wire [7:-32]temp2 = fft_real[cnt] *fft_real[cnt]  + fft_imag[cnt] *fft_imag[cnt] ;
  always @(posedge clk,posedge rst )
  begin
    if(rst)
    begin
      freq<=0;
    end
    else if(cs == COMP)
    begin
      freq<=(temp1<temp2)?  cnt:freq;
    end
  end


endmodule
