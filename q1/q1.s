# struct Node {
#     int val;
#     struct Node* left;
#     struct Node* right;
# };



# Register	Name	Use
# x0	    zero	always 0
# x1	    ra	    return address
# x2	    sp	    stack pointer
# x10–x17	a0–a7	function arguments
# x5–x7	    t0–t2	temporary
# x8–x9	    s0–s1	saved
# x18–x27	s2–s11	saved

    # a7=service 
    # Work	        a7 value
    # Print int	        1
    # Print string	    4
    # Read int	        5
    # Allocate memory	9
    # Exit	            10

.text
.globl make_node

# make_node(int val){
#     struct node* new=malloc(sizeof(struct node));
#     new->val=val;
#     new->left=NULL;
#     new->right=NULL;
#     return new;
#     }

make_node:
    addi sp, sp,-16
    sw a0, 0(sp)        # sp[0]=val
    sw ra, 8(sp)
    li a7 , 9                   


    li a0, 12           # memory allocate of 12 byte

    ecall

    lw t0, 0(sp)        # t0=val
    sw t0, 0(a0)        # node->val=val
    sw zero, 4(a0)      # node->left=NULL
    sw zero, 8(a0)      # node->right=NULL

    lw ra , 8(sp)
    addi sp, sp, 16
    ret

# struct Node* insert(struct Node* root, int val){
#     struct Node* temp=root;
#     while(!root){
#         if(root->val>val)root=root->left;
#         else root=root->right;
#         }
#     root=make_node(val);
#     return temp;

insert:
    beqz a0, make           # if root==NULL

    lw t0, 0(a0)            # root->val

    addi sp, sp, -16
    sw a0, 0(sp)            # save root
    sw ra, 4(sp)

    ble t0, a1, right       #if root->val <= val
    

left:
    lw a0, 4(a0)            # root->left
    jal ra, insert

    lw t1, 0(sp)            # restore root
    sw a0, 4(t1)            # root->letf = result

    lw ra, 4(sp)
    addi sp, sp, 16

    mv a0, t1               # return root
    ret;

right:
    lw a0, 8(a0)            # root->right
    jal ra, insert

    lw t1, 0(sp)            # restore root
    sw a0, 8(t1)            # root->right= result

    lw ra, 4(sp)
    addi sp, sp, 16

    mv a0, t1               # return root

    ret;

make:
    mv a0, a1               # val-> a0
    jal ra, make_node       
    ret
# ************************************** #

get:
    beqz a0, Exit
    lw t0, 0(a0)
    
    beq t0, a1, Exit
    blt t0, a1, right
left:
    lw a0,4(a0)
    j get
right:
    lw a0, 8(a0)
    j get;
Exit:
    ret;

# ************************************** #

getATMost:
    li s0,-1
loop:
    beqz a1,exit
    lw t0, 0(a1)

    ble t0, a0, right_get
left_get:
    lw a1,4(a1)
    j loop
right_get:
    mv s0, t0
    lw a1, 8(a1)
    j loop

exit:
    mv a0,s0
    ret