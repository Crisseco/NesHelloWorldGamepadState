

cc=../path/to/ca65
ldcc=../path/to/ld65
py_exec=python3

# make vars
bin=main.nes
objets=main.o
memory_file=memory.cfg

# debug vars
map=main.map.txt
labels=main.labels.txt
debug_bin=main.nes.dbg

#cible : dépendance 

main.nes: $(objets)
	$(ldcc) -o $(bin) -C $(memory_file) $(objets)

main.o: main.asm
	$(cc) main.asm -g -o main.o
	
debug: $(objets)
	$(ldcc) -o $(bin) -C $(memory_file) $(objets) -m $(map) -Ln $(labels) --dbgfile $(debug_bin)
	$(py_exec) gen_fceux_symbols.py 

clean:
	\rm -f *.o
	\rm -f $(bin)
	\rm -f *~
	\rm -f *.nl
	\rm -f *.dbg
	\rm -f *.labels.txt
	\rm -f *.map.txt
