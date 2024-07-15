Main:
 jal  ra,  swap        # chama subrotina swap                      PC = 00
fim:
 jal  zero,  fim       # Pare                                                     PC = 04
swap:
addi  a0,  zero,  0   # carrega 0 em r10 e                             PC = 08
addi  a1,  zero,  3   # carrega 3 em r11 e                             PC = 0C
slli  t0,  a1,  2         # r5 = r11*4 = 3*4 = 12 (C em hexa) e PC = 10
add  t0,  a0,  t0      # r5 = r10 + r5 e                                     PC = 0C
lw  t1,  0(t0)           # r6 = M[0+12] = 9 e                              PC = 14
lw  t2,  4(t0)           # r7 = M[4+12] = 7 e                              PC = 18
sw  t2,  0(t0)          # M[0+12} = r7 = 7 e                              PC = 1C
sw  t1,  4(t0)          # M{4+12} = r6 = 9 e                              PC - 20
jal zero, 0                       # Pare a execucao                                   PC = 24