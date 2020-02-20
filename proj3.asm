# CSE 220 Programming Project #3
# Bryan Navas
# bnavas
# 112244631

#################### DO NOT CREATE A .data SECTION ####################
#################### DO NOT CREATE A .data SECTION ####################
#################### DO NOT CREATE A .data SECTION ####################

.text
initialize:
    #$a0 will hold 'state' or 'piece' address
    #$a1 will hold 'num_rows'
    #$a2 will hold 'num_cols'
    #$a3 will hold 'character'
    
    #returns -1 in $v0 if num_rows less than or equal to 0
    li $t0, 1
    bge $a1, $t0, row.isValid
    
    #happens only when row_num is invalid
    li $v0, -1  
    li $v1, -1
    j initialize.end   #ends the function when $v0 and $v1 have a value
    
    row.isValid:
    move $v0, $a1  #sets $v0 to 'num_rows' if greater than or equal to 1
    
    #returns -1 in $v1 if num_cols less than or equal to 0
    checkCol:
    li $t0, 1
    bge $a2, $t0, col.isValid
    
    #happens only when num_cols is invalid
    li $v0, -1
    li $v1, -1  
    j initialize.end   #ends the function when $v0 and $v1 have a value
    
    col.isValid:
    move $v1, $a2  #sets $v1 to 'num_cols' if greater than or equal to 1
    
    sb $a1, 0($a0)  #stores 'num_rows' in first byte of 2d arr
    sb $a2, 1($a0)  #stores 'num_cols' in second byte of 2d arr
    addi $a0, $a0, 2  #offsets 2d arr addr by 2 after storing first 2 bytes
    
    
    li $t0, 0 # 'i', or row_counter
    row_loop:
    li $t1, 0 # 'j', or col_counter
    	col_loop:
    	#address = base_addr + (i * num_cols + j)
    	mul $t2, $a2, $t0  #$t2 = i * num_cols
    	add $t2, $t2, $t1  #$t2 = i * num_cols + j
    	add $t2, $a0, $t2  #$t2 = base_addr + (i * num_cols + j)
    	sb $a3, 0($t2)     #stores 'character' argument into this spot in the 2d array
    	
    	addi $t1, $t1, 1  #j++
    	blt $t1, $a2, col_loop   #if the counter 'j' is less than 'num_cols' loop again		
    	col_loop.end:
    
    addi $t0, $t0, 1  #i++
    blt $t0, $a1, row_loop  #if the counter 'i' is less than 'num_rows', loop again
    row_loop.end:     
        
    initialize.end:
    jr $ra

load_game:
    #$a0 will hold a pointer to 'GameState'
    #$a1 will hold 'filename'
    
    #saves the registers we will be overriding
    addi $sp, $sp, -20
    sw $s0, 0($sp)
    sw $s1, 4($sp)
    sw $s2, 8($sp)
    sw $s3, 12($sp)
    sw $s4, 16($sp)
    
    move $s0, $a0    #$s0 will now contain pointer to 'GameState'
    move $s1, $a1    #$s1 will now contain 'filename'
    #$s2 will contain file descriptor
    #$s3 will contain number of O's
    li $s3, 0
    #$s4 will contain number of invalid characters
    li $s4, 0
    
    # Opening a file (game#.text)
    li $v0, 13       #system call for opening file
    move $a0, $s1    #$a0 is arg for filename
    li $a1, 0        #open for reading (0 is reading, 1 is writing
    li $a2, 0        #mode is ignored
    syscall
    move $s2, $v0    #saves the file descriptor returned in $v0
    
    bltz $s2, load_game.end
    
    
    	addi $sp, $sp, -1  #allocates 1 byte of memory in the stack for reading file
    	
    	#getting the 'row_length' -----------------------------------------------------------------------------
    	li $v0, 14       #system call for read from file
    	move $a0, $s2    #loads file descriptor into $a0 arg
    	move $a1, $sp    #adress of 1 byte input buffer
    	li $a2, 1        #sets maximum #of characters to read to 1
    	syscall
    	lb $t0, 0($sp)   #this gets the 1st character we just read in for 'row_length'

    	li $v0, 14       #system call for read from file
    	move $a0, $s2    #loads file descriptor into $a0 arg
    	move $a1, $sp    #adress of 1 byte input buffer
    	li $a2, 1        #sets maximum #of characters to read to 1
    	syscall
    	lb $t1, 0($sp)   #this gets the 2nd character in the file for 'row_length'
    	
    	#we now have 2 characters, and the second could be a new line char (ASCII: 10)
    	li $t2, 10    #temporary used to check if ASCII: 10 or '\n'
    	beq $t1, $t2, row.lessThan10    #if the second character in the file is ASCII 10, then there is only 1 char and it is less than 10	
    	row.greaterThan10:   #if the second character is not a new line this runs
    		#when row is >10 we have 2 valid characters. we want to turn that into a real number of only 1 byte
    		andi $t0, $t0, 0x0F   #converts the ascii number to actual number by masking and grabbing last 4 bits
    		andi $t1, $t1, 0x0F   #same logic as above for the second character
    		
    		li $t2, 10  #temporary used to multiply by 10
    		mul $t0, $t0, $t2   #multiplies the first number by 10
    		add $t0, $t0, $t1   # (first number)*10  + second number
    		sb $t0, 0($s0)   #successfully stores 'row_length' into 'GameState' if 2 characters	
    		
    		li $v0, 14       #system call for read from file
    		move $a0, $s2    #loads file descriptor into $a0 arg
	    	move $a1, $sp    #adress of 1 byte input buffer
	    	li $a2, 1        #sets maximum #of characters to read to 1
	    	syscall
	    	lb $t0, 0($sp)   #this system call essentially "skips" the new line character bound to be after first 2 chars	
    											
    	j checkColumn   #jump so that it doesnt execute less than 10 code
    	row.lessThan10:
    	        #when row is <l0 we have 1 valid character. we want to turn that into a real # and store it
    	        andi $t0, $t0, 0x0F   #converts the ascii number to actual number by masking and grabbing last 4 bits
 		sb $t0, 0($s0)  #successfully store 'row_length' into 'GameState' if only 1 character 
 	#end getting row_length --------------------------------------------------------------------------------------  	
 	
    	checkColumn:   #gets the column length
    	#getting the 'col_length' ************************************************************************************
    	li $v0, 14       #system call for read from file
    	move $a0, $s2    #loads file descriptor into $a0 arg
    	move $a1, $sp    #adress of 1 byte input buffer
    	li $a2, 1        #sets maximum #of characters to read to 1
    	syscall
    	lb $t0, 0($sp)   #this gets the 1st character we just read in for 'col_length'

    	li $v0, 14       #system call for read from file
    	move $a0, $s2    #loads file descriptor into $a0 arg
    	move $a1, $sp    #adress of 1 byte input buffer
    	li $a2, 1        #sets maximum #of characters to read to 1
    	syscall
    	lb $t1, 0($sp)   #this gets the 2nd character in the file for 'col_length'
    	
    	#we now have 2 characters, and the second could be a new line char (ASCII: 10)
    	li $t2, 10    #temporary used to check if ASCII: 10 or '\n'
    	beq $t1, $t2, col.lessThan10    #if the second character in the file is ASCII 10, then there is only 1 char and it is less than 10	
    	col.greaterThan10:   #if the second character is not a new line this runs
    		#when row is >10 we have 2 valid characters. we want to turn that into a real number of only 1 byte
    		andi $t0, $t0, 0x0F   #converts the ascii number to actual number by masking and grabbing last 4 bits
    		andi $t1, $t1, 0x0F   #same logic as above for the second character
    		
    		li $t2, 10  #temporary used to multiply by 10
    		mul $t0, $t0, $t2   #multiplies the first number by 10
    		add $t0, $t0, $t1   # (first number)*10  + second number
    		sb $t0, 1($s0)   #successfully stores 'col_length' into 'GameState' if 2 characters
    		
    		li $v0, 14       #system call for read from file
    		move $a0, $s2    #loads file descriptor into $a0 arg
	    	move $a1, $sp    #adress of 1 byte input buffer
	    	li $a2, 1        #sets maximum #of characters to read to 1
	    	syscall
	    	lb $t0, 0($sp)   #this system call essentially "skips" the new line character
    						
    	j colCheck.end   #jump so that it doesnt execute less than 10 code
    	col.lessThan10:
    	        #when row is <l0 we have 1 valid character. we want to turn that into a real # and store it
    	        andi $t0, $t0, 0x0F   #converts the ascii number to actual number by masking and grabbing last 4 bits
 		sb $t0, 1($s0)  #successfully store 'col_length' into 'GameState' if only 1 character
 		
 	colCheck.end:	 
 	#end getting col_length ************************************************************************************
    	
    	#start looping for GameState ===============================================================================
	addi $s0, $s0, 2   #this adds 2 to 'GameState' addr so it skips the already written 2 bytes
	load_loop:
	li $v0, 14       #system call for read from file
    	move $a0, $s2    #loads file descriptor into $a0 arg
    	move $a1, $sp    #adress of 1 byte input buffer
    	li $a2, 1        #sets maximum #of characters to read to 1
    	syscall

	beqz $v0, load_loop.end  #when $v0 contains a 0, it is the end of file
	lb $t0, 0($sp)   #the character from the file
	
	li $t1, 10                      #ASCII value for new line char
	beq $t0, $t1, newLineChar       #if new line when skip and do nothing
	li $t1, 46    			#ASCII val for '.' used to check if proper char
	beq $t0, $t1, properChar	#if char is '.' it is proper
	
	li $t1, 79			#ASCII val for 'O' used to check if proper char
	beq $t0, $t1, addTo_O_counter	#else if char is 'O' it is proper
	j improperChar
	
	addTo_O_counter:
	addi $s3, $s3, 1          #adds 1 to 'O' counter
	j properChar
	
	improperChar:
		li $t1, '.'       #sets $t1 to default '.' if character is bad
		sb $t1, 0($s0)    #stores it in 'GameState'
		addi $s0, $s0, 1  #increments addr by 1 byte
		addi $s4, $s4, 1  #improper char counter
		
		j load_loop	
	properChar:
		sb $t0, 0($s0)    #stores the character into 'GameState' as is
		addi $s0, $s0, 1  #increments addr by 1 byte
		j load_loop  
	newLineChar:
		#when it is a new line, it does nothing and moves on

	j load_loop
	load_loop.end:
    	
    	#end looping for GameState ===============================================================================
    	
    	addi $sp, $sp, 1   #de-allocates the 1 byte of memory used from the stack for reading file
    
    # Closing the file (game#.text)
    li $v0, 16       #system call for closing a file
    move $a0, $s2    #file descriptor to close
    syscall
     
    #sets return values
    move $v0, $s3
    move $v1, $s4 
     
    #returns the register we used
    lw $s0, 0($sp)
    lw $s1, 4($sp)
    lw $s2, 8($sp)
    lw $s3, 12($sp)
    lw $s4, 16($sp)
    addi $sp, $sp, 20
    
    jr $ra
    
    load_game.end:  #this runs if and only if the file was not found
    li $v0, -1
    li $v1, -1
    jr $ra
get_slot:
    #$a0 will hold 'state' or 'piece' adress
    #$a1 will hold 'row', from where we want to read the character
    #$a2 will hold 'col', from where we want to read the character
  
    #first we want to eliminate all invalid inputs
    lb $t0, 0($a0)   #$t0 will hold the number of rows
    lb $t1, 1($a0)   #$t1 will hold the number of columns
    
    bge $a1, $t0, inputs.invalid
    bge $a2, $t1, inputs.invalid
    bltz $a1, inputs.invalid          #this block makes sure that inputs are [0, num_row(cols)  )
    bltz $a2, inputs.invalid
    
    j inputs.valid #jumps here if inputs are valid, otherwise code above jumps to invalid  
    inputs.invalid:
    	li $v0, -1
    	j get_slot.end    #if inputs are invalid, set $v0 to -1 and end
    	
    	
    inputs.valid:
    #at this point we know the inputs are valid   
    #to access we have to use: address = base_addr + (i * num_cols + j)
    addi $a0, $a0, 2  #we add 2 to our base addr bc the first 2 bytes are not part of the array
    mul $t2, $a1, $t1  #$t2 = i * num_cols
    add $t2, $t2, $a2  #$t2 = (i* num_cols + j)
    add $t2, $t2, $a0  #$t2 = base_addr + (i* num_cols + j)
    lbu $v0, 0($t2)   
    
    get_slot.end:
    jr $ra

set_slot:
    #$a0 will hold 'state' or 'piece' adress
    #$a1 will hold 'row', from where we want to read the character
    #$a2 will hold 'col', from where we want to read the character
    #$a3 will hold 'character' to be written in
  
    #first we want to eliminate all invalid inputs
    lb $t0, 0($a0)   #$t0 will hold the number of rows
    lb $t1, 1($a0)   #$t1 will hold the number of columns
    
    bge $a1, $t0, inputs.set.invalid
    bge $a2, $t1, inputs.set.invalid
    bltz $a1, inputs.set.invalid          #this block makes sure that inputs are [0, num_row(cols)  )
    bltz $a2, inputs.set.invalid
    
    j inputs.set.valid #jumps here if inputs are valid, otherwise code above jumps to invalid  
    inputs.set.invalid:
    	li $v0, -1
    	j set_slot.end    #if inputs are invalid, set $v0 to -1 and end
    	
    	
    inputs.set.valid:
    #at this point we know the inputs are valid   
    #to access we have to use: address = base_addr + (i * num_cols + j)
    addi $a0, $a0, 2  #we add 2 to our base addr bc the first 2 bytes are not part of the array
    mul $t2, $a1, $t1  #$t2 = i * num_cols
    add $t2, $t2, $a2  #$t2 = (i* num_cols + j)
    add $t2, $t2, $a0  #$t2 = base_addr + (i* num_cols + j)
    sb $a3, 0($t2)  
    move $v0, $a3 
    
    set_slot.end:
    jr $ra

rotate:
    #$a0 contains 'piece' address (must remain unchanged)
    #$a1 contains 'rotation' or number of 90 degree clockwise turns
    #$a2 contains 'rotated_piece' address (buffer to write final piece)
    
    #first we check if the argument 'rotation' is negative
    bltz $a1, rotate.err   #ends the function right away if arg is negative
    
    lbu $t0, 0($a0)   #$t0 will contain the number of rows
    lbu $t1, 1($a0)   #$t1 will contain the number of cols
    
    li $t2, 2   #temporary used to check if row is equal to 2
    beq $t0, $t2, CheckO.piece  #if the row is equal we jump here to further check if col is also 2
    li $t3, 4   #temporaty used to check if row is equal to 4
    beq $t3, $t0, CheckI.piece
    li $t3, 1   #temporaty used to check if row is equal to 1
    beq $t3, $t0, CheckI.piece
    li $t2, 3   #temporary used to check if row is equal to 3
    beq $t0, $t2, Other.piece
    
    j Other.piece    #any other type of matrix
    #Dealing with the possible 'O' shape---------------------------------------------------------------
    CheckO.piece: #at this point we know that row is 2
    li $t2, 2
    bne $t2, $t1, Other.piece    #if the row is 2 and the col is NOT 2, then it is another piece (NOT I) 
    
    #at this point we know it is an O-Piece so we initialize the buffer
    
    li $t0, 0   #loop counter
    li $t1, 8   #max times loop will run
    setO.loop:
    	beq $t0, $t1, setO.loop.end   #ends loop when we hit max
    	
    	lbu $t2, 0($a0)  #grabs a char from Piece
    	sb  $t2, 0($a2)  #immediatly stores it in a buffer
    	
    	addi $a0, $a0, 1
    	addi $a2, $a2, 1
    	addi $t0, $t0, 1
    	j setO.loop
    setO.loop.end:
    
    move $v0, $a1
    j rotate.end
    #End dealing with the possible 'O' shape--------------------------------------------------------------- 
    
    					
    #Dealing with the possible 'I' shape///////////////////////////////////////////////////////////////
    CheckI.piece:       #Checks if it is an I piece, if it is, then it handles it
    addi $sp, $sp, -4   #allocating space for $v0 return
    sw $a1, 0($sp)      #stores 'rotation' number
    
    li $t0, 0   #loop counter
    li $t1, 8   #max times loop will run
    move $t3, $a0   #so our original vals wont change
    move $t4, $a2   #same as line above
    setI.loop:
    	beq $t0, $t1, setI.loop.end   #ends loop when we hit max
    	
    	lbu $t2, 0($t3)  #grabs a char from Piece
    	sb  $t2, 0($t4)  #immediatly stores it in a buffer
    	addi $t3, $t3, 1
    	addi $t4, $t4, 1
    	addi $t0, $t0, 1
    	j setI.loop
    setI.loop.end:
    
    li $t2, 2   #serves as our Modulo 2
    div $a1, $t2   #divides the number of rotations by 2
    mfhi $t0    #our remainder
    
    #if our remainder is 0, we do nothing
    beqz $t0, rem0.I
    
    #else if our remainder is 1, we return the other representation
    lbu $t0, 0($a0)    #gets the row from piece
    lbu $t1, 1($a0)    #gets the col from piece
    
    sb $t0, 1($a2)     #stores the row we just got into col of buffer
    sb $t1, 0($a2)     #stores the col we just got from piece into row buffer
    
    rem0.I:
    lw $v0, 0($sp)      #loads in 'rotation' number
    addi $sp, $sp, 4
    j rotate.end
    #End dealing with the possible 'I' shape///////////////////////////////////////////////////////////
    
    
    #Start dealing with the rest of the letters***********************************************************
    Other.piece:   #Could be S,Z,L,J,or T doesnt matter, then handles it
    
    #DONT FORGET THE STACK
    addi $sp, $sp, -44
    sw $ra, 0($sp)
    sw $s0, 4($sp)
    sw $s1, 8($sp)
    sw $s2, 12($sp)
    sw $s3, 16($sp)
    sw $s4, 20($sp)
    
    
    move $s0, $a0   #piece addr
    move $s1, $a1   #rotation
    move $s2, $a2   #buffer
    sw $s2, 24($sp)  #keeps OG buffer
    
    #saves original piece----------------------------
    	lbu $t0, 0($a0)  
        lbu $t1, 1($a0)
        lbu $t2, 2($a0)
        lbu $t3, 3($a0)
        lbu $t4, 4($a0)
        lbu $t5, 5($a0)
        lbu $t6, 6($a0)
        lbu $t7, 7($a0)
        
        sb $t0, 28($sp)
        sb $t1, 29($sp)
        sb $t2, 30($sp)
        sb $t3, 31($sp)
        sb $t4, 32($sp)
        sb $t5, 33($sp)
        sb $t6, 34($sp)
        sb $t7, 35($sp)
    #done saving original piece-----------------------
    
    sw $a1, 36($sp)    #keeps 'rotation'
    sw $a0, 40($sp)    #keeps the addr to beginning of piece
    
    #calling initialize
    move $a0, $s2   #piece arg (inputting buffer)
    lbu $t0, 0($s0)
    andi $a1, $t0, 0x0F  #sets 'num_row' arg to row
    lbu $t0, 1($s0)
    andi $a2, $t0, 0x0F  #sets 'num_col' arg to col
    li $a3, '.'   #sets character to '.'
    jal initialize
    
    li $t0, 4
    div $s1, $t0
    mfhi $s4
    
    beqz $s4, noChange
    
    
    li $s3, 0     #loop counter
    #$s4 will hold max times loop will run
    
    rotate.mainLoop:
    beq $s3, $s4, rotate.mainLoop.end
    	#THIS METHOD CALLS get_slot
    	move $a0, $s0
    	move $a1, $s2
    	jal rotate_once       
    	move $s0, $v0
    	move $s2, $v1
    
    addi $s3, $s3, 1
    j rotate.mainLoop
    rotate.mainLoop.end:
    
    #if $s4 (how many times loop ran)  == 1 then it's fine do nothing
    
    
    #if $s4 is 2, or 3 then we return what's in $v0
    li $t0, 1
    beq $t0, $s4, skipSwitch
    bgt $s4, $t0, switchOG
    
    switchOG:
    	lbu $t0, 0($v0)
        lbu $t1, 1($v0)
        lbu $t2, 2($v0)
        lbu $t3, 3($v0)
        lbu $t4, 4($v0)
        lbu $t5, 5($v0)
        lbu $t6, 6($v0)
        lbu $t7, 7($v0)
        
        lw $s2, 24($sp)   #original buffer
        sb $t0, 0($s2)
        sb $t1, 1($s2) 
        sb $t2, 2($s2)
        sb $t3, 3($s2)
        sb $t4, 4($s2)
        sb $t5, 5($s2)
        sb $t6, 6($s2)
        sb $t7, 7($s2) 
        j skipSwitch
    
    noChange:
    li $t0, 0   #loop counter
    li $t1, 8   #max times loop will run
    move $t3, $s0   #so our original vals wont change
    move $t4, $s2   #same as line above
    setNoChange.loop:
    	beq $t0, $t1, setNoChange.loop.end   #ends loop when we hit max
    	
    	lbu $t2, 0($t3)  #grabs a char from Piece
    	sb  $t2, 0($t4)  #immediatly stores it in a buffer
    	addi $t3, $t3, 1
    	addi $t4, $t4, 1
    	addi $t0, $t0, 1
    	j setNoChange.loop
    setNoChange.loop.end:        
        
    skipSwitch:
    #DONT FORGET THE STACK
    lw $v0, 36($sp)    #restores the number of rotations  	
    	lb $t0, 28($sp)
        lb $t1, 29($sp)
        lb $t2, 30($sp)
        lb $t3, 31($sp)
        lb $t4, 32($sp)
        lb $t5, 33($sp)
        lb $t6, 34($sp)
        lb $t7, 35($sp)   
        lw $s2, 40($sp)   #original piece
        sb $t0, 0($s2)
        sb $t1, 1($s2) 
        sb $t2, 2($s2)
        sb $t3, 3($s2)
        sb $t4, 4($s2)
        sb $t5, 5($s2)
        sb $t6, 6($s2)
        sb $t7, 7($s2)                         
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    lw $s1, 8($sp)
    lw $s2, 12($sp)
    lw $s3, 16($sp)
    lw $s4, 20($sp)
    addi $sp, $sp, 44
    #End dealing with the rest of the letters*************************************************************
    rotate.end:
    jr $ra
    
    rotate.err:  #runs if and only if 'rotation' arg is negative
    li $v0, -1
    jr $ra
count_overlaps:
    #$a0 will hold 'state' or addr of GameState struct
    #$a1 will hold 'row', the row of top most block of piece ON GameStruct
    #$a2 will hold 'col', the column of the leftmost block of piece ON GameStruct
    #$a3 will hold 'piece' address of Piece struct
    bltz $a1, negativeArgs
    bltz $a2, negativeArgs
    
    addi $sp, $sp, -36
    sw $s0, 0($sp)
    sw $s1, 4($sp)
    sw $s2, 8($sp)
    sw $s3, 12($sp)
    sw $s4, 16($sp)
    sw $s5, 20($sp)
    sw $s6, 24($sp)
    sw $s7, 28($sp)
    sw $ra, 32($sp)
    
    move $s0, $a0   # 'State' Address
    move $s1, $a1   # 'row'
    move $s2, $a2   # 'col'
    move $s3, $a3   # 'piece' Address
    li $s4, 0       # Piece ROW   (starting)
    li $s5, 0       # Piece COL   (starting)
    move $s6, $a1   # GameStruct ROW  (starts at what the args were)
    move $s7, $a2   # GameStruct COL  (starts at what the args were)
    
    	
    			
    	addi $sp, $sp, -24
    	li $t0, 0
    	sw $t0, 0($sp)                      # Loads 0 into 0($sp) -> Loop Counter
    	lbu $t0, 0($a3)     #gets row of Piece arg
    	lbu $t1, 1($a3)     #gets col of Piece arg
    	mul $t0, $t0, $t1   #loop will run row*col times
    	sw $t0, 4($sp)                      # Loads row * col into 4($sp)  -> Max times loop will run 
    	# 8($sp) will hold the current char grabbed by get_slot for GameState
    	# 12($sp) will hold the current char grabbed by get_slot for Piece
    	# 16($sp) will hold how many overlaps
    	li $t0, 0
    	sw $t0, 16($sp)
    	
    	
        countingLoop:
    		lw $t0, 0($sp)   #gets loop counter
	    	lw $t1, 4($sp)   #gets max times loop will run
	    	beq $t0, $t1, countingLoop.end
    		
    		#get slot for GameState
    		move $a0, $s0   #sets first arg to GameState
    		move $a1, $s6   #sets second arg to GameStruct ROW
    		move $a2, $s7   #sets third arg to GameStruct COL
    		jal get_slot
    		#$v0 now has the character located at the args
    		sw $v0, 8($sp)
    		
    		#get slot for Piece
    		move $a0, $s3  #sets first arg to Piece
    		move $a1, $s4  #sets second arg to Piece ROW
    		move $a2, $s5  #sets third arg to Piece COL
    		jal get_slot
    		#$v0 now has the char located at args
    		sw $v0, 12($sp)	
    		
    		#at this point we have both the character in the same space and we need to check
    		#to see if both of them are 'O'  (hence an overlap)	
		lw $t0, 8($sp)   #the char we just got from GameState
		lw $t1, 12($sp)  #the char we just got from Piece
		
		li $t2, 79  #79 is the ASCII char for 'O'
		bne $t0, $t2, noOverLap    #if both arent equal to 'O' then no overlap
		bne $t1, $t2, noOverLap    #this too has to be 'O'
		
		overlap:
		#if this runs, we know both spots are a 'O'
		lw $t0, 16($sp)   #gets the overlapcounter from stack
		addi $t0, $t0, 1  #adds 1
		sw $t0, 16($sp)   #puts it back onto stack
		li $t9, 4
		beq $t9, $t0, countingLoop.end   #4 is max overlap, so might as well end loop
		  					    					    					    					
    		noOverLap:  #serves as a skip for the counter++	
    		
    		addi $s4, $s4, 1   #adds 1 to piece ROW
    		lbu $t0, 0($s3)    #gets PieceStruct row
    		#addi $t0, $t0, -1  #subtracts one from it
    		beq $s4, $t0, resetRow  #if PieceRow == MAX ROW  then reset
    		addi $s6, $s6, 1   #adds 1 to gamestruct row	
    			#check if it is out of bounds
    			lbu $t0, 0($sp)  #gets loop counter 
    			addi $t0, $t0, 1   #adds 1
    			lbu $t1, 4($sp)  #gets max time loop will run
    			beq $t0, $t1, countingLoop.end
    			
    			lbu $t0, 0($s0)  #loads in gamestruct row
    			bge $s6, $t0, countingERR	
    		j skipResetR
    		resetRow:
    		li $s4, 0   #resets piece ROw to 0
    		#now we have to reset GamePiece ROW to original
    		move $s6, $s1 #resets GamePiece ROW to orignial args (so it's back on same level)
    		addi $s7, $s7, 1  #adds 1 to gamestruct col
    			
    			#check if it is out of bounds
    			lbu $t0, 0($sp)  #gets loop counter 
    			addi $t0, $t0, 1   #adds 1
    			lbu $t1, 4($sp)  #gets max time loop will run
    			beq $t0, $t1, countingLoop.end
    			
    			lbu $t0, 1($s0)  #loads in gamestruct cpl
    			bge $s7, $t0, countingERR
    		skipErr:
    		addi $s5, $s5, 1  #adds 1 to piece col
    		
    		skipResetR:	
    		lw $t0, 0($sp)    #gets loop counter
    		addi $t0, $t0, 1  #adds 1 to loop counter
    		sw $t0, 0($sp)    #stores the newly incremented counter back onto stack	
    	j countingLoop
    	countingLoop.end:
    	
    
    	lw $v0, 16($sp)
    	addi $sp, $sp, 24  #deallocating space, we dont care about the contents
    
    lw $s0, 0($sp)
    lw $s1, 4($sp)
    lw $s2, 8($sp)
    lw $s3, 12($sp)
    lw $s4, 16($sp)
    lw $s5, 20($sp)
    lw $s6, 24($sp)
    lw $s7, 28($sp)
    lw $ra, 32($sp)
    addi $sp, $sp, 36		
    jr $ra


    countingERR: #if out of bounds
    addi $sp, $sp, 24 #de allocates space used for loop   
    lw $s0, 0($sp)
    lw $s1, 4($sp)
    lw $s2, 8($sp)
    lw $s3, 12($sp)
    lw $s4, 16($sp)
    lw $s5, 20($sp)
    lw $s6, 24($sp)
    lw $s7, 28($sp)
    lw $ra, 32($sp)
    addi $sp, $sp, 36
    negativeArgs:
    li $v0, -1    #loads return with -1
    jr $ra
    
drop_piece:
    #$a0 will contain GameState addr
    #$a1 will contain 'col'
    #$a2 will contain Piece addr
    #$a3 will contain 'rotation'
    #stack will contain addr to rotated_piece
    
    bltz $a3, drop_pieceIN.Err       #if the value of rotation is negative
    bltz $a1, drop_pieceIN.Err       #if the value of rotation is negative
    lbu $t0, 1($a0)                #gets state.num_cols
    bge $a1, $t0, drop_pieceIN.Err   #if col >= state.num_cols
    
    lw $t0, 0($sp)   #4th argument, our rotated_piece address
    
    #at this point we know that rotation and col is a valid number
    addi $sp, $sp, -48
    sw $ra, 0($sp)
    sw $s0, 4($sp)
    sw $s1, 8($sp)
    sw $s2, 12($sp)        #saves all S register in the stack
    sw $s3, 16($sp)
    sw $s4, 20($sp)
    sw $s5, 24($sp)
    sw $s6, 28($sp)
    sw $s7, 32($sp)
    
    #stack will contain addr to rotated_piece
    move $s0, $a0     #$s0 will contain GameState addr
    move $s1, $a1     #$s1 will contain 'col'
    move $s2, $a2     #$a2 will contain Piece addr
    move $s3, $a3     #$a3 will contain 'rotation'
    move $s4, $t0     #this will contain our 4th argument Rotated_Piece addr
    
    move $a0, $s2      #loads in Piece address for rotate arg
    move $a1, $s3      #loads in 'rotation' for rotate arg
    move $a2, $s4      #the address of the buffer that will contain 'Rotated Piece'
    jal rotate
    
    #we have now checked for input errors and rotated the piece in $s4
    
    #we now check to see if it will stick out of the game board
    #if 'col' + (Piece.num_cols - 1) >= GameStruct.num_cols  -> then ERR
    lbu $t0, 1($s4)
    addi $t0, $t0, -1   #Piece.num_cols -1
    add $t0, $t0, $s1   #'col' + (Piece.num_cols - 1)
    lbu $t1, 1($s0)     # $t1 holds GameStruct.num_cols
    bge $t0, $t1, rotated_Pokesout
    
    
    #$s5 will hold 'previous_row' 
    li $s5, 0
    #$s6 will hold 'current_row'
    li $s6, 1
    #s7 will hold 'loop_counter'
    li $s7, 0
    
    #34(sp) will hold max times loop will run
    lbu $t0, 0($s0)     #number of rows inside state
    addi $t0, $t0, -1   #state.num_rows -1
    sw $t0, 36($sp)     #now this will hold max
    drop_pieceLoop:
    	lw $t0, 36($sp)   #max times loop will run
    	beq $t0, $s7, drop_pieceLoop.end   #when max times == loop counter, end
    	
    	#count overlaps starting at state[current] ['col']
    	move $a0, $s0    #state: state addr
    	move $a1, $s6    #row: the row of the topmost block  (CURRENT)
    	move $a2, $s1    #col: the col of the leftmost block
    	move $a3, $s4    #piece: addr of piece rotated struct
    	jal count_overlaps
    	#$v0 now contains number of overlaps
    	
    	beqz $v0, checkNext  #if it fits in this spot with no overlaps, check the next one
    	bltz $v0, checkPrev  #if the return was negative, check the previous one
    	bnez $v0, checkPrev  #if the result is more than 1, meaning there is an overlap, check the previous row
    	 
    	checkNext:  
    	addi $s5, $s5, 1   #previous++
    	addi $s6, $s6, 1   #current++
    	addi $s7, $s7, 1   #loop counter++ 
    	j drop_pieceLoop
    	
    	checkPrev:
    	#at this point, our 'current' row has hit a piece or gone out of the map
    	#now we want to check if we can put the piece in this spot
    	move $a0, $s0    #state: state addr
    	move $a1, $s5    #row: the row of the topmost block (PREVIOUS)
    	move $a2, $s1    #col: the col of the leftmost block
    	move $a3, $s4    #piece: addr of piece struct
    	jal count_overlaps
    	#$v0 now contains number of overlaps
    	
    	bnez $v0, neg1.Err   #if the piece doesnt fit in the next one, and not this one, then it wont fit in field
    	#at this point it this runs, $v0, is 0
    	sw $s5, 40($sp)   #stores the return value	
    		addi $sp, $sp, -24
    		move $t0, $s5     
    		sw $t0, 0($sp)         #0($sp) will contain original row
    		move $t0, $s1          
    		sw $t0, 4($sp)         #4($sp) will contain original col
    		
    		li $t0, 0
    		sw $t0, 8($sp)        #8($sp) will contain Piece[i][j] row
    		li $t1, 0
    		sw $t1, 12($sp)        #12($sp) will contain Piece[i][j] col
    		
    		
    		overWriteLoop:
    			#we need to take rotated_piece and put that into state.field
    			#we only overrite if it's a 'O'!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    			
    			#get Piece
    			move $a0, $s4   #piece: the rotated piece
    			lw $a1, 8($sp)  #row: the i
    			lw $a2, 12($sp) #col: the j
    			jal get_slot
    			#v0 now contains the char gotten from there
    			#we want to write that to the board
    			
    			li $t0, 79 #ASCII for 'O'
    			bne $t0, $v0, skipSet   #if it's not a 'O' then dont overrite
    			
    			#set to GameState
    			move $a0, $s0   #state: game state
    			move $a1, $s5   #row: previous
    			move $a2, $s1   #col: this function's inputted col
    			move $a3, $v0
    			jal set_slot
    			
    			skipSet:
    			lw $t0, 12($sp)   #gets j of rotated piece
    			addi $t0, $t0, 1  #j++ 
    			sw $t0, 12($sp)   #stores it back on stacck	
    			addi $s1, $s1, 1  #col in state++
    			  
    			
    			lbu $t1, 1($s4)  #gets the columns of Rpiece
    			beq $t0, $t1, resetColInRPiece   #if col is 3 and this is 3, we reset to 0
    			
    			j overWriteLoop
    			resetColInRPiece: 
    			li $t0, 0
    			sw $t0, 12($sp)  #resets it to 0
    			lw $t1, 4($sp)   #grabs the original col in state
    			move $s1, $t1    #resets it to original
    			#when we reset the col in piece, we add 1 to Piece_row 
    			lw $t0, 8($sp)
    			addi $t0, $t0, 1   #grabs, adds 1, and stores Piece_row
    			sw $t0, 8($sp)
    			
    			lbu $t3, 0($s4)  #gets row of Rpiece
    			beq $t0, $t3, overWriteLoop.end   #once we reach the max # of rows
    			#also we must also add 1 to State_row
    			addi $s5, $s5, 1   #adds 1 to state_row
    			
    			
    		j overWriteLoop	
    		overWriteLoop.end:
    		addi $sp, $sp, 24   #putting it back and we dont care about values
    		j drop_pieceLoop.end
    		
    	addi $s7, $s7, 1   #loop counter++
    	j drop_pieceLoop
    drop_pieceLoop.end:
    
    lw $v0, 40($sp)  #gets the return value from the stack
    
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    lw $s1, 8($sp)
    lw $s2, 12($sp)
    lw $s3, 16($sp)     #returns all s registers from the stack
    lw $s4, 20($sp)
    lw $s5, 24($sp)
    lw $s6, 28($sp)
    lw $s7, 32($sp)
    addi $sp, $sp, 48
    jr $ra
    
    drop_pieceIN.Err:  #runs if and only if we have input errors in rotation or col
    li $v0, -2
    jr $ra
    
    rotated_Pokesout:
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    lw $s1, 8($sp)
    lw $s2, 12($sp)
    lw $s3, 16($sp)     #returns all s registers from the stack
    lw $s4, 20($sp)
    lw $s5, 24($sp)
    lw $s6, 28($sp)
    lw $s7, 32($sp)
    addi $sp, $sp, 48
    
    li $v0, -3
    jr $ra
    
    neg1.Err:        #runs if the rotated piece could not be dropped to field due to a collision with blocks already there
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    lw $s1, 8($sp)
    lw $s2, 12($sp)
    lw $s3, 16($sp)     #returns all s registers from the stack
    lw $s4, 20($sp)
    lw $s5, 24($sp)
    lw $s6, 28($sp)
    lw $s7, 32($sp)
    addi $sp, $sp, 48
    
    li $v0, -1
    jr $ra
    
check_row_clear:
    #$a0 will contain GameState adress
    #$a1 will conain the row of GameState.field 
    lbu $t0, 0($a0)                #grabs the row from GameState
    bge $a1, $t0, CRC.INErr        #checks to see if row is greater than or equal to MAX rows
    bltz $a1, CRC.INErr            #checks to see if row is negative 
     
    addi $sp, $sp, -36
    sw $ra, 0($sp)
    sw $s0, 4($sp)         
    sw $s1, 8($sp)
    sw $s2, 12($sp)
    sw $s3, 16($sp)     
    sw $s4, 20($sp)
    sw $s5, 24($sp)
    sw $s6, 28($sp)
    sw $s7, 32($sp)
    
    move $s0, $a0        #will hold GameState arg
    move $s1, $a1        #will hold row arg
    li $s2, 0            #loop counter
    move $s3, $a1        #this will hold 'current row'
    addi $s4, $s3, -1    #this will hold 'previous row' (current_row-1)
    
    #now we check to see if this row can be cleared
        lbu $s5, 1($s0)   #gets the number of cols from GameState
        li $s6, 0         #loop counter
        
    	#loop that runs col of times
    	checkRowLoop:
    	    beq $s5, $s6, checkRowLoop.end   #condition to end the loop
    	    
    	    #Get GameState[row][$s6]
    	    move $a0, $s0    #state: addr of gamestate
    	    move $a1, $s1    #row: the row of the field array
    	    move $a2, $s6    #col: the col of the field array
    	    jal get_slot
    	    #$v0 now has the character located there
    	    
    	    li $t0, 79  #ASCII for '79'
    	    beq $v0, $t0, continueCheck
    	    
    	    li $v0, 0   #this only  runs if the row is not filled with all 'O' characters
    	    j check_row_clear.end
    	    
    	    continueCheck:
    	    addi $s6, $s6, 1
    	j checkRowLoop
    	checkRowLoop.end:
    
    #we check if it is row 0, if it is then we clear the top row bc we know it's all 'O's
    beqz $s1, clear_first_row
    
    #at this point we know that the row is filled with all 'O's
    #we end when prevoius row is 0
    
    #$s3 holds 'current row'
    #$s4 holds 'previous row'
    li $s5, 0  #current counter for State.col
    
    shiftLoop:
        bltz $s4, shiftLoop.end    #when it's negative end
    
        #gets from GameState previous row
        move $a0, $s0    #state: addr of gamestate
    	move $a1, $s4    #row: the row of the field array
    	move $a2, $s5    #col: the col of the field array
    	jal get_slot
    	#$v0 now has the character located there
    	
        #sets it into current row
    	move $a0, $s0   #state: game state
        move $a1, $s3   #row: current row
        move $a2, $s5   #col: the col of field array
       	move $a3, $v0   #the character to be set
    	jal set_slot
    	 
    	addi $s5, $s5, 1    #adds 1 to col
    	lbu $t0, 1($s0)     #gets GameState.col
    	beq $t0, $s5, resetCol
    	
    	j shiftLoop
    	resetCol:
    	li $s5, 0
    	addi $s3, $s3, -1   #current_row -1
    	addi $s4, $s4, -1   #previous_row -1 
    
    j shiftLoop	
    shiftLoop.end:		
    
    clear_first_row:
    	
    	lbu $s5, 1($s0)   #gets the number of cols from GameState
        li $s6, 0         #loop counter
    	clear_first_rowLoop:
    		beq $s5, $s6, clear_first_rowLoop.end   #condition to end the loop
		#sets it into first row
    		move $a0, $s0   #state: game state
	        li $a1, 0       #row: first row
	        move $a2, $s6   #col: the col of field array
	       	li $a3, '.'   #the character to be set
	    	jal set_slot    	    

		addi $s6, $s6, 1    	
    	j clear_first_rowLoop
    	clear_first_rowLoop.end:
        li $v0, 1
    
    check_row_clear.end:    
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    lw $s1, 8($sp)
    lw $s2, 12($sp)
    lw $s3, 16($sp)     #returns all s registers from the stack
    lw $s4, 20($sp)
    lw $s5, 24($sp)
    lw $s6, 28($sp)
    lw $s7, 32($sp)
    addi $sp, $sp, 36
    
    jr $ra
    
    CRC.INErr:    #runs when the inputted row is invalid
    li $v0, -1   
    jr $ra
    
    
simulate_game:
    jr $ra
    	
rotate_once:    #Helper Method for part 5 (:
 	#$a0 will hold piece_addr    ($s0 in main) (piece to be rotated)
 	#$a1 will hold buffer_addr   ($s2 in main) (where it will be rotated to)
 	#returns the rotated piece in $v0
 	
  	addi $sp, $sp, -40
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)   #max times loop will run   t0
	sw $s3, 16($sp)   #loop counter              t1
	sw $s4, 20($sp)	  #will hold our i           t2
	sw $s5, 24($sp)   #will hold our j	     t3
	sw $s6, 28($sp)   #will hold our max i       t4
	sw $s7, 32($sp)   #will hold our return value
	sw $a0, 36($sp)   #original piece_addr
	
	move $s0, $a0   
	move $s1, $a1
	move $s7, $a1 

	addi $s1, $s1, 2
	li $s2, 6     #max times loop will run
	li $s3, 0     #loop counter
	lbu $t7, 0($a0)   #our row_num in $t7
	andi $s4, $t7, 0x0F
	addi $s4, $t7, -1     #$t2 holds our i
	li $s5, 0             #$t3 holds our j	
	move $s6, $s4         #$t4 holds our MAX i	
	
	
	rotateLoop:
	beq $s2, $s3, rotateLoop.end     #ends our loop
	
	lw $s0, 36($sp) #resets the addr of piece arg
	#get character
	move $a0, $s0     #sets first arg to piece
	move $a1, $s4     #sets second arg to row
	move $a2, $s5     #sets third arg to col
	jal get_slot

	#sets character
	move $t9, $v0
	sb $v0, 0($s1)
	
	addi $s4, $s4, -1
	bltz $s4, reset.max
	j skipReset

	reset.max:
	move $s4, $s6
	addi $s5, $s5, 1

	skipReset:
	addi $s1, $s1, 1
	addi $s3, $s3, 1	
        j rotateLoop
        rotateLoop.end:
        
       
        #$s7 has original buffer addr
  	lw $t0, 36($sp)
  	lbu $t1, 0($t0)   #grabs row from original addr
  	lbu $t2, 1($t0)   #grabs col from original addr
  	
  	sb $t1, 1($s7)
  	sb $t2, 0($s7)
        
        move $v0, $s7   #the untouched beginning of buffer addr
        lw $v1, 36($sp)  #original piece addr

        
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	lw $s2, 12($sp)  
	lw $s3, 16($sp)   
	lw $s4, 20($sp)	
	lw $s5, 24($sp)  
	lw $s6, 28($sp)
	lw $s7, 32($sp)  
        
	addi $sp, $sp, 40
	
	jr $ra

#################### DO NOT CREATE A .data SECTION ####################
#################### DO NOT CREATE A .data SECTION ####################
#################### DO NOT CREATE A .data SECTION ####################
