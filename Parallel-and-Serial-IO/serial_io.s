.global main
.text

main:
    lw $10, 0x70003($0)     # Get the 1st serial port status
    andi $11, $10, 0x1      # Check if the RDR bit is set
    beqz $11, main          # if not, loop and try again
    lw $9, 0x70001($0)      # Get the character into $9

check:
    slei $2, $9, 96         # Check if the character less than the lowercase ASCII values
    sgei $3, $9, 123        # check if the character is greater than the lowercase ASCII values
    xor $3, $2, $3          # Check which is true
    beqz $3, transmit       # If character is lowercase, transmit it
    addi $9, $0, 42         # Get the character '*' if anything else

transmit:
    lw $10, 0x70003($0)
    andi $11, $10, 0x2      # Check if the TDS bit is set
    beqz $11, transmit      # If not, loop and try again
    sw $9, 0x70000($0)      # Send character to 1st Serial Port
    j main                  # Loop back and send another character
