riscv_mp2test.s:
.align 4
.section .text
.globl _start
    # Refer to the RISC-V ISA Spec for the functionality of
    # the instructions in this test program.
_start:
    # Note that the comments in this file should not be taken as
    # an example of good commenting style!!  They are merely provided
    # in an effort to help you understand the assembly style.

    # Note that one/two/eight are data labels
    lui  x1, 262144       # X1 <= 40000000                                  | Done
    lw   x25, (x1)        # Data forward working X25 = 400000b7             | Done
    addi x25, x25, 255    # Data Hzd - one bubble working X25 = 400001b6    | Done
    sw   x25, (x25)       # Data fwd to rs2 working                         | Done 
    auipc x2, 8           # X2 = 40008010                                   | Done
    addi x1, x1, 152      # X1 = 40000098                                   | Done
    addi x2, x1, 152      # X2 = 40000130                                   | Done

    lui  x1, 262144       # Testing writeback                               | Done
    addi x1, x1, 950      # X1 = 400003b6 (addr same set)
    sw   x1, (x1)         # 
    lw   x23, (x1)        # X23 = 400001b6

    lw   x24, (x25)       # RAW with load-store    X24= 400001b6            | Done



    lb   x10, (x1)        # x10 = rand_data | Load working
    addi x20, x10, 1       # Create data conflicts
    sw   x20, 0(x1)
    lui  x2, 66             # X2 <= 2000     | LUI working
    addi x2, x2, 255
    sb   x2, (x1)          # Store (sw)
    lhu   x10, (x1)         # x10 = 2000     | Store working
    xori x2, x2, 170
    xori x2, x2, 85       # x2 = 20ff       | Xori working
    slli x1, x1, 1       # x1 = 8xxxxxxx        | load x1 with leading 1 (slli working)
    srai x1, x1, 1       # x1 = cxxxxxxx       | srai (and srli) working (swap between commands to see correct msg bit in r1)
    xor  x2, x2, x2        # x2 = 0          | xor working 
    lui  x11, 65535        # x11 = ffff
    addi x7, x7, 1	   # x7 = 1
    and  x10, x10, x11     # x10 = 2000      | and working
    sra  x1, x1, x7        # x1 = exxxxxxx   | sra working
    andi x11, x10, 255     # x11 = 0       | Andi working
    or  x10, x10, 15       # x10 = 200f    | or working
    sll  x1, x1, x7        # x1 = 8xxxxxxx   | sll working
    ori  x10, x10, 255    # x10 = 20ff   | or working
    lui  x2, 2            # x2 = 2000 
    srl  x1, x1, x7        # x1 = 6xxxxxxx   | srl working
    sub  x2, x10, x2      # x2 = ff | sub working
    add  x12, x2, x5
    or   x13, x6, x2
    add  x14, x2, x2
    #sd   x15, 100(x2) TODO: Nitish talk with your teammates
    slti x9, x7, 4         # x7 = 1 < 5 true, x9 = 1 | working
    slti x9, x7, 0         # x7 = 1 < 0 false, x9 = 0 | working
    xor  x2, x2, x2        # x2 = 0        | xor working 
    slt x9, x7, x10         # x7 = 1 < 20ff true, x9 = 1 | working?

    addi x0, x0, 0
    addi x0, x0, 0
    addi x0, x0, 0
    addi x0, x0, 0
    loop1:
    slt x9, x7, x2         # x7 = 1 < 0 false, x9 = 0 | working?
    lui  x3, 8     # X3 <= 8
    addi x25, x25, 0
    addi x25, x25, 0
    lw  x1, threshold # X1 <- 0x80
    srli x2, x2, 12
    srli x3, x3, 12

    addi x4, x3, 4    # X4 <= X3 + 2


    slli x3, x3, 1    # X3 <= X3 << 1
    xori x5, x2, 127  # X5 <= XOR (X2, 7b'1111111)
    addi x5, x5, 1    # X5 <= X5 + 1
    addi x4, x4, 4    # X4 <= X4 + 8

    bleu x4, x1, loop1   # Branch if last result was zero or positive.

    andi x6, x3, 64   # X6 <= X3 + 64

    auipc x7, 8         # X7 <= PC + 8
    lw x8, good         # X8 <= 0x600d600d
    la x10, result      # X10 <= Addr[result]
    sw x8, 0(x10)       # [Result] <= 0x600d600d
    lw x9, result       # X9 <= [Result]
    bne x8, x9, deadend # PC <= bad if x8 != x9

    
    #lui  x3, 8     # X3 <= 8
    #addi x25, x25, 0
    #addi x25, x25, 0
    #lw  x1, threshold # X1 <- 0x80
    #srli x2, x2, 12
    #srli x3, x3, 12

    #addi x4, x3, 4    # X4 <= X3 + 2


    slli x3, x3, 1    # X3 <= X3 << 1
    #xori x5, x2, 127  # X5 <= XOR (X2, 7b'1111111)
    #addi x5, x5, 1    # X5 <= X5 + 1
    #addi x4, x4, 4    # X4 <= X4 + 8

    #bleu x4, x1, loop1   # Branch if last result was zero or positive.
    addi x5, x5, 1    # X5 <= X5 + 1
    addi x4, x4, 4    # X4 <= X4 + 8

    #andi x6, x3, 64   # X6 <= X3 + 64

    #auipc x7, 8         # X7 <= PC + 8
    #lw x8, good         # X8 <= 0x600d600d
    #la x10, result      # X10 <= Addr[result]
    #sw x8, 0(x10)       # [Result] <= 0x600d600d
    #lw x9, result       # X9 <= [Result]
    #bne x8, x9, deadend # PC <= bad if x8 != x9

    #li  t0, 1
    #la  t1, tohost
    #sw  t0, 0(t1)
    #sw  x0, 4(t1)
#halt:                 # Infinite loop to keep the processor
    #beq x0, x0, halt  # from trying to execute the data below.
                      # Your own programs should also make use
                      # of an infinite loop at the end.

deadend:
    lw x8, bad     # X8 <= 0xdeadbeef
deadloop:
    beq x8, x8, deadloop

.section .rodata

bad:        .word 0xdeadbeef
threshold:  .word 0x00000040
result:     .word 0x00000000
good:       .word 0x600d600d

dummy:	    .word 0x00000004
testval:    .word 0x80000001

.section ".tohost"
.globl tohost
tohost: .dword 0
.section ".fromhost"
.globl fromhost
fromhost: .dword 0
