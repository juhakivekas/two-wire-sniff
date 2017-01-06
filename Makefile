MCU=attiny45
CCMCU=__ATtiny45__

CC=avr-gcc
CFLAGS=-O1 -Wall -mmcu=$(MCU) -D$(CCMCU)

SOURCE=USI_TWI_Sniffer.S

compile:two-wire-sniff.o

two-wire-sniff.o:$(SOURCE)
	$(CC) $(CFLAGS) -o $@ $^ 

hex:two-wire-sniff.hex
two-wire-sniff.hex:two-wire-sniff.o
	avr-objcopy -O ihex $^ $@

#this needs sudo/raw usb access
flash: hex
	avrdude -v -c usbtiny -p $(MCU) -U flash:w:two-wire-sniff.hex:i 

clean:
	rm -f two-wire-sniff.o two-wire-sniff.hex
