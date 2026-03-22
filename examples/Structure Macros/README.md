To use "Structure Macros.asm" in code to be processed by AsmProc, simply:
.include "Structure Macros.asm"

From there, using predefined macros is quite simple:

	CMP	#14
	IF EQ
		<actions>	; if condition is true, perform these actions...
		<actions>
		<actions>
	ELSE_
		<actions>	; ...else perform these actions
		<actions>
		<actions>
	END_IF
	
	BEGIN
		<actions>	; loop forever, performing these actions each time
		<actions>
		<actions>
	AGAIN
	
	BEGIN
		<actions>		; all code from BEGIN to WHILE will be uncondionally run
		<actions>
		<actions>
	WHILE <condition>	; if condition ever becomes false, exit the loop...
		<actions>		; all code from WHILE to REPEAT will only be run so long as condition is true
		<actions>
		<actions>
	REPEAT				; ...otherwise continue looping
	
	BEGIN
		<actions>
		<actions>
		<actions>
	UNTIL <condition>
	
	SWITCH ACCUM		; Test the accumulator against the following cases.
		CASE 0x0A		; In the case of it containing the linefeed character,
			<actions>	; execute these instructions,
			<actions>
			BREAK		; then jump to the first instruction after ENDSW.


		CASE 0x0D		; If it has the carriage-return character,
			<actions>	; execute these instructions,
			<actions>
		 	BREAK		; then jump to the first instruction after ENDSW.


		CASE 0x08		; If it has the backspace character,
			<actions>	; execute these instructions,
			<actions>
		 	BREAK		; then jump to the first instruction after ENDSW.


		<actions>		; If the character is anything else, do these default
		<actions>		; actions to feed it to the display as display data.
	ENDSW
	
	FOR_X 8, DOWN_TO, 0	; will run 8 times, with indices of 8, 7, 6, 5, 4, 3, 2, 1, but not 0
		<actions>
		<actions>
	NEXT_X
	
	FOR	var1, 1, TO, 5000	; will loop 5,000 times
		<actions>
		<actions>
		<actions>
	NEXT var1