module processor(
  input clk,
  input reset,
  output logic done
  );
    logic[8:0] imem[512]; //instruction memory
    logic[7:0] dmem[255]; // data memory
    logic[7:0] regs[16]; // regfile
    logic[7:0] PC; // program counter
    logic[8:0] instr; // the actual instruction

    // enum/constant declarations
    enum logic[1:0] {IDLE=2'b00, COMPUTE:2'b01, DUMMY:2'b10} state;
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
    const logic[3:0] DEC = 4'b1010 // decrement instruction check
    const logic[3:0] STOP = 4'b1011 // Stop instruction
    const logic[3:0] MOVREG = 4'b1100 // move register to register instruction

    //MOV constants for encrypt
    const logic[4:0] MOV_41 = 5'b00000; // moving 41 into r0
    const logic[4:0] MOV_ENC64 = 5'b00001; // moving 64 into r1
    const logic[4:0] MOV_SPACE2 = 5'b00010; // move space char into r2
  const logic[4:0] MOV_ZERO = 5'b00011; // move 0 into r0

    // MOVREG constants for encrypt could cross over
    const logic[4:0] MOVREG_TAP_ADDR = 5'b00000; // move value in r2 into r9
    const logic[4:0] MOVREG_SEED = 5'b00001; // move value in r5 into r8
    const logic[4:0] MOVREG_TAP_ADDR_BACK = 5'b00010; // move value in r9 to r2
    const logic[4:0] MOVREG_BACKSEED = 5'b00011; // move value in r8 to r5

  // BRANCH 
  const logic[4:0] BRANCH_PADDING = 5'b00000; // compare the value in r4 with the value 0 



    assign instr = imem[PC]; // the instruction will always be updated whenever the PC changes i think?

    // ALU function block
    function logic[7:0] ALU(input logic[7:0] r1, input logic[7:0] r2, input logic[7:0] r3,
      input logic t1,
      input logic[4:0] opcode) begin
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
      if(reset) begin
        PC <= 8'b00000000;
        state <= IDLE;
      end
      else
        case(state) begin
          IDLE: begin
            if(!reset) begin
              PC <= 8'b00000000;
              for(int i = 0; i < 16; i++) begin
                regs[i] <= 8'b00000000;
              end
              state <= COMPUTE;
            end

          end

          COMPUTE: begin
          case(instr[8:5]):
            LW: begin
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
              regs[instr[4:1]] <= ALU(regs[instr[4:2]], regs[instr[1:0]], regs[instr[4:1]], 0, instr[8:5]);
              PC <= PC + 1;
              state <= COMPUTE;
            end
            MOV: begin
            case(instr[4:0]):
                MOV_41: regs[0] <= 41;
                MOV_64ENC: regs[1] <= 64;

            endcase
            PC <= PC + 1;
            state <= COMPUTE;
            end
            MOVREG: begin
            case(instr[4:0]):


            endcase
            PC <= PC + 1;
            state <= COMPUTE;
            end
            BRANCH: begin
            case(instr[4:0]):
              BRANCH_PADDING: begin
                if(regs[4] == 0) begin
                  PC <= PC + 1;
                end
                else begin
                  PC <= 
                end
                
              end


            endcase

            state <= COMPUTE;
            end
            STOP: begin // STOP instruction
              PC <= 8'b00000000;
              state <= DUMMY;
              done <= 1;
            end





          endcase //endcase

          end
          DUMMY: begin // just to ensure that reset gets set to 1 on the testbench's side
          // will need to tweak this later probably
            state <= IDLE;

          end


        endcase // endcase

    end // endff




  endmodule
