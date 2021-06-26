###################################
# HK Transfield
#
# Counter
###################################


# Define list of macros to make code more readable
.equ par_btn,		0x73001
.equ par_ctrl,		0x73004
.equ par_iack,		0x73005
.equ par_ulssd,		0x73006
.equ par_urssd,		0x73007
.equ par_llssd,		0x73008
.equ par_lrssd,		0x73009
.equ user_itr_btn,  0x7F000

######################################################################

.text
.global main
main:

# Set up CPU Control Register
    movsg $1, $cctrl        # Copy the current value of $cctrl into $1
    andi $1, $1, 0x000f     # Mask (disable) all interrupts
    ori $1, $1, 0xAF        # Enable IRQ1, IRQ3, and IE (global interrupt enable)
    movgs $cctrl, $1        # Copy the new CPU control value back to $cctrl

# Set up $evec 
    movsg $1, $evec         # Copy the old handler's address to $1
    sw $1, old_vector($0)   # Save it to memory
    la $1, handler          # Get the address of the handler
    movgs $evec, $1         # Copy the address of the handler into $evec

    addui $13, $0, 0x3      # Enable parallel control interrupt
    sw $13, par_ctrl($0)  

loop:
    lw $3, counter($0)      # Load the current value of counter from memory

# Write 1st digit to lower right SSD
    remui $5, $3, 10
    sw $5, par_lrssd($0)      
    divui $3, $3, 10

# Write 2nd digit to lower left SSD
    remui $5, $3, 10
    sw $5, par_llssd($0)      
    divui $3, $3, 10

# Write 3rd digit to upper right SSD
    remui $5, $3, 10
    sw $5, par_urssd($0)      
    divui $3, $3, 10

# Write 4th digit to upper left SSD 
    remui $5, $3, 10
    sw $5, par_ulssd($0)      

    j loop

######################################################################

handler:
    movsg $13, $estat       # Get the cause of the interrupt
    andi $13, $13, 0x20     # Check if interrupt was caused by the user interrupt button
    bnez $13, handle_irq1   # No other interrupt happened, the user interrupt button caused it

    movsg $13, $estat       # Get the cause of the interrupt
    andi $13, $13, 0x80     # Check if the interrupt was caused by the parallel push buttons
    bnez $13, handle_irq3   # No other interrupt happened, the parallel push button caused it

    lw $13, old_vector($0)  # Restore the old old_vector as the handler
    jr $13

handle_irq1:
    sw $0, user_itr_btn($0) # Acknowledge the user interrupt 

# Increment counter
    lw $13, counter($0)     
    addi $13, $13, 1
    sw $13, counter($0)
    
    rfe

handle_irq3:
    sw $0, par_iack($0)      # Acknowledge the Parallel interrupt

    lw $13, par_btn($0)      # load the value from the push buttons 
    beqz $13, end_handle     # if not, loop though until a button has been pressed 

# Increment counter
    lw $13, counter($0)
    addi $13, $13, 1
    sw $13, counter($0)

end_handle:   
    rfe

######################################################################

.data
counter:
    .word 0

.bss
old_vector:
    .word