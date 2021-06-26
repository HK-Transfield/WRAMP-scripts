.text		            # start of .text segment. Instructions follow
.global main	        # main is public

main:		            # program entry point
    jal readswitches    # reads current value represented switches
   
    add $2, $1, $0      # adds the value of readswitches and stores it in $2
    jal writessd        # write the value of $2 to SSD
    
    j main              # loop again