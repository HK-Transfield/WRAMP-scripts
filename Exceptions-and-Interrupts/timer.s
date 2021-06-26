###################################
# HK Transfield
#
# Timer
###################################


# Define programmable timer macros
.equ timer_ctrl,    0x72000
.equ timer_load,    0x72001
.equ timer_count,   0x72002
.equ timer_iack,    0x72003 

# Define parallel macros
.equ par_btn,		0x73001
.equ par_ctrl,		0x73004
.equ par_iack,		0x73005
.equ par_ulssd,		0x73006
.equ par_urssd,		0x73007
.equ par_llssd,		0x73008
.equ par_lrssd,		0x73009

######################################################################

.text
.global main
main:

# Adjust the CPU control register to setup interrupts
    movsg $1, $cctrl        # Copy the current value of $cctrl into $1
    andi $1, $1, 0x000f     # Mask (disable) all interrupts
    ori $1, $1, 0x4F        # Enable IRQ2 and IE (global interrupt enable)
    movgs $cctrl, $1        # Copy the new CPU control value back to $cctrl

# Setup a new exception/interrupt handler
    movsg $1, $evec         # Copy the old handler's address to $1
    sw $1, old_vector($0)   # Save it to memory
    la $1, handler          # Get the address of the handler
    movgs $evec, $1         # Copy the address of the handler into $evec

# Setup timer
    sw $0, timer_iack($0)   # Acknowledge any outstanding interrupts
    addui $1, $0, 2400      # Put our count value into the timer load register
    sw $1, timer_load($0)    
    addui $1, $0, 0x3       # Enable the timer and set auto-restart mode
    sw $1, timer_ctrl($0)  

loop:
    lw $3, counter($0)      # Load current value of counter from memory

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

    j loop                  # Go around again

######################################################################

handler:
    movsg $13, $estat       # The cause of the interrupt
    andi $13, $13, 0x40     # Check if the interrupt is because of the programmable timer (IRQ2)
    bnez $13, handle_irq2   # No other interrupt; the timer caused it
    lw $13, old_vector($0)  # Restore the old old_vector as the handler
    jr $13                  # This will stop counting

handle_irq2:
    sw $0, timer_iack($0)   # Acknowledge the IRQ2 interrupt

# Increment counter
    lw $13, counter($0)     # Load counter from memory
    addi $13, $13, 1        # Increment counter by 1
    sw $13, counter($0)     # Save new counter value to memory
    rfe                     # Return from interrupt/exception

######################################################################

.data
counter: .word 0

.bss
old_vector: .word
