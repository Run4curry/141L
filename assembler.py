opcode_dict = {'lw': '0000',
               'sw': '0001',
               'mov': '0010',
               'xor': '0011',
               'and': '0100',
               'or': '0101',
               'lsl': '0110',
               'b': '0111',
               'inc': '1000',
               'par': '1001',
               'dec': '1010',
               'stop': '1011',
               'movreg': '1100'}

register_4bits = {'r0': '0000', 'r1': '0001', 'r2': '0010', 'r3': '0011', 'r4': '0100', 'r5': '0101',
                  'r6': '0110', 'r7': '0111', 'r8': '1000', 'r9': '1001', 'r10': '1010', 'r11': '1011',
                  'r12': '1100', 'r13': '1101', 'r14': '1110', 'r15' : '1111'}

label_list = ['padding:', 'message:', 'morepadding:', 'end:', 'while:', 'for:', 'int1:',
              'int2:', 'skip:', 'notequal:', 'next:', 'next2:', 'decryption:', 'decryption3:',
              'decryption2:', 'while2:', 'main_loop:', 'second_space:', 'end3:']
mov_lut = {'41': '00000', 'enc64': '00001', 'space2': '00010', 'zero': '00011', '8taps': '00100',
           'tap_addr': '00101', 'counttaps': '00110', 'tap_zero': '00111', 'space': '01000'}
movreg_lut = {'tap_addr': '00000', 'seed': '00001', 'tap_addr_back': '00010', 'backseed': '00011',
              'seed2': '00100', 'newseed': '00101'}
b_lut = {'padding': '00000', 'message': '00001', 'end': '00010', 'morepadding': '00011',
         'while': '00100', 'next': '00101', 'skip': '00110', 'notequal': '00111', 'for': '01000',
         'int1': '01001', 'int2': '01010', 'decryption': '01011', 'next2': '01100', 'decryption3': '01101',
         'decryption2': '01110', 'edge': '01111', 'main_loop': '10000', 'second_space': '10001',
         'end3': '10010'}

# Read from assembly file
file = open('encrypt2.s', 'r')
output = open('encrypt2.txt', 'w')
for line in file:
    if not line == '\n':
        instr = line.replace(',', '').split(" ")
        words = [i for i in instr if i]
        op = words[0].replace('\n', '')

        if op not in label_list:
            assembly_instr = opcode_dict[op] + "_"
            if op == 'stop':
                assembly_instr += "00000"
                comment = " // stop"
            else:
                rs = words[1]
                if op == 'mov':
                    assembly_instr += mov_lut[rs]
                    comment = " // mov " + rs
                if op == 'inc' or op == 'par' or op == 'lsl' or op == 'dec':
                    assembly_instr += register_4bits[rs] + '0'
                    comment = " // {0} ".format(op) + rs
                if op == 'movreg':
                    assembly_instr += movreg_lut[rs]
                    comment = " // movreg " + rs
                if op == 'b':
                    assembly_instr += b_lut[rs]
                    comment = " // b " + rs
                if op == 'lw' or op == 'and' or op == 'or' or op == 'xor' or op == 'sw':
                    rt = words[2]
                    assembly_instr += register_4bits[rs][1:] + register_4bits[rt][2:]
                    comment = " // {0} ".format(op) + rs + ", " + rt
            output.write(assembly_instr + comment + "\n")

output.close()
file.close()
