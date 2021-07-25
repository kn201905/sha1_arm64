// "dGhlIHNhbXBsZSBub25jZQ==258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
	//	b3 7a 4f 2c  c0 62 4f 16  90 f6 46 06  cf 38 59 45  b2 be c4 ea
	// s3pP LMBi TxaQ 9kYG zzhZ RbK+ xOo=

// "E4WSEcseoWr4csPLS2QJHA==258EAFA5-E914-47DA-95CA-C5AB0DC85B11";
	// ed e4 02 86  00 ad 40 c9  d5 20 b7 9f  24 03 ba 74  ae 49 c0 f7 
	// 7eQC hgCt QMnV ILef JAO6 dK5J wPc=

// "zYuFKiL/3y3UA63cCi8V6g==258EAFA5-E914-47DA-95CA-C5AB0DC85B11";
	// 7f 8b ce b1  ca 9f ab b2  fa ab 7a f2  79 89 4a 73  db f6 98 e5
	// f4vO scqf q7L6 q3ry eYlK c9v2 mOU=
	
	.global _start
	.cpu generic+fp+simd+crypto

sys_exit = 93
sys_read = 63
sys_write = 64

# ---------------------------------
	.text
_start:
		// ---------------------------------
		mov     x0, #1				// stdout
		adr     x1, L_msg_start		// string address
		mov     x2, #18				// length
		mov     x8, #sys_write
		svc     #0
		
		// ---------------------------------
		// ハッシュ元文字列の取り込み
		mov		x0, #0					// stdin
		adr     x1, L_1st_blk_to_hash	// store address
		mov		x2, #22					// length
		mov     x8, #sys_read
		svc     #0
		
		// ---------------------------------
		// 確認のため、ハッシュ元の文字列を表示
		mov     x0, #1					// stdout
		adr     x1, L_1st_blk_to_hash	// string address
		mov     x2, #60					// length
		mov     x8, #sys_write
		svc     #0
		
		bl		DBG_cout_LF

		// ---------------------------------
		// x1 : 512 bits ブロックへのアドレス
		adr		x1, L_1st_blk_to_hash
		
		// 512 bits ブロックをロード
		ld1		{v26.16b}, [x1], 16
		ld1		{v27.16b}, [x1], 16
		ld1		{v28.16b}, [x1], 16
		ld1		{v29.16b}, [x1], 16

		// 取得した 512 bits ブロックをビッグエンディアンに並べ替える
		rev32	v26.16b, v26.16b
		rev32	v27.16b, v27.16b
		rev32	v28.16b, v28.16b
		rev32	v29.16b, v29.16b

		// ---------------------------------
		// SHA-1 １周目
		// v24, v25 <- ABCDE
		adr		x0, L_init_sha_state
		ld1		{v24.4s}, [x0], 16	// v24 = (d0 c0 b0 a0)
		ld1		{v25.4s}, [x0]		// s25 = e0
		
/*
		# +++++++++++++++++++++++++
		# ハッシュ入力値の表示
		str		q24, [sp, #-16]!
		bl		DBG_cout_128bit
		bl		DBG_cout_LF

		str		q25, [sp, #-16]!
		bl		DBG_cout_32bit
		bl		DBG_cout_LF
		# ^^^^^^^^^^^^^^^^^^^^^^^^^
*/
		// v24 にハッシュ値 (D C B A)、V25.4s[0] に E が生成される
		bl		G_sha1_block

		// ---------------------------------
		// SHA-1 ２周目
		eor		v26.16b, v26.16b, v26.16b
		eor		v27.16b, v27.16b, v27.16b
		eor		v28.16b, v28.16b, v28.16b
		eor		v29.16b, v29.16b, v29.16b

		mov		x0, #0x1e000000000
		fmov	v29.d[1], x0
/*
		# +++++++++++++++++++++++++
		# 512bit ブロック入力値の表示
		str		q29, [sp, #-16]!
		bl		DBG_cout_128bit
		bl		DBG_cout_LF
		bl		DBG_cout_LF
		# ^^^^^^^^^^^^^^^^^^^^^^^^^
*/
		// v24 にハッシュ値 (D C B A)、V25.s[0] に E が生成される
		bl		G_sha1_block
		
		mov		x0, #1				// 出力先 fd
		bl		show_hash_v24_s25
		bl		DBG_cout_LF
		bl		DBG_cout_LF
		
		// ---------------------------------
		mov     x0, xzr			// exit code
		mov     x8, #sys_exit
		svc     #0


# ---------------------------------
# >>> IN
# x0 : 出力先 fd
# v24, s25 : sha1 の結果

show_hash_v24_s25:
//		mov		x0, ??
		stp		x0, lr, [sp, #-16]!

		adr		x4, L_hash_val
		
		fmov	x3, d24
		mov		x1, #0x61 - 0x3a
		bl		DBG_crt_ui64_to_x0
		str		x0, [x4]
		
		lsr		x3, x3, #16
		bl		DBG_crt_ui64_to_x0
		str		x0, [x4, #9]

		fmov	x3, v24.d[1]
		bl		DBG_crt_ui64_to_x0
		str		x0, [x4, #18]
		
		lsr		x3, x3, #16
		bl		DBG_crt_ui64_to_x0
		str		x0, [x4, #27]

		fmov	x3, d25
		bl		DBG_crt_ui64_to_x0
		str		x0, [x4, #36]
		
		ldp		x0, lr, [sp], #16
		mov		x1, x4
		mov		x2, 44
		mov		x8, #sys_write
		svc		#0
		ret
		
	
# ---------------------------------
	.align	4	// アライメントは 2^4 = 16 bytes
L_init_sha_state:
	.word	0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476  // v24
	.word	0xc3d2e1f0, 0x00000000, 0x00000000, 0x00000000  // v25

# ---------------------------------
	.data

	.align 2
L_msg_start:
	.ascii  "--- start program\n"

	.align 4
L_1st_blk_to_hash:
	.ascii "xxxxxxxxxxxxxxxxxxxxxx=="
	.ascii "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
	.byte	0x80, 0, 0, 0

	.align 2
L_hash_val:
	.ascii "xxxxxxxx xxxxxxxx xxxxxxxx xxxxxxxx xxxxxxxx"
