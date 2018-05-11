mov 64enc       @ move a counter value of 64 into r1
mov 8taps       @ move the value 8 into r11
mov zero        @ move the value 0 into r0

mov space       @ move the space char into r7
lw r2, r1       @ load the value from the memory location in r1
inc r1          @ increment the value in r1
xor r7, r2      @ xor the encrypted char in r2 with the space char in r5

while2:
      mov tap_addr    @ move the address 140 into r2
      b next_2        @ if r11 is equal to 1 branch to next
      movreg seed     @ move the seed in r5 to r8
      mov space       @ move the space char into r7
      mov counttaps   @ move the value 0 into r14
      lw r2, r1       @ load the encrypted char from memory location in r1
      inc r1          @ increment the value in r1
      xor r7, r2      @ xor the encrypted char in r2 with space char in r7 to produce next seed store in r5
      movreg seed2    @ move value in r5 into r3
      movreg backseed @ move the seed in r8 to r5
      mov tap_addr    @ move the address 140 into r2
      for2:           @ looping through all 8 patterns
      int1_2:
                      movreg tap_addr   @ move value in r2 into r9
                      lw r2, r2         @ load in a tap pattern
                      inc r9            @ increment value in r9
                      b skip2           @ if the value in r2 is 0, branch to skip2
                      and r5, r2        @ take seed in r5 and with tap pattern in r2 store result in r10
                      par r10           @ take parity of value in r10 and store in r2
                      lsl r5            @ left shift seed in r5
                      or r5, r2         @ or left shifted seed in r5 with the parity result in r2 store back in r5
                      b notequal2       @ check the value in r5 with r3 if not equal branch to notequal2
                      int2_2:
                      inc r14           @ increase number of taps by 1
                      movreg tap_addr_back  @ move value in r9 back in to r2
                      movreg backseed       @ move old seed from r8 back in to r5
                      b for2                @ check to see if r14 equal to 8 if not branch back to for2
                      movreg newseed        @ move the seed in r3 into r5
                      b while2              @ branch back to while2
    skip2:
          inc r14       @ move to the next tap
          movreg tap_addr_back  @ move value in r9 back into r2
          b int1_2        @ branch back to the for loop

    notequal2:  @ not equal
          dec r9        @ decrement value in r9
          dec r11       @ decrease the number of potential taps
          movreg tap_addr_back  @ move value in r9 back into r2
          mov tap_zero          @ move 0 into r7
          sw r7, r2     @ store 0 at the memory address held in r2
          movreg tap_addr       @ move value in r2 into r9
          inc r9        @ increment the address in r9
          b int2_2        @ branch back into the for loop

  next_2:
  next2_2:
        movreg tap_addr   @ move value in r2 into r9
        lw r2, r2         @ load in a tap pattern from memory location in r2
        inc r9            @ increment value in r9 by 1
        b find            @ branch to decryption_2 if r2 is not equal to 0
        movreg tap_addr_back  @ move value in r9 back in to r2
        b next2_2          @ branch back to next2_2


find3:
      movreg backseed   @ move the value in r8 back into r5
      movreg tap_addr_back   @ move tap value
      b find2           @ branch to find2
find:     @ find first non-space character
find2:
    mov space     @ move space char into r7
    movreg tap_addr   @ move value in r2 into r9
    and r5, r2    @ and seed in r5 with tap pattern in r2 and store in r10
    lsl r5        @ left shift the value in r5
    par r10       @ take parity of thing in r10 and store in r2
    or r5, r2     @ or left shifted seed in r5 with parity result in r2 and store back in r5
    lw r2, r1     @ load in encrypted char from address specified in r1
    inc r1        @ increment the value in r1
    movreg seed   @ move seed in r5 into r8
    xor r5, r2    @ xor the shifted seed in r5 with encrypted char in r2 and store in r5
    b find3       @ if value in r5 equal to value in r7 branch to find3

sw r5, r0         @ store the decrypted non-space char into memory location specified by r0
inc r0            @ increment the value of r0 by 1
movreg backseed   @ move the value in r8 back into r5
movreg tap_addr_back  @ move the value in r9 back into r2

main_loop:
  movreg tap_addr @ move value in r2 into r9
  and r5, r2      @ and seed in r5 with tap pattern in r2 and store in r10
  lsl r5          @ left shift the value in r5
  par r10         @ take parity of thing in r10 and store in r2
  or r5, r2       @ or left shifted seed in r5 with parity result in r2 and store back in r5
  lw r2, r1       @ load in encrypted char from address specified in r1
  inc r1          @ increment the value in r1
  movreg seed     @ move seed in r5 to r8
  xor r5, r2      @ xor the shifted seed in r5 with encrypted char in r2 and store in r5
  b second_space  @ branch to second_space if we see a space char in r5
  sw r5, r0       @ store decrypted char in r5 at specified location by r0
  inc r0          @ increment the value in r0
  movreg backseed @ move the value in r8 back to r5
  movreg tap_addr_back  @ move the value in r9 back into r2
  b main_loop     @ branch back to main_loop


second_space:
    movreg backseed @ move the value in r8 back into r5
    movreg tap_addr_back  @ move the value in r9 back into r2
    and r5, r2      @ and seed in r5 with tap pattern in r2 and store in r10
    lsl r5          @ left shift the value in r5
    par r10         @ take parity of thing in r10 and store in r2
    or r5, r2       @ or left shifted seed in r5 with parity result in r2 and store back in r5
    lw r2, r1       @ load in encrypted char from address specified in r1
    inc r1          @ increment the value in r1
    movreg seed     @ move seed in r5 to r8
    xor r5, r2      @ xor the shifted seed in r5 with encrypted char in r2 and store in r5
    b end3          @ if char in r5 is space branch to end3
    mov space       @ move space char into r7
    sw r7, r0       @ store the space char in r7 at specified location by r0
    inc r0          @ increment the value in r0
    sw r5, r0       @ store the decrypted char in r5 at specified location by r0
    inc r0          @ increment the value in r0
    movreg backseed @ move the value in r8 back to r5
    movreg tap_addr_back  @ move the value in r9 back into r2
    b main_loop     @ branch back to main_loop



end3:
    stop
