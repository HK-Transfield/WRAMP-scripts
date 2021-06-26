###################################
# HK Transfield
#
# Stopwatch
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

# Define serial macros
.equ sp2_tx,		0x71000
.equ sp2_rx,		0x71001
.equ sp2_ctrl,		0x71002
.equ sp2_stat,		0x71003
.equ sp2_iack,		0x71004

######################################################################


.global main
.text
main:

# Setup stack
    subui $sp, $sp, 1       # Create stack frame
    sw $ra, 0($sp)          # Save $ra

# Adjust the CPU control register to setup interrupts
    movsg $1, $cctrl        # Copy the current value of $cctrl into $1
    andi $1, $1, 0x000F     # Mask (disable) all interrupts
    ori $1, $1, 0xC2        # Enable IRQ2, IRQ3 and IE (global interrupt enable)
    movgs $cctrl, $1        # Copy the new CPU control value back to $cctrl

# Setup a new exception/interrupt handler
    movsg $1, $evec         # Copy the old handler's address to $1
    sw $1, old_vector($0)   # Save it to memory
    la $1, handler          # Get the address of the handler
    movgs $evec, $1         # Copy the address of the handler into $evec

# Setup timer
    sw $0, timer_iack($0)   # Acknowledge any outstanding interrupts
    addui $1, $0, 2400      # Put our count value into the timer load register
    sw $1, timer_load($0)   # Save it to the timer load register 
    addui $1, $0, 0x2       # Enable the timer and set auto-restart mode
    sw $1, timer_ctrl($0)   # Save it to the timer control register

# Setup parallel I/O
    sw $0, par_iack($0)     # Acknowledge any outstanding interrupts
    addui $1, $0, 0x3       # Enable parallel control interrupt
    sw $1, par_ctrl($0)     # Save it to the parallel control register

loop:
    lw $9, terminate($0)    # Check if termination flag has been initialized
    beqz $9, exit           # If so, exit the program

    lw $3, counter($0)      # Load current counter value from memory

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

    j loop                   # Go around again

exit: 

# Undo stack
    lw $ra, 0($sp)           # Restore $ra 
    addui $sp, $sp, 1        # Destroy the stack frame

    jr $ra                   # Return to WRAMPmon prompt

######################################################################

######################
# Main Handler
#####################
handler:

# Inspect for an IRQ2 interrupt
    movsg $13, $estat           # The cause of the interrupt   
    andi $13, $13, 0x40         # Check if the interrupt is because of the programmable timer
    bnez $13, handle_irq2       # No other interrupt; the timer caused it

# Inspect for an IRQ3 interrupt
    movsg $13, $estat           # The cause of the interrupt
    andi $13, $13, 0x80         # Check if the interrupt is because of the parallel IO    
    bnez $13, handle_irq3       # No other interrupt; the parallel IO caused it

# Another exception has occurred, call the old handler
    lw $13, old_vector($0)
    jr $13

######################
# Handlers for Timer
#####################
handle_irq2:
    sw $0, timer_iack($0)       # Acknowledge the timer interrupt

# Increment counter
    lw $13, counter($0)         # Load the current value of counter from memory
    addui $13, $13, 1           # Add 1 to that current value 
    sw $13, counter($0)         # Store it back into memory
    rfe                         # Return from exception

######################
# Handlers for Parallel
#####################
handle_irq3:
    sw $0, par_iack($0)         # Acknowledge the Parallel interrupt
    lw $13, par_btn($0)         # Check if the push buttons are pressed
    beqz $13, irq3_return       # If not, return from exception

# Rightmost button has been pressed 
    lw $13, par_btn($0)         # Load the value of the push button
    seqi $13, $13, 0x1          # Check that it was push button 0 
    bnez $13, irq3_resume       # If so, pause the counter

# Middle button has been pressed
    lw $13, par_btn($0)         # Load the value of the push button
    seqi $13, $13, 0x2          # Check that it was push button 1
    bnez $13, irq3_reset        # If so, reset the counter

# Leftmost button has been pressed
    lw $13, par_btn($0)         # Load the value of the push button
    seqi $13, $13, 0x4          # Check that it was push button 2
    bnez $13, irq3_terminate    # If so, terminate the program

irq3_resume:

# Toggle the timer
    lw $13, timer_ctrl($0)      # Load the current value of the programmable timer control
    xori $13, $13, 0x1          # Use exclusive OR to toggle the interrupt enable
    sw $13, timer_ctrl($0)      # Save it to the timer control
    rfe                         # Return from exception

irq3_reset:

# Reset the counter to 0
    lw $13, timer_ctrl($0)      # Load the value of the timer control
    seqi $13, $13, 0x3          # Check if the bits are set
    bnez $13, irq3_return       # If so, counter is incrementing
    sw $0, counter($0)          # If not, reset the counter

irq3_return:
    rfe                         # Return from exception

irq3_terminate:
    sw $0, terminate($0)        # Initialize termination flag
    rfe

######################################################################


.data
counter: .word 0

.bss
old_vector: .word
terminate:  .word
