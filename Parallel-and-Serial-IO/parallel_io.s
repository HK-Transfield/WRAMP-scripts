.global main
.text
main:
    lw $2, 0x73001($0)      # load the value from the push buttons 
    ori $2, $2, 0           # check if any buttons have been pressed
    beqz $2, main           # if not, loop though until a button has been pressed
    lw $3, 0x73000($0)      # load the input value from the switches
    
check_buttons:
    andi $6, $2, 0x4        # Leftmost button was pressed
    bnez $6, end
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
    j main

end:
    jr $ra                  # End program