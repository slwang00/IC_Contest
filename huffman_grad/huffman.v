module huffman(
    input clk,
    input reset,
    input gray_valid,
    input [7:0] gray_data,
    output reg CNT_valid,
    output [7:0] CNT1, CNT2, CNT3, CNT4, CNT5, CNT6,
    output reg code_valid,
    output  [7:0] HC1, HC2, HC3, HC4, HC5, HC6,
    output  [7:0] M1, M2, M3, M4, M5, M6
  );

  reg [2:0]cs;

  parameter IDLE=0,LOAD = 1,HUFF=2,CODE=3,OUTPUT=4;

  reg [7:0] CNT_list[1:6];
  reg [3:0] symbol_list[1:6];
  reg [3:0] i,j;
  reg [7:0] M[1:6],HC[1:6];
  reg [2:0] min1_i,min2_i;
  reg [7:0] min1_val,min2_val;

  integer a;

  assign CNT1 = CNT_list[1];
  assign CNT2 = CNT_list[2];
  assign CNT3 = CNT_list[3];
  assign CNT4 = CNT_list[4];
  assign CNT5 = CNT_list[5];
  assign CNT6 = CNT_list[6];

  //bit-correction///////////
  assign M1 = 8'hff>>(8-M[1]);//M[i] is represented number of valid bits
  assign M2 = 8'hff>>(8-M[2]);
  assign M3 = 8'hff>>(8-M[3]);
  assign M4 = 8'hff>>(8-M[4]);
  assign M5 = 8'hff>>(8-M[5]);
  assign M6 = 8'hff>>(8-M[6]);

  assign HC1 = HC[1]>>(8-M[1]);
  assign HC2 = HC[2]>>(8-M[2]);
  assign HC3 = HC[3]>>(8-M[3]);
  assign HC4 = HC[4]>>(8-M[4]);
  assign HC5 = HC[5]>>(8-M[5]);
  assign HC6 = HC[6]>>(8-M[6]);
  /////////////////////////////

  always @(posedge clk ,posedge reset)
  begin
    if(reset)
    begin
      cs <=IDLE;
      i<=1;
      j<=1;
      min1_i<=1;
      min2_i<=1;
      min1_val<=8'hff;
      min2_val<=8'hff;
      code_valid <= 0;
      CNT_valid <= 0;
      for (a = 1;a<=6 ;a=a+1 )
      begin
        CNT_list[a]<=0;
      end
      for (a = 1;a<=6 ;a=a+1 )
      begin
        symbol_list[a]<=a;
        HC[a]<=0;
        M[a]<=0;
      end
    end
    else
    begin
      case (cs)
        IDLE:
        begin
          cs <= (gray_valid)? LOAD:IDLE;
          CNT_list[gray_data] <= (gray_valid)? CNT_list[gray_data]+1:0;
        end
        LOAD:
        begin
          if(gray_valid)
          begin
            CNT_list[gray_data] <= CNT_list[gray_data]+1;
          end
          else
          begin
            CNT_valid <= 1;
            cs <= HUFF;
          end
        end
        HUFF:
        begin//min1 bigger than min2
          CNT_valid<=0;
          if(i<=5)
          begin
            i <= i+1;
          end
          else
          begin
            cs <= CODE;
            i<=1;
          end
          //find min and second_min////////////////////////////////////////////////////////////////////
          if(CNT_list[i]<min2_val || CNT_list[i]==min2_val && symbol_list[i]>symbol_list[min2_i])
          begin
            min1_i <= min2_i;
            min1_val <= min2_val;
            min2_i <= i;
            min2_val <= CNT_list[i];
          end
          else if(CNT_list[i]<min1_val || CNT_list[i]==min1_val && symbol_list[i]>symbol_list[min1_i])
          begin
            min1_i <= i;
            min1_val <= CNT_list[i];
          end
          /////////////////////////////////////////////////////////////////////////////////////////////
        end
        CODE:
        begin
          /////////////////////////////////////////////////////////////////////////////////////////////
          for (a =1 ;a<=6 ;a=a+1 )
          begin
            if(symbol_list[a]==symbol_list[min1_i])
            begin
              HC[a] <= HC[a]>>1;
              M[a] <= M[a]+1;
              symbol_list[a] <= j +6;
            end
            else if(symbol_list[a]==symbol_list[min2_i])
            begin
              HC[a] <= {1'b1,HC[a][7:1]};
              M[a] <= M[a]+1;
              symbol_list[a] <= j +6;
            end
          end
          /////////////////////////////////////////////////////////////////////////////////////////////

          CNT_list[min2_i] <= 8'hff;//in order not to join in comparison,the value of min_index is set to the maximun
          CNT_list[min1_i] <= CNT_list[min1_i]+CNT_list[min2_i];

          if(j<=4)
          begin
            i<=1;
            j <= j+1;
            cs <= HUFF;

            min1_i <= 1;
            min2_i <= 1;
            min1_val<=8'hff;
            min2_val<=8'hff;
          end
          else
          begin
            j<=0;
            cs <= OUTPUT;
          end
        end
        OUTPUT:
        begin
          code_valid <= 1;
          cs <= OUTPUT;
        end
      endcase
    end
  end
endmodule
