.global main
.text
main:
    subui $sp, $sp, 3   # setup stack frame
    sw  $ra, 2($sp)     # save return address

    jal readswitches    # retrieve value from switches
    
    andi $5, $1, 0xFF   # mask most significant bits to obtain least significant
    sw	$5, 0($sp)      # initialize end

    srli $4, $1, 8      # shift bits right to get most significant bits
    sw	$4, 1($sp)      # initialize start

	jal	count
end:                    # return registers
    lw	$5, 0($sp)
    lw	$4, 1($sp)
    lw	$ra, 2($sp) 
	addui $sp, $sp, 3   # destroy stack frame
    jr $ra              # return