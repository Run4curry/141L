module processor(
  input clk,
  input init,
  output logic done
  );
    logic[8:0] imem[512]; //instruction memory
    logic[7:0] dmem[255]; // data memory
    logic[7:0] regs[16]; // regfile
    logic[7:0] PC; // program counter
    logic[8:0] instr; // the actual instruction

    // enum/constant declarations
    enum logic[1:0] {IDLE=2'b00, COMPUTE=2'b01, DUMMY=2'b10} state;
    const logic[3:0] LW = 4'b0000; // load word check
    const logic[3:0] SW = 4'b0001; // store word check
    const logic[3:0] MOV = 4'b0010; // Move instruction
    const logic[3:0] XOR = 4'b0011; // XOR instruction check
    const logic[3:0] AND = 4'b0100; // AND instruction check
    const logic[3:0] OR = 4'b0101; // OR instruction check
    const logic[3:0] LSL = 4'b0110; // Logical shift left instruction check
    const logic[3:0] BRANCH = 4'b0111; // Branch instruction
    const logic[3:0] PAR = 4'b1001; // parity instruction check
    const logic[3:0] INC = 4'b1000; // increment instruction check
    const logic[3:0] DEC = 4'b1010; // decrement instruction check
    const logic[3:0] STOP = 4'b1011; // Stop instruction
    const logic[3:0] MOVREG = 4'b1100; // move register to register instruction

    //MOV constants for encrypt
    const logic[4:0] MOV_41 = 5'b00000; // moving 41 into r0
    const logic[4:0] MOV_ENC64 = 5'b00001; // moving 64 into r1
    const logic[4:0] MOV_SPACE2 = 5'b00010; // move space char into r2
    const logic[4:0] MOV_ZERO = 5'b00011; // move 0 into r0

    const logic[4:0] MOV_8TAPS = 5'b00100; // move 8 into r11
    const logic[4:0] MOV_TAP_ADDR = 5'b00101; // move 140 into r2
    const logic[4:0] MOV_COUNTTAPS = 5'b00110; // move 0 into r14
    const logic[4:0] MOV_TAP_ZERO = 5'b00111; // move 0 into r7
    const logic[4:0] MOV_SPACE = 5'b01000; // move space into r7

    // MOVREG constants for encrypt could cross over
    const logic[4:0] MOVREG_TAP_ADDR = 5'b00000; // move value in r2 into r9
    const logic[4:0] MOVREG_SEED = 5'b00001; // move value in r5 into r8
    const logic[4:0] MOVREG_TAP_ADDR_BACK = 5'b00010; // move value in r9 to r2
    const logic[4:0] MOVREG_BACKSEED = 5'b00011; // move value in r8 to r5
    const logic[4:0] MOVREG_SEED2 = 5'b00100; // move value in r5 to r3
    const logic[4:0] MOVREG_NEWSEED = 5'b00101; // move value in r3 to r5

  // BRANCH
  const logic[4:0] BRANCH_PADDING = 5'b00000; // compare the value in r4 with the value 0
  const logic[4:0] BRANCH_MESSAGE = 5'b00001; // compare the value in r0 to 41
  const logic[4:0] BRANCH_END = 5'b00010; // compare the value in r1 to 128
  const logic[4:0] BRANCH_MORE_PADDING = 5'b00011; // compare the value in r1 to 128
  const logic[4:0] BRANCH_WHILE = 5'b00100; // always branch
  const logic[4:0] BRANCH_NEXT = 5'b00101; // compare value in r11 to 1
  const logic[4:0] BRANCH_SKIP = 5'b00110; // compare value in r2 to 0
  const logic[4:0] BRANCH_NOTEQUAL = 5'b00111; // compare value in r5 with r3
  const logic[4:0] BRANCH_FOR = 5'b01000; // compare the value in r14 to 8
  const logic[4:0] BRANCH_INT1 = 5'b01001; // branch back to int
  const logic[4:0] BRANCH_INT2 = 5'b01010; // branch back to int2
  const logic[4:0] BRANCH_DECRYPTION = 5'b01011; // compare r2 to 0
  const logic[4:0] BRANCH_NEXT2 = 5'b01100; // branch back to next2
  const logic[4:0] BRANCH_DECRYPTION3 = 5'b01101; // compare r3 to space
  const logic[4:0] BRANCH_DECRYPTION2 = 5'b01110; // compare r0 to 41
  const logic[4:0] BRANCH_EDGE = 5'b01111; // compare r14 to 8
  const logic[4:0] BRANCH_MAIN_LOOP = 5'b10000; // branch back to main loop
  const logic[4:0] BRANCH_SECOND_SPACE = 5'b10001; // compare the value in r5 to space
  const logic[4:0] BRANCH_END3 = 5'b10010; // compare the value in r5 to space



    assign instr = imem[PC]; // the instruction will always be updated whenever the PC changes i think?

    // ALU function block
    function logic[7:0] ALU(input logic[7:0] r1, input logic[7:0] r2, input logic[7:0] r3,
      input logic t1,
      input logic[4:0] opcode);
      if(t1) begin
        if(opcode == AND) begin // AND
          ALU = r1 & r2;
        end
        else if(opcode == OR) begin // OR
          ALU = r1 | r2;
        end
        else begin // XOR
          ALU = r1 ^ r2;
        end
      end
      else begin
        if(opcode == LSL) begin // LSL
          //$display("LSL: %b", r3);
          ALU = r3 << 1;
        end
        else if(opcode == INC) begin // INC
          ALU = r3 + 1;
        end
        else if(opcode == DEC) begin // DEC
          ALU = r3 - 1;
        end
        else begin // PAR
          ALU = ^r3;
        end
      end

    endfunction

    // Computer is basically an FSM so make it an FSM!!!!!
    always_ff @(posedge clk) begin
      if(init) begin
        PC <= 8'b00000000;
        done <= 0;
        //$display("%d",done);
        //$display("Hello\n");
      //  $display("%x", init);
        state <= IDLE;
      end
      else
        case(state)
          IDLE: begin
          //  $display("%x", init);
            if(!init) begin
              PC <= 8'b00000000;
              for(int i = 0; i < 16; i++) begin
                regs[i] <= 8'b00000000;
              end
            //  $display("%b", imem[50]);
              state <= COMPUTE;
            end

          end

          COMPUTE: begin
        /*  if(regs[11] <= 8) begin
            $display("r11: %d", regs[11]);
            $display("PC: %d", PC + 1);
          end*/
        //  $display("PC: %d", PC + 1);
          case(instr[8:5])
            LW: begin
          //    $display("Hi from LW!");
              regs[instr[4:2]] <= dmem[regs[instr[1:0]]];
              PC <= PC + 1;
              state <= COMPUTE;
            end
            SW: begin
              dmem[regs[instr[1:0]]] <= regs[instr[4:2]];
              PC <= PC + 1;
              state <= COMPUTE;
            end
            XOR: begin
              regs[5] <= ALU(regs[instr[4:2]], regs[instr[1:0]], regs[instr[4:1]], 1, instr[8:5]);
              PC <= PC + 1;
              state <= COMPUTE;
            end
            AND: begin
              regs[10] <= ALU(regs[instr[4:2]], regs[instr[1:0]], regs[instr[4:1]], 1, instr[8:5]);
              PC <= PC + 1;
              state <= COMPUTE;
            end
            OR: begin
            //$display("OR: %b", regs[5]);
              regs[5] <= ALU(regs[instr[4:2]], regs[instr[1:0]], regs[instr[4:1]], 1, instr[8:5]);
              PC <= PC + 1;
              state <= COMPUTE;
            end
            LSL: begin
              regs[instr[4:1]] <= ALU(regs[instr[4:2]], regs[instr[1:0]], regs[instr[4:1]], 0, instr[8:5]);
              PC <= PC + 1;
              state <= COMPUTE;
            end
            PAR: begin
              regs[2] <= ALU(regs[instr[4:2]], regs[instr[1:0]], regs[instr[4:1]], 0, instr[8:5]);
              PC <= PC + 1;
              state <= COMPUTE;

            end
            INC: begin
              regs[instr[4:1]] <= ALU(regs[instr[4:2]], regs[instr[1:0]], regs[instr[4:1]], 0, instr[8:5]);
              PC <= PC + 1;
              state <= COMPUTE;
            end
            DEC: begin
              /*if(instr[4:1] == 4'b1011) begin
                $display("r11: %d", regs[11]);
                $display("r9: %d", regs[9]);
                $display("r5: %x", regs[5]);
                $display("r3: %x", regs[3]);
              end*/
              regs[instr[4:1]] <= ALU(regs[instr[4:2]], regs[instr[1:0]], regs[instr[4:1]], 0, instr[8:5]);
              PC <= PC + 1;
              state <= COMPUTE;
            end
            MOV: begin
            case(instr[4:0])
                MOV_41: regs[0] <= 41;
                MOV_ENC64: regs[1] <= 64;
                MOV_ZERO: regs[0] <= 0;
                MOV_SPACE2: regs[2] <= 8'h20;
                MOV_8TAPS: regs[11] <= 8;
                MOV_TAP_ADDR: begin
                  regs[2] <= 140;
                  //$display("r5: %x", regs[5]);
                end
                MOV_COUNTTAPS: regs[14] <= 0;
                MOV_TAP_ZERO: regs[7] <= 0;
                MOV_SPACE: regs[7] <= 8'h20;

            endcase
            PC <= PC + 1;
            state <= COMPUTE;
            end
            MOVREG: begin
            case(instr[4:0])
              MOVREG_TAP_ADDR: regs[9] <= regs[2];
              MOVREG_TAP_ADDR_BACK: begin
                regs[2] <= regs[9];
                //$display("tap_addr_back: r9: %d", regs[9]);
                //$display("r14: %d", regs[14]);
                //$display("PC: %d", PC);
              end
              MOVREG_SEED: regs[8] <= regs[5];
              MOVREG_BACKSEED: regs[5] <= regs[8];
              MOVREG_SEED2: regs[3] <= regs[5];
              MOVREG_NEWSEED: begin
                regs[5] <= regs[3];
              //  $display("NEWSEED");
              end




            endcase
            PC <= PC + 1;
            state <= COMPUTE;
            end
            BRANCH: begin
            case(instr[4:0])
              BRANCH_PADDING: begin
                if(regs[4] == 0) begin
                  PC <= PC + 1;
                end
                else begin
                  PC <= 7;
                end

              end
              BRANCH_MESSAGE: begin
                if(regs[0] == 41) begin
                  PC <= PC + 1;

                end
                else begin
                  PC <= 23;
                end
              end

              BRANCH_END: begin
                if(regs[1] == 128) begin
                  PC <= 53;
                end
                else begin
                  PC <= PC + 1;
                end

              end

              BRANCH_MORE_PADDING: begin
                if(regs[1] == 128) begin
                  PC <= PC + 1;
                end
                else begin
                  PC <= 39;
                end

              end
              BRANCH_WHILE: begin
                PC <= 7;
              end
              BRANCH_NEXT: begin
                if(regs[11] == 1) begin
                  PC <= 44;
              //    $display("BRANCHED!!");
                end
                else begin
                  PC <= PC + 1;
                end
              end

              BRANCH_SKIP: begin
                if(regs[2] == 0) begin
                  PC <= 33;
                end
                else begin
                  PC <= PC + 1;
                end

              end

              BRANCH_NOTEQUAL: begin
                if(regs[5] != regs[3]) begin
                  PC <= 36;
                end
                else begin
                  PC <= PC + 1;
                end
              end
              BRANCH_FOR: begin
                if(regs[14] < 8) begin
                  PC <= 18;
                end
                else begin
                  PC <= PC + 1;
                end
              end
              BRANCH_INT1: begin
                PC <= 18;
              end
              BRANCH_INT2: begin
                PC <= 28;
              end
              BRANCH_DECRYPTION: begin
                if(regs[2] != 0) begin
              //    $display("R2 tap: %x", regs[2]);
              //    $display("R9 mem: %d", regs[9]);
                  PC <= 50;
                end
                else begin
                  PC <= PC + 1;
                end
              end

              BRANCH_NEXT2: begin
                PC <= 44;
              end

              BRANCH_DECRYPTION3: begin
                if(regs[3] == 8'h20) begin
                  PC <= 50;
                end
                else begin
                  PC <= PC + 1;
                end
              end

              BRANCH_DECRYPTION2: begin
                if(regs[0] != 41) begin
                  PC <= 65;
                end
                else begin
                  PC <= PC + 1;
                end
              end

              BRANCH_EDGE: begin
                if(regs[14] == 8) begin
                  PC <= 31;
                end
                else begin
                  PC <= PC + 1;
                end
              end


            endcase

            state <= COMPUTE;
            end
            STOP: begin // STOP instruction
              PC <= 8'b00000000;
              state <= DUMMY;
              done <= 1;
            //  $display("done");
            end





          endcase //endcase

          end
          DUMMY: begin // just to ensure that reset gets set to 1 on the testbench's side
          // will need to tweak this later probably
        //    $display("%d", done);
            done <= 0;
            state <= IDLE;

          end


        endcase // endcase

    end // endff




  endmodule
