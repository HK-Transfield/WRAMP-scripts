.text		            # start of .text segment. Instructions follow
.global main	        # main is public

main:		            # program entry point
    addi $3, $0, 0      # set counter to 0
    jal readswitches    # read value of switches
    andi $4, $1, 0xFF   # AND operation, store result in $4
    
    jal count           # jump and link count label

count:      
    beqz $4, write      # if the binary equals 0, write count
    
    addi $3, $3, 1      # add 1 to counter
    subi $5, $4, 1      # subtract 1 from binary number

    and $4, $4, $5      # perform another AND

    j count             # continue counting

write:
    add $2, $3, $0      # store count in $2
    jal writessd        # display count to SSD
    j main              # loop back to main