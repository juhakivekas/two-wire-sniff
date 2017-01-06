two wire sniff
==============

This is a  minimal AyTiny AVR firmware that  will listen to a TWI  (I2C) bus and
store all data on EEPROM. It's simple, but will probably require some getting to
know before  any modifications can  be done. I'm sorry  for the assembly,  but I
really needed fine control over execution and timing.

[hackaday.io project](https://hackaday.io/project/18461-two-wire-sniff)

###Motivation

While taking a closer look at a  hardware password manager from a friend, It was
noted that sometimes  critical data is going on physical  busses of devices. The
design in  question would gladly  read an  encryption key from  protected memory
over TWI without encrypting it in transit. By implanting the device with a small
microcontroller, the keys to decrypt the password store can be obtained.

Essentially this implant will listen to a TWI bus and store any captured data on
the EEPROM of the chip, from which it  can later be read. An attacker would need
to  implant  the chip,  have  the  owner do  the  operation  that will  generate
the  wanted  traffic,  and  finally  retrieve  the  device  for  collection  and
post-processing of the data.

