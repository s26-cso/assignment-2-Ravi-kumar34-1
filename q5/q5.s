.data
    filename: .string "input.txt"
    mode:     .string "r"
    yes_msg:  .string "Yes\n"
    no_msg:   .string "No\n"

.text
.globl main
.extern fopen
.extern fseek
.extern ftell
.extern fgetc
.extern fclose
.extern printf

main:
    # ------------------------------------
    # Prologue: Save registers on stack
    # ------------------------------------
    addi sp, sp, -64
    sd ra, 56(sp)
    sd s0, 48(sp)       # s0 = FILE pointer
    sd s1, 40(sp)       # s1 = left index
    sd s2, 32(sp)       # s2 = right index
    sd s3, 24(sp)       # s3 = file size
    sd s4, 16(sp)       # s4 = left character

    # ------------------------------------
    # Step 1: Open input.txt
    # ------------------------------------
    la a0, filename
    la a1, mode
    call fopen
    mv s0, a0           # Save FILE* in s0
    beqz s0, exit_err   # If NULL, file didn't open properly

    # ------------------------------------
    # Step 2: Find the size of the file
    # ------------------------------------
    mv a0, s0
    li a1, 0
    li a2, 2            # SEEK_END = 2
    call fseek

    mv a0, s0
    call ftell
    mv s3, a0           # Save size in s3

    blez s3, is_palin   # If size <= 0, empty string is a palindrome!

    # ------------------------------------
    # Step 3: Handle trailing newlines
    # Text editors often add an invisible '\n'
    # at the end of a file. Let's ignore it.
    # ------------------------------------
    mv a0, s0
    addi a1, s3, -1     # Go to last character
    li a2, 0            # SEEK_SET = 0
    call fseek

    mv a0, s0
    call fgetc
    li t0, 10           # ASCII for '\n'
    bne a0, t0, setup_loop
    addi s3, s3, -1     # If it is a newline, reduce the effective file size by 1

setup_loop:
    # ------------------------------------
    # Step 4: Setup Two Pointers
    # ------------------------------------
    li s1, 0            # left = 0
    addi s2, s3, -1     # right = size - 1

loop:
    # If left >= right, we checked everything! It's a palindrome.
    bge s1, s2, is_palin 

    # --- Read Left Character ---
    mv a0, s0
    mv a1, s1           # offset = left
    li a2, 0            # SEEK_SET
    call fseek

    mv a0, s0
    call fgetc
    mv s4, a0           # Save left char in s4

    # --- Read Right Character ---
    mv a0, s0
    mv a1, s2           # offset = right
    li a2, 0            # SEEK_SET
    call fseek

    mv a0, s0
    call fgetc          # Right char is now in a0

    # --- Compare ---
    bne s4, a0, not_palin # If left != right, jump to not_palin

    # Move pointers inwards
    addi s1, s1, 1      # left++
    addi s2, s2, -1     # right--
    j loop              # Repeat

is_palin:
    la a0, yes_msg
    call printf
    j cleanup

not_palin:
    la a0, no_msg
    call printf

cleanup:
    # Close the file to prevent memory/file descriptor leaks
    mv a0, s0
    call fclose

    li a0, 0            # return 0 (Success)
    j restore

exit_err:
    li a0, 1            # return 1 (Error)

restore:
    # ------------------------------------
    # Epilogue: Restore registers
    # ------------------------------------
    ld ra, 56(sp)
    ld s0, 48(sp)
    ld s1, 40(sp)
    ld s2, 32(sp)
    ld s3, 24(sp)
    ld s4, 16(sp)
    addi sp, sp, 64
    ret
    