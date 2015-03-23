TITLE ASM Snake by Hamza and Sohaib

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	HAMZA MASUD - Reg#4582
;	SOHAIB AHMAD - Reg#5076
;	BS(CS)-3A
;	CS235 - Computer Organization & Assembly Language Project
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE Irvine32.inc

COORDINATE STRUCT
	X BYTE ?
	Y BYTE ?
COORDINATE ENDS

.DATA
;Alternate Names
	UP = 1
	DOWN = 2
	LEFT = 3
	RIGHT = 4
	
	ROW =  24
	COLUMN = 60					;80

;Variables	
	snake BYTE 219				;219 is ASCII for a filled block
	appleChar BYTE 178			;Apple character
	speed DWORD 45				;in milliseconds

	currentDirection BYTE RIGHT
	currentX BYTE ?
	currentY BYTE ?

	snakeMax = 1276					;22*58 = 1276 | Snake can't be bigger than the field
	snakeLength WORD 10				;Start with 10 blocks
	snakeBody COORDINATE SnakeMax DUP(<0,0>)	;0 = empty
	snakeHead COORDINATE <>
	snakeTail COORDINATE <>
	apple COORDINATE <>
	tempX BYTE ?					
	tempY BYTE ?
	hit	BYTE 0h

	score WORD 0h
	scoreString BYTE "Score:",0
	speedString BYTE "Speed",0
	credits1 BYTE "****************",0
	credits2 BYTE "Made by:",0
	credits3 BYTE "Hamza Masud",0
	credits4 BYTE "Sohaib Ahmad",0
	speed_1 BYTE "Normal",0
	speed_2 BYTE "Fast  ",0
	speed_3 BYTE "Faster",0
	speed_4 BYTE "Fasterer",0
	speed_5 BYTE "Crazy",0
	speed_meh BYTE "Meh    ",0


.CODE
main PROC
startingPoint:
	
	call splashScreen
;Zero initialize just in case, it actually matters
	mov eax,0h						
	mov edx,0h
	mov ecx,0h

	call initializeSnake
	call drawWalls					;Need to draw only once, so it's outside the game loop
	call appleManager

	mov dh, (ROW-2)/2						;Mid-point of field
	mov dl, (COLUMN-2)/2
	call gotoXY	

gameLoop:
	mov ecx,5						;Infinite Loop
	call sideBar
	call changeSpeed
	call handleDirection
	call moveSnake
	call drawSnake
	call drawApple
	call eatApple
	call checkCollision
	.IF hit==1
		mov eax, 550
		call delay
		jmp finishGame
	.ENDIF
		
	mov eax, speed
	call delay	
loop gameLoop

finishGame:
	call gameOverScreen
exit
main ENDP
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Initialize the snake
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
initializeSnake PROC
	mov currentX, (ROW-2)/2
	mov currentY, (COLUMN-2)/2

	mov cx, snakeLength
	mov edi, 0
snakeIni:
	mov al, currentX
	mov (COORDINATE PTR snakeBody[edi]).X, al
	mov al, currentY
	mov (COORDINATE PTR snakeBody[edi]).Y, al
	
	.IF cx==1
		mov al, currentX
		mov snakeTail.X, al
		mov al, currentY
		mov snakeTail.Y, al
	.ENDIF
	.IF cx==snakeLength
		mov al, currentX
		mov snakeHead.X, al
		mov al, currentY
		mov snakeHead.Y, al
	.ENDIF
	add edi, TYPE COORDINATE
	dec currentY
loop snakeIni

ret
initializeSnake ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Simply manages 'currentDirection' by reading keys
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

handleDirection PROC uses eax
	call readKey
	.IF ah==72 && currentDirection!=DOWN
	mov currentDirection, UP
	jmp exitFunction
		.ELSEIF ah==77 && currentDirection!=LEFT
		mov currentDirection, RIGHT
		jmp exitFunction
			.ELSEIF ah==80 && currentDirection!=UP
			mov currentDirection, DOWN
			jmp exitFunction
				.ELSEIF ah==75 && currentDirection!=RIGHT
				mov currentDirection, LEFT
exitFunction:
	.ENDIF
ret
handleDirection ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Draws the borders
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
drawWalls PROC uses edx
	mov eax, 0h
	call gotoXY
	mov ecx, COLUMN
drawTop:
	mov al,178		;ASCII
	call writeChar
loop drawTop

	mov dh, ROW
	mov dl, 0
	call gotoXY
	mov ecx, COLUMN
drawBottom:
	mov al,178		;ASCII
	call writeChar
loop drawBottom

	mov edx,0h
	call gotoXY
	mov ecx,ROW
drawLeft:
	mov al,178
	call writeChar
	call crlf	
loop drawLeft

	mov dh, 0h
	mov dl, COLUMN-1
	call gotoXY
	mov ecx,ROW
drawRight:
	mov al,178
	call writeChar
	inc dh
	call gotoXY
loop drawRight	

ret
drawWalls ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Snake Movement
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
moveSnake PROC uses eax ecx edi
;Save tail coordinates for deletion later
	mov al, snakeTail.X
	mov tempX, al
	mov al, snakeTail.Y
	mov tempY, al

;Push all coordinates back to make space for the saved tail
	mov cx, snakeLength
	sub cx, 1

	mov ax, snakeLength				;Doing (SnakeLength-2)*2 -_-
	sub ax, 2						;-1 to correct for zero correction, another -1 to get the second last element
	shl ax, 1						;Multiply by 2 ; TYPE COORD = 2

	mov di, ax
pushCoord:
	mov ax, snakeBody[di]
	mov snakeBody[di+2], ax

	sub di, 2
loop pushCoord

.IF currentDirection == RIGHT
	mov al, snakeHead.X
	mov (snakeBody[0]).X, al
	mov snakeHead.X, al

	mov al, snakeHead.Y
	inc al
	mov (snakeBody[0]).Y, al
	mov snakeHead.Y, al
.ENDIF

.IF currentDirection == LEFT
	mov al, snakeHead.X
	mov (snakeBody[0]).X, al
	mov snakeHead.X, al

	mov al, snakeHead.Y
	dec al
	mov (snakeBody[0]).Y, al
	mov snakeHead.Y, al
.ENDIF

.IF currentDirection == UP
	mov al, snakeHead.X
	dec al
	mov (snakeBody[0]).X, al
	mov snakeHead.X, al

	mov al, snakeHead.Y
	mov (snakeBody[0]).Y, al
	mov snakeHead.Y, al
.ENDIF

.IF currentDirection == DOWN
	mov al, snakeHead.X
	inc al
	mov (snakeBody[0]).X, al
	mov snakeHead.X, al

	mov al, snakeHead.Y
	mov (snakeBody[0]).Y, al
	mov snakeHead.Y, al
.ENDIF

;Clear old block, a nice workaround for not using clrscr
	mov dh, tempX
	mov dl, tempY
	call gotoXY
	mov al, ' '
	call writeChar

;Set the new tail
	mov di, snakeLength			;;;;
	sub di, 1					  ;; (snakeLength-1)*2 -_____-
	shl di, 1					;;;;

	mov bl, snakeBody[di].X
	mov bh, snakeBody[di].Y

	mov snakeTail.X, bl
	mov snakeTail.Y, bh

ret
moveSnake ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Draw the whole snake
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
drawSnake PROC uses ecx eax
	mov cx, snakeLength
	mov edi, 0
	mov edx, 0
drawingLoop:
	mov al, snakeBody[edi].X
	mov tempX, al

	mov al, snakeBody[edi].Y
	mov tempY, al

	.IF tempX!=0 && tempY!=0		
		mov dh, tempX
		mov dl, tempY
		call gotoXY

		mov al, snake
		call writeChar
	.ENDIF
	add edi, TYPE COORDINATE
loop drawingLoop

ret
drawSnake ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Apple Stuff
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
appleManager PROC
	mov eax, ROW-1
	call randomRange
	inc eax				;Dont't spawn on walls
	mov apple.X, al

	mov eax, COLUMN-1
	call randomRange
	inc eax
	mov apple.Y, al

ret
appleManager ENDP


drawApple PROC uses edx eax
	mov dh, apple.X
	mov dl, apple.Y
	call gotoXY

	mov eax, lightRed+(black*16)
	call setTextColor

	mov al, appleChar
	call writeChar

;Set back to default color after drawing
	mov eax, white+(black*16)
	call setTextColor
ret
drawApple ENDP

eatApple PROC
	mov dh, snakeHead.X
	mov dl, snakeHead.Y
COMMENT $
	.IF dh==apple.X && dl==apple.Y
		add score,8
		call appleManager
		inc snakeLength
	.ENDIF
$

	cmp dh, apple.X
	jne safeExit
	cmp dl, apple.Y
	jne safeExit
		add score,8
		call appleManager
		inc snakeLength
safeExit:
ret 
eatApple ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Collision detection
; OUTPUT: 'hit' variable
; Store decision in bl which can be used to end the game
; 0 = OK, 1 = Hit
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
checkCollision PROC
	mov dh, snakeHead.X
	mov dl, snakeHead.Y
COMMENT $
	.IF dl==0 || dh==0 || dh==ROW || dl==COLUMN-1
		mov bl,1
		mov hit,bl
	.ENDIF
$

	or dl,dl
	je doThis
	or dh,dh
	je doThis
	cmp dh, ROW
	je doThis
	cmp dl, COLUMN-1h
	jne didntMakeIt

doThis:
	mov bl,1
	mov hit,bl

didntMakeIt:	

;Check collisions with body
	mov edi,2
	mov cx, snakeLength
	dec cx
hitItself:
COMMENT $
	.IF dh==snakeBody[edi].X && dl==snakeBody[edi].Y
		mov bl,1
		mov hit,bl
	.ENDIF
$

	cmp dh, snakeBody[edi].X
	jne nextStep
	cmp dl, snakeBody[edi].Y
	jne nextStep
		mov bl,1
		mov hit, bl
	
nextStep:
	add edi, TYPE COORDINATE
loop hitItself

safe:	
ret
checkCollision ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Change speed depending on score
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
changeSpeed PROC uses eax
	.IF score==48
		mov eax, 38
		mov speed, eax
	.ELSEIF score==80
		mov eax, 30
		mov speed, eax
	.ELSEIF score==128
		mov eax, 22
		mov speed, eax
	.ELSEIF score==160
		mov eax, 16
		mov speed, eax
	.ELSEIF score==200
		mov eax, 10
		mov speed, eax
	.ENDIF

ret
changeSpeed ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Manage the sidebar
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
sideBar PROC
	mov dh, 2
	mov dl, 62
	call gotoXY
	mov edx, OFFSET scoreString
	call writeString

	mov dh, 3
	mov dl, 68
	call gotoXY
	mov ax, score
	call writeDec

	mov dh, 7
	mov dl, 62
	call gotoXY
	mov edx, OFFSET speedString
	call writeString

	mov dh, 8
	mov dl, 68
	call gotoXY
	
	.IF score<48
		mov edx, OFFSET speed_1
		call writeString
	.ELSEIF score>=48 && score<80
		mov edx, OFFSET speed_meh
		call writeString
	.ELSEIF score>=80 && score<128
		mov edx, OFFSET speed_2
		call writeString
	.ELSEIF score>=128 && score<160
		mov edx, OFFSET speed_3
		call writeString
	.ELSEIF score>=160 && score<200
		mov edx, OFFSET speed_4
		call writeString
	.ELSEIF score>200
		mov edx, OFFSET speed_5
		call writeString
	.ENDIF

	mov dh, 20
	mov dl, 62
	call gotoXY
	mov edx, OFFSET credits1
	call writeString
	mov dh, 21
	mov dl, 62
	call gotoXY
	mov edx, OFFSET credits2
	call writeString
	mov dh, 22
	mov dl, 65
	call gotoXY
	mov edx, OFFSET credits3
	call writeString
	mov dh, 23
	mov dl, 65
	call gotoXY
	mov edx, OFFSET credits4
	call writeString
ret
sideBar ENDP

.data

splash BYTE"     #######                          /",13,10    
BYTE "	     /       ###                      #/",13,10
BYTE "	    /         ##                      ##",13,10
BYTE "	    ##        #                       ##",13,10
BYTE "	     ###                              ##",13,10
BYTE "	    ## ###      ###  /###     /###    ##  /##      /##",13,10
BYTE "	     ### ###     ###/ #### / / ###  / ## / ###    / ###",13,10
BYTE "	       ### ###    ##   ###/ /   ###/  ##/   /    /   ###",13,10
BYTE "	         ### /##  ##    ## ##    ##   ##   /    ##    ###",13,10
BYTE "	           #/ /## ##    ## ##    ##   ##  /     ########",13,10
BYTE "	            #/ ## ##    ## ##    ##   ## ##     #######",13,10
BYTE "	             # /  ##    ## ##    ##   ######    ##",13,10
BYTE "	   /##        /   ##    ## ##    /#   ##  ###   ####    /",13,10
BYTE "	  /  ########/    ###   ### ####/ ##  ##   ### / ######/",13,10
BYTE "	 /     #####       ###   ### ###   ##  ##   ##/   #####",13,10
BYTE "	 |",13,10                                                       
BYTE "	  \)",0

ourNames BYTE "-Hamza Masud & Sohaib Ahmad",0
start BYTE "Start Game", 0


.code
splashScreen PROC
	call clrscr
	mov dh,0
	mov dl,10
	call gotoXY

	mov eax, green+(black*16)
	call setTextColor
	mov edx, OFFSET splash
	call writeString

	mov dh, 15
	mov dl, 35
	call gotoXY
	mov edx, OFFSET ourNames
	call writeString

	mov dh, 19
	mov dl, 34
	call gotoXY
	mov eax, white+(cyan*16)
	call setTextColor
	mov edx, OFFSET start
	call writeString

	mov eax, white+(black*16)
	call setTextColor
	
	mov dh, 19
	mov dl,32
	call gotoXY
	mov al, '>'
	call writeChar
again:
	call readChar	
	cmp al, 0Dh
	jne again

	call clrscr
	
ret
splashScreen ENDP


.data
gameOverSplash BYTE "	  _____                       ____",13,10                 
BYTE "		 / ____|                     / __ \",13,10                
BYTE "		| |  __  __ _ _ __ ___   ___| |  | |_   _____ _ __",13,10 
BYTE "		| | |_ |/ _` | '_ ` _ \ / _ \ |  | \ \ / / _ \ '__|",13,10
BYTE "		| |__| | (_| | | | | | |  __/ |__| |\ V /  __/ |",13,10   
BYTE "		 \_____|\__,_|_| |_| |_|\___|\____/  \_/ \___|_|",0   

yourScore BYTE "Your score is: ",0
restartButton BYTE "Restart",0
exitButton BYTE "Exit",0
choice BYTE 0
                                                 

.code
gameOverScreen PROC
	call clrscr
	mov dh,4
	mov dl,10
	call gotoXY

	mov eax, green+(black*16)
	call setTextColor
	mov edx, OFFSET gameOverSplash
	call writeString

	mov dh, 12
	mov dl, 24
	call gotoXY
	mov edx, OFFSET yourScore
	call writeString

	mov dh, 13
	mov dl, 39
	call gotoXY
	mov ax, score
	call writeDec
	call crlf

	mov dh, 17
	mov dl, 32
	call gotoXY
	mov edx, OFFSET restartButton
	call writeString

	mov dh, 18
	mov dl, 32
	call gotoXY
	mov edx, OFFSET exitButton
	call writeString

	endChoice:
		call moveCursor
		call readChar
		call cleanMenu
		cmp al, 0Dh
		jne nopeNope
			.IF choice==0h
			call again
			.ELSEIF choice==1h
			call crlf
			exit
			.ENDIF
		nopeNope:

		.IF ah == 72
			mov choice,0h
		.ELSEIF ah == 80
			mov choice,1h
		.ENDIF
		
						
	jmp endChoice	
ret
gameOverScreen ENDP

;SUBFUNCTION TO OVERCOME JMP LIMIT
moveCursor PROC uses eax edx
	.IF choice==0
			mov dh, 17
			mov dl, 30
			call gotoXY
			mov al,'>'
			call writeChar
			
	.ELSEIF choice==1
				mov dh, 18
				mov dl, 30
				call gotoXY
				mov al,'>'
				call writeChar
	.ENDIF
ret
moveCursor ENDP

cleanMenu PROC uses eax edx				
		cmp choice, 1
		je otherOption
			mov dh, 17
			mov dl, 30
			call gotoXY
			mov al,' '
			call writeChar
			jmp goBack
		otherOption:
			mov dh, 18
			mov dl, 30
			call gotoXY
			mov al,' '
			call writeChar
goBack:
ret
cleanMenu ENDP

again PROC
	mov ax, 10
	mov snakeLength, ax

	mov ecx, snakeMax
	mov edi, 0
zeroInitialize:
	mov ax, 0
	mov snakeBody[edi],ax
	add edi, TYPE COORDINATE
loop zeroInitialize
	call initializeSnake

	mov score, 0
	mov hit, 0
	mov speed,45
	mov currentDirection, RIGHT
	call main
ret
again ENDP

end main