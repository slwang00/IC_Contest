module LCD_CTRL(clk, reset, cmd, cmd_valid, IROM_Q, IROM_rd, IROM_A, IRAM_valid, IRAM_D, IRAM_A, busy, done);
  input clk;
  input reset;
  input [3:0] cmd;
  input cmd_valid;
  input [7:0] IROM_Q;
  output IROM_rd;
  output [5:0] IROM_A;
  output IRAM_valid;
  output [7:0] IRAM_D;
  output [5:0] IRAM_A;
  output reg busy;
  output reg done;

  parameter IDLE = 12,
            LD = 13,
            CMD = 14,
            
            WR = 0,
            SFT_U =1,
            SFT_D = 2,
            SFT_L = 3,
            SFT_R = 4,
            MAX = 5,
            MIN = 6,
            AVG = 7,
            CC_R = 8,
            C_R = 9,
            M_X = 10,
            M_Y = 11,
            DONE = 15;
            

  reg   [3:0] cs;
  reg   [7:0] reg_space[0:63];
  reg   [2:0]op_pt_x;
  reg   [2:0]op_pt_y;
  wire [5:0]op_init;
  reg [5:0] cnt;

  
  assign op_init = {op_pt_y,op_pt_x};
  assign IROM_rd = (cs == LD);
  assign IRAM_D = reg_space[IRAM_A];
  assign IRAM_A = cnt;
  assign IROM_A = cnt;
  assign IRAM_valid = cs == WR ;

  wire [7:0] max_temp1 = (reg_space[op_init]>reg_space[op_init+1])? reg_space[op_init]:reg_space[op_init+1];
  wire [7:0] max_temp2 = (reg_space[op_init+8]>reg_space[op_init+9])? reg_space[op_init+8]:reg_space[op_init+9];
  wire [7:0] max = (max_temp1>max_temp2)? max_temp1:max_temp2;


  wire [7:0] min_temp1 = (reg_space[op_init]<reg_space[op_init+1])? reg_space[op_init]:reg_space[op_init+1];
  wire [7:0] min_temp2 = (reg_space[op_init+8]<reg_space[op_init+9])? reg_space[op_init+8]:reg_space[op_init+9];
  wire [7:0] min = (min_temp1<min_temp2)? min_temp1:min_temp2;

  wire [10:0] avg_temp = (reg_space[op_init] + reg_space[op_init+1] + reg_space[op_init+8] + reg_space[op_init+9]);//note: once add will extend 1 bit,so need to add 3 bit here 
  wire [7:0] avg = avg_temp>>2;

  always @(posedge clk ,posedge reset)
  begin
    if(reset)
      done <= 0;
    else if(cs == WR && IRAM_A==63)
      done <=1;
  end

  integer i;
  always @(posedge clk ,posedge reset)
  begin
    if(reset)
    begin
      op_pt_x <= 3;
      op_pt_y <= 3;
      cs <=IDLE;
      busy <= 1;
    end
    else
    case (cs)
      IDLE:
        cs <=!reset? LD:IDLE;
      LD:
      begin
        reg_space[IROM_A]<= IROM_Q ;
        cs <= cnt == 63 ? CMD:LD;
        busy <= !(cnt == 63);
      end
      CMD:
      begin
        busy<=1;
        cs <= cmd;
      end
      WR:
      begin
        cs <= (IRAM_A == 63)? CMD:WR;
      end
      SFT_U:
      begin
        op_pt_y <= (op_pt_y !=0)? op_pt_y-1:op_pt_y;
        cs <= CMD;
        busy <= 0;
      end
      SFT_D:
      begin
        op_pt_y <= (op_pt_y !=6)? op_pt_y+1:op_pt_y;
        cs <= CMD;
        busy <= 0;
      end
      SFT_L:
      begin
        op_pt_x <= (op_pt_x !=0)? op_pt_x-1:op_pt_x;
        cs <= CMD;
        busy <= 0;
      end
      SFT_R:
      begin
        op_pt_x <= (op_pt_x !=6)? op_pt_x+1:op_pt_x;
        cs <= CMD;
        busy <= 0;
      end
      MAX:
      begin
        reg_space[op_init]  <=max;
        reg_space[op_init+1]<=max;
        reg_space[op_init+8]<=max;
        reg_space[op_init+9]<=max;
        cs <= CMD;
        busy <= 0;
      end
      MIN:
      begin
        reg_space[op_init]  <=min;
        reg_space[op_init+1]<=min;
        reg_space[op_init+8]<=min;
        reg_space[op_init+9]<=min;
        cs <= CMD;
        busy <= 0;
      end
      AVG:
      begin
        reg_space[op_init]  <=avg;
        reg_space[op_init+1]<=avg;
        reg_space[op_init+8]<=avg;
        reg_space[op_init+9]<=avg;
        cs <= CMD;
        busy <= 0;
      end
      CC_R:
      begin
        reg_space[op_init]  <=reg_space[op_init+1];
        reg_space[op_init+1]<=reg_space[op_init+9];
        reg_space[op_init+8]<=reg_space[op_init];
        reg_space[op_init+9]<=reg_space[op_init+8];
        cs <= CMD;
        busy <= 0;
      end
      C_R:
      begin
        reg_space[op_init]  <=reg_space[op_init+8];
        reg_space[op_init+1]<=reg_space[op_init];
        reg_space[op_init+8]<=reg_space[op_init+9];
        reg_space[op_init+9]<=reg_space[op_init+1];
        cs <= CMD;
        busy <= 0;
      end
      M_X:
      begin
        reg_space[op_init]  <=reg_space[op_init+8];
        reg_space[op_init+1]<=reg_space[op_init+9];
        reg_space[op_init+8]<=reg_space[op_init];
        reg_space[op_init+9]<=reg_space[op_init+1];
        cs <= CMD;
        busy <= 0;
      end
      M_Y:
      begin
        reg_space[op_init]  <=reg_space[op_init+1];
        reg_space[op_init+1]<=reg_space[op_init];
        reg_space[op_init+8]<=reg_space[op_init+9];
        reg_space[op_init+9]<=reg_space[op_init+8];
        cs <= CMD;
        busy <= 0;
      end
      DONE:
        cs <= IDLE;
    endcase
  end

  always @(posedge clk ,posedge reset)
  begin
    if(reset)
      cnt <= 0;
    else if(cs == LD)
      cnt <= cnt +1;
    else if(cs == WR)
      cnt <= cnt +1;
  end
endmodule



