###################################
# HK Transfield
#
# Amazing Stopwatch
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

#########################################################################################

.global main
.text
main:

# Setup stack
    subui $sp, $sp, 1       # Create stack frame
    sw $ra, 0($sp)          # Save $ra

# Adjust the CPU control register to setup interrupts
    movsg $1, $cctrl        # Copy the current value of $cctrl into $1
    andi $1, $1, 0x000F     # Mask (disable) all interrupts
    ori $1, $1, 0xCF        # Enable IRQ2, IRQ3 and IE (global interrupt enable)
    movgs $cctrl, $1        # Copy the new CPU control value back to $cctrl

# Setup a new exception/interrupt handler
    movsg $1, $evec         # Copy the old handler's address to $1
    sw $1, old_vector($0)   # Save it to memory
    la $1, handler          # Get the address of the handler
    movgs $evec, $1         # Copy the address of the handler into $evec

# Setup timer
    sw $0, timer_iack($0)   # Acknowledge any outstanding interrupts
    addui $1, $0, 24        # Put our count value into the timer load register
    sw $1, timer_load($0)   # Save it to the timer load register 
    addui $1, $0, 0x2       # Enable the timer and set auto-restart mode
    sw $1, timer_ctrl($0)   # Save it to the timer control register

# Setup parallel I/O
    sw $0, par_iack($0)     # Acknowledge any outstanding interrupts
    addui $1, $0, 0x3       # Enable parallel control interrupt
    sw $1, par_ctrl($0)     # Save it to the parallel control register


######################
# Mainline code
#####################
loop:    
    lw $7, counter($0)       # Load current value of counter from memory

    lw $9, terminate($0)     # Load the termination flag from memory
    beqz $9, end_program     # If it has been initialized, end program

    lw $3, print($0)         # Check if the print flag has been initialized
    beqz $3, writessd        # If not, continue incrementing the counter

######################
# Transmit Characters
#####################
return_char:
    lw $9, sp2_stat($0)     # Get the status of Serial Port 2
    andi $9, $9, 0x2        # Check if the TDS bit is set
    beqz $9, return_char    # If not, loop and try again

# Transmit '\r'
    addi $9, $0, '\r'
    sw $9, sp2_tx($0)
    
newline_char:
    lw $9, sp2_stat($0)     # Get the status of Serial Port 2
    andi $9, $9, 0x2        # Check if the TDS bit is set
    beqz $9, newline_char   # If not, loop and try again  

# Transmit '\n' to SP2
    addi $9, $0, '\n'
    sw $9, sp2_tx($0)

first_digit:
    lw $9, sp2_stat($0)     # Get the status of Serial Port 2
    andi $9, $9, 0x2        # Check if the TDS bit is set
    beqz $9, first_digit    # If not, loop and try again

# Transmit 's' to SP2
    divui $9, $7, 1000
    remui $9, $9, 10
    addui $9, $9, '0'
    sw $9, sp2_tx($0)

second_digit:
    lw $9, sp2_stat($0)     # Get the status of Serial Port 2
    andi $9, $9, 0x2        # Check if the TDS bit is set
    beqz $9, second_digit   # If not, loop and try again

# Transmit 's' to SP2
    divui $9, $7, 100
    remui $9, $9, 10
    addui $9, $9, '0'
    sw $9, sp2_tx($0)

period_char:
    lw $9, sp2_stat($0)     # Get the status of Serial Port 2
    andi $9, $9, 0x2        # Check if the TDS bit is set
    beqz $9, period_char    # If not, loop and try again

# Transmit '.' to SP2
    addui $9, $0, '.'
    sw $9, sp2_tx($0)

third_digit:
    lw $9, sp2_stat($0)     # Get the status of Serial Port 2
    andi $9, $9, 0x2        # Check if the TDS bit is set
    beqz $9, third_digit    # If not, loop and try again

# Transmit 's' to SP2
    divui $9, $7, 10
    remui $9, $9, 10
    addui $9, $9, '0'
    sw $9, sp2_tx($0)

fourth_digit:
    lw $9, sp2_stat($0)     # Get the status of Serial Port 2
    andi $9, $9, 0x2        # Check if the TDS bit is set
    beqz $9, fourth_digit   # If not, loop and try again

# Transmit 's' to SP2
    remui $9, $7, 10
    addui $9, $9, '0'
    sw $9, sp2_tx($0)

    sw $0, print($0)        # Reset the print flag

######################
# Write to SSD
#####################
writessd:
    divui $7, $7, 100       # Divide the counter by 100 so it displays seconds elapsed

# Write 1st digit to lower right SSD
    remui $5, $7, 10
    sw $5, par_lrssd($0)      
    divui $7, $7, 10

# Write 2nd digit to lower left SSD 
    remui $5, $7, 10
    sw $5, par_llssd($0)       

    j loop

end_program:

# Undo stack
    lw $ra, 0($sp)          # Restore $ra 
    addui $sp, $sp, 1       # Destroy the stack frame

    jr $ra                   # Close the program, return to WRAMPmon prompt

#########################################################################################

######################
# Main Handler
#####################
handler:

# Inspect for an IRQ2 interrupt
    movsg $13, $estat        # The cause of the interrupt   
    andi $13, $13, 0x40      # Check if the interrupt is because of the programmable timer
    bnez $13, handle_irq2    # No other interrupt; the timer caused it

# Inspect for an IRQ3 interrupt
    movsg $13, $estat        # The cause of the interrupt
    andi $13, $13, 0x80      # Check if the interrupt is because of the parallel IO    
    bnez $13, handle_irq3    # No other interrupt; the parallel IO caused it

# Another exception has occurred, call the old handler
    lw $13, old_vector($0)
    jr $13

######################
# Handlers for Timer
#####################
handle_irq2:
    sw $0, timer_iack($0)    # Acknowledge the interrupt

# Increment counter 100 times per second
    lw $13, counter($0)      # Load the current value of counter from memory
    addui $13, $13, 1        # Add 1 to that current value 
    sw $13, counter($0)      # Store it back into memory
    rfe                      # Return from exception

######################
# Handlers for Parallel
#####################
handle_irq3:
    sw $0, par_iack($0)      # Acknowledge the Parallel interrupt
    lw $13, par_btn($0)      # Do something only if the push buttons are pressed
    beqz $13, irq3_return    # If not, return from exception

# Rightmost button has been pressed
    lw $13, par_btn($0)       
    seqi $13, $13, 0x1
    bnez $13, irq3_resume

# Middle button has been pressed
    lw $13, par_btn($0)      
    seqi $13, $13, 0x2
    bnez $13, irq3_reset

# Leftmost button has been pressed 
    lw $13, par_btn($0)     
    seqi $13, $13, 0x4
    bnez $13, irq3_terminate

irq3_resume:
# Toggle the timer
    lw $13, timer_ctrl($0)
    xori $13, $13, 0x1
    sw $13, timer_ctrl($0)
    rfe

irq3_reset:
# Reset the counter to 0
    lw $13, timer_ctrl($0)
    seqi $13, $13, 0x3
    bnez $13, irq3_print        # If it's still counting, print time to SP2
    sw $0, counter($0)
    rfe

irq3_print:
    addui $13, $0, 1
    sw $13, print($0)

irq3_return:
    rfe

irq3_terminate:
    sw $0, terminate($0)
    rfe

#########################################################################################

.data
counter:    .word 0
print:      .word 0

.bss
old_vector: .word
terminate:  .word 