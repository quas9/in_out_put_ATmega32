.INCLUDE "M32DEF.INC"
.def NULL = R15
.def TMP = R17
.def OP = R18
.def FLAG = R20
.def TEMP = R21
.def Y_1 = R22
.def Y_2 = R23
.def FULL = R24

.org $000
 JMP reset ; ��������� �� ������ ���������
.org INT0addr
 JMP int_1 ; ��������� �� ���������� ���������� int0
.org INT1addr
 JMP int_0 ; ��������� �� ���������� ���������� int1

reset:
	; ��������� �������� ��������
	 CLR NULL ; 0x00
	 SER FULL ; 0xFF 
	 CLR OP ; 0x00
	 CLR Y_1
	 CLR Y_2
	 LDI FLAG, 0x01
 
	; ��������� ������ �����-�������

	 OUT DDRA, FULL ; �����
	 OUT DDRB, FULL ; �����
	 OUT DDRC, NULL ; ����
	 LDI TMP, 0x73 
	 OUT DDRD, TMP ; 7,3,2 - ����

	; ��������� ������� ����� � ����� ���
	 LDI TMP, HIGH(RAMEND) ; ������� ������� ������
	 OUT SPH, TMP
	 LDI TMP, LOW(RAMEND) ; ������� ������� ������
	 OUT SPL, TMP
	 SER R16
	 LDI R16, 0x0F
	 OUT MCUCR, R16 ; ��������� ���������� int0 � int1 �� ������� 0/1
	 LDI R16, 0xC0
	 OUT GICR, R16 ; ���������� ���������� int0 � int1
	 OUT GIFR, R16 ; �������������� ������������ int0 � int1 ������������ ����������
 SEI ; ��������� ����������

read_eeprom:
	SBIC EECR,EEWE
	RJMP read_eeprom
	MOV R18,NULL
	LDI R17,0
	OUT EEARH,R18
	OUT EEARL,R17
	SBI EECR,EERE
	IN FLAG,EEDR 
	call read_eeprom_y
	jmp change

read_eeprom_y:
	SBIC EECR,EEWE
	RJMP read_eeprom_y
	MOV R18,NULL
	LDI R17,1
	OUT EEARH,R18
	OUT EEARL,R17
	SBI EECR,EERE
	IN Y_1,EEDR 
	RET

light_mode1:
	LDI TEMP, 0xFF
    OUT PORTA, TEMP
	out PORTB, NULL
	LDI TEMP, 0x11  ; ����� ������� 2
	out PORTD, TEMP
    call delay; �������� ����� ������ ���������
	call delay
	LDI TEMP, 0xFF
    OUT PORTA, TEMP
    out PORTA, NULL
	out PORTB, TEMP
	LDI TEMP, 0x01  ; ����� ������� 2
	out PORTD, TEMP
	call delay
	LDI TEMP, 0x01
	CP FLAG, TEMP
	jmp change

change:
    call write_eeprom
	ldi TMP, 0X01
	LDI TEMP, 0x01 ; ����� ������� 1
	CP FLAG, TMP    ; ����������, ����� �� 1 ������
    out PORTD, TEMP ; �������
    CP FLAG, TMP    ; ����������, ����� �� 1 ������
	BREQ light_mode1  

	ldi TMP, 0X02
	LDI TEMP, 0x02  ; ����� ������� 2
	CP FLAG, TMP    ; ����������, ����� �� 1 ������
    out PORTD, TEMP ; �������
    CP FLAG, TMP    ; ����������, ����� �� 2 ������
	BREQ light_mode2

	ldi TMP, 0X03
	LDI TEMP, 0x03  ; ����� ������� 3
	CP FLAG, TMP    ; ����������, ����� �� 1 ������
    out PORTD, TEMP ; �������
    CP FLAG, TMP    ; ����������, ����� �� 3 ������
	BREQ light_mode3
	LDI Y_1, 0xAA
	LDI FLAG, 0x01
	brne change
	jmp light_mode1
	
light_mode2:
	call delay; �������� ����� ������ ���������
	call delay; �������� ����� ������ ���������
	LDI TEMP, 0xAA
    OUT PORTA, TEMP
	LDI TEMP, 0x55
	out PORTB, TEMP
	LDI TEMP, 0x12  ; ����� ������� 2
	out PORTD, TEMP

    call delay; �������� ����� ������ ���������
	call delay
		LDI TEMP, 0xAA
    OUT PORTB, TEMP
	LDI TEMP, 0x55
	out PORTA, TEMP
	LDI TEMP, 0x02  ; ����� ������� 2
	out PORTD, TEMP
	LDI TEMP, 0x02
	CP FLAG, TEMP
	brne change
	jmp light_mode2

change_1:
	jmp change


light_mode3: ; ���������� ��������
	CALL delay      ; �������� ������� ���������� ������
	IN TEMP, PIND   ; ��������� �������� �� PORTD
	ldi TMP, 0X83
    CP TEMP, TMP
	BREQ stop_pd7 ; ���������� ��������

	out PORTA, Y_1  ; ����� �������� Y_1 � Y_2 � PORT A � B
	out PORTB, Y_2  ; ����� �������� -y �� ���� PORTB
	LDI TEMP, 0x13  ; ����� ������� 2
	out PORTD, TEMP
	CALL delay
	CALL delay
	out PORTA, NULL ; ��������� PORT A � B
	out PORTB, NULL
	LDI TEMP, 0x03
	; ����� ������� 2
	out PORTD, TEMP
	call write_eeprom
	LDI TEMP, 0x03
	CP FLAG, TEMP
	brne change_1
	jmp light_mode3

stop_pd7:
	CALL delay      ; �������� ������� ���������� ������
	IN TEMP, PIND   ; ��������� �������� �� PORTC
	ldi TMP, 0X83
    CP TEMP, TMP
	BRNE light_mode3
	IN TEMP, PINC   ; ��������� �������� �� PORTC
	CPSE TEMP, NULL ; ����������, ���� ����� 0(�.� ������ �� ������� - ������ �� ����������)
	mov Y_1 , TEMP  ; ���� �� ����� ���� - ���������� ��� Y
	mov Y_2,  TEMP
	
    OUT DDRB, FULL

    COM Y_1
    MOV Y_2, Y_1

    OUT PORTB, Y_1

	rjmp stop_pd7

int_0:
	in R28, SREG
	push R28
	dec FLAG
	CPI FLAG, 0
	BREQ intr_int0
	pop R28
	out SREG, R28
	RETI

intr_int0:
	LDI FLAG, 3
	pop R28
	out SREG, R28
	RETI

int_1:
	in R28, SREG
	push R28
	inc FLAG
	CPI FLAG, 4
	BREQ int_1
	pop R28
	out SREG, R28
	RETI

intr_int1:
	LDI FLAG, 1
	pop R28
	out SREG, R28
	RETI

write_eeprom:
	SBIC EECR,EEWE
	RJMP write_eeprom
	LDI R18,0
	LDI R17,0
	OUT EEARH,R18
	OUT EEARL,R17
	OUT EEDR,FLAG
	SBI EECR,EEMWE
	SBI EECR,EEWE
	call write_eeprom_y
	RET

write_eeprom_y:
	SBIC EECR,EEWE
	RJMP write_eeprom_y
	LDI R18,0
	LDI R17,1
	OUT EEARH,R18
    OUT EEARL,R17
	OUT EEDR,Y_1
	SBI EECR,EEMWE
	SBI EECR,EEWE
	RET

delay: ; 
	LDI R31, 5
	LDI R30, 223
	LDI R29, 188
delay_sub:
	DEC R29
	BRNE delay_sub
	DEC R30
	BRNE delay_sub
	DEC R31
	BRNE delay_sub
	NOP
	NOP
	RET
