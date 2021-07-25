	.global DBG_cout_LF
	.global DBG_cout_32bit
	.global DBG_cout_64bit
	.global DBG_cout_128bit
	
	.global DBG_crt_ui64_to_x0

sys_write = 64

# ---------------------------------
DBG_cout_LF:
		stp		x0, x1, [sp, #-16]!
		stp		x2, x8, [sp, #-16]!
		
		mov		x0, #1				// fd
		adr		x1, L_str_LF
		mov		x2, #1				// 表示文字数
		mov		x8, #sys_write
		svc		#0		
		
		ldp		x2, x8, [sp], #16
		ldp		x0, x1, [sp], #16
		ret

	.align 2
L_str_LF:
	.ascii "\n"
	
# ---------------------------------
# スタックに push されている 32bit値を表示する
# スタッククリア: この関数内で実行される

	.align 2
DBG_cout_32bit:
		stp		x0, x1, [sp, #-16]!
		stp		x2, x8, [sp, #-16]!
		stp		x3, lr, [sp, #-16]!
		
		mov		x1, #0x61 - 0x3a
		ldr		x3, [sp, #48]
		bl		L_crt_ui64_to_x0
		
		adr		x1, L_str_8dig_for_cout
		str		x0, [x1]
		
		mov		x0, #1				// fd
		mov		x2, #9				// 表示文字数
		mov		x8, #sys_write
		svc		#0
		
		ldp		x3, lr, [sp], #16
		ldp		x2, x8, [sp], #16
		ldp		x0, x1, [sp], #32	// スタッククリアも含む
		ret

# ---------------------------------
# スタックに push されている 64bit値を表示する
# スタッククリア: この関数内で実行される

DBG_cout_64bit:
		stp		x0, x1, [sp, #-16]!
		stp		x2, x8, [sp, #-16]!
		stp		x3, lr, [sp, #-16]!
		
		// ---------------------
		mov		x1, #0x61 - 0x3a
		ldr		x3, [sp, #48]
		bl		L_crt_ui64_to_x0
		
		adr		x8, L_str_8dig_for_cout
		str		x0, [x8, #9]
		
		lsr		x3, x3, #16
		bl		L_crt_ui64_to_x0
		str		x0, [x8]
		
		// ---------------------
		mov		x0, #1				// fd
		mov		x1, x8
		mov		x2, #18				// 表示文字数
		mov		x8, #sys_write
		svc		#0
		
		ldp		x3, lr, [sp], #16
		ldp		x2, x8, [sp], #16
		ldp		x0, x1, [sp], #32	// スタッククリアも含む
		ret

# ---------------------------------
# スタックに push されている 128bit値を表示する
# スタッククリア: この関数内で実行される

DBG_cout_128bit:
		stp		x0, x1, [sp, #-16]!
		stp		x2, x8, [sp, #-16]!
		stp		x3, lr, [sp, #-16]!
		
		// ---------------------
		mov		x1, #0x61 - 0x3a
		ldr		x3, [sp, #48]
		bl		L_crt_ui64_to_x0
		
		adr		x8, L_str_8dig_for_cout
		str		x0, [x8, #27]
		
		lsr		x3, x3, #16
		bl		L_crt_ui64_to_x0
		str		x0, [x8, #18]

		ldr		x3, [sp, #56]
		bl		L_crt_ui64_to_x0
		str		x0, [x8, #9]

		lsr		x3, x3, #16
		bl		L_crt_ui64_to_x0
		str		x0, [x8]
		
		// ---------------------
		mov		x0, #1				// fd
		mov		x1, x8
		mov		x2, #36				// 表示文字数
		mov		x8, #sys_write
		svc		#0
		
		ldp		x3, lr, [sp], #16
		ldp		x2, x8, [sp], #16
		ldp		x0, x1, [sp], #32	// スタッククリアも含む
		ret
		
# ----------------------------
# >>> IN
# x3 : 文字列に変換したい値（下位32bits が変換される）
# x1 : 「= 0x61 - 0x3a」であること

# <<< OUT
# x0 : 「リトルエンディアン」で、８文字が格納される

# 破壊
# x3 : 16ビット右にシフトされる
# x2 : ワーキング

DBG_crt_ui64_to_x0:
L_crt_ui64_to_x0:
		ldr		x0, L_str_8dig_zero
		
		and		x2, x3, #0xf
		cmp		x2, #0xa
		b.mi	1f
		add		x2, x2, x1
1:		lsl		x2, x2, #56
		add		x0, x0, x2
		
		and		x2, x3, #0xf0
		cmp		x2, #0xa0
		b.mi	2f
		add		x2, x2, x1, LSL #4
2:		lsl		x2, x2, #48 - 4
		add		x0, x0, x2
		
		and		x2, x3, #0xf00
		cmp		x2, 0xa00
		b.mi	3f
		add		x2, x2, x1, LSL #8
3:		lsl		x2, x2, #40 - 8
		add		x0, x0, x2

		and		x2, x3, #0xf000
		cmp		x2, 0xa000
		b.mi	4f
		add		x2, x2, x1, LSL #12
4:		lsl		x2, x2, #32 - 12
		add		x0, x0, x2

		and		x2, x3, #0xf0000
		cmp		x2, 0xa0000
		b.mi	5f
		add		x2, x2, x1, LSL #16
5:		lsl		x2, x2, #24 - 16
		add		x0, x0, x2

		and		x2, x3, #0xf00000
		cmp		x2, 0xa00000
		b.mi	6f
		add		x2, x2, x1, LSL #20
6:		lsr		x2, x2, #20 - 16
		add		x0, x0, x2

		lsr		x3, x3, #16
		and		x2, x3, #0x0f00
		cmp		x2, 0x0a00
		b.mi	7f
		add		x2, x2, x1, LSL #8
7:		add		x0, x0, x2

		and		x2, x3, #0xf000
		cmp		x2, 0xa000
		b.mi	8f
		add		x2, x2, x1, LSL #12
8:		lsr		x2, x2, #12
		add		x0, x0, x2
		ret
	
	.align 2
L_str_8dig_zero:
	.ascii "00000000"

	
# ---------------------------------
	.data

	.align 2
L_str_8dig_for_cout:
	.ascii "xxxxxxxx xxxxxxxx xxxxxxxx xxxxxxxx "
