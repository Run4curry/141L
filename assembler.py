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

register_2bits = {'r0': '00', 'r1': '01', 'r2': '10'}
register_4bits = {'r0': '0000', 'r1': '0001', 'r2': '0010', 'r3': '0100', 'r4': '0101', 'r5': '0110',
                  'r6': '0111', 'r7': '1000', 'r8': '1001', 'r9': '1010', 'r10': '1011', 'r11': '1100',
                  'r12': '1101', 'r13': '1110', 'r14': '1111'}

label_list = ['padding:', 'message:', 'morepadding:\n', 'end:\n']
mov_lut = {'41': '00000', 'enc64': '00001', 'space2': '00010', 'zero': '00011'}
movreg_lut = {'tap_addr': '00000', 'seed': '00001', 'tap_addr_back': '00010', 'backseed': '00011'}
b_lut = {'padding': '00000', 'message': '00001', 'end': '00010', 'morepadding': '00011'}

# Read from assembly file
file = open('encrypt2.s', 'r')
output = open('assembled_encrypt.txt', 'w')
for line in file:
    if not line == '\n':
        instr = line.replace(',', '').split(" ")
        words = [i for i in instr if i]
        op = words[0]

        if op not in label_list:
            assembly_instr = opcode_dict[op] + "_"
            rs = words[1]
            rt = words[2]
            if op == 'mov':
                assembly_instr += mov_lut[rs]
                comment = " // mov " + rs
            elif op == 'lw' or op == 'and' or op == 'or' or op == 'xor' or op == 'sw':
                assembly_instr += register_4bits[rs][1:] + register_4bits[rt][2:]
                comment = " // {0} ".format(op) + rs + ", " + rt
            elif op == 'inc' or op == 'par' or op == 'lsl' or op == 'dec':
                assembly_instr += register_4bits[rs] + '0'
                comment = " // {0} ".format(op) + rs
            elif op == 'movreg':
                assembly_instr += movreg_lut[rs]
                comment = " // movreg " + rs
            elif op == 'b':
                assembly_instr += b_lut[rs]
                comment = " // b " + rs
            elif op == 'stop':
                assembly_instr += "00000"
                comment = " // stop"

            output.write(assembly_instr + comment + "\n")

output.close()
file.close()
