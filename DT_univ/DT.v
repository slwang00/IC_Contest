module DT (
    input    clk,
    input   reset,
    output  reg done ,
    output  reg sti_rd ,
    output reg [9:0] sti_addr ,
    input  [15:0] sti_di,
    output  reg res_wr ,
    output  reg res_rd ,
    output  reg [13:0] res_addr ,
    output  reg [7:0] res_do,
    input  [7:0] res_di
  );
  parameter START = 0, DATA_MOVE = 1, FORWARD = 2, BACKWARD = 3 ,DONE = 4;
  reg [2:0] cs;

  reg [4:0]cnt;
  //cs
  always @(posedge clk or negedge reset)
  begin
    if (!reset)
    begin
      cs <= START;
      done <= 0;
      sti_rd <= 1;
      sti_addr <= 0;
      res_wr <=1;
      res_rd <=0;
      res_addr <=0;
      res_do <= 0;
      cnt <= 0;
    end
    else
    case (cs)
      START:
      begin
        if(reset)begin
          cs <= DATA_MOVE;
          res_do[0] <= sti_di[15];
          cnt <= 1;
        end
      end
      DATA_MOVE:
      begin
        if(&sti_addr && cnt[3:0] ==15)begin
          cs <=  FORWARD;
          cnt <= 0;
          res_do <= 0;
          res_wr <= 0;
          res_rd <= 1;
          res_addr <= 129;
          cnt[2:0]<=0;
        end

        res_do[0] <= sti_di[15-cnt[3:0]];
        res_addr <= res_addr + 1;
        cnt[3:0] <= cnt[3:0] +1 ;

        sti_addr <= cnt[3:0] == 15? sti_addr +1:sti_addr;
      end
      FORWARD:
      begin
        cs <= res_addr == 16254 && cnt[2:0] == 5? BACKWARD:FORWARD;
        case (cnt[2:0])
          0:
          begin
            cnt[2:0] <= (res_di == 0)? 5:1;
            res_addr <= (res_di == 0)? res_addr: res_addr-1;
          end
          1:
          begin
            res_do <= res_di;
            res_addr <= res_addr - 128;
            cnt[2:0] <= 2;
          end
          2:
          begin
            res_do <= (res_di < res_do)? res_di:res_do;
            res_addr <= res_addr +1;
            cnt[2:0] <=3;
          end
          3:
          begin
            res_do <= (res_di < res_do)? res_di:res_do;
            res_addr <= res_addr +1;
            cnt[2:0] <=4;
          end
          4:
          begin
            res_do <= (res_di < res_do)? res_di+1:res_do+1;
            res_addr <= res_addr +127;
            res_rd <= 0;
            res_wr <= 1;
            cnt[2:0]<= 5;
          end
          5:
          begin
            if(res_addr == 16254)begin
              res_do <= 0;
              res_wr <= 0;
              res_rd <= 1;
              res_addr <= 16254;
              cnt[2:0] <=0;
            end
            res_do <= 0;
            res_rd <= 1;
            res_wr <= 0;
            res_addr <= res_addr +1;
            cnt[2:0] <= 0;
          end
        endcase
      end
      BACKWARD:
      begin
        cs <= (res_addr == 1)&&cnt[2:0] == 6? DONE:BACKWARD;
        case (cnt[2:0])
          0:
          begin
            if(res_di == 0)begin
              cnt[2:0] <=  5;
            end
            else begin 
              res_do <= res_di;
              res_addr <= res_addr +1;
              cnt[2:0] <= 1;
            end
          end
          1:
          begin
            res_do <= (res_di+1<res_do)? res_di+1 : res_do;
            res_addr <= res_addr + 126;
            cnt[2:0] <= 2;
          end
          2:
          begin
            res_do <= (res_di+1<res_do)? res_di+1 : res_do;
            res_addr <= res_addr + 1;
            cnt[2:0] <= 3;
          end
          3:
          begin
            res_do <= (res_di+1<res_do)? res_di+1 : res_do;
            res_addr <= res_addr + 1;
            cnt[2:0] <= 4;
          end
          4:
          begin
            res_do <= (res_di+1<res_do)? res_di+1 : res_do;
            res_addr <= res_addr - 129;
            res_wr <= 1;
            res_rd <= 0;
            cnt[2:0] <= 5;
          end
          5:
          begin
            res_do <= 0;
            res_addr <= (res_addr == 1)? 0:res_addr - 1;
            res_rd <= 1;
            res_wr <= 0;
            cnt[2:0] <= 0;
            done <= (res_addr == 1);
          end
        endcase
      end
    endcase
  end
endmodule
