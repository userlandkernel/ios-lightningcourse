; Compile with: clang -arch arm64 -isysroot /var/theos/sdks/iPhoneOS11.2.sdk kernel01.S -o kernel

.text
.align 4
.global _main

; Configuration
.equ STACK_SIZE, 512

; File descriptors
.equ STDIN, 0
.equ STDOUT, 1
.equ STDERR, 2

; System call numbers
.equ SYS_EXIT, 1
.equ SYS_FORK, 2

.equ SYS_READ, 3
.equ SYS_WRITE, 4

.equ SYS_OPEN, 5
.equ SYS_CLOSE, 6

.equ SYS_WAIT4, 7

.equ SYS_LINK, 9
.equ SYS_UNLINK, 10
.equ SYS_CHDIR, 12
.equ SYS_FCHDIR, 13
.equ SYS_MKNOD, 14
.equ SYS_CHMOD, 15
.equ SYS_CHOWN, 16

.equ SYS_KILL, 37
.equ SYS_EXECVE, 59


; TODO: Use stack for the arguments
syscall:

	MOV X16, X0 ; Store syscall number in X16

	MOV X0, X1 ; Arg 1
	MOV X1, X2 ; Arg 2
	MOV X2, X3 ; Arg 3
	MOV X3, X4 ; Arg 4
	MOV X4, X5 ; Arg 5
	MOV X5, X6 ; Arg 6
	MOV X6, X7 ; Arg 7

	SVC #0x80 ; Perform system call

	BR LR

stack_alloc:
	SUB SP, SP, #8
	STR LR, [SP] ; Backup LR

	MOV X1, X0

	SUB SP, SP, X1
	MOV X0, SP ; Save pointer to allocated stack
	ADD SP, SP, X1
	
	ADD SP, SP, #16 

	LDR LR, [SP] ; Restore LR
	BR LR


write:
	SUB SP, SP, #16
	STP LR, X0, [SP] ; Backup LR and X0 in stack
	
	MOV X7, X6
	MOV X6, X5
	MOV X5, X4
	MOV X4, X3
	MOV X3, X2
	MOV X2, X1
	MOV X1, X0
	MOV X0, SYS_WRITE
	BL syscall

	LDP LR, X0, [SP]
	ADD SP, SP, #16
	BR LR

read:
	SUB SP, SP, #16
	STP LR, X0, [SP] ; Backup LR and X0 in stack
	
	MOV X7, X6
	MOV X6, X5
	MOV X5, X4
	MOV X4, X3
	MOV X3, X2
	MOV X2, X1
	MOV X1, X0
	MOV X0, SYS_READ
	BL syscall

	LDR LR, [SP]
	ADD SP, SP, #16
	BR LR


strlen:
	SUB SP, SP, #16
	STP LR, X0, [SP] ; Backup LR and X0 in stack

	LDRB W3, [X0, X1]
	CBZ W3, strlen.finish
	ADD X1, X1, #1
	B strlen

strlen.finish:

	LDP LR, X0, [SP] ; Restore LR and X0
	ADD SP, SP, #16

	MOV X0, X1
	BR LR

gets:
	SUB SP, SP, #16
	STP LR, X0, [SP] ; Backup LR and X0 in stack

	
	MOV X0, STDIN

	SUB SP, SP, STACK_SIZE
	MOV X1, SP ; Stack memory for storing input
	ADD SP, SP, STACK_SIZE

	MOV X2, STACK_SIZE ; Maximum size to read
	BL read

	SUB SP, SP, STACK_SIZE
	MOV X1, SP ; Load pointer to string
	STRB WZR, [X1, X0] ; Remove newline
	ADD SP, SP, STACK_SIZE

	MOV X0, X1 ; Return pointer to string
	
	LDR LR, [SP] ; Restore LR
	ADD SP, SP, #16

	BR LR

putchar:
	SUB SP, SP, #16
	STP LR, X0, [SP] ; Backup LR and X0 in stack

	STRB W1, [X0]

puts:
	SUB SP, SP, #16
	STP LR, X0, [SP] ; Backup LR and X0 in stack

	MOV X1, XZR
	BL strlen

	MOV X2, X0 ; Store string length in X3
	MOV X0, STDOUT
	LDP LR, X1, [SP]

	BL write

	LDP LR, X0, [SP] ; Restore LR and X0
	ADD SP, SP, #16
	BR LR

exit:
	STR LR, [SP, #-8]!

	MOV X1, X0
	MOV X0, SYS_EXIT
	BL syscall

	LDR LR, [SP], #8

	BR LR

print_ps1:

	SUB SP, SP, #16
	STP LR, X0, [SP] ; Backup LR and X0 in stack

	ADRP X0, ps1@page
	ADD X0, X0, ps1@pageoff
	BL puts

	LDP LR, X0, [SP] ; Restore LR and X0
	ADD SP, SP, #16

	BR LR


print_newline:

	SUB SP, SP, #16
	STP LR, X0, [SP] ; Backup LR and X0 in stack

	ADRP X0, newline@page
	ADD X0, X0, newline@pageoff
	BL puts

	LDP LR, X0, [SP] ; Restore LR and X0
	ADD SP, SP, #16

	BR LR

print_input:

	SUB SP, SP, #16
	STP LR, X0, [SP] ; Backup LR and X0 in stack

	BL puts

	LDP LR, X0, [SP] ; Restore LR and X0
	ADD SP, SP, #16

	BR LR

print_banner:
	SUB SP, SP, #16
	STP LR, X0, [SP] ; Backup LR and X0 in stack

	ADRP X0, version@page
	ADD X0, X0, version@pageoff
	BL puts
	BL print_newline


	ADRP X0, copyright@page
	ADD X0, X0, copyright@pageoff
	BL puts
	BL print_newline
	BL print_newline

	LDP LR, X0, [SP] ; Restore LR and X0
	ADD SP, SP, #16

	BR LR

cmdhandler_help:
	SUB SP, SP, #16
	STP LR, X0, [SP] ; Backup LR and X0 in stack
	
	LDP LR, X0, [SP] ; Restore LR and X0
	ADD SP, SP, #16
	B shell

atoi:
	SUB SP, SP, #16
	STP LR, X0, [SP] ; Backup LR and X0 in stack
	SUB X0, X0, #30
	ADD SP, SP, #16
	BR LR

print_notfound:
	SUB SP, SP, #16
	STP LR, X0, [SP] ; Backup LR and X0 in stack

	ADRP X0, msg_unknown_cmd@page
	ADD X0, X0, msg_unknown_cmd@pageoff
	BL puts

	LDP LR, X0, [SP]
	BL puts

	BL print_newline

	LDP LR, X0, [SP]
	ADD SP, SP, #16
	BR LR

do_help:
	SUB SP, SP, #16
	STP LR, X0, [SP] ; Backup LR and X0 in stack

	LDP LR, X0, [SP] ; Restore LR and X0
	ADD SP, SP, #16
	B shell

parse_cmd:
	SUB SP, SP, #16
	STP LR, X0, [SP] ; Backup LR and X0 in stack

	ADRP X0, str.unimplemented@page
	ADD X0, X0, str.unimplemented@pageoff
	B panic

	LDP LR, X0, [SP] ; Restore LR and X0
	ADD SP, SP, #16
	BR LR

change_interpreter:
	ADRP X0, ps1@page
	ADD X0, X0, ps1@pageoff

	ADRP X1, ps2@page
	ADD X1, X1, ps1@pageoff
	
	MOV W1, #0x48
	STRB W1, [X0]

	MOV W1, #0x41
	STRB W1, [X0, #1]
	
	MOV W1, #0x43
	STRB W1, [X0, #2]

	MOV W1, #0x4B
	STRB W1, [X0, #3]

	MOV W1, #0x53
	STRB W1, [X0, #4]

	B shell

panic:
	SUB SP, SP, #16
	STP LR, X0, [SP] ; Backup LR and X0 in stack

	ADRP X0, str.panic@page
	ADD X0, X0, str.panic@pageoff
	BL puts

	LDP LR, X0, [SP]
	BL puts

	BL print_newline

	ADRP X0, CPFM@page
	ADD X0, X0, CPFM@pageoff
	
	LDRB W0, [X0] ; Load CPFM bit
	
	CMP W0, #3 ; Compare CPFM status, 0 = HACK, 1 = EVT, 2 = DVT, 3 = PVT
	BLT debugloop.enter ; if EVT or DVT CPFM we can enter a debugloop

	MOV X0, #1
	B exit

shell.reset:
	MOV X0, XZR
	MOV X1, XZR
	MOV X2, XZR
	MOV X3, XZR
	MOV X4, XZR
	MOV X5, XZR
	MOV X6, XZR
	MOV X7, XZR
	MOV LR, XZR
	B shell


shell:
	BL print_ps1
	BL gets
	BL parse_cmd
	B shell.reset

debugloop.enter:
	ADRP X0, str.enter_dbgloop@page
	ADD X0, X0, str.enter_dbgloop@pageoff
	BL puts
	B debugloop

debugloop:
	B debugloop

_main:
	BL print_banner
	BL shell
	BL exit
	RET

.section strings, "aS"
	version:
		.ascii "Userland kernel v1.0-alpha\0"

	author:
		.ascii "Sem Voigtländer\0"

	copyright:
		.ascii "© Copright 2020, Sem Voigtländer. All rights reserved.\0"

	newline:
		.ascii "\n\0"

	msg_unknown_cmd:
		.ascii "Command not found: \0"

	cmd_help:
		.ascii "help\0"

	cmd_echo:
		.ascii "echo\0"

	str.panic:
		.ascii "panic: \0"

	str.unimplemented:
		.ascii "Logic at this location has not been implemented yet.\0"

	str.enter_dbgloop:
		.ascii "Entering debug loop...\0"

.section variables, "aw"
	ps1:
		.ascii "ASM64> \0"

	ps2:
		.ascii "HACKS> \0"

	CPFM:
		.byte 2
