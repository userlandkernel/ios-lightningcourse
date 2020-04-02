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

		mov X16, X0 ; Store syscall number in X16

		mov X0, X1 ; Arg 1
		mov X1, X2 ; Arg 2
		mov X2, X3 ; Arg 3
		mov X3, X4 ; Arg 4
		mov X4, X5 ; Arg 5
		mov X5, X6 ; Arg 6
		mov X6, X7 ; Arg 7

		svc #0x80 ; Perform system call

		br lr

	stack_alloc:
		sub sp, sp, #8
		str lr, [sp] ; Backup lr

		mov X1, X0

		sub sp, sp, X1
		mov X0, sp ; Save pointer to allocated stack
		add sp, sp, X1

		add sp, sp, #16

		ldr lr, [sp] ; Restore lr
		br lr


	write:
		sub sp, sp, #16
		stp lr, X0, [sp] ; Backup lr and X0 in stack

		mov X7, X6
		mov X6, X5
		mov X5, X4
		mov X4, X3
		mov X3, X2
		mov X2, X1
		mov X1, X0
		mov X0, SYS_WRITE
		bl syscall

		ldp lr, X0, [sp]
		add sp, sp, #16
		br lr

	read:
		sub sp, sp, #16
		stp lr, X0, [sp] ; Backup lr and X0 in stack

		mov X7, X6
		mov X6, X5
		mov X5, X4
		mov X4, X3
		mov X3, X2
		mov X2, X1
		mov X1, X0
		mov X0, SYS_READ
		bl syscall

		ldr lr, [sp]
		add sp, sp, #16
		br lr


	strlen:
		sub sp, sp, #16
		stp lr, X0, [sp] ; Backup lr and X0 in stack

		LDRB W3, [X0, X1]
		cbz W3, strlen.finish
		add X1, X1, #1
		B strlen

	strlen.finish:

		ldp lr, X0, [sp] ; Restore lr and X0
		add sp, sp, #16

		mov X0, X1
		br lr

	gets:
		sub sp, sp, #16
		stp lr, X0, [sp] ; Backup lr and X0 in stack

		mov X0, STDIN

		sub sp, sp, STACK_SIZE
		mov X1, sp ; Stack memory for storing input
		add sp, sp, STACK_SIZE

		mov X2, STACK_SIZE ; Maximum size to read
		bl read

		sub sp, sp, STACK_SIZE
		mov X1, sp ; Load pointer to string
		STRB WZR, [X1, X0] ; Remove newline
		add sp, sp, STACK_SIZE

		mov X0, X1 ; Return pointer to string

		ldr lr, [sp] ; Restore lr
		add sp, sp, #16

		br lr

	putchar:
		sub sp, sp, #16
		stp lr, X0, [sp] ; Backup lr and X0 in stack

		STRB W1, [X0]

	puts:
		sub sp, sp, #16
		stp lr, X0, [sp] ; Backup lr and X0 in stack

		mov X1, XZR
		bl strlen

		mov X2, X0 ; Store string length in X3
		mov X0, STDOUT
		ldp lr, X1, [sp]

		bl write

		ldp lr, X0, [sp] ; Restore lr and X0
		add sp, sp, #16
		br lr

	exit:
		str lr, [SP, #-8]!

		mov X1, X0
		mov X0, SYS_EXIT
		bl syscall

		ldr lr, [sp], #8

		br lr

	print_ps:

		sub sp, sp, #16
		stp lr, X0, [sp] ; Backup lr and X0 in stack

		ADRP X0, var.promptstatement@page
		add X0, X0, var.promptstatement@pageoff
		LDR X0, [X0]
		bl puts

		ldp lr, X0, [sp] ; Restore lr and X0
		add sp, sp, #16

		br lr


	print_newline:

		sub sp, sp, #16
		stp lr, X0, [sp] ; Backup lr and X0 in stack

		ADRP X0, const.newline@page
		add X0, X0, const.newline@pageoff
		bl puts

		ldp lr, X0, [sp] ; Restore lr and X0
		add sp, sp, #16

		br lr

	print_input:

		sub sp, sp, #16
		stp lr, X0, [sp] ; Backup lr and X0 in stack

		bl puts

		ldp lr, X0, [sp] ; Restore lr and X0
		add sp, sp, #16

		br lr

	print_banner:
		sub sp, sp, #16
		stp lr, X0, [sp] ; Backup lr and X0 in stack

		ADRP X0, const.version@page
		add X0, X0, const.version@pageoff
		bl puts
		bl print_newline


		ADRP X0, const.legal@page
		add X0, X0, const.legal@pageoff
		bl puts
		bl print_newline
		bl print_newline

		ldp lr, X0, [sp] ; Restore lr and X0
		add sp, sp, #16

		br lr

	cmdhandler_help:
		sub sp, sp, #16
		stp lr, X0, [sp] ; Backup lr and X0 in stack

		ldp lr, X0, [sp] ; Restore lr and X0
		add sp, sp, #16
		B shell

	atoi:
		sub sp, sp, #16
		stp lr, X0, [sp] ; Backup lr and X0 in stack
		sub X0, X0, #30
		add sp, sp, #16
		br lr

	print_notfound:
		sub sp, sp, #16
		stp lr, X0, [sp] ; Backup lr and X0 in stack

		ADRP X0, str.cmd_notfound@page
		add X0, X0, str.cmd_notfound@pageoff
		bl puts

		ldp lr, X0, [sp]
		bl puts

		bl print_newline

		ldp lr, X0, [sp]
		add sp, sp, #16
		br lr

	do_help:
		sub sp, sp, #16
		stp lr, X0, [sp] ; Backup lr and X0 in stack

		ldp lr, X0, [sp] ; Restore lr and X0
		add sp, sp, #16
		B shell

	parse_cmd:
		sub sp, sp, #16
		stp lr, X0, [sp] ; Backup lr and X0 in stack
		bl print_notfound

		ldp lr, x0, [sp]
		add sp, sp, #16
		br lr

	change_interpreter:

		MOV X0, #6 ; hacks + nullterminator

		bl stack_alloc

		mov W1, #0x48 ; 'h'
		STRB W1, [X0] ;

		mov W1, #0x41 ; 'a'
		STRB W1, [X0, #1] ;

		mov W1, #0x43 ; 'c'
		STRB W1, [X0, #2] ;

		mov W1, #0x4B ; 'k'
		STRB W1, [X0, #3]

		mov W1, #0x53 ; 's'
		STRB W1, [X0, #4]

		ADRP X1, var.promptstatement@page
		ADD X1, X1, var.promptstatement@pageoff

		STR X0, [X1] ; Update the prompt

		B shell

	panic:
		sub sp, sp, #16
		stp lr, X0, [sp] ; Backup lr and X0 in stack

		ADRP X0, str.panic@page
		add X0, X0, str.panic@pageoff
		bl puts

		ldp lr, X0, [sp]
		bl puts

		bl print_newline

		ADRP X0, const.fuse@page
		add X0, X0, const.fuse@pageoff

		LDRB W0, [X0] ; Get fuse

		CMP W0, #3 ;
		blt debugloop.enter ; if EVT or DVT fuse we can enter a debugloop

		mov X0, #1
		B exit

	shell.reset:
		mov X0, XZR
		mov X1, XZR
		mov X2, XZR
		mov X3, XZR
		mov X4, XZR
		mov X5, XZR
		mov X6, XZR
		mov X7, XZR
		mov lr, XZR
		B shell


	shell:
		bl print_ps
		bl gets
		bl parse_cmd
		B shell.reset

	debugloop.enter:
		ADRP X0, str.enter_dbgloop@page
		add X0, X0, str.enter_dbgloop@pageoff
		bl puts
		B debugloop

	debugloop:
		B debugloop

	_main:

		; Initialize prompt
		ADRP X0, var.promptstatement@page
		ADD X0, X0, var.promptstatement@pageoff

		ADRP X1, const.defaultprompt@page
		ADD X1, X1, const.defaultprompt@pageoff
		STR X1, [X0]

		; Initialize user
		ADRP X0, const.guest@page
		ADD X0, X0, const.guest@pageoff

		ADRP X1, var.username@page
		ADD X1, X1, var.username@pageoff
		STR X1, [X0]

		; Spawn commandline
		bl print_banner
		bl shell


		bl exit
		RET

.section strings, "aS"

	str.enter_dbgloop:
		.ascii "Entering debug loop...\0"

	str.spinning_forever:
		.ascii "Spinning forever...\0"

	str.please_enter_name:
		.ascii "Please enter your name.\0"

	str.panic:
		.ascii "panic: \0"

	str.cmd_notfound:
		.ascii "command not found: \0"


.section errors, "aS"

	err.unimplemented:
		.ascii "Error: Logic has not yet been implemented at this location.\0"

	err.invalid_argument:
		.ascii "Error: Invalid argument.\0"

	err.unknown:
		.ascii "Error: Unknown error.\0"


.section constants, "aS"

	const.author:
		.ascii "Sem Voigtländer\0"

	const.version:
		.ascii "ARM64 UserlandKernel v1.0-alpha\0"

	const.legal:
		.ascii "© Copright 2020, Sem Voigtländer. All rights reserved.\0"

	const.guest:
		.ascii "guest\0"

	const.root:
		.ascii "root\0"

	const.defaultprompt:
		.ascii "ARM64> \0"

	const.newline:
		.ascii "\n\0"

	const.fuse:
		.byte 2


.section variables, "aw"

	var.username:
		.quad 0

	var.promptstatement:
		.quad 0

.section commands, "aw"

	cmd.help:
		.ascii "help\0"
		.quad 0

	cmd.echo:
		.ascii "echo\0"
		.quad 0

	cmd.exit:
		.ascii "exit\0"
		.quad 0

	cmd.panic:
		.ascii "panic\0"
		.quad 0

	.endofcmds:
		.ascii "\0"
