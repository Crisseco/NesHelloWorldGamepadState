NesHelloWorldGamepadState

What you need
. An emulator. I strongly suggest fceux since it has its own debugger
. cc65 compiler

********************************************************************************
Read first
********************************************************************************
I have built and learned a lot from reading this simple nes example, which this
rom is base upon:

https://github.com/bbbradsmith/NES-ca65-example

It is both simple and complete. I have reused some of their subroutines, such
as the nmi and ppu management. The python script to generate the debugging
symbols

This even simpler example displays and Hello World! alongside the current
gamepad state. I have also added the reset_count variable that will be
incremented every time the player hits the reset button.

********************************************************************************
Run
********************************************************************************
1- Compile
	Without debugging symbols:
		cc65\bin\ca65 main.asm -g -o main.o 
		cc65\bin\ld65 -o main.nes -C memory.cfg main.o
	With debugging symbols:	
		cc65\bin\ca65 main.asm -g -o main.o 
		cc65\bin\ld65 -o main.nes -C memory.cfg main.o -m main.map.txt -Ln main.labels.txt --dbgfile main.nes.dbg
		py gen_fceux_symbols.py

2- Open main.nes with fceux

3- Enjoy!
