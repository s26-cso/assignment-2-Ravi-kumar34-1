.data 
fmt:
    .string "%d "

# ---------------- REGISTER MEANING ----------------
# s0 -> top index of stack
# s1 -> base address of integer array
# s2 -> loop index (i)
# s3 -> base address of stack
# s4 -> size of array
# s5 -> base address of original argv (char**)

.text
.extern printf

# ============================================================
# HELPER FUNCTIONS
# ============================================================

# ---- allocate stack ----
.extern malloc
stack:
    addi sp, sp, -16      # Save ra because we are calling malloc
    sd ra, 8(sp)

    slli a0, a0, 2        # allocate size * 4 bytes
    call malloc           # Use standard C malloc instead of ecall 9
    
    li s0, -1             # initialize stack top = -1 (empty)

    ld ra, 8(sp)          # Restore ra
    addi sp, sp, 16
    ret

# ---- stack insert ----
# a0 -> stack base address
# a1 -> value to insert
insert:
    addi s0, s0, 1        # increase top index
    slli t0, s0, 2        # offset = top * 4
    add t1, t0, a0        # address = base + offset
    sw a1, 0(t1)          # push value
    ret

# ---- stack view ----
# a0 -> stack base address
view:
    slli t0, s0, 2        # offset = top * 4
    add t1, t0, a0        # address of top element
    lw a0, 0(t1)          # load top element
    ret

# ---- str_to_int ----
# Input:  a0 -> pointer to null-terminated string
# Output: a0 -> integer value
str_to_int:
    li t0, 0              # t0 = result (starts at 0)
    li t1, 10             # t1 = 10 (multiplier)
str_to_int_loop:
    lbu t2, 0(a0)         # Load 1 byte (character)
    beq t2, zero, str_to_int_done 
    addi t2, t2, -48      # Convert ASCII to integer ('0' is 48)
    mul t0, t0, t1        # result = result * 10
    add t0, t0, t2        # result = result + digit
    addi a0, a0, 1        # Move to next character
    j str_to_int_loop
str_to_int_done:
    mv a0, t0             # Return result in a0
    ret

# ============================================================
# MAIN FUNCTION
# ============================================================
.globl main
main:
    # -------- PROLOGUE --------
    # Save ra so we can exit safely!
    addi sp, sp, -16
    sd ra, 8(sp)          

    # -------- INITIALIZATION --------
    addi s4, a0, -1       # s4 = size of array (argc - 1)
    mv s5, a1             # s5 = argv base address

# -------- ALLOCATE INTEGER ARRAY --------
    slli a0, s4, 2        # allocate size * 4 bytes for integers
    call malloc           # REPLACED ECALL 9 WITH MALLOC
    mv s1, a0             # s1 = base address of NEW integer array

    # -------- CONVERT ARGV STRINGS TO INTEGERS --------
    li s2, 0              # Loop index i = 0
    
parse_loop:
    bge s2, s4, parse_done

    addi t0, s2, 1        # Skip argv[0] ("a.out")
    slli t0, t0, 3        # Multiply by 8 to get offset (64-bit pointers)
    add t0, t0, s5        # t0 = address of argv[i+1]
    ld a0, 0(t0)          # a0 = pointer to string (e.g., "21")

    jal ra, str_to_int    # Call our function! a0 now = integer (e.g., 21)

    slli t1, s2, 2        # offset = i * 4 bytes
    add t1, t1, s1
    sw a0, 0(t1)          # arr[i] = integer

    addi s2, s2, 1        # i++
    j parse_loop

parse_done:
    # -------- CREATE STACK --------
    mv a0, s4             # pass size to stack
    jal ra, stack
    mv s3, a0             # s3 = base address of stack
    
    mv s2, s4             # s2 = size (reset loop index for NGE logic)

# -------- MAIN LOOP (RIGHT → LEFT) --------
for:
    addi s2, s2, -1       # i--
    blt s2, x0, exit      # if i < 0 → exit (changed ble to blt so it processes index 0)

    # load arr[i]
    slli t1, s2, 2
    add t2, t1, s1
    lw t3, 0(t2)          # t3 = arr[i]

# -------- WHILE LOOP --------
while:
    blt s0, x0, empty     # if stack empty → exit2

    mv a0, s3
    jal ra, view          # a0 = stack[top]

    blt t3, a0, true      # if arr[i] < stack[top] → found
    addi s0, s0, -1       # else pop
    j while

# -------- FOUND NEXT GREATER --------
true:
    sw a0, 0(t2)          # arr[i] = next greater
    j join

# -------- STACK EMPTY CASE --------
empty:
    li t4, -1
    sw t4, 0(t2)          # arr[i] = -1

# -------- PUSH CURRENT ELEMENT --------
join:
    mv a1, t3             # value = arr[i] (push original value, not the overwritten one)
    mv a0, s3             # stack base
    jal ra, insert        # push into stack
    j for

# -------- PRINT RESULT --------
exit:   
    li s6, 0              # s6 = index (Using s6 because printf destroys t0!)

print_loop:
    beq s6, s4, return    # if i == size → end

    mv a1, s1
    slli t1, s6, 2        # calculate offset using s6
    add a1, a1, t1
    lw a1, 0(a1)          # load arr[i] into a1

    lla a0, fmt
    call printf           # print value (This destroys t0-t6, but s6 is safe!)

    addi s6, s6, 1        # i++
    j print_loop

# -------- END --------
return:
    # Restore ra and exit
    ld ra, 8(sp)          
    addi sp, sp, 16       
    li a0, 0              # Return code 0 (success)
    ret
