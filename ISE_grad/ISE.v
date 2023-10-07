// 10/5 19:30
`timescale 1ns/10ps
module ISE( clk, reset, image_in_index, pixel_in, busy, out_valid, color_index, image_out_index);
  input               clk;
  input               reset;
  input       [4:0]   image_in_index;
  input       [23:0]  pixel_in;
  output           busy;
  output           out_valid;
  output   [1:0]   color_index;
  output   [4:0]   image_out_index;

  reg [5:0]cs;
  reg [5:0]x,y;
  reg [15:0]pix_index;
  reg [4:0] img_index;

  reg [15:0]pix_cnt[2:0];
  reg [23:0]cur_img_int[2:0];

  reg  [1:-13]img_int  [0:31];//(type,int)=Q2.(10+3)
  reg [1:0] img_type [0:31];
  reg [4:0] out_index[0:31];

  reg [1:0]max_type;
  reg [21:0]max_int;
  reg [15:0]max_cnt;
  reg [1:0]pix_type;
  wire rst = reset;

  parameter LOAD = 0,STORE=1 ,SORT = 2, OUT=3,R=2'd0,G=2'd1,B=2'd2;

  //control
  always @(posedge clk ,posedge rst)
  begin
    if(rst)
    begin
      x<=0;
      y<=0;
      cs<=LOAD;
      pix_index<=0;
      img_index<=0;
    end
    else
    begin
      case (cs)
        LOAD:
        begin
          pix_index<=pix_index+1;
          if(pix_index==16383)
            cs<=STORE;
        end
        STORE:
        begin
          img_index<=img_index+1;
          pix_index<=0;
          if(img_index==31)
            cs<=SORT;
          else
            cs<=LOAD;
        end
        SORT:
        begin
          /*做bubble sort時如果想要把control和data path分開寫，
          比較的時候只在y<31-x時做，y=31時是不能做比較的，所以在y=30-x時下一個要馬上接0，
          x=29且y=1時cs下一個就要接OUT了。
          居然犯了這個錯，而且rtl 模擬居然還是正確的，但gate模擬時就錯了*/
          if(y!=30-x)
          begin
            y<=y+1;
          end
          else
          begin
            y<=0;
            x<=x+1;
            cs <= (x==29)?OUT:SORT;
          end
        end

      endcase
    end
  end

  always @(*)
  begin
    if( pixel_in[23:16] >= pixel_in[15:8] && pixel_in[23:16] >= pixel_in[7:0] ) // Red
      pix_type = R;
    else if( pixel_in[15:8] >= pixel_in[7:0] && pixel_in[15:8] > pixel_in[23:16] ) // Green
      pix_type = G;
    else
      pix_type = B;
  end
  always @(*)
  begin
    if(pix_cnt[R]>pix_cnt[G]&&pix_cnt[R]>pix_cnt[B])
    begin
      max_type = R;
      max_cnt = pix_cnt[R];
      max_int = cur_img_int[R];
    end
    else if(pix_cnt[G]>pix_cnt[B]&&pix_cnt[G]>pix_cnt[R])
    begin
      max_type = G;
      max_cnt = pix_cnt[G];
      max_int = cur_img_int[G];
    end
    else
    begin
      max_type = B;
      max_cnt = pix_cnt[B];
      max_int = cur_img_int[B];
    end
  end

  //storage device
  always @(posedge clk ,posedge rst)
  begin
    if(rst)
    begin
      pix_cnt[R]<=0;
      pix_cnt[G]<=0;
      pix_cnt[B]<=0;

      cur_img_int[R]<=0;
      cur_img_int[G]<=0;
      cur_img_int[B]<=0;
    end
    else
    begin
      case (cs)
        LOAD:
        begin
          if( pix_type == R )
          begin
            pix_cnt[R]<=pix_cnt[R]+1;
            cur_img_int[R]<=cur_img_int[R]+pixel_in[23:16];
          end
          else if(pix_type == G )
          begin
            pix_cnt[G]<=pix_cnt[G]+1;
            cur_img_int[G]<=cur_img_int[G]+pixel_in[15:8];
          end
          else
          begin
            pix_cnt[B]<=pix_cnt[B]+1;
            cur_img_int[B]<=cur_img_int[B]+pixel_in[7:0];
          end
        end
        STORE:
        begin
          pix_cnt[R]<=0;
          pix_cnt[G]<=0;
          pix_cnt[B]<=0;

          cur_img_int[R]<=0;
          cur_img_int[G]<=0;
          cur_img_int[B]<=0;
        end
      endcase
    end
  end

  integer i;
  always @(posedge clk ,posedge rst)
  begin
    if(rst)
    begin
      for (i = 0;i<32 ;i=i+1 )
      begin
        img_int [i] <= 0;
        img_type[i] <= 0;
        out_index[i]<= i;
      end
    end
    else
    begin
      case (cs)
        STORE:
        begin
          img_type[31]<=max_type;
          img_int[31][-1:-13]<={max_int,3'b0}/max_cnt;//多3bit，讓小數點後3位也考慮進去
          img_int[31][1:0]<=max_type;
          for (i = 1;i<32 ;i=i+1 )
          begin
            img_int[i-1] <=img_int[i];
            img_type[i-1] <=img_type[i];
          end
        end
        SORT:
        begin
          if(img_int[y]>img_int[y+1])
          begin
            img_int[y+1]  <= img_int[y];
            img_int[y]    <= img_int[y+1];
            img_type[y+1] <= img_type[y];
            img_type[y]   <= img_type[y+1];
            out_index[y+1] <= out_index[y];
            out_index[y]   <= out_index[y+1];
          end
        end
        OUT:
        begin
          for (i = 1;i<32 ;i=i+1 )
          begin
            img_type[i-1] <=img_type[i];
            out_index[i-1]<= out_index[i];
          end
        end
      endcase
    end
  end

  assign busy = cs == STORE;
  assign out_valid = cs == OUT;
  assign color_index = img_type[0];
  assign image_out_index=out_index[0];
endmodule
