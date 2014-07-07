CBBkernel: kernel64.asm
	date +"buildinfo db '%T-%m-%d-%y',13,0"  > build.asm
	nasm -f bin -o kernel64.sys kernel64.asm