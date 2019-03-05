; HEADER
.segment "HEADER"
.byte "NES", $1A
.byte $02 ; 2x16K PRG rom
.byte $01 ; 1x8K CHR rom
.byte $01 ; Horizontal mirroring
.byte $00
.byte $00
.byte $00 ; NTSC
.byte $00
.byte $00,$00,$00,$00,$00

; CHR ROM
.segment "TILES"
.incbin "ascii4k.chr"

; VECTORS
.segment "VECTORS"
.word nmi
.word reset
.word irq

.segment "RODATA"
example_palette:
.byte $0F,$15,$26,$37 ; bg0 purple/pink
.byte $0F,$09,$19,$29 ; bg1 green
.byte $0F,$01,$11,$21 ; bg2 blue
.byte $0F,$00,$10,$30 ; bg3 greyscale
.byte $0F,$18,$28,$38 ; sp0 yellow
.byte $0F,$14,$24,$34 ; sp1 purple
.byte $0F,$1B,$2B,$3B ; sp2 teal
.byte $0F,$12,$22,$32 ; sp3 marine

; ##############################################################################
; ZERO PAGES VARIABLE DECLARATION
; ##############################################################################
.segment "ZEROPAGE"
nmi_lock:	.res 1 ; prevents NMI re-entry
nmi_count:	.res 1 ; is incremented every NMI
nmi_ready:	.res 1 ; 1= Push PPU frame update; 2= Rendering off next NMI
nmt_update_len:	.res 1 ; number of bytes in nmt_update buffer

scroll_x:	.res 1 ; x scroll position
scroll_y:	.res 1 ; y scroll position
scroll_nmt:	.res 1 ; nametable select (0-3 = $2000,$2400,$2800,$2C00)
reset_count:	.res 1

gamepad:	.res 1

posX:		.res 1
posY:		.res 1
temp:		.res 1

.segment "CODE"
	lda #0
	sta reset_count
reset:
	sei		; mask interrupts
	inc reset_count
	lda #0
	sta $2000	; disable NMI
	sta $2001	; disable rendering
	sta $4015	; disable APU sound
	sta $4010	; disable DMC IRQ
	lda #$40
	sta $4017	; disable APU IRQ
	cld		; disable decimal mode
	ldx #$FF
	txs		; initialize stack

	; wait for first vblank
	bit $2002
	:
		bit $2002
		bpl :-

	; clear all RAM to 0
	ldy reset_count
	lda #0
	ldx #0
	:
		sta $0000, X
		sta $0100, X
		sta $0200, X
		sta $0300, X
		sta $0400, X
		sta $0500, X
		sta $0600, X
		sta $0700, X
		inx
		bne :-

	; wait for second vblank
	:
		bit $2002
		bpl :-
	; NES is initialized, ready to begin!
	; enable the NMI for graphical updates, and jump to our main program
	sty reset_count
	ldy #0
	lda #$88
	sta $2000
	jmp main

.segment "BSS"
nmt_update:	.res 256 ; nametable update entry buffer for PPU update
palette:	.res 32  ; palette buffer for PPU update

.segment "OAM"
oam: .res 256        ; sprite OAM data to be uploaded by DMA

.segment "CODE"
nmi:
	; save registers
	php
	pha
	txa
	pha
	tya
	pha
	; prevent NMI re-entry
	lda nmi_lock
	beq :+
		jmp @nmi_end
	:
	lda #1
	sta nmi_lock
	; increment frame counter
	inc nmi_count
	;
	lda nmi_ready
	bne :+ ; nmi_ready == 0 not ready to update PPU
		jmp @ppu_update_end
	:
	cmp #2 ; nmi_ready == 2 turns rendering off
	bne :+
		lda #%00000000
		sta $2001
		ldx #0
		stx nmi_ready
		jmp @ppu_update_end
	:
	; sprite OAM DMA
	ldx #0
	stx $2003
	lda #>oam
	sta $4014
	; palettes
	lda #%10001000
	sta $2000 ; set horizontal nametable increment
	lda $2002
	lda #$3F
	sta $2006
	stx $2006 ; set PPU address to $3F00
	ldx #0
	:
		lda palette, X
		sta $2007
		inx
		cpx #32
		bcc :-
	; nametable update
	ldx #0
	cpx nmt_update_len
	bcs @scroll
	@nmt_update_loop:
		lda nmt_update, X
		sta $2006
		inx
		lda nmt_update, X
		sta $2006
		inx
		lda nmt_update, X
		sta $2007
		inx
		cpx nmt_update_len
		bcc @nmt_update_loop
	lda #0
	sta nmt_update_len
@scroll:
	lda scroll_nmt
	and #$03 ; keep only lowest 2 bits to prevent error
	ora #$88
	sta $2000
	lda scroll_x
	sta $2005
	lda scroll_y
	sta $2005
	; enable rendering
	lda #%00011110
	sta $2001
	; flag PPU update complete
	ldx #0
	stx nmi_ready
@ppu_update_end:
	; if had music/sound, this would be a good place to play it
	; unlock re-entry flag
	lda #0
	sta nmi_lock
@nmi_end:
	; restore registers and return
	pla
	tay
	pla
	tax
	pla
	plp
	rti

.segment "CODE"
irq:
	rti

; ##############################################################################
; MAIN CODE
; ##############################################################################
.segment "CODE"
main:
	ldx #0
	:
		lda example_palette, X
		sta palette, X
		inx
		cpx #32
		bcc :-
@loop:
	jsr gamepad_poll
	lda gamepad

	jsr displayText

	jsr displayGamepad

	jsr ppu_update
	jmp @loop

; Poll the gamepad state and put its result in gamepad
gamepad_poll:
	; save registers
	php
	pha
	txa
	pha
	tya
	pha
	; strobe the gamepad to latch current button state
	lda #1
	sta $4016
	lda #0
	sta $4016
	; read 8 bytes from the interface at $4016
	ldx #8
	:
		pha
		lda $4016
		; combine low two bits and store in carry bit
		and #%00000011
		cmp #%00000001
		pla
		; rotate carry into gamepad variable
		ror
		dex
		bne :-
	sta gamepad
	; restore registers and return
	pla
	tay
	pla
	tax
	pla
	plp
	rts


Test: .byte 12, "Hello world!"

displayText:
	ldx #1
	stx posY
	ldx #0
	:
		inx
		ldy Test, X
		dex
		sty temp

		stx posX
		jsr setTileXY
		inx
		txa
		cmp Test
		bne :-
	rts

displayGamepad:
	; save registers
	php
	pha
	txa
	pha
	tya
	pha

	ldy #10
	sty posY

	ldx #0
	:
		stx posX
		lda gamepad
		clc
		ror
		sta gamepad
		bcc @display0
@display1:
		ora #$80
		sta gamepad
		lda #'1'
		jmp @end
@display0:
		lda #'0'
@end:
		sta temp
		jsr setTileXY
		inx
		txa
		cmp #8
		bne :-

	; restore registers and return
	pla
	tay
	pla
	tax
	pla
	plp

	rts

; set Tile temp at (posX, posY)
setTileXY:
	; save registers
	php
	pha
	txa
	pha
	tya
	pha

	ldx nmt_update_len
	lda posY
	lsr
	lsr
	lsr
	ora #$20	; Y = (1 div 8 + 0x20)
	sta nmt_update, X
	inx
	lda posY
	asl
	asl
	asl
	asl
	asl
	ora posX
	sta nmt_update, X
	inx
	lda temp
	sta nmt_update, X
	inx
	stx nmt_update_len

	; restore registers and return
	pla
	tay
	pla
	tax
	pla
	plp

	rts


; Refresh the ppu (video)
ppu_update:
	lda #1
	sta nmi_ready
	:
		lda nmi_ready
		bne :-
	lda #$01
	lsr
	lsr
	lsr
	rts