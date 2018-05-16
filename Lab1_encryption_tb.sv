// Lab1_encryption_tb
// testbench for programmable message encryption
// CSE141L  Spring 2018
module Lab1_encryption_tb      ;
  logic      clk               ;		 // advances simulation step-by-step
  logic      init              ;         // init (reset, start) command to DUT
  wire       done              ;         // done flag returned by DUT
  logic[7:0] message[41]       ,		 // original message, in binary
             msg_padded[64]    ,		 // original message, plus pre- and post-padding
             msg_crypto[64]    ,		 // encrypted message to test against DUT
             msg_crypto_DUT[64],         // encrypted message according to the DUT
			 pre_length        ,         // bytes before first character in message
			 lfsr_ptrn         ,         // one of 8 maximal length 8-tap shift reg. ptrns
			 lfsr_state        ;         // initial state of encrypting LFSR

  logic[7:0] LFSR              ;		 // linear feedback shift register, makes PN code
  logic[7:0] i    = 0          ;		 // index counter -- increments on each clock cycle
// our original American Standard Code for Information Interchange message follows
// note in practice your design should be able to handle ANY ASCII string
  string     str  = "Mr. Wlgedb, come here. I want to see you.";
// displayed encrypted string will go here:
  string     str_enc[64]       ;

  processor dut(.*)            ;         // your top level design goes here

  initial begin
  clk         = 0            ; 		 // initialize clock
  init        = 1            ;		 // activate reset
	pre_length  = 23            ;         // set preamble length
	lfsr_ptrn   = 8'hb8        ;         // select one of 8 permitted
	lfsr_state  = 8'h23        ;         // any nonzero value (zero may be helpful for debug)
    LFSR        = lfsr_state   ;         // initalize test bench's LFSR
    $display("%s",str)         ;         // print original message in transcript window
    $readmemb("assembled_encrypt.txt", dut.imem);
    for(int j=0; j<64; j++) 			 // pre-fill message_padded with ASCII space characters
      msg_padded[j] = 8'h20;
    for(int l=0; l<41; l++)  			 // overwrite up to 41 of these spaces w/ message itself
	  msg_padded[pre_length+l] = str[l];
    for(int m=0; m<41; m++)
	  dut.dmem[m] = str[m];	         // copy original string into device's data memory[0:40]
  dut.dmem[41] = pre_length;       // number of bytes preceding message
	dut.dmem[42] = lfsr_ptrn;		 // LFSR feedback tap positions (8 possible ptrns)
	dut.dmem[43] = lfsr_state;		 // LFSR starting state (nonzero)
  dut.dmem[140] = 8'b11100001;
  dut.dmem[141] = 8'b11010100;
  dut.dmem[142] = 8'b11000110;
  dut.dmem[143] = 8'b10111000;
  dut.dmem[144] = 8'b10110100;
  dut.dmem[145] = 8'b10110010;
  dut.dmem[146] = 8'b11111010;
  dut.dmem[147] = 8'b11110011;
//    $display("%d  %h  %h  %h  %s",i,message[i],msg_padded[i],msg_crypto[i],str[i]);
    #20ns init = 0             ;
    #60ns; 	                             // wait for 6 clock cycles of nominal 10ns each
    wait(done);                          // wait for DUT's done flag to go high
	// print testbench version of encrypted message next to DUT's version -- should match
    init = 1; // set init to 1 so processor is chilling
    done = 0; // set this to 0 as well? I think
/*    if(i<15)
      $display("%d  %h  %h  %h  %s  %s",
        i,message[i],msg_padded[i],msg_crypto[i],str[i-16],str_enc[i]);
    else
      $display("%d  %h  %h  %h  ",
        i,message[i],msg_padded[i],msg_crypto[i]);//,str[i],str_enc[i]);
*/
    for(int n=0; n<64; n++)
      assert(msg_crypto[i] == dut.dmem[i+64]);
  $readmemb("assembled_decrypt.txt", dut.imem);
  #20ns init = 0;
  #60ns;
  wait(done);
  init = 1;
  done = 0;
  for(int i = 0; i < 41; i++)
    assert(str[i] == dut.dmem[i]);

$display("Tests finished!!!!");
$stop;
end




always begin							 // continuous loop
  #5ns clk = 1;							 // clock tick
  #5ns clk = 0;							 // clock tock
// print count, message, padded message, encrypted message, ASCII of message and encrypted
end										 // continue

always @(negedge clk) begin				 // testbench will change on falling clocks
  if(i < 64) begin
    //$display("msg_padded[%d] %b", i, msg_padded[i]);
    //$display("LFSR[%d] %b", i, LFSR);
    msg_crypto[i]        = msg_padded[i] ^ LFSR;//{1'b0,LFSR[6:0]};	   // encrypt 7 LSBs
    //$display("msg_crypto[%d] %b", i, msg_crypto[i]);
  //  $displayb(msg_padded[i],,,LFSR,,,msg_crypto[i]);
    LFSR                 = (LFSR<<1)+(^(LFSR&lfsr_ptrn));//{LFSR[6:0],(^LFSR[5:3]^LFSR[7])};		   // roll the rolling code
    str_enc[i]           = string'(msg_crypto[i]);
    i                    = i+1;									   // increment counter
  end
end

endmodule
