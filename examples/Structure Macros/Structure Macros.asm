; Originally made by Garth Wilson @ [https://wilsonminesco.com/StructureMacros/]
; Ported to work with Assembly Preprocessor's odd syntax and eccentricities
; Contents of this file use a different licence as compared to the main project, specifically: CC BY-SA 4.0 -- [https://creativecommons.org/licenses/by-sa/4.0/]

.let strucMacVer = "1.0.0"

;                         +--------------------------+
;                         |  IF_xx...ELSE_...END_IF  |
;                         +==========================+

\^{createStack, ifElseLabel}

.macro IF COND ; Execute following code if COND is met. For use with ELSE and ENDIF.
.let ifElseTmpLabel = ifLabel_\${*}
\^{push, ifElseLabel, \&{ifElseTmpLabel}} ; and push the label on the stack for later use by ELSE or ENDIF.
	.switch \%{COND}
		.case == Z_SET
		.case == EQ
		.case == ZERO
			BNE \&{ifElseTmpLabel}
			.break
		.case == Z_CLR
		.case == NEQ
		.case == NOT_ZERO
			BEQ \&{ifElseTmpLabel}
			.break
		.case == N_SET
		.case == NEG
		.case == MINUS
			BPL \&{ifElseTmpLabel}
			.break
		.case == N_CLR
		.case == POS
		.case == PLUS
			BMI \&{ifElseTmpLabel}
			.break
		.case == C_SET
		.case == GE
			BCC \&{ifElseTmpLabel}
			.break
		.case == C_CLR
		.case == LT
			BCS \&{ifElseTmpLabel}
			.break
		.case == V_SET
			BVC \&{ifElseTmpLabel}
			.break
		.case == V_CLR
			BVS \&{ifElseTmpLabel}       ; Lay down the appropriate op code,
			.break
	.endsw
.endm
;----------------


.macro ELSE
.let ifElseTmpLabel = elseLabel_\${*}
	BRA \&{ifElseTmpLabel}                ; Lay down the BRA op code that jumps to ENDIF if IF had been taken.
\^{pop, ifElseLabel}:                     ; IF will bra to here if its cond was false
\^{push, ifElseLabel, \&{ifElseTmpLabel}} ; push new address so ELSE can BRA to ENDIF
.endm
;----------------                        ; Note that ELSE assembles only a single instruction, a forward branch.


.macro ENDIF
\^{pop, ifElseLabel}: ; Note that ENDIF adds not a single byte to the code, only places down the label that IF or optional ELSE above BRA to.
.endm
;----------------


.macro IF_BIT MEM_ADR, BIT_NR, CONDX      ; Syn: IF_BIT VIA3PA, 4, IS_LOW
.let ifElseTmpLabel = ifLabel_\${*}    ; Tests a bit in a memory location. Accum is changed if you specify a bit other than 6 or 7.
\^{push, ifElseLabel, \&{ifElseTmpLabel}} ; push the label on the stack for later use by ELSE or ENDIF.
	.switch \%{BIT_NR}
		.case < 0
		.case > 7
			\!{WHILE_BIT.outOfBounds, \%{MEM_ADR}, \%{BIT_NR}, \%{CONDX}}
			.break                       ; bounds check for the LOLZ
		.case == 6
		.case == 7 ; We can branch on V or N for 6 & 7.
			BIT \%{MEM_ADR}
			.if \%{BIT_NR} == 7          ; For bit 7, branch on N.
				.if \%{CONDX} == IS_HIGH
					BPL \&{ifElseTmpLabel}
				.else
					BMI \&{ifElseTmpLabel}
				.endif
			.else                        ; By process of elimination, the only bit left here is 6, so branch on V.
				.if \%{CONDX} == IS_HIGH
					BVC \&{ifElseTmpLabel}
				.else
					BVS \&{ifElseTmpLabel}
				.endif
			.endif
			.break
		.default                         ; BIT_NR == 0..5
			LDA #(1 << \%{BIT_NR})       ; Accum gets changed if you specify a bit other than 6 or 7.
			BIT \%{MEM_ADR}
			.if \%{CONDX} == IS_HIGH     ; The 2nd function of BIT is to AND the accum with the mem and set Z if the
				BEQ \&{ifElseTmpLabel}    ; result is 0, otherwise clear it.  Specifying IS_SET means you do the
			.else                        ; following code if the bit is set.  A set bit results in Z flag clear.
				BNE \&{ifElseTmpLabel}
			.endif                       ; If you have the BBS & BBR instructions, then instead of always using BIT and Bxx,
			.break                       ; you could also have the macro watch for the adr being in ZP and have it use BBR/BBS in
	.endsw                               ; that case, for efficiency.  That's mostly for if you have I/O in ZP though, which is
                                         ; very rare outside of microcontrollers like the Rockwell 65c19.
.endm
;------------------








;                        +--------------------------+
;                        |      BEGIN...AGAIN       |
;                        |      BEGIN...UNTIL       |
;                        |  BEGIN...WHILE...REPEAT  |
;                        +==========================+

\^{createStack, beginLabel}
\^{createStack, whileLabel}
.let whileTmpLabel = blank ; tmp label that REPEAT places down for WHILE to BRA to

.macro BEGIN                                   ; For use with AGAIN, REPEAT, and any of the UNTIL_xx and WHILE_xx macros.
\#{label, beginTmpLabel, beginLabel_\${*}}: ; UNTIL, THEN, and REPEAT use this to know where to branch up to
\^{push, beginLabel, \&{beginTmpLabel}}       ; BEGIN does not actually add any machine code.

\^{push, whileLabel, \&{whileTmpLabel}} ; save current tmp label to the stack. Allows nested BEGIN...REPEAT(AGAIN, UNTIL) statements
.let whileTmpLabel = whileLabel_\${*} ; generate a new unique label for WHILE to use
.endm
;----------------


.macro AGAIN                ; Continue loop unconditionally.  Similar to REPEAT, but not for use with WHILE_xx.
	BRA \^{pop, beginLabel} ; (same kind of thing as UNTIL below)
.let whileTmpLabel = \^{pop, whileLabel} ; WHILE label isn't used by AGAIN, but it still has to be popped from the stack
.endm
;----------------


.macro REPEAT               ; Similar to AGAIN, but for use with WHILE_xx. Only adds two bytes to the code, those of the BRA instruction.
	BRA \^{pop, beginLabel} ; Assemble a branch back to the top of the loop (BEGIN). And pop the label as it's no longer needed
\&{whileTmpLabel}:          ; label for WHILE to BRA to once condition becomes false
.let whileTmpLabel = \^{pop, whileLabel} ; pop previous label off of stack now that REPEAT is done with it
.endm
;----------------


.macro WHILE COND ; Continue while COND is met. For use with BEGIN and REPEAT.
	.switch \%{COND}
		.case == Z_SET
		.case == EQ
		.case == ZERO
			BNE \&{whileTmpLabel}
			.break
		.case == Z_CLR
		.case == NEQ
		.case == NOT_ZERO
			BEQ \&{whileTmpLabel}
			.break
		.case == N_SET
		.case == NEG
		.case == MINUS
			BPL \&{whileTmpLabel}
			.break
		.case == N_CLR
		.case == POS
		.case == PLUS
			BMI \&{whileTmpLabel}
			.break
		.case == C_SET
		.case == GE
			BCC \&{whileTmpLabel}
			.break
		.case == C_CLR
		.case == LT
			BCS \&{whileTmpLabel}
			.break
		.case == V_SET
			BVC \&{whileTmpLabel}
			.break
		.case == V_CLR
			BVS \&{whileTmpLabel}       ; Lay down the appropriate op code,
			.break
	.endsw
.endm
;----------------


.macro WHILE_BIT MEM_ADR, BIT_NR, CONDX  ; Syn: WHILE_BIT VIA3PA, 4, IS_LOW
	.switch \%{BIT_NR}                   ; Tests a bit in a memory location. Accum is changed if you specify a bit other than 6 or 7.
		.case < 0
		.case > 7
			\!{WHILE_BIT.outOfBounds, \%{MEM_ADR}, \%{BIT_NR}, \%{CONDX}}
			.break                       ; bounds check for the LOLZ
		.case == 6
		.case == 7 ; We can branch on V or N for 6 & 7.
			BIT \%{MEM_ADR}
			.if \%{BIT_NR} == 7          ; For bit 7, branch on N.
				.if \%{CONDX} == IS_HIGH
					BPL \&{whileTmpLabel}
				.else
					BMI \&{whileTmpLabel}
				.endif
			.else                        ; By process of elimination, the only bit left here is 6, so branch on V.
				.if \%{CONDX} == IS_HIGH
					BVC \&{whileTmpLabel}
				.else
					BVS \&{whileTmpLabel}
				.endif
			.endif
			.break
		.default                         ; BIT_NR == 0..5
			LDA #(1 << \%{BIT_NR})       ; Accum gets changed if you specify a bit other than 6 or 7.
			BIT \%{MEM_ADR}
			.if \%{CONDX} == IS_HIGH     ; The 2nd function of BIT is to AND the accum with the mem and set Z if the
				BEQ \&{whileTmpLabel}    ; result is 0, otherwise clear it.  Specifying IS_SET means you do the
			.else                        ; following code if the bit is set.  A set bit results in Z flag clear.
				BNE \&{whileTmpLabel}
			.endif                       ; If you have the BBS & BBR instructions, then instead of always using BIT and Bxx,
			.break                       ; you could also have the macro watch for the adr being in ZP and have it use BBR/BBS in
	.endsw                               ; that case, for efficiency.  That's mostly for if you have I/O in ZP though, which is
                                         ; very rare outside of microcontrollers like the Rockwell 65c19.
.endm
;--------------------------


.macro UNTIL COND ; The UNTIL macros are for use with BEGIN but not WHILE.
	.switch \%{COND} ; Continue loop until condition is met
		.case == Z_SET
		.case == EQ
		.case == ZERO
			BNE \^{pop, beginLabel} ; Branch up to the top of the loop to the addr kept in the top structure-macro stack level.
			.break                  ; We're also done with that stack cell, so drop it.
		.case == Z_CLR
		.case == NEQ
		.case == NOT_ZERO
			BEQ \^{pop, beginLabel}
			.break
		.case == N_SET
		.case == NEG
		.case == MINUS
			BPL \^{pop, beginLabel}
			.break
		.case == N_CLR
		.case == POS
		.case == PLUS
			BMI \^{pop, beginLabel}
			.break
		.case == C_SET
		.case == GE
			BCC \^{pop, beginLabel}
			.break
		.case == C_CLR
		.case == LT
			BCS \^{pop, beginLabel}
			.break
		.case == V_SET
			BVC \^{pop, beginLabel}
			.break
		.case == V_CLR
			BVS \^{pop, beginLabel}
			.break
	.endsw
.let whileTmpLabel = \^{pop, whileLabel} ; WHILE label isn't used by UNTIL, but it still has to be popped from the stack
.endm
;----------------


.macro UNTIL_BIT MEM_ADR, BIT_NR, CONDX ; Syn: UNTIL_BIT VIA3PA, 4, IS_LOW
	.switch \%{BIT_NR} ; Tests a bit in a memory location.  Accum is changed if you specify a bit other than 6 or 7.
		.case < 0
		.case > 7
			\!{UNTIL_BIT.outOfBounds, \%{MEM_ADR}, \%{BIT_NR}, \%{CONDX}}
			.break                       ; bounds check for the LOLZ
		.case == 6
		.case == 7 ; We can branch on V or N for 6 & 7.
			BIT \%{MEM_ADR}
			.if \%{BIT_NR} == 7          ; For bit 7, branch on N.
				.if \%{CONDX} == IS_HIGH
					BPL \^{pop, beginLabel}
				.else
					BMI \^{pop, beginLabel}
				.endif
			.else                        ; By process of elimination, the only bit left here is 6, so branch on V.
				.if \%{CONDX} == IS_HIGH
					BVC \^{pop, beginLabel}
				.else
					BVS \^{pop, beginLabel}
				.endif
			.endif
			.break
		.default                         ; BIT_NR == 0..5
			LDA #(1 << \%{BIT_NR})       ; Accum gets changed if you specify a bit other than 6 or 7.
			BIT \%{MEM_ADR}
			.if \%{CONDX} == IS_HIGH     ; The 2nd function of BIT is to AND the accum with the mem and set Z if the
				BEQ \^{pop, beginLabel}  ; result is 0, otherwise clear it.  Specifying IS_SET means you do the
			.else                        ; following code if the bit is set.  A set bit results in Z flag clear.
				BNE \^{pop, beginLabel}
			.endif                       ; If you have the BBS & BBR instructions, then instead of always using BIT and Bxx,
			.break                       ; you could also have the macro watch for the adr being in ZP and have it use BBR/BBS in
	.endsw                               ; that case, for efficiency.  That's mostly for if you have I/O in ZP though, which is
                                         ; very rare outside of microcontrollers like the Rockwell 65c19.
.let whileTmpLabel = \^{pop, whileLabel} ; WHILE label isn't used by UNTIL, but it still has to be popped from the stack
.endm
;--------------------------





;                        +-----------------------+
;                        | SWITCH-CASE statement |
;                        +=======================+

; For this version using JMPs at the BREAKs, the only places that branch distances might be excessive is the BNEs in CASE,
; and it's pretty unlikely that those would be a problem.

\^{createStack, switchReg} ; ACCUM, X_REG, or Y_REG. This gets recorded by SWITCH, getting the macro parameter value.
\^{createStack, switchCaseEndLabel} ; This gets used by CASE and BREAK(_) to temporarily store a label to bra to
\^{createStack, switchEndLabel} ; this if used by BREAK to jmp to ENDSW

.macro SWITCH reg ; reg is ACCUM, X_REG, or Y_REG
\^{push, switchReg, \%{reg}} ; so the CASE's will know whether to use CMP, CPX, or CPY.
\^{push, switchEndLabel, caseEnd_\${*}} ; make a unique label for BREAK to jump to ENDSW
.endm                   ; Note that the SWITCH macro does not add even a single byte of machine code.
;-----------------


.macro CASE Nr_to_comp_to          ; Note that as written here, the same register (A, X, or Y) must have
	.switch \^{peek, switchReg}    ; the right number every time CASE is encountered.  This is normally
		.case == ACCUM             ; not a problem if no action is taken until a case match if found;
			cmp #\%{Nr_to_comp_to} ; but if you have any reason to put code between a BREAK and the
			.break                 ; following CASE, make sure the right number is in the chosen
		.case == X_REG             ; register (A, X, or Y) when the next CASE is encountered.
			cpx #\%{Nr_to_comp_to}
			.break
		.case == Y_REG
			cpy #\%{Nr_to_comp_to}
			.break
	.endsw
.let caseTmpLabel = caseEndOf_\${*}         ; BREAK uses this to fill in the branch address.
    bne \&{caseTmpLabel}                       ; The BNE is used to branch only to the end of the individual case.
\^{push, switchCaseEndLabel, \&{caseTmpLabel}} ; Push the unique label for when BREAK is laid down
.endm
;----------------


.macro BREAK
	jmp \^{peek, switchEndLabel} ; First assemble the jump to the ENDSW for if the condition was met.
\^{pop, switchCaseEndLabel}:       ; Then pull and lay down bra target for preceeding CASE
.endm ; (CASEs use relative branching to the BREAK, whereas BREAK will use JMP.
;----------------


.macro BREAK_                ; This one (with the trailing "_") omits the JMP, for when it is either immediately
\^{pop, switchCaseEndLabel}: ; preceded by an unconditional RTS, JMP, or branch, or where the next line is ENDSW.
.endm                        ; Still need to pull and lay down bra target for preceeding CASE
;----------------


.macro ENDSW
\^{pop, switchEndLabel}: ; ENDSW does not compile anything new; it only lays down the label that BREAKs jump to.
\#{drop, switchReg} ; as well as drop the temp switchReg off of the stack
.endm
;----------------------------





;                       +--------------------+
;                       |     FOR...NEXT     |
;                       +====================+


; As stated in the macros.html page, there are many different combinations to implement in a FOR...NEXT,
; and it's perhaps not possible to do them all in the same macros.  FOR...NEXT below is a suggestion of
; one way to do a loop needing more than 255 iterations.  This first FOR...NEXT pair is for when the
; index begins and ends with constants, and it increments by 1 unless you put something between the FOR
; and NEXT to modify the index variable.  FOR_X...NEXT_X and FOR_Y...NEXT_Y further down replace many of
; the more-common loops where X or Y is used as the counter, being 8-bit for 6502.


; For FOR...NEXT (where the counter is 16-bit):

; example usage:
;
;      FOR  var1, 1, TO, 1000 ; For this, the loop does run 1000 times, dropping out when NEXT
;         <actions>           ; increments the counter to 1001.  Not so for FOR_X etc. further down.
;         <actions> 
;      NEXT  var1

\^{createStack, forNextControl} ; stack to hold limit and bra address for FOR and NEXT

.macro FOR var_name, index, dummy, limit      ; This is a dummy arg to make the FOR macro call more English-like.
	LDA   #<\%{index}                         ; Store the starting counter value
	STA   \%{var_name}                        ; in the specified 2-byte variable.
	LDA   #>\%{index}
	STA   \%{var_name}+1
\#{label, tmpMacroLabel, forNextLabel_\${*}}: ; (Addr of top of loop for NEXT to branch back up to.)
\^{push, forNextControl, \%{limit}}           ; (This is used by NEXT.)
\^{push, forNextControl, \&{tmpMacroLabel}}
\^{push, forNextControl, \%{var_name}}
.endm
;----------------


.macro NEXT var_name
.let tmpNextVar = \^{pop, forNextControl}
.if \%{var_name} != null
	.if \%{var_name} != \&{tmpNextVar}
		\!{"Mismatched vars! \%{var_name} != \&{tmpNextVar}"}
	.endif
.endif
	INC   \&{tmpNextVar}
.let tmpMacroLabel = nextBne_\${*}
	BNE   \&{tmpMacroLabel}
	INC   \&{tmpNextVar} + 1
\&{tmpMacroLabel}:
	LDA  \&{tmpNextVar}
	CMP  #<\^{NOS, forNextControl} + 1  ; If the incremented variable is not 1 past the limit,
	BNE  \^{TOS, forNextControl}        ; then branch to the top of the loop again.
	LDA  \&{tmpNextVar} + 1
	CMP  #>\^{NOS, forNextControl} + 1
	BNE  \^{pop, forNextControl}        ; Watch the branch distance.
	\#{drop, forNextControl}
                                        ; If, after being incremented, the specified variable
.endm                                   ; matches the limit +1 (checking both bytes), drop through.
;----------------------------





;                        +--------------------+
;                        | FOR_X/Y...NEXT_X/Y |
;                        +====================+


; Some amount of the following comments may be incorrect due to differences in the ported code...

; FOR_X...NEXT_X and FOR_Y...NEXT_Y below cover most of the senarios you could want for looping with X or Y as the counter, just
; as efficiently as you would do without the macros.
;
; Initial index values for either X or Y can be:
;      pre-existing accumulator contents (specifying "ACCUM")
;      pre-existing X-register contents  (specifying "X_REG")
;      pre-existing Y-register contents  (specifying "Y_REG")
;      a specified constant between 0 and $FF inclusive.
;
; You can:
;      count down one at a time (by specifying "DOWN_TO")
;      count  up  one at a time (by specifying "UP_TO"  )
; If you want two at a time, you would have to precede the NEXT_X or NEXT_Y with an extra INX/INY/DEX/DEY.  For other numbers,
; you can of course alter X or Y in the loop.
;
; The limit can be:
;      a specified constant between 0 and $FF inclusive
;      the contents of a non-ZP variable above $102 (since $101 and $102 are the numerical representation for NEG_NRs and POS_NRs)
;      or you can specify that it loop until the index becomes negative or positive (watching bit 7) by specifying:
;              UP_TO,   NEG_NRs
;              DOWN_TO, NEG_NRs
;              UP_TO,   POS_NRs
;              DOWN_TO, POS_NRs
;
; FOR_X...NEXT_X and FOR_Y...NEXT_Y below are nestable.  Their limitations are:
;    1. The counter must be 8-bit index reg X or Y, not a variable.  They can count up or down though, from/to any 8-bit value.
;    2. The initial index can be a constant, or it can be what's already in A, X, or Y.  The macro won't fetch it from a variable.
;        If it's a constant, it can of course be calculated by the assembler.
;    3. The limit can be any 8-bit constant, or it can be in a non-ZP variable above address $102.  The loop can alter the
;        variable.  If you use a constant, it can of course be computed by the assembler.
;    4. NEXT_X and NEXT_Y do the comparison of the index to the limit _after_ the increment or decrement, and drop through if
;        there's a match; so the loop will not be run with the final "to" value.  IOW,  "FOR  COUNT, 8, DOWN_TO, 0" will run 8
;        times, not 9:   8, 7, 6, 5, 4, 3, 2, and 1, but not 0.  If you want 9, do "9, DOWN_TO, 0" or "8, DOWN_TO, NEG_NRs".
;    5. The loop must be short enough that a relative branch at the end will reach the top.  It is rare that loops are too long.
;
; The NEXT_X and NEXT_Y macros are 44 lines long and yet might assemble only two instructions, like DEX, BNE.
;
; LEAVE_LOOP could be implemented, but the complexity is probably not justified considering the rare need.  I'm leaving it out for
; now, and if there's a need, it can be handled in more-conventional ways, like a branch instruction to a label after the loop.
; Otherwise, what you could do is use an additional stack level, and have FOR_X or FOR_Y initialize it as 0.  Then if there's a
; LEAVE_LOOP, it would store the address of its branch instruction in that stack cell, and NEXT_X or NEXT_Y would test it to see
; if that cell is non-0 and fill it in with a branch to the end if so.  You would have to be careful not to put the LEAVE_LOOP
; inside another structure that might be using the macro structure stack.  Also, allowing more than one LEAVE_LOOP would
; complicate things furter.  And as always, "compiler" security is up the to programmer.

; The number of clock cycles taken for a loop which loads its own index (call it "N") into X or Y and decrements it to 0 is:
;
;    2                    for loading X or Y immediate  (Omit this if you're starting with what was already there.)
;  + N * loop_contents    your code in the loop, plus the 2 clocks for DEX or DEY, meaning an empty loop still has N * 2.
;  + (N-1) * 3            for BNE top_of_loop.  The 3 turns to 4 if the loop straddles a page boundary.  (Usually it doesn't.)
;  + 2                    for final BNE that does not branch.
;
; So for:
;     FOR_X  8, DOWN_TO, 0
;     NEXT_X
; you have 2 + 16 + 21 + 2 = 41 clocks.  (The PIC16 takes 100 to do the same thing.)
;
;
; More syntax examples:
;
; FOR_X   ACCUM, DOWN_TO, 0            ; FOR_X will assemble TAX, and the loop will be done as many times as the accumulator's
; NEXT_X                               ; initial contents say.  The NEXT_X will assemble DEX, BNE.
;
; FOR_X   X_REG, DOWN_TO, NEG_NRs      ; Will start with whatever is already in X, and decrement until it sees you're below 0.
; NEXT_X                               ; The NEXT_X will assemble DEX, BPL.  If you add an DEX in the loop, the end result could
;                                      ; be either $FF or $FE, and this works without CPX.
;
; FOR_X   0, UP_TO, $40                ; Will do 40 iterations from 0 to $3F.  For will assemble LDX #0.
; NEXT_X                               ; NEXT_X will assemble INX, CPX #$40, BNE.
;
; FOR_X   Y_REG, UP_TO, FOOBAR         ; FOR_X will assemble PHY, PLX, leaving A undisturbed.  Loop until X matches contents of
; NEXT_X                               ; non-ZP variable FOOBAR.  NEXT_X will assemble INX, CMP FOOBAR, BNE.  Note that the
;                                      ; contents of the loop could even modify the contents of the variable between comparisons.
;
; FOR_X   $F0, DOWN_TO, POS_NRs        ; FOR_X will assemble LDX #F0.  Loop until X's high bit is clear.
; NEXT_X                               ; NEXT_X will assemble DEX, BMI.
;
; FOR_Y   15, DOWN_TO, $FF             ; FOR_Y will assemble LDY #15.
; NEXT_Y                               ; NEXT_Y will assemble DEY, BPL.  (If you put "DOWN_TO, $FE" though, it will add the CPX #.


\^{createStack, forXYcontrol} ; stack to hold [index, dir, and limit] for FOR_X/Y and NEXT_X/Y macros


.macro FOR_X index, dir, limit            ; Syn: FOR_X 8, DOWN_TO, 0
	.switch \%{index}                     ; Example runs 8 times: 8, 7, 6, 5, 4, 3, 2, and 1,
		.case == ACCUM                    ; but drops thru when the DEX at the end takes X to 0.
			TAX                           ; Syn: FOR_X ACCUM, UP_TO, $7F ; This syntax example will lay down a TAX to start.
			.break
		.case == Y_REG
			PHY                           ; NOTE: TYA TAX would be faster but would alter the accumulator. (65816 has TYX which would be even faster)
			PLX                           ; It is not expected that this "Y_REG" option would be used often though.
			.break
		.case != X_REG                    ; This one is for literals as in the first syntax example above (8 down to 0).
			LDX #\%{index}
			.break                        ; The only possibility left is that you want to start with the value already in X, so we
	.endsw                                ; don't need an .case to tell it to do nothing.
\#{label, forXYTmpLabel, forXLabel_\${*}}:
\^{push, forXYcontrol, \&{forXYTmpLabel}} ; Record addr of the top of the loop for NEXT to branch up to.
\^{push, forXYcontrol, \%{limit}}         ; Record what ending number NEXT should be watching for.  When the INX or DEX takes X to
                                          ; that final target, the branch to the top of the loop will not be taken which is why the
                                          ; example above of 8 down to 0 runs the loop only 8 times, not 9.
                                          ; Note that there's nothing keeping you from modifying X during loop execution if you wish.
\^{push, forXYcontrol, \%{dir}}           ; Record whether NEXT_X should INX or DEX.
.endm
;----------------


.macro NEXT_X
	.if \^{pop, forXYcontrol} == DOWN_TO ; incoming stack contains [bottom] addr, limit, dir [top]
		dex ; If we're counting down, assemble DEX before anything else.
	.else
		inx ; otherwise we're counting up, so assemble INX before anything else.
	.endif
	.let tmpForXYlimit = \^{pop, forXYcontrol}
	.switch \&{tmpForXYlimit}
		.case == 0
			BNE \^{pop, forXYcontrol} ; Up/Down to 0 is pretty normal, using BNE.
			.break
		.case == 0xFF
		.case == -1
		.case == NEG_NRs
			BPL \^{pop, forXYcontrol} ; Going 'til index is negative is pretty normal too, using BPL.
			.break
		.case == POS_NRs
			BMI \^{pop, forXYcontrol} ; Likewise going 'til the index turns positive, using BMI.
			.break
		.default
			.if \&{tmpForXYlimit} >= 0x100
				CPX \&{tmpForXYlimit} ; Now if the limit is > 8-bit, do a CMP abs to the specified non-ZP RAM variable.
			.else
				CPX #\&{tmpForXYlimit} ; The only possibility left now is that you want to compare to an 8-bit constant, so use CPY #.
			.endif
			BNE \^{pop, forXYcontrol} ; Either of these will be followed by BNE.
		.break
	.endsw
.endm
;------------------


.macro FOR_Y index, dir, limit            ; Syn: FOR_Y 8, DOWN_TO, 0
	.switch \%{index}                     ; Example runs 8 times: 8, 7, 6, 5, 4, 3, 2, and 1,
		.case == ACCUM                    ; but drops thru when the DEY at the end takes Y to 0.
			TAY                           ; Syn: FOR_Y ACCUM, UP_TO, $7F ; This syntax example will lay down a TAY to start.
			.break
		.case == X_REG
			PHX                           ; NOTE:  TXA TAY would be faster but would alter the accumulator.
			PLY                           ; It is not expected that this "X_REG" option would be used often though.
			.break
		.case != Y_REG                    ; This one is for literals as in the first syntax example above (8 down to 0).
			LDY #\%{index}
			.break                        ; The only possibility left is that you want to start with the value already in Y, so we
	.endsw                                ; don't need an .case to tell it to do nothing.
\#{label, forXYTmpLabel, forYLabel_\${*}}:
\^{push, forXYcontrol, \&{forXYTmpLabel}} ; Record addr of the top of the loop for NEXT to branch up to.
\^{push, forXYcontrol, \%{limit}}         ; Record what ending number NEXT should be watching for.  When the INY or DEY takes Y to
                                          ; that final target, the branch to the top of the loop will not be taken which is why the
                                          ; example above of 8 down to 0 runs the loop only 8 times, not 9.
                                          ; Note that there's nothing keeping you from modifying Y during loop execution if you wish.
\^{push, forXYcontrol, \%{dir}}           ; Record whether NEXT_Y should INY or DEY.
.endm
;----------------


.macro NEXT_Y
	.if \^{pop, forXYcontrol} == DOWN_TO ; incoming stack contains [bottom] addr, limit, dir [top]
		dey ; If we're counting down, assemble DEY before anything else.
	.else
		iny ; otherwise we're counting up, so assemble INY before anything else.
	.endif
	.let tmpForXYlimit = \^{pop, forXYcontrol}
	.switch \&{tmpForXYlimit}
		.case == 0
			BNE \^{pop, forXYcontrol} ; Up/Down to 0 is pretty normal, using BNE.
			.break
		.case == 0xFF
		.case == -1
		.case == NEG_NRs
			BPL \^{pop, forXYcontrol} ; Going 'til index is negative is pretty normal too, using BPL.
			.break
		.case == POS_NRs
			BMI \^{pop, forXYcontrol} ; Likewise going 'til the index turns positive, using BMI.
			.break
		.default
			.if \&{tmpForXYlimit} >= 0x100
				CPY \&{tmpForXYlimit} ; Now if the limit is > 8-bit, do a CMP abs to the specified non-ZP RAM variable.
			.else
				CPY #\&{tmpForXYlimit} ; The only possibility left now is that you want to compare to an 8-bit constant, so use CPY #.
			.endif
			BNE \^{pop, forXYcontrol} ; Either of these will be followed by BNE.
		.break
	.endsw
.endm
;------------------





;                       +--------------------+
;                       |     Accessories    |
;                       +====================+

; It is common to want to exit a routine under certain conditions, without necessarily even finishing executing a program structure.
; Here are some macros I have found helpful.

; .let accTmpLabel = accTmpLabel_\${*} ; temporary label used by accessory macros

; using RTS_ because RTS is an assembly mnemonic...
.macro RTS_ COND ; Takes 1 more byte than conditionally branching to the nearest RTS already there.
.let accTmpLabel = accTmpLabel_\${*}
	.switch \%{COND} ; Timing is the same, whether 3 bytes & 8 clocks for the macro or 2 bytes & 8 without the macro.
		.case == Z_SET
		.case == EQ
		.case == ZERO
			BNE \&{accTmpLabel} ; cond was not met, so BRA past the RTS
			.break
		.case == Z_CLR
		.case == NEQ
		.case == NOT_ZERO
			BEQ \&{accTmpLabel}
			.break
		.case == N_SET
		.case == NEG
		.case == MINUS
			BPL \&{accTmpLabel}
			.break
		.case == N_CLR
		.case == POS
		.case == PLUS
			BMI \&{accTmpLabel}
			.break
		.case == C_SET
		.case == GE
			BCC \&{accTmpLabel}
			.break
		.case == C_CLR
		.case == LT
			BCS \&{accTmpLabel}
			.break
		.case == V_SET
			BVC \&{accTmpLabel}
			.break
		.case == V_CLR
			BVS \&{accTmpLabel}
			.break
	.endsw
	RTS ; cond was met, so RTS
\&{accTmpLabel}: ; label to BRA to if cond is not met
.endm
;----------------


.macro RTS_IF_BIT MEM_ADR, BIT_NR, CONDX ; Syn: RTS_IF_BIT VIA3PB, 4, IS_LOW
.let accTmpLabel = accTmpLabel_\${*}
	.switch \%{BIT_NR}                   ; RTS based on the value of the specified bit in specified memory location.
		.case < 0
		.case > 7
			\!{RTS_IF_BIT.outOfBounds, \%{MEM_ADR}, \%{BIT_NR}, \%{CONDX}}
			.break                       ; bounds check for the LOLZ
		.case == 6
		.case == 7
			BIT \%{MEM_ADR}
			.if \%{BIT_NR} == 7          ; For bit 7, branch on N.
				.if \%{CONDX} == IS_HIGH
					BPL \&{accTmpLabel}
				.else
					BMI \&{accTmpLabel}
				.endif
			.else                        ; By process of elimination, the only bit left here is 6, so branch on V.
				.if \%{CONDX} == IS_HIGH
					BVC \&{accTmpLabel}
				.else
					BVS \&{accTmpLabel}  ; RTS_IF_BIT IS VERY CONFUSING, SO TEST THOROUGHLY! * * * * *
				.endif
			.endif
			.break
		.default                         ; BIT_NR == 0..5
			LDA #(1 << \%{BIT_NR})       ; Accum gets changed if you specify a bit other than 6 or 7.
			BIT \%{MEM_ADR}
			.if \%{CONDX} == IS_HIGH     ; The 2nd function of BIT is to AND the accum with the mem and set Z if the
				BEQ \&{accTmpLabel}      ; result is 0, otherwise clear it.  Specifying IS_SET means you do the
			.else                        ; following code if the bit is set.  A set bit results in Z flag clear.
				BNE \&{accTmpLabel}
			.endif                       ; If you have the BBS & BBR instructions, then instead of always using BIT and Bxx,
			.break                       ; you could also have the macro watch for the adr being in ZP and have it use BBR/BBS in
	.endsw                               ; that case, for efficiency.  That's mostly for if you have I/O in ZP though, which is
	RTS	                                 ; very rare outside of microcontrollers like the Rockwell 65c19.
\&{accTmpLabel}:
.endm
;------------------




.macro swapNibble ; 0x12 -> 0x21 -- modifies only A & flags
	ASL A
	ADC #0x80
	ROL A
	ASL A
	ADC #0x80
	ROL A
.endm

.macro DELAY ; 9*(256*A+Y)+8 -- leaves 0xFF in A & Y
	BEGIN
		CPY #1 ; clears carry if Y is 0
		DEY ; underflows Y to 0xFF if 0
		SBC #0 ; if carry is clear, this will subtract 1 from A
	UNTIL C_CLR ; carry will be cleared if A was 0 at the SBC
.endm

.macro COPY var1, prep, var2 ; COPY var1, to, var2
	LDA \%{var1}
	STA \%{var2}
.endm

.macro COPY2 var1, prep, var2 ; COPY2 var1, to, var2
	LDA \%{var1}
	STA \%{var2}
	LDA \%{var1}+1
	STA \%{var2}+1
.endm

.macro PUT2 var1, prep, var2, reg ; PUT2 0x1234, in, 0, using_Y
	.let tmp1 = \%{var1}
	.let tmp1 &= 0xFF ; get low byte of var1
	.let tmp2 = \%{var1}
	.let tmp2 /= 256 ; get high byte of var1
	.if \%{var1} == 0 ; 65(C)02 has STore Zero opcodes, but the NMOS version doesn't...
		STZ \%{var2}
		STZ \%{var2} + 1
	.elseif \&{tmp1} == \&{tmp2} ; check if low/high bytes of var1 are equal, and if so, skip a LD
		.switch \%{reg}
			.case == using_X
				LDX #\&{tmp1}
				STX \%{var2}
				STX \%{var2} + 1
				.break
			.case == using_Y
				LDY #\&{tmp1}
				STY \%{var2}
				STY \%{var2} + 1
				.break
			.default
				LDA #\&{tmp1}
				STA \%{var2}
				STA \%{var2} + 1
				.break
		.endsw
	.else
		.switch \%{reg}
			.case == using_X
				LDX #(\%{var1} & 0xFF) ; I use %var1 here to keep output more readable
				STX \%{var2}
				LDX #((\%{var1} >> 8) & 0xFF)
				STX \%{var2} + 1
				.break
			.case == using_Y
				LDY #(\%{var1} & 0xFF)
				STY \%{var2}
				LDY #((\%{var1} >> 8) & 0xFF)
				STY \%{var2} + 1
				.break
			.default
				LDA #(\%{var1} & 0xFF)
				STA \%{var2}
				LDA #((\%{var1} >> 8) & 0xFF)
				STA \%{var2} + 1
				.break
		.endsw
	.endif
.endm

.macro CLR_FLAG ; SYN: CLR_FLAG addr0, addr1, addr2, ... addrN
	.let index == 0
	LDA #0 ; only need to load once
	.begin
	.while \&{index} < \${argc} ; [.while .repeat] and [.until] are functionally equivalent...
		STA \#{arg, \&{index}} ; get each addr from arg list and lay down a STore A opcode
		.let index ++ ; next arg index
	.repeat
	;.until \&{index} == \${argc} ; [.while .repeat] and [.until] are functionally equivalent...
.endm