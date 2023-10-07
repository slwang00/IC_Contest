module SME(
    input clk,
    input reset,
    input [7:0] chardata,
    input isstring,
    input ispattern,
    output reg match,
    output reg [4:0] match_index,
    output reg valid
  );


  parameter IDLE = 0,LOAD=1,COMPARE1=2,OUTPUT=3;
  reg [1:0] cs;
  reg [7:0] str [0:31];
  reg [7:0] pat [0:8];
  reg [5:0] str_index,s_t;
  reg [4:0] pat_index,p_t;
  reg [7:0] mask;
  reg match_wire;
  reg [4:0] i;
  reg update_pat,update_str;
  integer j;

  always @(*)
  begin
    match_wire = 1;
    for (j = 0;j<9 ;j=j+1 )//題目pattern有誤，最後一筆測資有9個字元，故pat register開9個
    begin:L1
      match_wire = match_wire & comp(pat[j],str[i+j],i,s_t,j,p_t);
    end
  end
  /*wire [0:8] match_list =
  {   comp(pat[0],str[i+0],i,s_t,0,p_t),
      comp(pat[1],str[i+1],i,s_t,1,p_t),
      comp(pat[2],str[i+2],i,s_t,2,p_t),
      comp(pat[3],str[i+3],i,s_t,3,p_t),
      comp(pat[4],str[i+4],i,s_t,4,p_t),
      comp(pat[5],str[i+5],i,s_t,5,p_t),
      comp(pat[6],str[i+6],i,s_t,6,p_t),
      comp(pat[7],str[i+7],i,s_t,7,p_t),
      comp(pat[8],str[i+8],i,s_t,8,p_t)};*/

  function comp;
    input [7:0]p,s;
    input [4:0]init,s_final;
    input [3:0]index,p_final;

    if(index<=p_t)
    case (p)
      8'h5e://^
      begin
        comp = (s==8'h20);
      end
      8'h2e://.
      begin
        comp = 1;
      end
      8'h24://$
      begin
        comp = (init+index==s_final+1)||(s==8'h20);
      end
      default:
        comp = (s==p);
    endcase
    else
    begin
      comp =1;
    end
  endfunction


  always @(posedge clk ,posedge reset)
  begin
    if(reset)
    begin
      cs <= IDLE;
    end
    else
    begin
      case (cs)
        IDLE:
        begin
          if(!reset)
          begin
            cs <= LOAD;
            str[0]<=chardata;
            str_index <= 1;
            pat_index <= 0;
          end
        end
        LOAD:
        begin
          valid<=0;
          match <= 0;
          match_index <= 0;
          if(!(ispattern || isstring))
          begin
            cs <= COMPARE1;
            s_t <= update_str? str_index-1:s_t;
            p_t <= update_pat? pat_index-1:p_t;
          end
          if(isstring)
          begin
            update_str <= 1;
            str[str_index]<=chardata;
            str_index <= str_index+1;
          end
          if(ispattern)
          begin
            update_pat <=1;
            pat[pat_index]<=chardata;
            pat_index <= pat_index+1;
          end
          i <= (pat[0]==8'h5e);
        end
        COMPARE1:
        begin
          update_pat <= 0;
          update_str <= 0;
          if(i<=s_t-p_t+1)
          begin
            if(match_wire)
            begin
              match_index <= (pat[0]==8'h5e)? i+1:i;
              cs <= OUTPUT;
              match <= 1;
            end
            else
            begin
              i <= i+1;
            end
          end
          else
          begin
            cs <= OUTPUT;
            match <= 0;
          end
        end
        OUTPUT:
        begin
          pat_index <= 0;
          str_index <= 0;
          valid <= 1;
          cs <= LOAD;
        end
      endcase
    end
  end

endmodule
