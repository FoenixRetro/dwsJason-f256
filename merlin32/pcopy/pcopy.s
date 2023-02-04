;
; Merlin32 Hello.PGX program, for Jr
;
; To Assemble "merlin32 -v hello.s"
;
		mx %11

; some Kernel Stuff
		put ..\kernel\api.s

;PGX_CPU_65816 = $01
;PGX_CPU_680X0 = $02
PGX_CPU_65C02 = $03

		org $0
		dsk pcopy.pgx
		db 'P','G','X' 		; PGX header
		db PGX_CPU_65C02    ; CPU - 65c02
		adrl start

;------------------------------------------------------------------------------
; Some Global Direct page stuff

; MMU modules needs 0-1F

	dum $20
temp0 ds 4
temp1 ds 4
temp2 ds 4
temp3 ds 4
	dend

; Event Buffer at $30
event_type = $30
event_buf  = $31
event_ext  = $32

event_file_data_read  = event_type+kernel_event_event_t_file_data_read
event_file_data_wrote = event_type+kernel_event_event_t_file_wrote_wrote 

args = $300

xfer_data = $10000

; first thing is a c string with the name of the file
; second thing is the length of the file (3) bytes
; third thing is the zip crc32
; followed by file data

; File uses $B0-$BF
; Term uses $C0-$CF
; Kernel uses $F0-FF

		dum $2000
filename ds 256
crc32    ds 4
len24    ds 3
		dend

;
; $200-$3FF is currently ear-marked for args, and environment status shit
; Even if we don't care, we don't know if it will be placed in these locations
; before we're loaded, or after
;
		org $400
start
		jsr TermInit					; Clear Terminal, etc
		jsr mmu_unlock					; Set us up, so we can read/write system memory

		; Looking for data message
		lda #<txt_look_for_data
		ldx #>txt_look_for_data
		jsr TermPUTS

		ldy #^xfer_data
		lda #<xfer_data
		ldx #>xfer_data
		jsr TermPrintAXYH
		jsr TermCR

		lda #<xfer_data
		ldx #>xfer_data
		ldy #^xfer_data
		jsr set_read_address

		; Print out the filename
		; copy the filename into our mapped space
		ldx #0
]name	jsr readbyte
		sta filename,x
		inx
		cmp #0
		bne ]name

		lda #<txt_filename
		ldx #>txt_filename
		jsr TermPUTS

		lda #<filename
		ldx #>filename
		jsr TermPUTS
		jsr TermCR

;-----------------------------------------------

		; Print out the CRC 32
		lda #<txt_crc32
		ldx #>txt_crc32
		jsr TermPUTS

		ldx #0
]crc32  jsr readbyte
		sta crc32,x
		inx
		cpx #4
		bcc ]crc32

		lda crc32+3
		jsr TermPrintAH
		lda crc32+2
		jsr TermPrintAH
		lda crc32+1
		jsr TermPrintAH
		lda crc32+0
		jsr TermPrintAH
		jsr TermCR

;--------------------------------------------------

		; Print out the length
		lda #<txt_length
		ldx #>txt_length
		jsr TermPUTS

		ldx #0
]len	jsr readbyte
		sta len24,x
		inx
		cpx #3
		bcc ]len

		lda len24
		ldx len24+1
		ldy len24+2
		jsr TermPrintAXYH
		jsr TermCR

;--------------------------------------------------

:start  = temp1
:length = temp2

		; save data start for the write later, if we decide to write
		jsr get_read_address
		sta :start
		stx :start+1
		sty :start+2









;-----------------------------------------------

		; Print out the length



		put mmu.s
		put term.s
		put file.s
		put crc32.s


txt_look_for_data asc 'Looking for data at $'
		db 0
txt_filename      asc '          filename: '
		db 0
txt_length        asc '            length: $'
		db 0
txt_crc32         asc '             CRC32: $'
		db 0
txt_calc32		  asc '  Calculated CRC32: $'
		db 0
txt_match		  asc '         CRC Match: '
		db 0
txt_yes asc 'yes'
		db 13,0
txt_no  asc 'fuck off'
		db 13,0

txt_done db 13
		asc 'pcopy is done.'
		db 13,0
		
