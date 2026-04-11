.data 
fmt:
    .string "%d"

.text
# a0-> no of element
stack:
    li a7, 9
    slli a0,a0,2
    ecall
    li s0, -1               # top index
    ret
# a0 base address
# a1 val
insert:
    addi s0,s0,1            # increse the index
    slli t0,s0,2            # set the offset

    add t1,t0, a0           # address in memory 
    sw a1,0(t1)
    ret

# a0 base address
view:
    slli t0,s0,2
    add t1,t0,a0
    lw a0, 0(t1)
    ret

next_greater:
    mv s1, a1               # base address of arr;
    mv s2, a0               # size of arr
    jal ra, stack

    mv s3,a0                # base address of stack
               

for:
    addi s2,s2,-1
    blt s2,x0, exit

    slli t1, s2,2
    add t2,t1,s1            
    lw t3, 0(t2)            # t3->arr[i]

while:
    blt s0,x0,exit2

    mv a0, s3
    jal ra, view               # a0->top of stack

    blt t3,a0,true
    addi s0,s0,-1
    j while

true:
    sw a0, 0(t2)
    j join
    
exit2:
    li t4,-1
    sw t4,0(t2)

join:
    mv a1,t3
    mv a0,s3
    jal ra, insert
    j for

exit:   
    
    lla a0,fmt
    printf
