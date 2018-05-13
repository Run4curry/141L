mov 41    @ move address 41 into r0
lw r4, r0  @ load number of space chars specified in r0
inc r0      @ add 1 to the value of r0
lw r2, r0   @ load the lfsr feedback tap pattern into r2
inc r0      @ add 1 to the value of r0
lw r5, r0   @ load the starting seed value into r5

mov enc64   @ move a counter value of 64 into r1

padding:    @ number of space chars to encrypt
    movreg seed        @ move the seed in r5 to r8
    movreg tap_addr    @ move the value in r2 into r9
    mov space2         @ move the space char into r2
    xor r5, r2         @ xor the seed with the space char in r2 and store in r5
    sw r5, r1          @ store the encrypted char at mem location specified by r1
    inc r1             @ increment the value in r1
    dec r4             @ decrement the value in r4
    movreg backseed    @ move the seed in r8 to r5
    movreg tap_addr_back    @ move the value in r9 into r2
    and r5, r2         @ and the seed with tap in r2 store in r10
    par r10            @ take parity of the thing in r10 and store in r2
    lsl r5             @ shift the seed in r5 by 1
    or r5, r2          @ or left shifted seed in r5 with parity result in r2 and store in r5 new seed
    movreg tap_addr_back  @ move the value in r9 back into r2
    b padding          @ if r4 not equal to 0 branch back to padding

mov zero    @ move address 0 into r0

message:    @ encrypting the actual message
    movreg seed         @ move the seed in r5 to r8
    movreg tap_addr     @ move the value in r2 into r9
    lw r2, r0           @ load word from memory location in r0 into r2
    xor r5, r2          @ xor the seed with the space char in r2 and store in r5
    sw r5, r1           @ store the encrypted char at mem location specified by r1
    inc r1              @ increment value in r1 by 1
    inc r0              @ increment value in r0 by 1
    movreg backseed     @ move the seed in r8 to r5
    movreg tap_addr_back      @ move the value in r9 into r2
    and r5, r2          @ and the seed with tap in r2 store in r10
    par r10             @ take parity of the thing in r10 and store in r2
    lsl r5              @ shift the seed in r5 by 1
    or r5, r2           @ or left shifted seed in r5 with parity result in r2 and store in r5
    movreg tap_addr_back  @ move the value in r9 back into r2
    b message           @ if r0 is not equal to 0 branch back to padding

b end             @ check r1, if equal to 128 branch to end

morepadding:
    movreg seed        @ move the seed in r5 to r8
    movreg tap_addr    @ move the value in r2 into r9
    mov space2        @ move the space char into r2
    xor r5, r2         @ xor the seed with the space char in r2 and store in r5
    sw r5, r1          @ store the encrypted char at mem location specified by r1
    inc r1             @ increment the value in r1 by 1
    movreg backseed    @ move the value in r8 back into r5
    movreg tap_addr_back  @ move the value in r9 into r2
    and r5, r2         @ and the seed with tap in r2 store in r10
    par r10            @ take parity of the thing in r10 and store in r2
    lsl r5             @ shift the seed in r5 by 1
    or r5, r2          @ or left shifted seed in r5 with parity result in r2 and store in r5
    movreg tap_addr_back  @ move the value in r9 back into r2
    b morepadding     @ check the value in r1 if not equal to 128 branch back to morepadding
end:
    stop      @ sets the done flag to 1
