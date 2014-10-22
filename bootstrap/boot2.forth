[text-section] init

[code]
 opt h-f+
 org $8000
[end-code]

[text-section] text

23 constant visible-files

$01 constant dbg-total-files
$02 constant dbg-max-heapify

$022F constant sdmctl
$0230 constant dladr
$02E0 constant runad
$02E2 constant initad
$0300 constant ddevic
$0301 constant dunit
$0302 constant dcmnd
$0303 constant dstats
$0304 constant dbufa
$0306 constant dtimlo
$0307 constant dunuse
$0308 constant dbyt
$030A constant daux1
$030B constant daux2
$0600 constant temp
$0800 constant copy-buffer
$5000 constant screen
$A600 constant file-sizes
$AA00 constant sec-buf1
$AE00 constant fat-buf
$D01F constant consol
$D5E8 constant command
$D5E9 constant sec-offs
$D5EA constant sec-cnt
$D5EB constant sec-num

\ master boot record
$1BE constant mbr-pi

\ partition info record
$00 constant pi-active
$01 constant pi-start-head
$02 constant pi-start-cyl-sec
$04 constant pi-fs-type
$05 constant pi-end-head
$06 constant pi-end-cyl-sec
$08 constant pi-first-sector
$0C constant pi-size

\ BPB record
$0B constant bpb-bytes-per-sector
$0D constant bpb-sectors-per-cluster
$0E constant bpb-reserved-sectors
$10 constant bpb-fat-copies
$11 constant bpb-root-dir-entries
$13 constant bpb-num-secs
$15 constant bpb-media-type
$16 constant bpb-fat16-size
$18 constant bpb-sectors-per-track
$1A constant bpb-num-heads
$1C constant bpb-hidden-sectors
$20 constant bpb-total-sectors-32
$24 constant bpb-fat32-size
$2C constant bpb-root-cluster

\ FAT directory entry
$00 constant direntry-name
$0B constant direntry-attrs
$14 constant direntry-1st-clus-hi
$1A constant direntry-1st-clus-lo
$1C constant direntry-file-size
32  constant direntry-size

variable cursor
variable negative
create msg1 ,' unknown FAT type'
create error-message-loader-overwrite ,' ERROR: attempted loader overwrite'
create fs-type 0 c,
create sectors-per-cluster 0 c,
2variable part0-1st-sector
2variable fat-size
2variable fat-start
2variable first-data-sector
2variable root-dir-cluster
variable direntry-sector-counter
variable de-ptr
variable total-files
variable de-scan-finished?
variable prev-de-attrs
variable done-sector?
variable filename
variable char-count
variable left
variable right
variable current
variable largest
variable heap-size
create line-addresses 256 cells allot
create filename-indexes 256 allot
create first-clusters 256 4 * allot
variable sector-in-cluster
variable byte-in-sector
2variable byte-in-file
2variable current-file-cluster
2variable selected-file-size
variable byte-ptr
variable byte-index
variable block-end
variable first-block
variable chunk-length
variable selected-file-index
variable new-selected-file-index
variable select-window-top-index
variable dlist-select
create legend $DC c, $DD c, ' :select file,' ' Return'* ' :load & run        '
create dlist0
  $70 c, $70 c, $70 c,
  $42 c, screen   0 + ,
  $42 c, screen  40 + ,
  $42 c, screen  80 + ,
  $42 c, screen 120 + ,
  $42 c, screen 160 + ,
  $42 c, screen 200 + ,
  $42 c, screen 240 + ,
  $42 c, screen 280 + ,
  $42 c, screen 320 + ,
  $42 c, screen 360 + ,
  $42 c, screen 400 + ,
  $42 c, screen 440 + ,
  $42 c, screen 480 + ,
  $42 c, screen 520 + ,
  $42 c, screen 560 + ,
  $42 c, screen 600 + ,
  $42 c, screen 640 + ,
  $42 c, screen 680 + ,
  $42 c, screen 720 + ,
  $42 c, screen 760 + ,
  $42 c, screen 800 + ,
  $42 c, screen 840 + ,
  $42 c, screen 880 + ,
  $42 c, legend ,
  $41 c, dlist0 ,
create dlist1
  $70 c, $70 c, $70 c,
  $42 c, screen   0 + ,
  $42 c, screen  40 + ,
  $42 c, screen  80 + ,
  $42 c, screen 120 + ,
  $42 c, screen 160 + ,
  $42 c, screen 200 + ,
  $42 c, screen 240 + ,
  $42 c, screen 280 + ,
  $42 c, screen 320 + ,
  $42 c, screen 360 + ,
  $42 c, screen 400 + ,
  $42 c, screen 440 + ,
  $42 c, screen 480 + ,
  $42 c, screen 520 + ,
  $42 c, screen 560 + ,
  $42 c, screen 600 + ,
  $42 c, screen 640 + ,
  $42 c, screen 680 + ,
  $42 c, screen 720 + ,
  $42 c, screen 760 + ,
  $42 c, screen 800 + ,
  $42 c, screen 840 + ,
  $42 c, screen 880 + ,
  $42 c, legend ,
  $41 c, dlist1 ,

: brk
[code]
 brk
 jmp next
[end-code] ;

: mul-8-32      ( x1 x2 c -- y1 y2 )
[code]
 lda pstack,x
 inx
 inx
 ldy #0
 sty w
 sty w+1
 sty w+2
 sty w+3
mul_8_32_loop
 clc
 ror @
 tay
 bcc mul_8_32_next
 clc
 lda w+2
 adc pstack+2,x
 sta w+2
 lda w+3
 adc pstack+3,x
 sta w+3
 lda w+0
 adc pstack+0,x
 sta w+0
 lda w+1
 adc pstack+1,x
 sta w+1
mul_8_32_next
 asl pstack+2,x
 rol pstack+3,x
 rol pstack+0,x
 rol pstack+1,x
 tya
 bne mul_8_32_loop
mul_8_32_done
 lda w+0
 sta pstack+0,x
 lda w+1
 sta pstack+1,x
 lda w+2
 sta pstack+2,x
 lda w+3
 sta pstack+3,x
 jmp next
[end-code] ;

: get-char    ( -- c )
[code]
 lda #0
 dex
 sta pstack,x
 stx w
 jsr do_gc
 ldx w
 dex
 sta pstack,x
 jmp next
do_gc
 lda $E425
 pha
 lda $E424
 pha
 rts
[end-code] ;

: debug  ( n -- )
[code]
 lda pstack,x
 inx
 inx
 jmp next
[end-code] ;

: jsioint
[code]
 jsr $E459
 jmp next
[end-code] ;

\ send data through SIO interface
\ u1 - data address
\ u2 - data length
\ u3 - command
: sio-command   ( u1 u2 u3 -- )
  dcmnd c!
  dup daux1 ! dbyt !
  dbufa !
  $31 ddevic c!
  $01 dunit c!
  $80 dstats c!
  $08 dtimlo c!
  jsioint ;

: ++            ( addr -- )
  [label] plus_plus
  dup @ 1+ swap ! ;

: print-str     ( c-addr -- )
  dup count cursor @ swap cmove
  count cursor @ + cursor !
  drop ;

: put-digit     ( c-addr c -- )
  $0F and
  dup 9 > if 23 else 16 then +
  negative c@ or
  swap c! ;

: cursor-next   ( -- u )
  cursor @ dup 1+ cursor ! ;

: set-cursor    ( u -- )
  screen + cursor ! ;

: put-char      ( c -- )
  cursor-next c! ;

: space 0 put-char ;

: print-hex-byte ( c -- )
  cursor-next over 4 rshift put-digit
  cursor-next swap put-digit ;

: print-hex-word ( u -- )
  cursor-next over 12 rshift put-digit
  cursor-next over  8 rshift put-digit
  cursor-next over  4 rshift put-digit
  cursor-next swap           put-digit ;

: print-hex-dword ( u1 u2 -- )
  print-hex-word print-hex-word ;

: show-sp
  [ 40 23 * 2 - ] literal set-cursor
  sp print-hex-byte ;

: show-sp-l
  legend 38 + cursor !
  sp print-hex-byte ;

: show-rsp-l
  legend cursor !
  rsp print-hex-byte ;

: error
[code]
error_loop
 lda $D40B
 sta $D01A
 jmp error_loop
[end-code] ;

: w8-cart-read
  begin
    command c@ dup
    $80 and if error then
    $40 and until ;

: cart-read
  1 command c!
  w8-cart-read ;

: ud-rshift
[code]
 ldy pstack,x
 inx
 inx
 lda pstack+1,x
ud_rshift_loop
 cpy #0
 beq ud_rshift_end
 dey
 lsr @
 ror pstack+0,x
 ror pstack+3,x
 ror pstack+2,x
 jmp ud_rshift_loop
ud_rshift_end
 sta pstack+1,x
 jmp next
[end-code] ;

: shift-sec-buf
[code]
 ldy #0
shift_loop
 lda sec_buf1+512,y
 sta sec_buf1,y
 lda sec_buf1+768,y
 sta sec_buf1+256,y
 iny
 bne shift_loop
 jmp next
[end-code] ;

: cluster-to-sector     ( ud -- ud )
  2 0 d- sectors-per-cluster c@ mul-8-32
  first-data-sector 2@ d+ ;

: find-next-cluster     ( ud -- ud )
  [ fat-buf $8000 - 512 / ] literal sec-offs c!
  1 sec-cnt c!
  \ sector_number = fat-start + cluster/128
  2dup 7 ud-rshift fat-start 2@ d+ swap sec-num 2!
  cart-read
  \ next_cluster_addr = fat-buf + (cluster & 127) * 4
  drop $7F and 2 lshift fat-buf +
  2@ swap ;

: find-next-file-cluster
  current-file-cluster 2@ find-next-cluster current-file-cluster 2! ;

: find-next-root-dir-cluster
  root-dir-cluster 2@ find-next-cluster root-dir-cluster 2! ;

\ sector_number = first-data-sector +
\    sectors_per_cluster * (root-dir-cluster - 2) +
\    direntry-sector-counter
: load-root-dir-sector
  root-dir-cluster 2@ cluster-to-sector
  direntry-sector-counter @ 0 d+
  swap sec-num 2!
  [ sec-buf1 $8000 - 512 / 1 + ] literal sec-offs c!
  cart-read ;

: last-root-dir-cluster?
  root-dir-cluster 2@ $0FFF and swap $FFF8 and swap $FFF8 $0FFF d= ;

\ addr1 : direntry
\ addr2 : filename
\ addr3 : &char-count
: copy-direntry-lfn     ( addr1 addr2 addr3 -- )
[code]
 ; cntr = &char-count
 lda pstack,x+
 sta cntr
 lda pstack,x+
 sta cntr+1
 ; w = filename
 lda pstack,x+
 sta w
 lda pstack,x+
 sta w+1
 ; z = direntry
 lda pstack,x+
 sta z
 lda pstack,x+
 sta z+1
 ldy #1
 jsr cp_lfn_chr
 ldy #3
 jsr cp_lfn_chr
 ldy #5
 jsr cp_lfn_chr
 ldy #7
 jsr cp_lfn_chr
 ldy #9
 jsr cp_lfn_chr
 ldy #14
 jsr cp_lfn_chr
 ldy #16
 jsr cp_lfn_chr
 ldy #18
 jsr cp_lfn_chr
 ldy #20
 jsr cp_lfn_chr
 ldy #22
 jsr cp_lfn_chr
 ldy #24
 jsr cp_lfn_chr
 ldy #28
 jsr cp_lfn_chr
 ldy #30
 jsr cp_lfn_chr
 jmp next

cp_lfn_chr
 lda (z),y
 bne do_cp_lfn_chr
 lda #40
 ldy #0
 sta (cntr),y
 pla
 pla
 jmp next
do_cp_lfn_chr
 jsr ascii_to_internal
 ; filename[char-count] := chr
 pha
 ldy #0
 lda (cntr),y
 tay
 pla
 sta (w),y
 ; char-count++
 iny
 tya
 ldy #0
 sta (cntr),y
 cmp #40
 beq term_cp_lfn_chr
 rts
term_cp_lfn_chr
 pla
 pla
 jmp next

;ascii_to_internal
; cmp #$20
; bcs range_1
;range_0
; add #$40
; rts
;range_1
; cmp #$60
; bcs range_2
; sub #$20
; rts
;range_2
; cmp #$80
; bcs range_3
; rts
;range_3
; cmp #$a0
; bcs range_4
; add #$30
; rts
;range_4
; cmp #$e0
; bcs range_5
; rts
;range_5
; sub #$10
; rts

ascii_to_internal
 tay
 lda a2i_lut,y
 rts

a2i_lut
 dta $40,$41,$42,$43,$44,$45,$46,$47,$48,$49,$4A,$4B,$4C,$4D,$4E,$4F,$50,$51,$52,$53,$54,$55,$56,$57,$58,$59,$5A,$5B,$5C,$5D,$5E,$5F
 dta $00,$01,$02,$03,$04,$05,$06,$07,$08,$09,$0A,$0B,$0C,$0D,$0E,$0F,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$1A,$1B,$1C,$1D,$1E,$1F,$20,$21,$22,$23,$24,$25,$26,$27,$28,$29,$2A,$2B,$2C,$2D,$2E,$2F,$30,$31,$32,$33,$34,$35,$36,$37,$38,$39,$3A,$3B,$3C,$3D,$3E,$3F
 dta $60,$61,$62,$63,$64,$65,$66,$67,$68,$69,$6A,$6B,$6C,$6D,$6E,$6F,$70,$71,$72,$73,$74,$75,$76,$77,$78,$79,$7A,$7B,$7C,$7D,$7E,$7F
 dta $C0,$C1,$C2,$C3,$C4,$C5,$C6,$C7,$C8,$C9,$CA,$CB,$CC,$CD,$CE,$CF,$D0,$D1,$D2,$D3,$D4,$D5,$D6,$D7,$D8,$D9,$DA,$DB,$DC,$DD,$DE,$DF
 dta $80,$81,$82,$83,$84,$85,$86,$87,$88,$89,$8A,$8B,$8C,$8D,$8E,$8F,$90,$91,$92,$93,$94,$95,$96,$97,$98,$99,$9A,$9B,$9C,$9D,$9E,$9F,$A0,$A1,$A2,$A3,$A4,$A5,$A6,$A7,$A8,$A9,$AA,$AB,$AC,$AD,$AE,$AF,$B0,$B1,$B2,$B3,$B4,$B5,$B6,$B7,$B8,$B9,$BA,$BB,$BC,$BD,$BE,$BF
 dta $E0,$E1,$E2,$E3,$E4,$E5,$E6,$E7,$E8,$E9,$EA,$EB,$EC,$ED,$EE,$EF,$F0,$F1,$F2,$F3,$F4,$F5,$F6,$F7,$F8,$F9,$FA,$FB,$FC,$FD,$FE,$FF
[end-code] ;

: copy-long-filename
  0 char-count !
  de-ptr @
  begin
    direntry-size -
    dup filename @ char-count copy-direntry-lfn
    dup c@ $40 and char-count @ 39 > or
  until
  drop ;

: ascii2internal    ( c -- c )
  lit a2i_lut + c@ ;

: copy-short-filename
  0 char-count !
  8 0 do
    de-ptr @ i + c@
    dup 0= if drop leave then
    dup $20 = if drop leave then
    ascii2internal
    filename @ char-count @ + c!
    char-count ++
  loop
  $0e filename @ char-count @ + c!
  char-count ++
  12 8 do
    de-ptr @ i + c@
    dup 0= if drop leave then
    dup $20 = if drop leave then
    ascii2internal
    filename @ char-count @ + c!
    char-count ++
  loop ;

: load-file-sector
  current-file-cluster 2@ cluster-to-sector
  sector-in-cluster @ 0 d+
  swap sec-num 2!
  [ sec-buf1 $8000 - 512 / ] literal sec-offs c!
  1 sec-cnt c!
  cart-read
  0 byte-in-sector !
  sector-in-cluster ++ ;

: peek-byte
  byte-in-sector @ 512 = if
    sector-in-cluster @ sectors-per-cluster c@ = if
      find-next-file-cluster
      0 sector-in-cluster !
    then
    load-file-sector
  then ;

: load-byte     ( -- c )
  peek-byte
  sec-buf1 byte-in-sector @ + c@
  byte-in-file 2@ 1 0 d+ byte-in-file 2!
  byte-in-sector ++ ;

: load-word     ( -- u )
  load-byte load-byte 8 lshift or ;

: copy-block    ( c addr -- )
[code]
 jsr com_loader
 jmp next
[end-code] ;

: com-run
[code]
 jmp do_com_run
[end-code] ;

: com-init
[code]
 stx tmp
 jsr do_com_init
 ldx tmp
 jmp next
[end-code] ;

: reopen-editor
[code]
 stx tmp
 jsr do_reopen_editor
 ldx tmp
 jmp next
[end-code] ;

: memory-clear
[code]
 jsr do_memory_clear
 jmp next
[end-code] ;

: clear-screen
[code]
 lda pstack,x+
 sta w
 lda pstack,x+
 sta w+1
 lda #0
 tay
 stx z
 ldx #48
cls_loop
 sta (w),y
 iny
 bne cls_loop
 inc w+1
 dex
 bne cls_loop
 ldx z
 jmp next
[end-code] ;

: highlight-line    ( addr -- )
[code]
 lda pstack,x+
 sta w
 lda pstack,x+
 sta w+1
 ldy #39
hl_loop
 lda (w),y
 ora #$80
 sta (w),y
 dey
 bpl hl_loop
 jmp next
[end-code] ;

: unhighlight-line  ( addr -- )
[code]
 lda pstack,x
 inx
 sta w
 lda pstack,x
 inx
 sta w+1
 ldy #39
uhl_loop
 lda (w),y
 and #$7F
 sta (w),y
 dey
 bpl uhl_loop
 jmp next
[end-code] ;

: calc-selected-line-address
  filename-indexes selected-file-index @ + c@ cells
  line-addresses +
  @ ;

: update-selection      ( u -- )
  dup selected-file-index @ = not if
    \ 0 line-addresses selected-file-index @ cells + @ c!
    calc-selected-line-address unhighlight-line
    line-addresses selected-file-index @ cells + @ unhighlight-line

    selected-file-index !

    \ $7F line-addresses selected-file-index @ cells + @ c!
    calc-selected-line-address highlight-line
  else
    drop
  then ;

: switch-dlist
  $00 sdmctl c!
  dlist-select @ if dlist1 else dlist0 then
  dladr !
  $22 sdmctl c!
  dlist-select @ not dlist-select ! ;

: regenerate-dlist
  dlist-select @ if dlist1 else dlist0 then 4 +
  visible-files 0 do
    line-addresses filename-indexes i + select-window-top-index @ + c@ cells + @ over !
    3 +
  loop drop ;

: select-previous
  selected-file-index @ 0 > if
    selected-file-index @ select-window-top-index @ - 0 = if
      select-window-top-index @ 1- select-window-top-index !
      regenerate-dlist
      switch-dlist
    then
    selected-file-index @ 1- update-selection
  then ;

: select-next
  selected-file-index @ total-files @ 1- < if
    selected-file-index @ select-window-top-index @ - visible-files 1- = if
      select-window-top-index @ 1+ select-window-top-index !
      regenerate-dlist
      switch-dlist
    then
    selected-file-index @ 1+ update-selection
  then ;

: line-address-by-index     ( n -- addr )
  1- filename-indexes + c@ cells line-addresses + @ ;

: cmp-fnames    ( addr1 addr2 -- n )
[code]
 ; w := addr2
 lda pstack,x+
 sta w
 lda pstack,x+
 sta w+1
 ; z := addr1
 lda pstack,x+
 sta z
 lda pstack,x+
 sta z+1
 ldy #0
cmp_fnames_loop
 lda (w),y
 jsr internal2lowercase
 sta tmp
 lda (z),y
 jsr internal2lowercase
 ; (addr1) - (addr2)
 cmp tmp
 beq cmp_fnames_next
 bcc cmp_fnames_lt
 jmp cmp_fnames_gt
cmp_fnames_next
 iny
 cpy #40
 bne cmp_fnames_loop
cmp_fnames_equ
 lda #0
 dex
 sta pstack,x
 dex
 sta pstack,x
 jmp next
cmp_fnames_lt
 lda #$FF
 dex
 sta pstack,x
 dex
 sta pstack,x
 jmp next
cmp_fnames_gt
 lda #0
 dex
 sta pstack,x
 lda #1
 dex
 sta pstack,x
 jmp next

internal2lowercase
 cmp #$21  ; 'A'
 bcc internal2lowercase_done
 cmp #$3B  ; 'Z'+1
 bcs internal2lowercase_done
 ora #$40
internal2lowercase_done
 rts
[end-code] ;

: max-heapify   ( n -- )
  recursive

  dup 2* left !
  dup 2* 1+ right !
  dup current !
  largest !

  left @ heap-size @ <= if
    left @ line-address-by-index current @ line-address-by-index cmp-fnames 1 = if
      left @ largest !
    then
  then

  right @ heap-size @ <= if
    right @ line-address-by-index largest @ line-address-by-index cmp-fnames 1 = if
      right @ largest !
    then
  then

  largest @ current @ <> if
    current @ 1- filename-indexes + c@
    largest @ 1- filename-indexes + c@
    current @ 1- filename-indexes + c!
    largest @ 1- filename-indexes + c!
    largest @ max-heapify
  then ;

: min
  over over u< if drop else nip then ;

: u>= [label] u_gt_eq u< not ;

: u<= [label] u_lt_eq u> not ;

: reinitialize-display
[code]
 ; disable interrupts
 sei
 lda #$00
 sta $D40E
 ; wait for vertical blank
 inc $D40E
 lda $D40B
 bne *-3
 ; set display list address
 lda <$BC20
 sta $D402
 lda >$BC20
 sta $D403
 ; use font in ROM
 lda #$E0
 sta $D409
 ; set default system colors
 lda #$00
 sta $D012
 sta $D013
 sta $D014
 sta $D015
 lda #$28
 sta $D016
 lda #$CA
 sta $D017
 lda #$94
 sta $D018
 lda #$46
 sta $D019
 lda #$00
 sta $D01A
 ; screen width
 lda #$22
 sta $D400
 ; font mirror
 lda #$02
 sta $D401
 jmp next
[end-code] ;

: c!+           ( c addr -- )
  [label] c_store_plus
  swap over @ c!
  dup @ 1+ swap ! ;

: !+            ( u addr -- )
  [label] store_plus
  swap over @ !
  dup @ 2 + swap ! ;

: main
  0 negative !

  \ initialize data addresses in display list
  screen dlist0 4 + 23 0 do 2dup ! 3 + swap 40 + swap loop 2drop

  screen clear-screen

  0 dlist-select !
  switch-dlist

  \ read MBR
  0 0 sec-num 2!
  [ sec-buf1 $8000 - 512 / ] literal sec-offs c!
  1 sec-cnt c!
  cart-read

  \ save filesystem type
  sec-buf1 mbr-pi + pi-fs-type + c@ fs-type c!
  \ save partition 0 first sector
  sec-buf1 mbr-pi + pi-first-sector + 2@ swap part0-1st-sector 2!

  \ read partition 0 first sector
  part0-1st-sector 2@ swap sec-num 2!
  cart-read

  \ save FAT size
  fs-type c@ $0B = \ FAT32
  if sec-buf1 bpb-fat32-size + 2@ swap fat-size 2!
  else 40 set-cursor msg1 print-str begin again
  then

  \ save number of sectors per cluster
  sec-buf1 bpb-sectors-per-cluster + c@ sectors-per-cluster c!

  \ fat-start = part0-1st-sector + reserved_sectors_number
  part0-1st-sector 2@
  sec-buf1 bpb-reserved-sectors + @ 0
  d+
  fat-start 2!

  \ first-data-sector = fat-copies*fat-size + fat-start
  fat-size 2@ sec-buf1 bpb-fat-copies + c@ mul-8-32
  fat-start 2@ d+
  first-data-sector 2!

  \ save root dir cluster
  sec-buf1 bpb-root-cluster + 2@ swap root-dir-cluster 2!

  256 0 do
    i filename-indexes i + c!
  loop

  screen 256 0 do
    dup line-addresses i cells + !
    i [ 102 1 - ] literal = i [ 204 1 - ] literal = or if
      [ 40 16 + ] literal   \ 102 filenames in $5000..$5FFF and in $6000..$6FFF
    else
      40
    then +
  loop drop

  \ scan root directory entries
  0 total-files !
  0 de-scan-finished? !
  0 prev-de-attrs !
  0 direntry-sector-counter !
  0 selected-file-index !
  0 select-window-top-index !
  begin
    de-scan-finished? @ not while
    shift-sec-buf
    load-root-dir-sector
    direntry-sector-counter ++
    [ sec-buf1 512 + ] literal de-ptr !
    0 done-sector? !
    begin
      de-ptr @ [ sec-buf1 1024 + ] literal u< if
        de-ptr @ c@ 0= if -1 de-scan-finished? ! then
      else
        -1 done-sector? !
      then
      done-sector? @ de-scan-finished? @ or not while
      -1                                                   \ skip direntry flag
      de-ptr @ c@ $E5 = if drop 0 then                     \ deleted/available
      de-ptr @ c@ $2E = if drop 0 then                     \ '.'/'..'
      de-ptr @ direntry-attrs + c@ $DE and if drop 0 then  \ not a regular file
      if
        \ copy filename to screen buffer
        line-addresses total-files @ cells + @ filename !
        prev-de-attrs @ $0F = if
          copy-long-filename
        else
          copy-short-filename
        then

        \ save file's 1st cluster
        de-ptr @ direntry-1st-clus-lo + @
        de-ptr @ direntry-1st-clus-hi + @
        first-clusters total-files @ 2 lshift + 2!

        \ save file's size
        de-ptr @ direntry-file-size + 2@ swap
        file-sizes total-files @ 2 lshift + 2!

        total-files ++
      then
      de-ptr @ direntry-attrs + c@ prev-de-attrs c!
      de-ptr @ direntry-size + de-ptr !
    repeat
    direntry-sector-counter @ sectors-per-cluster c@ = if
      find-next-root-dir-cluster
      last-root-dir-cluster? if -1 de-scan-finished? ! then
      0 direntry-sector-counter !
    then
  repeat

  \ build max heap
  total-files @ heap-size !
  1 heap-size @ 2/ do
    i max-heapify
  -1 +loop
  \ sort filenames
  begin
    heap-size @ 1 > while
    \ swap elements heap[1] and heap[n]
    filename-indexes c@ filename-indexes heap-size @ 1- + c@
    filename-indexes c! filename-indexes heap-size @ 1- + c!
    \ discard node n from heap
    heap-size @ 1- heap-size !
    \ fix heap
    1 max-heapify
  repeat
  regenerate-dlist
  switch-dlist

  \ select file
  calc-selected-line-address highlight-line
  begin
    get-char dup
    $9B = not while
    dup $1C = if select-previous then       \ [Control] + [Up]
    dup $2D = if select-previous then       \ '-'
    dup $1D = if select-next then           \ [Control] + [Down]
    dup $3D = if select-next then           \ '='
    drop
  repeat drop

  \ find selected file's 1st cluster
  filename-indexes selected-file-index @ + c@ 2 lshift
  first-clusters + 2@
  current-file-cluster 2!

  \ find selected file's size
  filename-indexes selected-file-index @ + c@ 2 lshift
  file-sizes + 2@
  selected-file-size 2!

  $FF $D301 c!        \ turn off Basic ROM
  $01 $3F8 c!         \ BASICF (0 = enabled)

  \ copy .com loader setup to internal memory
  lit com_loader_setup_start lit com_loader_setup lit com_loader_setup_length cmove

  memory-clear

  \ build mirror of OS display list
  $BC20 byte-ptr !
  $70 byte-ptr c!+
  $70 byte-ptr c!+
  $70 byte-ptr c!+
  $42 byte-ptr c!+
  $BC40 byte-ptr !+
  23 0 do $02 byte-ptr c!+ loop
  $41 byte-ptr c!+
  $BC20 byte-ptr !+
  $00 byte-ptr c!+
  $00 byte-ptr c!+
  $80 byte-ptr c!+
  byte-ptr @ [ 40 24 * 3 - ] literal 0 fill

  reopen-editor

  \ copy .com loader to internal memory
  lit com_loader_start lit com_loader lit com_loader_length cmove

  \ load & run executable file
  0 0 byte-in-file 2!
  512 byte-in-sector !
  0 sector-in-cluster !
  0 runad !
  load-file-sector
  begin
    load-word
    dup $FFFF = if drop load-word then
    byte-ptr !
    load-word block-end !

    byte-ptr @ [ copy-buffer 256 + ] literal u<
    block-end @ lit com_loader u>= and
    if
      reinitialize-display
      error-message-loader-overwrite count $BC40 swap cmove
      begin again
    then

    runad @ 0= if
      byte-ptr @ runad !
    then

    lit dummy_init initad !

    begin
      peek-byte
      512 byte-in-sector @ -
      block-end @ 1+ byte-ptr @ - min
      256 min
      dup chunk-length !
      if
        sec-buf1 byte-in-sector @ + copy-buffer chunk-length @ cmove
        chunk-length @ byte-ptr @ copy-block
        chunk-length @ byte-ptr @ + byte-ptr !
        chunk-length @ byte-in-sector @ + byte-in-sector !
        chunk-length @ 0 byte-in-file 2@ d+ byte-in-file 2!
      then
      byte-ptr @ block-end @ u>
    until

    com-init
    byte-in-file 2@ selected-file-size 2@ d= if com-run then
  again
  ;

[code]
 ert *>$9FFF

com_loader_setup_start equ *
 org r:$0900

com_loader_setup

setup_enable_cart
 sei
 lda #$C0
 sta $D5EF
 nop
 lda $D013
 sta $3FA
 cli
 rts

setup_disable_cart
 sei
 lda #0
 sta $D5EF
 nop
 lda $D013
 sta $3FA
 cli
 rts

cio0
 sta $342
 ldx #0
 jmp $E456

ename dta c'E:',$9B

do_reopen_editor
 jsr setup_disable_cart
 ; close editor
 lda #12 ; close
 jsr cio0
 ; set RAMTOP
 lda #$C0
 sta $6A
 ; open editor
 lda #<ename
 sta $344
 lda #>ename
 sta $345
 lda #3 ; open
 jsr cio0
 jsr setup_enable_cart
 rts

; zero-fill memory $1000-$BFFF
do_memory_clear
 jsr setup_disable_cart
 lda #$10
 sta mem_clear_loop_i+2
mem_clear_loop_o
 lda #0
 ldy #0
mem_clear_loop_i
 sta $1000,y
 iny
 bne mem_clear_loop_i
 inc mem_clear_loop_i+2
 lda #$C0
 cmp mem_clear_loop_i+2
 bne mem_clear_loop_o
 jsr setup_enable_cart
 rts

com_loader_setup_end

com_loader_setup_length equ *-com_loader_setup

com_loader_start equ com_loader_setup_start+com_loader_setup_length

 org r:$0700

com_loader
 jsr disable_cart
 lda pstack,x
 inx
 sta w
 lda pstack,x
 inx
 sta w+1
 lda pstack,x
 inx
 inx
 sta cntr
 ldy #0
com_loader_block_loop
 lda copy_buffer,y
 sta (w),y
 iny
 cpy cntr
 bne com_loader_block_loop
 jsr enable_cart
 rts

do_com_run
 jsr disable_cart
 pla
 pla
 jmp ($2E0)

do_com_init
 jsr disable_cart
 jsr jmp_init
 lda #$C0
 sta $D20E
 jsr enable_cart
 rts
jmp_init
 jmp ($2E2)

enable_cart
 sei
 lda #$C0
 sta $D5EF
 nop
 lda $D013
 sta $3FA
 rts

disable_cart
 sei
 lda #0
 sta $D5EF
 nop
 lda $D013
 sta $3FA
 cli
 rts

dummy_init
 rts

com_loader_end

 ert com_loader_end>=copy_buffer

com_loader_length equ *-com_loader
 ert com_loader_start+com_loader_length>=file_sizes
[end-code]
