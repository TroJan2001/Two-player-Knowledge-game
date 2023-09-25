#INCLUDE<P16F877A.INC> 
cblock 0x20
SAVEDANSWER
Counter
TEMP
QUESTIONSEL
SEL
P1SCORE
P2SCORE
Q0SEL
Q1SEL
Q2SEL
Q3SEL
Q4SELP1
Q4SELP2
RightANS
BONUSVALUE
MSD
LSD
INTERRUPTED
endc
;**************************************************
org 0x00
GOTO   INITIAL;Initialization
;**************************************************
org 0x0004
INT_SVC
BANKSEL    INTERRUPTED
BSF        INTERRUPTED,0 
BANKSEL    PORTD
BTFSC      PORTD,0
GOTO 	   SUBMITTED
GOTO 	   SUBMITTED2
;**************************************************
INITIAL 
        BANKSEL     INTERRUPTED
		CLRF        INTERRUPTED
        BANKSEL     Q4SELP1
       	CLRF		Q4SELP1
        BANKSEL     Q4SELP2
       	CLRF		Q4SELP2
        BANKSEL     Q0SEL
       	CLRF		Q0SEL
        BANKSEL     Q1SEL
		CLRF	    Q1SEL
        BANKSEL     Q2SEL
		CLRF	    Q2SEL
        BANKSEL     Q3SEL
		CLRF	    Q3SEL
        BANKSEL     RightANS
		CLRF	    RightANS
		BANKSEL   	TRISA       	
  		MOVLW     	0xFF         	
        MOVWF       TRISA;for inputs
  		MOVLW      	b'00000001'
		MOVWF	    TRISB;for 7-segment and INT
        CLRF      	TRISC;for LCD          
		CLRF		TRISD;for LEDs and lcd output pins(RS,RW,E)
        MOVLW		b'00000110'
        MOVWF		TRISE;for Answer Switches
        BANKSEL     PORTA
        CLRF        PORTA
        BANKSEL     PORTB       
       	CLRF        PORTB
        BANKSEL     PORTC
        CLRF        PORTC
        BANKSEL     PORTD
        CLRF        PORTD
        BANKSEL     PORTE
        CLRF        PORTE   
        BANKSEL		ADCON1
		MOVLW		0x0F;Left Justified, AN0 channel is analog only
		MOVWF		ADCON1
		BANKSEL		ADCON0			
		MOVLW		0x41;
       	MOVWF		ADCON0
        CALL        DELAY
        Movlw 		0x38 ; 8-bit mode, 2-line display, 5x7 dot format
 		Call 		send_cmd
		Movlw 		0x0c ; Display on, Cursor Underline off, Blink off
		Call 		send_cmd
		Movlw 		0x02 ; Display and cursor home
		Call 		send_cmd
		Movlw 		0x01 ; clear display
		Call 		send_cmd

;**************************************************
Main             
        BANKSEL     PORTA
WAIT    btfss       PORTA,1;Pulling start push button until game starts
        GOTO        WAIT        
		CALL		DELAY
        CALL        Player1;Player 1 picks a question
        CALL        Player2;Player 2 picks a question
		CALL        Player1;Player 1 picks a question
       	CALL        Player2;Player 2 picks a question
        CALL        Player1;Player 1 picks a question
        CALL        Player2;Player 2 picks a question
        MOVF        P1SCORE,0;move player1 to w
        SUBWF       P2SCORE;check if player2 score if the same
        BTFSC       STATUS,Z
        GOTO        DRAW;type draw
        BTFSC       STATUS,C;if not the same either player with higher score wins
        GOTO        PLAYER2WINS
        GOTO        PLAYER1WINS
		GOTO        FINAL;finish the game(Got to end)
;************************** PLAYER1 ************************
Player1 
        	BANKSEL     PORTD
        	BSF        	PORTD,0;Player1 led is on
        	BCF         PORTD,1;Player2 led is off
        	CALL        DELAY
            CALL        SELECT_QUESTIONS;To select 1 of 4 questions or a bonus
            BANKSEL     INTCON
        	MOVLW      	0XD0
        	MOVWF      	INTCON;Enable the Interrupt on RB0(Subimt)
        	GOTO        COUNTER;Start the Counter(9-0)9 Seconds
SUBMITTED              
            BANKSEL     INTCON
        	MOVLW      	0X00
        	MOVWF      	INTCON;Disable the Interrupt on RB0(Subimt)
            Movlw 		0x02 ; Display and cursor home
			Call 		send_cmd
			Movlw 		0x01 ; clear display
			Call 		send_cmd
            BANKSEL     PORTE
            BTFSC       PORTE,2;check RE2 value
            GOTO        DONE2
            BTFSC       PORTE,1;check RE1 value
            MOVLW       .1
            MOVLW		.0
            MOVWF       SAVEDANSWER;
            GOTO        DONE1
DONE2		MOVLW       .2
            MOVWF       SAVEDANSWER       
DONE1       GOTO        CHECK;Go check the answer compared to Right Answer        
RIGHT       MOVLW       .10
            ADDWF       P1SCORE;If Right add 10 points to Player1 Score
WRONG           
   			RETURN
;************************** PLAYER2 ************************
Player2 
        	BANKSEL     PORTD
        	BSF        	PORTD,1;for LEDs2 on
        	BCF         PORTD,0;;for LEDs1 off
        	CALL        DELAY      
            CALL        SELECT_QUESTIONS
            BANKSEL     INTCON
        	MOVLW      	0XD0
        	MOVWF      	INTCON;Enable the Interrupt on RB0(Subimt)
        	GOTO        COUNTER;Start the Counter(9-0)9 Seconds
SUBMITTED2  
			BANKSEL     INTCON
        	MOVLW      	0X00
        	MOVWF      	INTCON;Disable the Interrupt on RB0(Subimt)
            Movlw 		0x02 ; Display and cursor home
			Call 		send_cmd
			Movlw 		0x01 ; clear display
			Call 		send_cmd
            BANKSEL     PORTE
            BTFSC       PORTE,2;check RE2 value
            GOTO        DONE22
            BTFSC       PORTE,1;check RE1 value
            MOVLW       .1
            MOVLW		.0
            MOVWF       SAVEDANSWER
            GOTO        DONE11
DONE22		MOVLW       .2
            MOVWF       SAVEDANSWER       
DONE11      GOTO        CHECK;Go check the answer compared to Right Answer        
RIGHT2      MOVLW       .10
            ADDWF       P2SCORE;If Right add 10 points to Player2 Score
WRONG2           
   			RETURN                     

;************************** SELECT QUESTIONS ************************
SELECT_QUESTIONS
			BANKSEL	  ADCON0			
			MOVLW     0x41
			MOVWF     ADCON0;ADCS1:ADCS0: A/D Conversion Clock Select bits = FOSC/8 & ADON: A/D On bit
			CALL      DELAY
			BSF       ADCON0,GO;1 = A/D conversion in progress		
GOWAIT    	BTFSC     ADCON0,GO
			GOTO      GOWAIT;pulling go/done bit value 
            BCF       STATUS,C;clear the carry flag
            ;A specific calcuation needed to convert ADRESH Register value to corresponding question
			MOVLW     .4
			MOVWF     SEL
			BANKSEL   ADRESH
			MOVF      ADRESH,W
			MOVWF     QUESTIONSEL
			movlw     .204  
			SUBWF     QUESTIONSEL,0
			BTFSC     STATUS,C
			GOTO      FINISH4;Player selected Bonus Question
			MOVLW     .3
			MOVWF     SEL
			MOVLW     .153  
			SUBWF     QUESTIONSEL,0
			BTFSC     STATUS,C
			GOTO      FINISH3;Player selected Question 4
			MOVLW     .2
			MOVWF     SEL
			movlw     .102  
			SUBWF     QUESTIONSEL,0
			BTFSC     STATUS,C
			GOTO      FINISH2;Player selected Question 3
			MOVLW     .1
			MOVWF     SEL
			movlw     .51  
			SUBWF     QUESTIONSEL,0
			BTFSC     STATUS,C
			GOTO      FINISH1;Player selected Question 2
			MOVLW     .0
			MOVWF     SEL
			GOTO      FINISH0;Player selected Question 1

FINISH4   BTFSC     PORTD,0;Check which player selected the Bonus
          GOTO      B1CHECK;Player1 
          GOTO      B2CHECK;Player2 
B1CHECK	  BTFSC     Q4SELP1,0;Check if Bonus Question for player1 selected before
          GOTO      SELECTDIFFERENT;if Player1 selected Bonus before then select another
          GOTO      Q4SELECTED;If first time to be selected then proceed
B2CHECK	  BTFSC     Q4SELP2,0;Check if Bonus Question for player2 selected before
          GOTO      SELECTDIFFERENT;if Player2 selected Bonus before then select another
          GOTO      Q4SELECTED;If first time to be selected then proceed   
FINISH3   BTFSC     Q3SEL,0;Check if either player selected Question 4 before
          GOTO      SELECTDIFFERENT;if either player selected Question 4 before then select another
          GOTO      Q3SELECTED;If first time to be selected then proceed
FINISH2   BTFSC     Q2SEL,0;Check if either player selected Question 3 before
          GOTO      SELECTDIFFERENT;if either player selected Question 3 before then select another
          GOTO      Q2SELECTED;If first time to be selected then proceed
FINISH1   BTFSC     Q1SEL,0;Check if either player selected Question 2 before
          GOTO      SELECTDIFFERENT;if either player selected Question 2 before then select another
          GOTO      Q1SELECTED;If first time to be selected then proceed
FINISH0   BTFSC     Q0SEL,0;Check if either player selected Question 1 before
          GOTO      SELECTDIFFERENT;if either player selected Question 1 before then select another
          GOTO      Q0SELECTED ;If first time to be selected then proceed   
TESTED;Checked that the question never picked before   
		  BANKSEL   SEL
          MOVF 		SEL,0;Move SEL value to w  
		  CALL 		TABLE2
FINISHED 
RETURN
;************************** QUESTIONS ************************
;To display questions
Q0
Movlw 0x01 ; clear display
Call  send_cmd
Movlw 0x02 ; Display and cursor home
Call  send_cmd
movlw '1'
call  send_char
movlw '+'
call  send_char
movlw '2'
call  send_char
movlw '='
call  send_char
movlw '?'
call  send_char
movlw b'11000000'
call  send_cmd
movlw '1'
call  send_char
movlw ' '
call  send_char
movlw '2'
call  send_char
movlw ' '
call  send_char
movlw '3'
call  send_char
GOTO  FINISHED
Q1
Movlw 0x01 ; clear display
Call  send_cmd
Movlw 0x02 ; Display and cursor home
Call  send_cmd
movlw '6'
call  send_char
movlw '-'
call  send_char
movlw '2'
call  send_char
movlw '='
call  send_char
movlw '?'
call  send_char
movlw b'11000000'
call  send_cmd
movlw '5'
call  send_char
movlw ' '
call  send_char
movlw '4'
call  send_char
movlw ' '
call  send_char
movlw '2'
call  send_char
Movlw 0x02 ; Display and cursor home
Call send_cmd
GOTO  FINISHED
Q2
Movlw 0x01 ; clear display
Call  send_cmd
Movlw 0x02 ; Display and cursor home
Call  send_cmd
movlw '3'
call  send_char
movlw '*'
call  send_char
movlw '2'
call  send_char
movlw '='
call  send_char
movlw '?'
call  send_char
movlw b'11000000'
call  send_cmd
movlw '6'
call  send_char
movlw ' '
call  send_char
movlw '2'
call  send_char
movlw ' '
call  send_char
movlw '1'
call  send_char
GOTO  FINISHED
Q3
Movlw 0x01 ; clear display
Call  send_cmd
Movlw 0x02 ; Display and cursor home
Call  send_cmd
movlw '8'
call  send_char
movlw '/'
call  send_char
movlw '2'
call  send_char
movlw '='
call  send_char
movlw '?'
call  send_char
movlw b'11000000'
call  send_cmd
movlw '5'
call  send_char
movlw ' '
call  send_char
movlw '4'
call  send_char
movlw ' '
call  send_char
movlw '2'
call  send_char
GOTO  FINISHED
BONUS
Movlw 0x01 ; clear display
Call  send_cmd
Movlw 0x02 ; Display and cursor home
Call  send_cmd
movlw 'B'
call  send_char
movlw 'O'
call  send_char
movlw 'N'
call  send_char
movlw 'U'
call  send_char
movlw 'S'
call  send_char
movlw '='
call  send_char
BANKSEL ADRESH
BTFSC ADRESH,0
movlw '-'
BTFSC ADRESH,0
call  send_char
MOVLW 0x30 
BANKSEL BONUSVALUE
ADDWF  BONUSVALUE,0
call  send_char
GOTO  FINISHED
RETURN
;************************** SENDCHAR ************************
send_char
    BANKSEL PORTC
	movwf PORTC
	bsf PORTD, 3;rs=1; // Select the Data Register by pulling RS HIGH
	bsf PORTD, 2;en=1; // Send a High-to-Low Pusle at Enable Pin
	nop
	bcf PORTD, 2;
	bcf PORTD, 4;rw=0; // Select the Write Operation by pulling RW LOW
	CALL DELAY
RETURN
;************************** SENDCMD ************************
send_cmd
    BANKSEL PORTC
	movwf PORTC
	bcf PORTD, 3;rs=0; // Select the Command Register by pulling RS LOW
	bsf PORTD, 2;en=1; // Send a High-to-Low Pusle at Enable Pin
	nop
	bcf PORTD, 2
	bcf PORTD, 4;rw=0; // Select the Write Operation by pulling RW LOW
	CALL DELAY
RETURN
;************************** DELAY ************************
DELAY
		movlw 0x80
		movwf MSD
		clrf LSD
loop2
		decfsz LSD,f
		goto loop2
		decfsz MSD,f
endLcd
		goto loop2
RETURN
;************************** Lookup Table2 ************************
;check which question was selected to display on LCD
TABLE2 
        BANKSEL     SEL
        MOVF        SEL,1
		BTFSC       STATUS,Z
		GOTO Q0		;'Q0'
        MOVLW       .1
        SUBWF       SEL,0
        BTFSC       STATUS,Z
		GOTO Q1		;'Q1'
        MOVLW       .2
        SUBWF       SEL,0
        BTFSC       STATUS,Z	
		GOTO Q2		;'Q2'
        MOVLW       .3
        SUBWF       SEL,0
        BTFSC       STATUS,Z 		
		GOTO Q3		;'Q3'  		
		GOTO BONUS  ;'BONUS'

;Here after I choose the question I must make him not to pick it again and put the right answer in RightANS Reg
;************************** Q0SELECTED ************************
Q0SELECTED
MOVLW .1
MOVWF Q0SEL
MOVLW .2
MOVWF RightANS
GOTO  TESTED
;************************** Q1SELECTED ************************
Q1SELECTED
MOVLW .1
MOVWF Q1SEL
MOVWF RightANS
GOTO  TESTED
;************************** Q2SELECTED ************************
Q2SELECTED
MOVLW .1
MOVWF Q2SEL
MOVLW .0
MOVWF RightANS
GOTO  TESTED
;************************** Q3SELECTED ************************
Q3SELECTED
MOVLW .1
MOVWF Q3SEL
MOVWF RightANS
GOTO  TESTED
;************************** Q4SELECTED ************************
Q4SELECTED
MOVLW .1
BTFSC PORTD,0
GOTO  P1
GOTO  P2
P1 	MOVWF Q4SELP1
    CALL  BONUSV  
    GOTO  TESTED
P2	MOVWF Q4SELP2
    CALL  BONUSV
	GOTO  TESTED
;************************** COUNTER ************************
COUNTER     CLRF     Counter
			movlw	 .9
        	movwf    Counter
LOOP1       movf     Counter,0
            BTFSC    INTERRUPTED,0
            GOTO     DONEHERE
            CALL     DISPLAY
            CALL     DELAY    
        	DECFSZ   Counter,1
        	GOTO     LOOP1
            MOVLW    .0
            CALL     DISPLAY
   			CALL     DELAY
DONEHERE
            BANKSEL  INTERRUPTED;if was interrputed then stop displaying numbers
			BCF      INTERRUPTED,0
            MOVLW    .10;check the Table, the corresponding is to turn 7seg off
            CALL     DISPLAY
            BTFSC    PORTD,0
            GOTO     SUBMITTED;Proceed on Player1
            GOTO     SUBMITTED2;Proceed on Player2            
;************************** DISPLAY ************************
DISPLAY 
  		CALL     	TABLE
        BANKSEL     PORTB
  		MOVWF    	PORTB;7seg connected to PortB 
    	RETURN
 
;************************** Lookup Table ************************
;check which number to show on 7seg
TABLE   
        MOVWF       TEMP
        MOVLW       .0
        SUBWF       TEMP,0       
		BTFSC       STATUS,Z
		RETLW		B'01111110'		;'0'
        MOVLW       .1
        SUBWF       TEMP,0
        BTFSC       STATUS,Z
		RETLW		B'00001100'		;'1'
        MOVLW       .2
        SUBWF       TEMP,0
        BTFSC       STATUS,Z	
		RETLW		B'10110110'		;'2'
        MOVLW       .3
        SUBWF       TEMP,0
        BTFSC       STATUS,Z		
		RETLW		B'10011110'		;'3'
        MOVLW       .4
        SUBWF       TEMP,0
        BTFSC       STATUS,Z 		
		RETLW		B'11001100'		;'4'
        MOVLW       .5
        SUBWF       TEMP,0
        BTFSC       STATUS,Z
		RETLW		B'11011010'		;'5'
        MOVLW       .6
        SUBWF       TEMP,0
        BTFSC       STATUS,Z		
		RETLW		B'11111010' 	;'6'
        MOVLW       .7
        SUBWF       TEMP,0
        BTFSC       STATUS,Z
		RETLW		B'00001110'		;'7'
        MOVLW       .8
        SUBWF       TEMP,0
        BTFSC       STATUS,Z		
		RETLW		B'11111110'		;'8'
        MOVLW       .9
        SUBWF       TEMP,0
        BTFSC       STATUS,Z
		RETLW		B'11011110'		;'9'
        MOVLW       .10
        SUBWF       TEMP,0
        BTFSC       STATUS,Z
		RETLW		B'00000000'		;'nothing'

;************************** CHECKANS ************************
;check if given ans is correct to the given question
CHECK
		MOVF        SAVEDANSWER,0
        SUBWF       RightANS,0
        BTFSC       PORTD,0;check if player 1 or 2 is playing at the moment
        GOTO        CHECK1
        GOTO        CHECK2
CHECK1  BTFSC       STATUS,Z
      	GOTO        WRONG
        GOTO        RIGHT
CHECK2  BTFSC       STATUS,Z
      	GOTO        WRONG2
        GOTO        RIGHT2
;************************** PLAYER1WINS ************************
;Display PLAYER1WINS
PLAYER1WINS
Movlw 0x01 ; clear display
Call  send_cmd
Movlw 0x02 ; Display and cursor home
Call  send_cmd
movlw 'P'
call  send_char
movlw 'L'
call  send_char
movlw 'A'
call  send_char
movlw 'Y'
call  send_char
movlw 'E'
call  send_char
movlw 'R'
call  send_char
movlw '1'
call  send_char
movlw 'W'
call  send_char
movlw 'I'
call  send_char
movlw 'N'
call  send_char
movlw 'S'
call  send_char
RETURN
;************************** PLAYER2WINS ************************
;Display PLAYER2WINS
PLAYER2WINS
Movlw 0x01 ; clear display
Call  send_cmd
Movlw 0x02 ; Display and cursor home
Call  send_cmd
movlw 'P'
call  send_char
movlw 'L'
call  send_char
movlw 'A'
call  send_char
movlw 'Y'
call  send_char
movlw 'E'
call  send_char
movlw 'R'
call  send_char
movlw '2'
call  send_char
movlw 'W'
call  send_char
movlw 'I'
call  send_char
movlw 'N'
call  send_char
movlw 'S'
call  send_char

RETURN
;************************** DRAW ************************
;Display DRAW
DRAW
Movlw 0x01 ; clear display
Call  send_cmd
Movlw 0x02 ; Display and cursor home
Call  send_cmd
movlw 'D'
call  send_char
movlw 'R'
call  send_char
movlw 'A'
call  send_char
movlw 'W'
call  send_char

RETURN
;************************** BONUSV ************************
;Generate a random value for bonus
BONUSV
        BANKSEL ADRESH 
        MOVF    ADRESH,0
        MOVWF   BONUSVALUE
        RRF     BONUSVALUE,1
        BTFSC   BONUSVALUE,6
        RRF     BONUSVALUE,1
        BTFSC   BONUSVALUE,4
        RRF     BONUSVALUE,1
        BTFSS   BONUSVALUE,3
        RRF     BONUSVALUE,1        
		MOVLW   b'00000111'
		ANDWF   BONUSVALUE,1
        MOVF    BONUSVALUE,0
		BTFSC   PORTD,0
		GOTO    ADDP1
		GOTO    ADDP2		   
ADDP1   
		BANKSEL ADRESL
		BTFSC   ADRESH,0;check if we need to add or sub
		ADDWF   P1SCORE
		SUBWF   P1SCORE
        RETURN
    
ADDP2 	
		BANKSEL ADRESH
        BTFSC   ADRESH,0;check if we need to add or sub
		ADDWF   P2SCORE
		SUBWF   P2SCORE
		RETURN
;************************** SELECTDIFFERENT ************************
;Display TRY ANOTHER Q
SELECTDIFFERENT
Movlw 0x01 ; clear display
Call  send_cmd
Movlw 0x02 ; Display and cursor home
Call  send_cmd
movlw 'T'
call  send_char
movlw 'R'
call  send_char
movlw 'Y'
call  send_char
movlw ' '
call  send_char
movlw 'A'
call  send_char
movlw 'N'
call  send_char
movlw 'O'
call  send_char
movlw 'T'
call  send_char
movlw 'H'
call  send_char
movlw 'E'
call  send_char
movlw 'R'
call  send_char
movlw ' '
call  send_char
movlw 'Q'
call  send_char
GOTO  SELECT_QUESTIONS
;********************************GAME OVER**********************************
FINAL  
END
