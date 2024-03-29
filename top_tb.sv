// Lab4_tb
// testbench for programmable message encryption
// CSE141L  Spring 2018
// Sequence:
// run program 1 (encrypt first message)
// run program 2 (decrypt second message)
// run program 1 again (encrypt third message)
// run program 3 (decrypt fourth message)
module top_tb ()            ;
  logic      clk            ,  // advances simulation step-by-step
             init           ;  // init (reset, start) command to DUT
  wire       done           ;  // done flag returned by DUT
  logic[7:0] message1[41]   ,  // first program 1 original message, in binary
             message2[41]   ,  // program 2 decrypted message
             message3[41]   ,  // second program 1 original message
             message4[41]   ,  // program 3 decrypted message
             pre_length[4]  ,  // bytes before first character in message
             lfsr_ptrn[4]   ,  // one of 8 maximal length 8-tap shift reg. ptrns
             lfsr1[64]      ,  // states of program 1 encrypting LFSR
             lfsr2[64]      ,  // states of program 2 decrypting LFSR
             lfsr3[64]      ,  // states of program 3 encrypting LFSR
             lfsr4[64]      ,  // states of program 4 decrypting LFSR
             msg_padded1[64],  // original message, plus pre- and post-padding
             msg_padded2[64],  // original message, plus pre- and post-padding
             msg_padded3[64],  // original message, plus pre- and post-padding
             msg_padded4[64],  // original message, plus pre- and post-padding
             msg_crypto1[64],  // encrypted message according to the DUT
             msg_crypto2[64],  // encrypted message according to the DUT
             msg_crypto3[64],  // encrypted message according to the DUT
             msg_crypto4[64],  // encrypted message according to the DUT
             LFSR_ptrn[8]   ,  // 8 possible maximal-length 8-bit LFSR tap ptrns
             LFSR_init[4]   ;  // four of 255 possible NONZERO starting states

  // our original American Standard Code for Information Interchange message follows
  // note in practice your design should be able to handle ANY ASCII string
  string     str1  = "Mr. Watson, come here. I want to see you.";  // 1st program 1 input
  string     str2  = "Knowledge comes, but wisdom lingers.     ";  // program 2 output
  string     str3  = "  01234546789abcdefghijklmnopqrstuvwxyz. ";  // 2nd program 1 input
  string     str4  = "          A joke is a very serious thing.";  // program 3 output

  // displayed encrypted string will go here:
  string     str_enc1[64];  // first program 1 output
  string     str_enc2[64];  // program 2 input
  string     str_enc3[64];  // second program 1 output
  string     str_enc4[64];  // program 3 input

  // the 8 possible maximal-length feedback tap patterns from which to choose
  assign LFSR_ptrn[0] = 8'he1;
  assign LFSR_ptrn[1] = 8'hd4;
  assign LFSR_ptrn[2] = 8'hc6;
  assign LFSR_ptrn[3] = 8'hb8;
  assign LFSR_ptrn[4] = 8'hb4;
  assign LFSR_ptrn[5] = 8'hb2;
  assign LFSR_ptrn[6] = 8'hfa;
  assign LFSR_ptrn[7] = 8'hf3;

  // different starting LFSR state for each program -- logical OR guarantees nonzero
  assign LFSR_init[0] = $random | 8'h40;  // for 1st program 1 run
  assign LFSR_init[1] = $random | 8'h20;  // for program 2 run
  assign LFSR_init[2] = $random | 8'h10;  // for 2nd program 1 run
  assign LFSR_init[3] = $random | 8'h08;  // for program 3 run

  // set preamble lengths for the four program runs (always > 8)
  assign pre_length[0] = 9 ;  // 1st program 1 run
  assign pre_length[1] = 9 ;  // program 2 run
  assign pre_length[2] = 11;  // 2nd program 1 run
  assign pre_length[3] = 12;  // program 3 run

  int lk;                     // counts leading spaces for program 3

  processor dut(.*);

  initial begin
    for(lk = 0; lk<25; lk++) begin
        if(str4[lk]==8'h20)
        continue;
        else
        break;
    end
    clk  = 0;  // initialize clock
    init = 1;  // activate reset

    // program 1 -- precompute encrypted message
    lfsr_ptrn[0] = LFSR_ptrn[1];  // select one of 8 permitted
    lfsr1[0]     = LFSR_init[0];  // any nonzero value (zero may be helpful for debug)
    $display("run program 1 for the first time");
    $display("%s",str1);          // print original message in transcript window
    $display("LFSR_ptrn = %h, LFSR_init = %h",lfsr_ptrn[0],lfsr1[0]);

    for(int j=0; j<64; j++)       // pre-fill message_padded with ASCII space characters
      msg_padded1[j] = 8'h20;

    for(int l=0; l<41; l++)       // overwrite up to 41 of these spaces w/ message itself
      msg_padded1[pre_length[0]+l] = str1[l];

    // compute the LFSR sequence
    for (int ii=0;ii<63;ii++)
      lfsr1[ii+1] = (lfsr1[ii]<<1)+(^(lfsr1[ii]&lfsr_ptrn[0]));

    // encrypt the message, testbench will change on falling clocks
    for (int i=0; i<64; i++) begin
      msg_crypto1[i]        = msg_padded1[i] ^ lfsr1[i];
      str_enc1[i]           = string'(msg_crypto1[i]);
    end

    for(int jj=0; jj<64; jj++)
      $write("%s",str_enc1[jj]);
    $display("\n");

    // program 2 -- precompute encrypted message
    lfsr_ptrn[1] = LFSR_ptrn[3];  // select one of 8 permitted
    lfsr2[0]     = LFSR_init[1];  // any nonzero value (zero may be helpful for debug)
    $display("run program 2");
    $display("%s",str2);          // print original message in transcript window
    $display("LFSR_ptrn = %h, LFSR_init = %h",lfsr_ptrn[1],lfsr2[0]);

    for(int j=0; j<64; j++)       // pre-fill message_padded with ASCII space characters
      msg_padded2[j] = 8'h20;

    for(int l=0; l<41; l++)       // overwrite up to 41 of these spaces w/ message itself
      msg_padded2[pre_length[1]+l] = str2[l];

    // compute the LFSR sequence
    for (int ii=0;ii<63;ii++)
      lfsr2[ii+1] = (lfsr2[ii]<<1)+(^(lfsr2[ii]&lfsr_ptrn[1]));

    // encrypt the message, testbench will change on falling clocks
    for (int i=0; i<64; i++) begin
      msg_crypto2[i]        = msg_padded2[i] ^ lfsr2[i];
      str_enc2[i]           = string'(msg_crypto2[i]);
    end

    for(int jj=0; jj<64; jj++)
      $write("%s",str_enc2[jj]);
    $display("\n");

    // program 1 -- precompute encrypted message
    lfsr_ptrn[2] = LFSR_ptrn[5];  // select one of 8 permitted
    lfsr3[0]     = LFSR_init[2];  // any nonzero value (zero may be helpful for debug)
    $display("run program 1 for the second time");
    $display("%s",str3);          // print original message in transcript window
    $display("LFSR_ptrn = %h, LFSR_init = %h",lfsr_ptrn[2],lfsr3[0]);

    for(int j=0; j<64; j++)       // pre-fill message_padded with ASCII space characters
      msg_padded3[j] = 8'h20;

    for(int l=0; l<41; l++)       // overwrite up to 41 of these spaces w/ message itself
      msg_padded3[pre_length[2]+l] = str3[l];

    // compute the LFSR sequence
    for (int ii=0;ii<63;ii++)
      lfsr3[ii+1] = (lfsr3[ii]<<1)+(^(lfsr3[ii]&lfsr_ptrn[2]));  // {LFSR[6:0],(^LFSR[5:3]^LFSR[7])};           // roll the rolling code

    // encrypt the message, testbench will change on falling clocks
    for (int i=0; i<64; i++) begin
      msg_crypto3[i]        = msg_padded3[i] ^ lfsr3[i];  //{1'b0,LFSR[6:0]};       // encrypt 7 LSBs
      str_enc3[i]           = string'(msg_crypto3[i]);
    end

    for(int jj=0; jj<64; jj++)
      $write("%s",str_enc3[jj]);
    $display("\n");

    // program 3 -- precompute encrypted message
    lfsr_ptrn[3] = LFSR_ptrn[7];  // select one of 8 permitted
    lfsr4[0]     = LFSR_init[3];  // any nonzero value (zero may be helpful for debug)
    $display("run program 3");
    $display("%s",str4)        ;  // print original message in transcript window
    $display("lead space count for program 3 = %d",lk);
    $display("LFSR_ptrn = %h, LFSR_init = %h",lfsr_ptrn[3],lfsr4[0]);

    for(int j=0; j<64; j++)       // pre-fill message_padded with ASCII space characters
      msg_padded4[j] = 8'h20;

    for(int l=0; l<41; l++)       // overwrite up to 41 of these spaces w/ message itself
      msg_padded4[pre_length[3]+l] = str4[l];

    // compute the LFSR sequence
    for (int ii=0;ii<63;ii++)
      lfsr4[ii+1] = (lfsr4[ii]<<1)+(^(lfsr4[ii]&lfsr_ptrn[3]));  // {LFSR[6:0],(^LFSR[5:3]^LFSR[7])};           // roll the rolling code

    // encrypt the message, testbench will change on falling clocks
    for (int i=0; i<64; i++) begin
      msg_crypto4[i]        = msg_padded4[i] ^ lfsr4[i];  // {1'b0,LFSR[6:0]};       // encrypt 7 LSBs
      str_enc4[i]           = string'(msg_crypto4[i]);
    end

    // display encrypted message
    for(int jj=0; jj<64; jj++)
      $write("%s",str_enc4[jj]);
    $display("\n");

    // run program 1
    $readmemb("assembled_encrypt.txt", dut.imem);
    for(int m=0; m<41; m++)
      dut.dmem[m] = str1[m];       // copy original string into device's data memory[0:40]
    dut.dmem[41] = pre_length[0];  // number of bytes preceding message
    dut.dmem[42] = lfsr_ptrn[0];   // LFSR feedback tap positions (8 possible ptrns)
    dut.dmem[43] = LFSR_init[0];   // LFSR starting state (nonzero)
    dut.dmem[140] = 8'b11100001;
    dut.dmem[141] = 8'b11010100;
    dut.dmem[142] = 8'b11000110;
    dut.dmem[143] = 8'b10111000;
    dut.dmem[144] = 8'b10110100;
    dut.dmem[145] = 8'b10110010;
    dut.dmem[146] = 8'b11111010;
    dut.dmem[147] = 8'b11110011;
    $display("lfsr_init[0]=%h,dut.data_mem.DM[43]=%h",LFSR_init[0],dut.dmem[43]);
    // $display("%d  %h  %h  %h  %s",i,message[i],msg_padded[i],msg_crypto[i],str[i]);
    #20ns init = 0;
    #60ns;                                // wait for 6 clock cycles of nominal 10ns each
    wait(done);                           // wait for DUT's done flag to go high
    init = 1;                          // activate reset
    //#10ns $display();
    $display("program 1:");
    for(int n=0; n<64; n++)
      $display("%d bench msg: %h dut msg: %h",n, msg_crypto1[n], dut.dmem[n+64]);

    // run program 2
    for(int i = 0; i < 16; i++)
      dut.regs[i] = 0;
    $readmemb("assembled_decrypt2.txt", dut.imem);
    for(int n=64; n<128; n++)
      dut.dmem[n] = msg_crypto2[n - 64];
    for(int i = 0; i < 41; i++)
      dut.dmem[i] = 8'h00;
    #20ns init = 0;
    #60ns;                             // wait for 6 clock cycles of nominal 10ns each
    wait(done);                        // wait for DUT's done flag to go high
    init = 1;
    //#10ns $display();
    $display("program 2:");
    for(int n=0; n<41; n++)
      $display("%d bench msg: %h dut msg: %h",n, str2[n], dut.dmem[n]);

    // run program 1
    $readmemb("assembled_encrypt.txt", dut.imem);
    for(int m=0; m<41; m++)
      dut.dmem[m] = str3[m];       // copy original string into device's data memory[0:40]

    dut.dmem[41] = pre_length[2];  // number of bytes preceding message
    dut.dmem[42] = lfsr_ptrn[2];   // LFSR feedback tap positions (8 possible ptrns)
    dut.dmem[43] = LFSR_init[2];   // LFSR starting state (nonzero)
    // $display("%d  %h  %h  %h  %s",i,message[i],msg_padded[i],msg_crypto[i],str[i]);
    #20ns init = 0;
    #60ns;                                // wait for 6 clock cycles of nominal 10ns each
    wait(done);                           // wait for DUT's done flag to go high
    init = 1;
    //#10ns $display();
    $display("program 1:");
    for(int n=0; n<64; n++)
      $display("%d bench msg: %h dut msg: %h",n, msg_crypto3[n], dut.dmem[n+64]);

    // run program 3
    $readmemb("assembled_decrypt3.txt", dut.imem);
    for(int n=64; n<128; n++)
      dut.dmem[n] = msg_crypto4[n - 64];
    dut.dmem[140] = 8'b11100001;
    dut.dmem[141] = 8'b11010100;
    dut.dmem[142] = 8'b11000110;
    dut.dmem[143] = 8'b10111000;
    dut.dmem[144] = 8'b10110100;
    dut.dmem[145] = 8'b10110010;
    dut.dmem[146] = 8'b11111010;
    dut.dmem[147] = 8'b11110011;
    #20ns init = 0;
    #60ns;                             // wait for 6 clock cycles of nominal 10ns each
    wait(done);                        // wait for DUT's done flag to go high
    init = 1;
    //#10ns $display();
    $display("program 3:");
    for(int n=0; n<31; n++)
      $display("%d bench msg: %h dut msg: %h",n, str4[n+lk], dut.dmem[n]);
    #20ns $stop;
  end

always begin     // continuous loop
  #5ns clk = 1;  // clock tick
  #5ns clk = 0;  // clock tock
end

endmodule
