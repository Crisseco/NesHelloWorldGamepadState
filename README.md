NesHelloWorldGamepadState
===

What you need
---
1. An emulator. I strongly suggest [fceux](http://www.fceux.com/web/download.html) since it has its own debugger
2. [cc65 compiler](https://www.cc65.org/index.php#Download)
3. [make utility](https://www.gnu.org/software/make/) (optional)

********************************************************************************
**Read first**
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
--------------------------------------------------
Compile
---
**Using Make**
Open the `makefile` and edit it the following variables: 
```bash
    ca65, (path/to/your/cc65/binary)
    ldcc  (path/to/your/ca65/binary)
```
**then, from the command line**
```bash
    # to simply produce the rom
    $ make
    
    # to produce the rom along with debugging symbols
    $ make debug
    
    # to clean the directory of all produced artefacts 
    $ make clean
```
--------------------------------------------
 **Manual compile**
Without debugging symbols:
```bash
$ cc65\bin\ca65 main.asm -g -o main.o
$ cc65\bin\ld65 -o main.nes -C memory.cfg main.o
```
 With debugging symbols:
 ```bash
    $ cc65\bin\ca65 main.asm -g -o main.o
    $ cc65\bin\ld65 -o main.nes -C memory.cfg main.o -m main.map.txt -Ln main.labels.txt --dbgfile main.nes.dbg
    $ py gen_fceux_symbols.py
 ```
Run
---
Open the generated *.nes file with fceux

Enjoy!
---


