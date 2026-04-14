.text

# Make functions visible to C (linker)
.globl make_node
.globl insert
.globl get
.globl getAtMost

.extern malloc     # use C malloc for dynamic memory

# =========================================================
# struct Node {
#   int val;          -> offset 0
#   padding           -> offset 4
#   Node* left;       -> offset 8
#   Node* right;      -> offset 16
# }
# Total size = 24 bytes
# =========================================================


# =========================================================
# make_node(int val)
# Allocates memory and initializes a node
# Input:  a0 = val
# Output: a0 = pointer to new node
# =========================================================
make_node:
    addi sp, sp, -16        # allocate stack space
    sd a0, 0(sp)            # save input val
    sd ra, 8(sp)            # save return address

    li a0, 24               # size of struct Node
    call malloc             # allocate memory → returns pointer in a0

    ld t0, 0(sp)            # restore val
    sw t0, 0(a0)            # node->val = val

    sd zero, 8(a0)          # node->left = NULL
    sd zero, 16(a0)         # node->right = NULL

    ld ra, 8(sp)            # restore return address
    addi sp, sp, 16         # restore stack
    ret


# =========================================================
# insert(root, val)
# Inserts a value into BST
# Input:  a0 = root, a1 = val
# Output: a0 = root (possibly new)
# =========================================================
insert:
    beqz a0, make           # if root == NULL → create new node

    addi sp, sp, -16
    sd ra, 8(sp)            # save return address
    sd a0, 0(sp)            # save current root

    lw t0, 0(a0)            # load root->val

    blt a1, t0, go_left     # if val < root->val → go left

# ---------------- RIGHT SUBTREE ----------------
go_right:
    ld a0, 16(a0)           # move to root->right
    jal ra, insert          # recursive insert

    ld t1, 0(sp)            # restore original root
    sd a0, 16(t1)           # root->right = returned subtree

    ld ra, 8(sp)            # restore return address
    addi sp, sp, 16
    mv a0, t1               # return root
    ret

# ---------------- LEFT SUBTREE ----------------
go_left:
    ld a0, 8(a0)            # move to root->left
    jal ra, insert

    ld t1, 0(sp)
    sd a0, 8(t1)            # root->left = returned subtree

    ld ra, 8(sp)
    addi sp, sp, 16
    mv a0, t1
    ret

# ---------------- CREATE NODE ----------------
make:
    mv a0, a1               # pass val to make_node
    j make_node             # jump (tail call optimization)


# =========================================================
# get(root, val)
# Searches for a node with given value
# Input:  a0 = root, a1 = val
# Output: a0 = pointer to node OR NULL
# =========================================================
get:
    beqz a0, ret_null       # if root == NULL → return NULL

    lw t0, 0(a0)            # load root->val

    beq t0, a1, done        # if equal → found node
    blt t0, a1, get_right   # if root->val < val → go right

# LEFT
get_left:
    ld a0, 8(a0)            # move to left child
    j get

# RIGHT
get_right:
    ld a0, 16(a0)           # move to right child
    j get

done:
    ret                     # return node pointer

ret_null:
    ret                     # return NULL


# =========================================================
# getAtMost(val, root)
# Finds largest value ≤ given val
# Input:  a0 = val, a1 = root
# Output: a0 = result OR -1 if none
# =========================================================
getAtMost:
    li t1, -1               # t1 = answer (default -1)

loop:
    beqz a1, exit           # if root == NULL → done

    lw t0, 0(a1)            # load current node value

    ble t0, a0, go_right2   # if node->val ≤ val → possible answer

# LEFT
go_left2:
    ld a1, 8(a1)            # move to left subtree
    j loop

# RIGHT
go_right2:
    mv t1, t0               # update answer
    ld a1, 16(a1)           # move to right subtree
    j loop

exit:
    mv a0, t1               # return answer
    ret
    