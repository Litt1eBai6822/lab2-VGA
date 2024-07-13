实验二-基于FPGA的VGA协议实现
------------------------------

#### 任务要求：

#### 1. 深入了解VGA协议，理解不同显示模式下的VGA控制时序参数（行频、场频、水平/垂直同步时钟周期、显示后沿/前沿等概念和计算方式）；

##### VGA协议是一种用于计算机图形显示的标准协议。在不同的显示模式下，VGA协议的控制时序参数会有所不同。以下是VGA协议控制时序参数的一些概念和计算方式：

    行频（Horizontal Frequency）：每秒钟图像中水平扫描线的数量。它与每行的像素数和水平同步时钟周期有关。计算公式为：水平同步时钟频率 / （每行像素数 + 水平同步时钟周期）。

    场频（Vertical Frequency）：每秒钟图像中场的数量。它与每个场中的行数和垂直同步时钟周期有关。计算公式为：行频 / （每个场中的行数 + 垂直同步时钟周期）。

    水平同步时钟周期（Horizontal Sync Clock）：每行像素传输完毕后，水平同步信号的持续时间。它与每行像素数和行频有关。计算公式为：（水平前沿到水平后沿的时间 + 水平同步信号宽度） x 行频。

    垂直同步时钟周期（Vertical Sync Clock）：每个场行传输完毕后，垂直同步信号的持续时间。它与每个场中的行数和场频有关。计算公式为：（垂直前沿到垂直后沿的时间 + 垂直同步信号宽度） x 场频。

    显示前沿（Front Porch）：每行像素传输完毕后，开始水平同步信号之前的时间。它与水平同步信号宽度和行频有关。计算公式为：水平前沿到水平同步信号之间的时间。

    显示同步（Sync Width）：水平同步信号的宽度，也就是保持在低电平状态的时间。它与水平同步时钟周期和行频有关。计算公式为：水平同步信号持续时间。

    显示后沿（Back Porch）：水平同步信号结束后，下一行像素开始传输之前的时间。它与行频和水平同步时钟周期有关。计算公式为：水平同步信号结束到下一行像素开始传输之间的时间。

**VGA接口即电脑采用VGA标准输出数据的专用接口。VGA接口共有15针，分成3排，每排5个孔，显卡上应用最为广泛的接口类型，绝大多数显卡都带有此种接口。它传输红、绿、蓝模拟信号以及同步信号(水平和垂直信号)。VGA显示器具有成本低、结构简单、应用灵活的优点。**

#### 2. 通过Verilog编程，在至少2种显示模式下（640*480@60Hz,1024*768@75Hz）分别实现以下VGA显示，并对照VGA协议信号做时序分析：

#### 1）屏幕上显示彩色条纹；

**代码：**

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

#### 2）显示自定义的汉字字符（姓名-学号）；

**代码：**

    module VGA_test(
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
     always@(posedge OSC_50)
        begin 
          CLK_25=~CLK_25;         //时钟
        end 
        assign VGA_SYNC = 1'b0;   //同步信号低电平
        assign VGA_BLANK = ~((H_Cont<H_BLANK)||(V_Cont<V_BLANK));  //当行计数器小于行空白总长或场计数器小于场空白总长时，空白信号低电平
        assign VGA_CLK = ~CLK_to_DAC;  //VGA时钟等于CLK_25取反
        assign CLK_to_DAC = CLK_25;
     always@(posedge CLK_to_DAC)
        begin
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
     always@(posedge VGA_HS)
        begin
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
     always@(posedge CLK_to_DAC)
        if(V_Cont == 10'd32)         //场计数器=32时
            valid_yr<=1'b1;           //行输入激活
        else if(V_Cont==10'd512)     //场计数器=512时
            valid_yr<=1'b0;           //行输入冻结
        wire valid_y=valid_yr;       //连线   
        reg valid_r;            
     always@(posedge CLK_to_DAC)   
        if((H_Cont == 10'd32)&&valid_y)     //行计数器=32时
            valid_r<=1'b1;                   //像素输入激活
        else if((H_Cont==10'd512)&&valid_y) //行计数器=512时 
            valid_r<=1'b0;                   //像素输入冻结
        wire valid = valid_r;               //连线
        wire[10:0] x_dis;     //像素显示控制信号
        wire[10:0] y_dis;     //行显示控制信号
        assign x_dis=X;       //连线X
        assign y_dis=Y;       //连线Y
            parameter
        char_line00=272'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF,
        char_line01=272'h00000000000000000000000000000000000000000000000000000000000000000000,
        char_line02=272'h00400C0000000000000000000000000000C008000000000000000000000000000000,
        char_line03=272'h00700E0000000180000000000000000000E00C0000000000000000800180000000C0,
        char_line04=272'h00600C00000003C0000000000000000000C01C0000000000000000FFFF80000001E0,
        char_line05=272'h00600C3003FFFC000000000000000080008018000000000000800080018003FFFE00,
        char_line06=272'h1FFFFFF8000180007FFE7FF003C80380008018007C1F03C803800080018000000000,
        char_line07=272'h00600C0000018000180E18180E3803800104301018040E3803800080018000000000,
        char_line08=272'h00600C00000180001802180C080803800FFE30381804080803800080018000000000,
        char_line09=272'h00600C000001800018031806180802800C0C7FF818041808028000FFFF8000000000,
        char_line0a=272'h007FFC000001800018011806300406C00C0C60300C08300406C00080018000000000,
        char_line0b=272'h00600C000001800018001806300404C00C0CC0300C08300404C00080018000000018,
        char_line0c=272'h00600C000001801018081806200004C00C0C80300C08200004C0008001800000003C,
        char_line0d=272'h007FFC000001803818081806600004C00C0D00300C08600004C0008001803FFFFFFE,
        char_line0e=272'h00600C003FFFFFFC1818180C60000C600C0D4030061060000C6000FFFF8000018000,
        char_line0f=272'h00600C10000180001FF81818600008600C0E20300610600008600080010000018000,
        char_line10=272'h00600C380001800018181FF0600008600C0C10300610600008600008200000418000,
        char_line11=272'h3FFFFFFC0001800018081800600008600FFC1830073060000860000C382000718800,
        char_line12=272'h003208000001800018081800603F1FF00C0C18300320603F1FF0080C307000E18600,
        char_line13=272'h00618C000001800018001800600C10300C0C0C300320600C10300C0C307000C18300,
        char_line14=272'h00C106000001800018001800600C10300C0C08300320600C1030060C30C001818180,
        char_line15=272'h018101C00001800018001800300C10300C0C003001C0300C1030030C30C0038180C0,
        char_line16=272'h030104FC0001800018001800300C30300C0C003001C0300C3030038C318003018060,
        char_line17=272'h0C010E380001800018001800180C20180C0C003001C0180C2018018C330006018070,
        char_line18=272'h187FF0000001800018001800180C20180C0C003001C0180C2018018C36000C018038,
        char_line19=272'h6001000000018000180018000C1060180C0C003000800C106018008C380018018038,
        char_line1a=272'h00010000000180007E007E0003E0F83E0C0C0030008003E0F83E000C301010018010,
        char_line1b=272'h00010000003F800000000000000000000FFC0C60000000000000000C303820738000,
        char_line1c=272'h00010060000F800000000000000000000C0C03E00000000000001FFFFFFC001F8000,
        char_line1d=272'h1FFFFFF00007000000000000000000000C0801C00000000000000000000000070000,
        char_line1e=272'h00000000000000000000000000000000000000800000000000000000000000020000,
        char_line1f=272'h00000000000000000000000000000000000000000000000000000000000000000000;
        reg[8:0] char_bit;
        always@(posedge CLK_to_DAC)
            if(X==10'd144)char_bit<=9'd272;   //当显示到144像素时准备开始输出图像数据
            else if(X>10'd144&&X<10'd416)     //左边距屏幕144像素到416像素时    416=144+272（图像宽度）
                char_bit<=char_bit-1'b1;       //倒着输出图像信息 
            reg[29:0] vga_rgb;                //定义颜色缓存
        always@(posedge CLK_to_DAC) 
            if(X>10'd144&&X<10'd416)    //X控制图像的横向显示边界：左边距屏幕左边144像素  右边界距屏幕左边界416像素
                begin case(Y)            //Y控制图像的纵向显示边界：从距离屏幕顶部160像素开始显示第一行数据
                    10'd160:
                    if(char_line00[char_bit])vga_rgb<=30'b1111111111_0000000000_0000000000;  //如果该行有数据 则颜色为红色
                    else vga_rgb<=30'b0000000000_0000000000_0000000000;                      //否则为黑色
                    10'd162:
                    if(char_line01[char_bit])vga_rgb<=30'b1111111111_0000000000_0000000000;
                    else vga_rgb<=30'b0000000000_0000000000_0000000000;
                    10'd163:
                    if(char_line02[char_bit])vga_rgb<=30'b1111111111_0000000000_0000000000;
                    else vga_rgb<=30'b0000000000_0000000000_0000000000;
                    10'd164:
                    if(char_line03[char_bit])vga_rgb<=30'b1111111111_0000000000_0000000000;
                    else vga_rgb<=30'b0000000000_0000000000_0000000000;
                    10'd165:
                    if(char_line04[char_bit])vga_rgb<=30'b1111111111_0000000000_0000000000;
                    else vga_rgb<=30'b0000000000_0000000000_0000000000; 
                    10'd166:
                    if(char_line05[char_bit])vga_rgb<=30'b1111111111_0000000000_0000000000;
                    else vga_rgb<=30'b0000000000_0000000000_0000000000;
                    10'd167:
                    if(char_line06[char_bit])vga_rgb<=30'b1111111111_0000000000_0000000000;
                    else vga_rgb<=30'b0000000000_0000000000_0000000000; 
                    10'd168:
                    if(char_line07[char_bit])vga_rgb<=30'b1111111111_0000000000_0000000000;
                    else vga_rgb<=30'b0000000000_0000000000_0000000000;
                    10'd169:
                    if(char_line08[char_bit])vga_rgb<=30'b1111111111_0000000000_0000000000;
                    else vga_rgb<=30'b0000000000_0000000000_0000000000; 
                    10'd170:
                    if(char_line09[char_bit])vga_rgb<=30'b1111111111_0000000000_0000000000;
                    else vga_rgb<=30'b0000000000_0000000000_0000000000;
                    10'd171:
                    if(char_line0a[char_bit])vga_rgb<=30'b1111111111_0000000000_0000000000;
                    else vga_rgb<=30'b0000000000_0000000000_0000000000;
                    10'd172:
                    if(char_line0b[char_bit])vga_rgb<=30'b1111111111_0000000000_0000000000;
                    else vga_rgb<=30'b0000000000_0000000000_0000000000;
                    10'd173:
                    if(char_line0c[char_bit])vga_rgb<=30'b1111111111_0000000000_0000000000;
                    else vga_rgb<=30'b0000000000_0000000000_0000000000;
                    10'd174:
                    if(char_line0d[char_bit])vga_rgb<=30'b1111111111_0000000000_0000000000;
                    else vga_rgb<=30'b0000000000_0000000000_0000000000;
                    10'd175:
                    if(char_line0e[char_bit])vga_rgb<=30'b1111111111_0000000000_0000000000;
                    else vga_rgb<=30'b0000000000_0000000000_0000000000;
                    10'd176:
                    if(char_line0f[char_bit])vga_rgb<=30'b1111111111_0000000000_0000000000;
                    else vga_rgb<=30'b0000000000_0000000000_0000000000;
                    10'd177:
                    if(char_line10[char_bit])vga_rgb<=30'b1111111111_0000000000_0000000000;
                    else vga_rgb<=30'b0000000000_0000000000_0000000000;
                    10'd178:
                    if(char_line11[char_bit])vga_rgb<=30'b1111111111_0000000000_0000000000;
                    else vga_rgb<=30'b0000000000_0000000000_0000000000;
                    10'd179:
                    if(char_line12[char_bit])vga_rgb<=30'b1111111111_0000000000_0000000000;
                    else vga_rgb<=30'b0000000000_0000000000_0000000000;
                    10'd180:
                    if(char_line13[char_bit])vga_rgb<=30'b1111111111_0000000000_0000000000;
                    else vga_rgb<=30'b0000000000_0000000000_0000000000;
                    10'd181:
                    if(char_line14[char_bit])vga_rgb<=30'b1111111111_0000000000_0000000000;
                    else vga_rgb<=30'b0000000000_0000000000_0000000000;
                    10'd182:
                    if(char_line15[char_bit])vga_rgb<=30'b1111111111_0000000000_0000000000;
                    else vga_rgb<=30'b0000000000_0000000000_0000000000;
                    10'd183:
                    if(char_line16[char_bit])vga_rgb<=30'b1111111111_0000000000_0000000000;
                    else vga_rgb<=30'b0000000000_0000000000_0000000000;
                    10'd184:
                    if(char_line17[char_bit])vga_rgb<=30'b1111111111_0000000000_0000000000;
                    else vga_rgb<=30'b0000000000_0000000000_0000000000;
                    10'd185:
                    if(char_line18[char_bit])vga_rgb<=30'b1111111111_0000000000_0000000000;
                    else vga_rgb<=30'b0000000000_0000000000_0000000000;
                    10'd186:
                    if(char_line19[char_bit])vga_rgb<=30'b1111111111_0000000000_0000000000;
                    else vga_rgb<=30'b0000000000_0000000000_0000000000;
                    10'd187:
                    if(char_line1a[char_bit])vga_rgb<=30'b1111111111_0000000000_0000000000;
                    else vga_rgb<=30'b0000000000_0000000000_0000000000;
                    10'd188:
                    if(char_line1b[char_bit])vga_rgb<=30'b1111111111_0000000000_0000000000;
                    else vga_rgb<=30'b0000000000_0000000000_0000000000;
                    10'd189:
                    if(char_line1c[char_bit])vga_rgb<=30'b1111111111_0000000000_0000000000;
                    else vga_rgb<=30'b0000000000_0000000000_0000000000;
                    10'd190:
                    if(char_line1d[char_bit])vga_rgb<=30'b1111111111_0000000000_0000000000;
                    else vga_rgb<=30'b0000000000_0000000000_0000000000;
                    10'd191:
                    if(char_line1e[char_bit])vga_rgb<=30'b1111111111_0000000000_0000000000;
                    else vga_rgb<=30'b0000000000_0000000000_0000000000;
                    10'd192:
                    if(char_line1f[char_bit])vga_rgb<=30'b1111111111_0000000000_0000000000;
                    else vga_rgb<=30'b0000000000_0000000000_0000000000;
                    default:vga_rgb<=30'h0000000000;   //默认颜色黑色
                endcase 
            end
        else vga_rgb<=30'h000000000;             //否则黑色
        assign VGA_R=vga_rgb[23:16];
        assign VGA_G=vga_rgb[15:8];
        assign VGA_B=vga_rgb[7:0];
    endmodule

#### 3. 在Verilog代码中，将行、场同步信号中，故意分别加入一定 ms延时（用delay命令），观察会出现什么现象。

##### 答：在Verilog代码中，将行、场同步信号中，故意分别加入一定 ms延时（用delay命令），会导致图像产生拉伸或者变形等不正常现象。因为行、场同步信号的延时被视为引入了相位偏移，而相位偏移会导致图像信号的位置或者大小发生不正常的变化。

#### 参考资料：

    1)  https://blog.csdn.net/u013793399/article/details/51319235

    2)  https://blog.csdn.net/chengfengwenalan/article/details/79854730

    3)  https://blog.csdn.net/cchulu/article/details/73876978

