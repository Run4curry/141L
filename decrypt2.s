mov enc64     @ move a counter value of 64 into r1
mov 8taps     @ move the value 8 into r11
mov zero         @ move the value 0 into r0

mov space     @ move the space char into r7
lw r2, r1     @ load the value from the memory location in r1
inc r1        @ increment the value in r1
xor r7, r2    @ xor the encrypted char in r2 with the space char in r7 and store in r5

while:
      mov tap_addr  @ move the address 140 into r2
      b next        @ if r11 is equal to 0 branch to next
      movreg seed    @ move the seed in r5 to r8
      mov space   @ move the space char into r7
      mov counttaps @ move the value 0 into r14
      lw r2, r1     @ load the encrypted char from memory location in r1
      inc r1        @ increment the value in r1
      xor r7, r2    @ xor the encrypted char in r2 with space char in r7 to produce next seed store in r5
      movreg seed2  @ move value in r5 into r3
      movreg backseed @ move the seed in r8 to r5
      mov tap_addr  @ move the address 140 into r2
      for:          @ looping through all 8 patterns
      int1:
                    movreg tap_addr @ move value in r2 into r9
                    lw r2, r2 @ load in a tap pattern from memory location held in r2
                    inc r14   @ increment the value in r14
                    inc r9    @ increment value in r9
                    b skip    @ if the value in r2 is 0, branch to skip
                    and r5, r2  @ take seed in r5 and with tap pattern in r2 store result in r10
                    par r10   @ take parity of value in r10 and store in r2
                    lsl r5    @ left shift seed in r5
                    or r5, r2 @ or left shifted seed in r5 with the parity result in r2 store back in r5
                    b notequal  @ check the value in r5 with r3 if not equal branch to notequal
                    int2:
                    movreg tap_addr_back @ move value in r9 back in to r2
                    movreg backseed      @ move old seed from r8 back in to r5
                    b for                @ check to see if r14 equal to 8 if not branch back to for
                    movreg newseed       @ move the seed in r3 into r5
                    b while              @ branch back to while
skip:
    movreg tap_addr_back  @ move value in r9 back into r2
    b edge                @ if value in r14 equal to 8 branch to movreg newseed
    b int1                @ branch back to the for loop

notequal: @ not equal
    dec r9      @ decrement value in r9
    dec r11     @ decrease the number of potential taps
    movreg tap_addr_back  @ move value in r9 back into r2
    mov tap_zero          @ move 0 in to r7
    sw r7, r2             @ store 0 at the memory address held in r2
    movreg tap_addr       @ move value in r2 into r9
    inc r9                @ increment the address in r9
    b int2                @ branch back into the for loop

next:
next2:
    movreg tap_addr   @ move value in r2 into r9
    lw r2, r2         @ load in a tap pattern from memory location in r2
    inc r9            @ increment value in r9 by 1
    b decryption      @ branch to decryption if r2 is not equal to 0
    movreg tap_addr_back  @ move value in r9 back in to r2
    b next2            @ branch back to next2

decryption:     @ decrypt rest of the message but first find first non-space
decryption3:
    movreg tap_addr   @ move value in r2 into r9
    and r5, r2        @ and the seed with tap in r2 store in r10
    par r10           @ take parity of the thing in r10 and store in r2
    lsl r5            @ left shift seed in r5 by 1
    or r5, r2         @ or left shifted seed in r5 with parity result in r2 and store in r5 new seed
    lw r2, r1         @ load in the encrypted char from memory location specified by r1
    inc r1            @ increment the value in r1
    movreg seed       @ move the seed in r5 to r8
    xor r5, r2        @ xor the seed with the char in r2 and store in r5
    movreg seed2      @ move the value in r5 to r3
    movreg backseed   @ move the value in r8 to r5
    movreg tap_addr_back @ move the value in r9 back into r2
    b decryption3     @ branch to decryption3 if value in r3 is a space
    sw r3, r0         @ otherwise store the decrypted char at memory location specified by r0
    inc r0            @ increment the value in r0

decryption2:
    movreg tap_addr   @ move value in r2 into r9
    and r5, r2        @ and the seed with tap in r2 store in r10
    par r10           @ take parity of the thing in r10 and store in r2
    lsl r5            @ left shift seed in r5 by 1
    or r5, r2         @ or left shifted seed in r5 with parity result in r2 and store in r5 new seed
    lw r2, r1         @ load in the encrypted char from memory location specified by r1
    inc r1            @ increment the value in r1
    movreg seed       @ move the seed in r5 to r8
    xor r5, r2        @ xor the seed with the char in r2 and store in r5
    movreg seed2      @ move the value in r5 to r3
    movreg backseed   @ move the value in r8 to r5
    movreg tap_addr_back  @ move seed value in r9 back into r2
    sw r3, r0         @ store decrypted char at memory location specified by r0
    inc r0            @ increment the value in r0
    b decryption2     @ if value in r0 not equal to 41 branch back to decryption2
stop      @ halts the program sets the done flag to one
