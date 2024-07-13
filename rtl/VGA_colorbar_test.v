module VGA_colorbar_test(
OSC_50,     //原CLK2_50时钟信号
VGA_CLK,    //VGA自时钟
VGA_HS,     //行同步信号
VGA_VS,     //场同步信号
VGA_BLANK,  //复合空白信号控制信号  当BLANK为低电平时模拟视频输出消隐电平，此时从R9~R0,G9~G0,B9~B0输入的所有数据被忽略
VGA_SYNC,   //符合同步控制信号      行时序和场时序都要产生同步脉冲
VGA_R,      //VGA绿色
VGA_B,      //VGA蓝色
VGA_G);     //VGA绿色
 input OSC_50;     //外部时钟信号CLK2_50
 output VGA_CLK,VGA_HS,VGA_VS,VGA_BLANK,VGA_SYNC;
 output [7:0] VGA_R,VGA_B,VGA_G;
 parameter H_FRONT = 16;     //行同步前沿信号周期长
 parameter H_SYNC = 96;      //行同步信号周期长
 parameter H_BACK = 48;      //行同步后沿信号周期长
 parameter H_ACT = 640;      //行显示周期长
 parameter H_BLANK = H_FRONT+H_SYNC+H_BACK;        //行空白信号总周期长
 parameter H_TOTAL = H_FRONT+H_SYNC+H_BACK+H_ACT;  //行总周期长耗时
 parameter V_FRONT = 11;     //场同步前沿信号周期长
 parameter V_SYNC = 2;       //场同步信号周期长
 parameter V_BACK = 31;      //场同步后沿信号周期长
 parameter V_ACT = 480;      //场显示周期长
 parameter V_BLANK = V_FRONT+V_SYNC+V_BACK;        //场空白信号总周期长
 parameter V_TOTAL = V_FRONT+V_SYNC+V_BACK+V_ACT;  //场总周期长耗时
 reg [10:0] H_Cont;        //行周期计数器
 reg [10:0] V_Cont;        //场周期计数器
 wire [7:0] VGA_R;         //VGA红色控制线
 wire [7:0] VGA_G;         //VGA绿色控制线
 wire [7:0] VGA_B;         //VGA蓝色控制线
 reg VGA_HS;
 reg VGA_VS;
 reg [10:0] X;             //当前行第几个像素点
 reg [10:0] Y;             //当前场第几行
 reg CLK_25;
 always@(posedge OSC_50)begin 
      CLK_25=~CLK_25;         //时钟
 end 
 
 assign VGA_SYNC = 1'b0;   //同步信号低电平
 assign VGA_BLANK = ~((H_Cont<H_BLANK)||(V_Cont<V_BLANK));  //当行计数器小于行空白总长或场计数器小于场空白总长时，空白信号低电平
 assign VGA_CLK = ~CLK_to_DAC;  //VGA时钟等于CLK_25取反
 assign CLK_to_DAC = CLK_25;
 
 always@(posedge CLK_to_DAC)begin
        if(H_Cont<H_TOTAL)           //如果行计数器小于行总时长
            H_Cont<=H_Cont+1'b1;      //行计数器+1
        else H_Cont<=0;              //否则行计数器清零
        if(H_Cont==H_FRONT-1)        //如果行计数器等于行前沿空白时间-1
            VGA_HS<=1'b0;             //行同步信号置0
        if(H_Cont==H_FRONT+H_SYNC-1) //如果行计数器等于行前沿+行同步-1
            VGA_HS<=1'b1;             //行同步信号置1
        if(H_Cont>=H_BLANK)          //如果行计数器大于等于行空白总时长
            X<=H_Cont-H_BLANK;        //X等于行计数器-行空白总时长   （X为当前行第几个像素点）
        else X<=0;                   //否则X为0
end
 
 always@(posedge VGA_HS)begin
        if(V_Cont<V_TOTAL)           //如果场计数器小于行总时长
            V_Cont<=V_Cont+1'b1;      //场计数器+1
        else V_Cont<=0;              //否则场计数器清零
        if(V_Cont==V_FRONT-1)       //如果场计数器等于场前沿空白时间-1
            VGA_VS<=1'b0;             //场同步信号置0
        if(V_Cont==V_FRONT+V_SYNC-1) //如果场计数器等于行前沿+场同步-1
            VGA_VS<=1'b1;             //场同步信号置1
        if(V_Cont>=V_BLANK)          //如果场计数器大于等于场空白总时长
            Y<=V_Cont-V_BLANK;        //Y等于场计数器-场空白总时长    （Y为当前场第几行）  
        else Y<=0;                   //否则Y为0
end
 
 reg valid_yr;
 
 always@(posedge CLK_to_DAC)begin
    if(V_Cont == 10'd32)         //场计数器=32时
        valid_yr<=1'b1;           //行输入激活
    else if(V_Cont==10'd512)     //场计数器=512时
        valid_yr<=1'b0;           //行输入冻结
 end
 
 wire valid_y=valid_yr;       //连线   
 reg valid_r;     
 
 always@(posedge CLK_to_DAC)begin
    if((H_Cont == 10'd32)&&valid_y)     //行计数器=32时
        valid_r<=1'b1;                   //像素输入激活
    else if((H_Cont==10'd512)&&valid_y) //行计数器=512时 
        valid_r<=1'b0;                   //像素输入冻结
 end
 
 wire valid = valid_r;               //连线
 assign x_dis=X;       //连线X
 assign y_dis=Y;       //连线Y
 // reg[7:0] char_bit;
 // always@(posedge CLK_to_DAC)
 //     if(X==10'd144)char_bit<=9'd240;   //当显示到144像素时准备开始输出图像数据
 //     else if(X>10'd144&&X<10'd384)     //左边距屏幕144像素到416像素时    416=144+272（图像宽度）
 //         char_bit<=char_bit-1'b1;       //倒着输出图像信息
         
 reg[29:0] vga_rgb;                //定义颜色缓存
 always@(posedge CLK_to_DAC) begin
     if(X>=0&&X<200)begin    //X控制图像的横向显示边界：左边距屏幕左边144像素  右边界距屏幕左边界416像素
         vga_rgb<=30'hffffffffff;   //白色
     end
     else if(X>=200&&X<400)begin
         vga_rgb<=30'hf00ff65f1f;   
     end
     else if(X>=400&&X<600)begin
         vga_rgb<=30'h9563486251; 
     end
     else begin
         vga_rgb<=30'h5864928654; 
     end
 end
 assign VGA_R=vga_rgb[23:16];
 assign VGA_G=vga_rgb[15:8];
 assign VGA_B=vga_rgb[7:0];
endmodule