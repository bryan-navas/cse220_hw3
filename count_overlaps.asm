.data
state:
.byte 8
.byte 10
.asciiz "...........O.........O.........O......O.OO.....OOOOOOO...OOOOOOOO.OOOOOOOOO.OOOO"  # not null-terminated during grading!
row: .word 5
col: .word 4
piece:
.byte 3
.byte 2
.asciiz "O.OOO." # not null-terminated during testing!

.text
main:
la $a0, state
lw $a1, row
lw $a2, col
la $a3, piece
jal count_overlaps

# report return value
move $a0, $v0
li $v0, 1
syscall

li $v0, 11
li $a0, '\n'
syscall

li $v0, 10
syscall

.include "proj3.asm"
