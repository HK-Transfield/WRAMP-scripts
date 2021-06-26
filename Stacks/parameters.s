.global print
.text
print:                      
    subui $sp, $sp, 7       # setup stack framework

    # save registers
    sw $7, 1($sp)           # loop counter
    sw $6, 2($sp)           # remainder
    sw $5, 3($sp)           # ASCII that will print
    sw $4, 4($sp)           # 1st serial port
    sw $3, 5($sp)           # divisor
    sw $ra, 6($sp)          # save return address

    addi $7, $0, 5          # initialize loop counter to 5
    addi $3, $0, 10000      # set divisor to 10000 to get rightmost digit 1st
loop:
    beqz $7, end            # if counter = 0, end program
    lw $8, 7($sp)           # load value of switches from main
    div $8, $8, $3          # divide $8 by 
    divi $3, $3, 10         # move to next digit
    remui $6, $8, 10        # calculate remainder of $8 by 10
    subi $7, $7, 1          # subtract 1 from counter
    addi $5, $6, '0'        # send ASCII to 1st serial port
    jal check               # check 1st serial port and print
check:
    lw $4, 0x70003 ($0)     # Get 1st serial port status
    andi $4, $4, 0x2        # Check if the TDS bit is set
    beqz $4, check          # if not, loop and try again
    sw $5, 0x70000($0)      # serial port is ready, transmit character
    j loop                  # jump back to loop
end:                        # return registers
    lw $7, 1($sp)
    lw $6, 2($sp)
    lw $5, 3($sp)
    lw $4, 4($sp)
    lw $3, 5($sp)
    lw $ra, 6($sp) 
    addui $sp, $sp, 7       # destroy stack frame
    jr $ra                  # return