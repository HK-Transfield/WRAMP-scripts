.global main
.text
main:
    jal serial_job
    jal parallel_job
    bnez $1, close          # Check if parallel_job returns a value greater than 0
    j main                  # If not, keep program running

close:
    syscall                 # End program

##########################################################################################

serial_job:
    subui $sp, $sp, 1       # Create stack frame
    sw $ra, 0($sp)          # Save return address

receive:
    lw $13, 0x70003($0)
    andi $13, $13, 0x1      # Check if the RDR bit is set
    beqz $13, end_serial    # if not, loop and try again
    lw $11, 0x70001($0)     # Get the character into $9

check:
    slei $10, $11, 96       # Check if the character less than the lowercase ASCII values
    sgei $12, $11, 123      # check if the character is greater than the lowercase ASCII values
    xor $12, $10, $12        # Check which is true
    beqz $12, transmit      # If character is lowercase, transmit it
    addi $11, $0, 42        # Get the character '*' if anything else

transmit:
    lw $13, 0x70003($0)     # Get the 1st serial port status
    andi $13, $13, 0x2      # Check if the RDR bit is set
    beqz $13, end_serial    # if not, loop and try again
    sw $11, 0x70000($0)     # Send character to 1st Serial Port

end_serial:
    lw $ra, 0($sp)          # Restore the return address
    addui $sp, $sp, 1       # Destroy the stack frame
    jr $ra                  # Return to main

##########################################################################################

parallel_job:
    subui $sp, $sp, 1       # Create the stack frame
    sw $ra, 0($sp)          # save return address to the stack
    add $1, $0, $0          # Set return value to 0
    
read_par:
    lw $2, 0x73001($0)      # load the value from the push buttons 
    ori $2, $2, 0           # check if any buttons have been pressed
    beqz $2, end_parallel   # if not, loop though until a button has been pressed
    lw $3, 0x73000($0)      # load the input value from the switches

check_buttons:
    andi $6, $2, 0x4        # Leftmost button was pressed
    bnez $6, set_close
    andi $6, $2, 0x2        # Rightmost button was pressed, includes rightmost and middle button
    beqz $6, toggle_leds    # Jump to toggle lights

invert:                     # If the middle button is pressed, it will invert the swtich value
    xori $3, $3, 0xFFFF

toggle_leds:                # Handles the LED lights
    remui $7, $3, 4         # Checks if the (potentially modified) switch value is a multiple of 4
    beqz $7, on_lights      # If so, turn on the LED lights 
    sw $0, 0x7300A($0)      # If not, keep them off
    j write                 # Jump to write

on_lights:  
    addi $8, $0, 0xFFFF     # Set all LED register bits on     
    sw $8, 0x7300A($0)      # Turn on lights

write:                      # write the hexadecimal value to the SSD
    sw $3, 0x73009($0)      # Write to lower right SSD
    srli $3, $3, 4
    sw $3, 0x73008($0)      # Write to lower left SSD
    srli $3, $3, 4
    sw $3, 0x73007($0)      # Write to upper right SSD
    srli $3, $3, 4
    sw $3, 0x73006($0)      # Write to upper left SSD

end_parallel:
    lw $ra, 0($sp)          # Restore return address
    addui $sp, $sp, 1       # Destroy stack frame
    jr $ra                  # Return to main

set_close:
    addui $1, $0, 1         # Set return value to 1
    j end_parallel          # End Task