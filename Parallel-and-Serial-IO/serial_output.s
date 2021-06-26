.global main
.text
main:
    addi $3, $0, 65         # Start at 'A'
    addi $7, $0, 97         # Start at 'a'

lowercase:          
    slei $2, $7, 122        # Check if have reached 'z'
    beqz $2, uppercase      # If so, start printing uppercase letters
    add $9, $7, $0          # Current character will be displayed
    addi $7, $7, 1          # Move to next character
    j check

uppercase:
    slei $2, $3, 90         # Check if we have reached 'Z'
    beqz $2, end            # If so, end program
    add $9, $3, $0          # Current character will be displayed
    addi $3, $3, 1          # Move to next character

check:
    lw $4, 0x71003 ($0)     # Get 1st serial port status
    andi $4, $4, 0x2        # Check if the TDS bit is set
    beqz $4, check          # if not, loop and try again
    sw $9, 0x71000($0)      # serial port is ready, transmit character
    j lowercase

end:
    jr $ra                  # End program