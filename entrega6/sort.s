main:

    .data
    arr: 
    .word 71
    .word 27
    .word 50
    arrS: 
    .word 3

    .text
    lui a0, %hi(arr) 
    addi a0, a0, %lo(arr)

    lui a1, %hi(arrS) 
    addi a1, a1, %lo(arrS)
    lw a1, 0(a1)

    addi sp,sp,-20 
    sw ra, 16(sp)
    sw s3, 12(sp) 
    sw s2, 8(sp)
    sw s1, 4(sp)
    sw s0, 0(sp)

    mv  s0,  zero

    for1tst:

    slt  t0,  s0, s3 
    beq  t0,  zero, exit1
    addi  s1,s0,-1

    for2tst:

    slti  t0,  s1,0 
    bne  t0,  zero, exit2 
    slli  t1,  s1, 2
    add  t2,  s2,  t1
    lw  t3, 0( t2)
    lw  t4, 4( t2)
    slt  t0,  t4,  t3 
    beq  t0,  zero, exit2

    mv  a0,  s2 
    mv  a1,  s1 
    jal swap

    addi  s1,  s1, -1
    j for2tst

    exit2: 

    addi  s0,  s0, 1 
    j for1tst 
    
    exit1: 

    lw  s0, 0( sp) 
    lw  s1, 4( sp)
    lw  s2, 8( sp)
    lw  s3,12( sp) 
    lw  ra,16( sp) 
    addi  sp, sp, 20 

    swap: 
    slli  t1,  a1, 2
    add  t1,  a0,  t1 
    
    lw  t0, 0( t1) 
    lw  t2, 4( t1) 
    
    sw  t2, 0( t1) 
    sw  t0, 4( t1) 
    jr  ra