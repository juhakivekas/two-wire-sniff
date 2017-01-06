#include <avr/io.h> 

/* hardware defines */
#define DDR_USI              DDRB
#define PORT_USI             PORTB
#define PIN_USI              PINB
#define PORT_USI_SDA         PORTB0
#define PORT_USI_SCL         PORTB2
#define PORT_DEBUG_1         PORTB1
#define PORT_DEBUG_2         PORTB3
#define PIN_USI_SDA          PINB0
#define PIN_USI_SCL          PINB2
#define PIN_DEBUG_1          PINB1
#define PIN_DEBUG_2          PINB3

/* logic defines */
#define WAIT_START   0
#define READ_ADDRESS 1
#define READ_DATA    2
#define READ_ACK     3

;this fixes a compilation error
#undef __SFR_OFFSET
#define __SFR_OFFSET 0x00 

__SP_H__ = 0x3e
__SP_L__ = 0x3d
__SREG__ = 0x3f
__tmp_reg__ = 0
__zero_reg__ = 1
.text

.global main
.type   main, @function
main:
	clr __zero_reg__
    sts EEPROM_Bytes_Written,__zero_reg__
    rcall TWI_Sniffer_Initialise
    sei 
.EEPROM_loop:
	/* poll for more data in the buffer */
    lds r25,EEPROM_Bytes_Written
    lds r24,TWI_Sniffer_Buffer_Len
    cp r24,r25
    brge .EEPROM_loop 
	/* there's a new byte, so do a thing*/
	cbi PORTB, PORT_DEBUG_1
    lds r24,EEPROM_Bytes_Written
	inc r24
    sts EEPROM_Bytes_Written,r24
	sbi PORTB, PORT_DEBUG_1
    rjmp .EEPROM_loop 
	ret

.global	SET_USI_WAIT_START
.type	SET_USI_WAIT_START, @function
SET_USI_WAIT_START:
	ldi r24, (1<<USISIE)|(0<<USIOIE)|\
             (1<<USIWM1)|(0<<USIWM0)|\
             (1<<USICS1)|(0<<USICS0)|(0<<USICLK)|\
             (0<<USITC)
	out USICR, r24 
	ldi r24, (1<<USISIF)|(1<<USIOIF)|(1<<USIPF)|(1<<USIDC)| \
             (0x0<<USICNT0)
	out USISR, r24
	ret

.global	SET_USI_READ_BYTE
.type	SET_USI_READ_BYTE, @function
SET_USI_READ_BYTE:
	ldi r24, (1<<USISIE)|(1<<USIOIE)|\
             (1<<USIWM1)|(1<<USIWM0)|\
             (1<<USICS1)|(0<<USICS0)|(0<<USICLK)|\
             (0<<USITC)
	out USICR,r24
	ldi r24, (1<<USISIF)|(1<<USIOIF)|(1<<USIPF)|(1<<USIDC)|\
             (0x0<<USICNT0)
	out USISR,r24
	ret

.global	SET_USI_READ_ACK
.type	SET_USI_READ_ACK, @function
SET_USI_READ_ACK:
	ldi r24, (1<<USISIE)|(1<<USIOIE)|\
             (1<<USIWM1)|(1<<USIWM0)|\
             (1<<USICS1)|(0<<USICS0)|(0<<USICLK)|\
             (0<<USITC)
	out USICR,r24
	ldi r24, (1<<USISIF)|(1<<USIOIF)|(1<<USIPF)|(1<<USIDC)|\
             (0xe<<USICNT0)
	out USISR,r24
	ret

.global	TWI_Sniffer_Initialise
.type	TWI_Sniffer_Initialise, @function
TWI_Sniffer_Initialise:
	/* enable debug pins */
	sbi DDRB, PORT_DEBUG_1
	sbi DDRB, PORT_DEBUG_2
	sbi PORTB, PORT_DEBUG_1
	sbi PORTB, PORT_DEBUG_2
	/* set TWI pin modes */
	cbi DDR_USI, PORT_USI_SCL
	cbi DDR_USI, PORT_USI_SDA
	cbi PORT_USI, PORT_USI_SCL
	cbi PORT_USI, PORT_USI_SDA
	/* initialize USI and sniffer globals */
	rcall SET_USI_WAIT_START
	sts TWI_Sniffer_State, __zero_reg__ ;WAIT_START
	sts TWI_Sniffer_Buffer_Len, __zero_reg__
	ret

.global	USI_START_vect
.type	USI_START_vect, @function
USI_START_vect:
	/* prologue: Signal */
	in r0,__SREG__
	push r0
	push r24
	/* clear the debug pin*/
	;cbi PORTB, PORT_DEBUG_1
	/* wait of the sloclk to go low */
.wait_SCL:
	sbic PIN_USI, PORT_USI_SCL
	rjmp .wait_SCL
	/* set up to receive a byte */
	rcall SET_USI_READ_BYTE
	ldi r24, READ_DATA
	sts TWI_Sniffer_State,r24
	/* set the debug pin */
	;sbi PORTB, PORT_DEBUG_1
	/* epilogue start */
	pop r24
	pop r0
	out __SREG__,r0
	reti

.global	USI_OVF_vect
.type	USI_OVF_vect, @function
USI_OVF_vect:
	/* prologue: Signal */
	in r0,__SREG__
	push r0
	clr __zero_reg__
	push r24
	push r25
	push r30
	push r31
	/* read USI data register */
	in r25,0xf
	/* switch based on state */
	lds r24,TWI_Sniffer_State
	cpi r24,lo8(READ_DATA)
	breq .case_READ_DATA
	cpi r24,lo8(READ_ACK)
	breq .case_READ_ACK
	rjmp .case_default
.case_READ_DATA:
	/* increment counter and write data to buffer */
	/* clear debug pin */
	cbi PORTB, PORT_DEBUG_2
	lds r30, TWI_Sniffer_Buffer_Len
	inc r30
	sts TWI_Sniffer_Buffer_Len, r30
	/* set debug pin */
	sbi PORTB, PORT_DEBUG_2
	ldi r31,0
	subi r30,lo8(-(TWI_Sniffer_Buffer))
	sbci r31,hi8(-(TWI_Sniffer_Buffer))
	st Z,r25

	/* set new state */
	rcall SET_USI_READ_ACK
	ldi r24,lo8(READ_ACK)
	sts TWI_Sniffer_State,r24
	rjmp .case_default
.case_READ_ACK:
	rcall SET_USI_READ_BYTE
	ldi r24,lo8(READ_DATA)
	sts TWI_Sniffer_State,r24
.case_default:
/* epilogue start */
	pop r31
	pop r30
	pop r25
	pop r24
	pop r0
	out __SREG__,r0
	reti

/* global variables */
	.global	EEPROM_Bytes_Written
    .comm   EEPROM_Bytes_Written,1,1
	.global	TWI_Sniffer_Buffer_Len
	.comm	TWI_Sniffer_Buffer_Len,1,1
	.global	TWI_Sniffer_Buffer
	.comm	TWI_Sniffer_Buffer,256,1
	.global	TWI_Sniffer_State
	.comm	TWI_Sniffer_State,1,1
.global __do_clear_bss
