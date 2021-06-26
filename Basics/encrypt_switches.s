.text		            # start of .text segment. Instructions follow
.global main	        # main is public

main:		            # program entry point
    addi $3, $0, 0      # set switch count to 0

    jal readswitches    # read value of switches
    andi $4, $1, 0xFF   # AND operation, store result in $4
    
    jal count           # jump and link count label
	
count:      
    beqz $4, encrypt    # finished counting, encrypt count 
    
    addi $3, $3, 1      # add 1 to counter
    subi $5, $4, 1      # subtract 1 from binary number

    and $4, $4, $5      # perform another AND

    j count             # continue counting

encrypt:
    lw $2, output($3)   # load output with count as index
    jal writessd        # write result to SSD
    j main              # loop back to main

.data
output:                 # output for encryption process
    .word 0xA3          # 0
    .word 0x22          # 1
    .word 0x6B          # 2
    .word 0x0D          # 3
    .word 0x49          # 4
    .word 0xC0          # 5
    .word 0x7F          # 6
    .word 0xB8          # 7
    .word 0x31          # 8