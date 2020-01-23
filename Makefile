
output.gb: main.o
	wlalink -r linkfile output.gb

main.o: src/main.asm
	wla-gb -Iinclude -o main.o src/main.asm

run: output.gb
	open -a SameBoy output.gb

clean:
	rm *.o *.gb
