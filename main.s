// "dGhlIHNhbXBsZSBub25jZQ==258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
	// b37a4f2c c0624f16 90f64606 cf385945 b2bec4ea
	// s3pP LMBi TxaQ 9kYG zzhZ RbK+ xOo=

// "E4WSEcseoWr4csPLS2QJHA==258EAFA5-E914-47DA-95CA-C5AB0DC85B11";
	// ede40286 00ad40c9 d520b79f 2403ba74 ae49c0f7
	// 7eQC hgCt QMnV ILef JAO6 dK5J wPc=

// "zYuFKiL/3y3UA63cCi8V6g==258EAFA5-E914-47DA-95CA-C5AB0DC85B11";
	// 7f8bceb1 ca9fabb2 faab7af2 79894a73 dbf698e5
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
		// start program の表示
		mov     x0, #2					// dbg out
		adr     x1, L_msg_start			// string address
		mov     x2, #18					// length
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
		mov     x0, #2					// dbg out
		adr     x1, L_1st_blk_to_hash	// string address
		mov     x2, #60					// length
		mov     x8, #sys_write
		svc     #0
		
		bl		DBG_cout_LF

		// ---------------------------------
		// x1 : 512 bits ブロックへのアドレス
		adr		x1, L_1st_blk_to_hash
		
		// 512 bits ブロックをロード
		ld1		{v20.16b}, [x1], #16
		ld1		{v21.16b}, [x1], #16
		ld1		{v22.16b}, [x1], #16
		ld1		{v23.16b}, [x1]

		// 取得した 512 bits ブロックをビッグエンディアンに並べ替える
		rev32	v20.16b, v20.16b
		rev32	v21.16b, v21.16b
		rev32	v22.16b, v22.16b
		rev32	v23.16b, v23.16b

		// ---------------------------------
		// sha1 初期値を設定
		// v0, v1 <- ABCDE
		adr		x0, L_init_sha_state
		ld1		{v0.4s}, [x0], 16	// v0.s4 = (d0 c0 b0 a0)
		ld1		{v1.4s}, [x0]		// v1.s[0] = e0
		
		bl		G_sha1_block

		// ---------------------------------
		// SHA-1 ２ブロック目
		eor		v20.16b, v20.16b, v20.16b
		eor		v21.16b, v21.16b, v21.16b
		eor		v22.16b, v22.16b, v22.16b
		eor		v23.16b, v23.16b, v23.16b

		mov		x0, #0x1e000000000
		fmov	v23.d[1], x0

		bl		G_sha1_block

		// ---------------------------------
		// 作成されたハッシュ値を fd 1 へ出力
		mov		x0, #1				// std out
		bl		L_out_to_x0_hash_v0_s1

		// 作成されたハッシュ値を fd 2 へ出力
		bl		DBG_cout_LF
		mov		x0, #2				// dbg out
		bl		L_out_to_x0_hash_v0_s1
		bl		DBG_cout_LF
		
		// ---------------------------------
		// ハッシュ値を base64 へエンコーディング
		rev32	v0.16b, v0.16b
		adr		x1, L_20bytes_to_base64
		st1		{v0.4s}, [x1], #16		
		
		rev32	v1.8b, v1.8b
		st1		{v1.2s}, [x1]

		adr		x0, L_20bytes_to_base64
		adr		x1, L_27letters_base64
		bl		G_base64_20bytes
		
		// ---------------------------------
		// 作成された base64 文字列（27文字）を fd 3 へ出力
		mov		x0, #3
		adr		x1, L_27letters_base64
		mov		x2, #27
		mov		x8, #sys_write
		svc		#0
		
		// ---------------------------------
		mov     x0, xzr			// exit code
		mov     x8, #sys_exit
		svc     #0


# ---------------------------------
# >>> IN
# x0 : 出力先 fd
# v0, s1 : sha1 の結果

# <<< out
# x0 で示される fd に L_hash_val の 44文字を出力する

# 破壊
# x0 - x2, x3, x8

L_out_to_x0_hash_v0_s1:
//		mov		x0, ??
		stp		x0, lr, [sp, #-16]!

		adr		x4, L_hash_val
		
		fmov	x3, d0
		mov		x1, #0x61 - 0x3a
		bl		DBG_crt_ui64_to_x0
		str		x0, [x4]
		
		lsr		x3, x3, #16
		bl		DBG_crt_ui64_to_x0
		str		x0, [x4, #9]

		fmov	x3, v0.d[1]
		bl		DBG_crt_ui64_to_x0
		str		x0, [x4, #18]
		
		lsr		x3, x3, #16
		bl		DBG_crt_ui64_to_x0
		str		x0, [x4, #27]

		fmov	x3, d1
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
	.word	0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476
	.word	0xc3d2e1f0, 0x00000000, 0x00000000, 0x00000000

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

	.align 4
L_20bytes_to_base64:
	.skip 24
	
	.align 4
L_27letters_base64:
	.skip 32
	
# ---------------------------------
# サンプルコード
/*
		# +++++++++++++++++++++++++
		str		q0, [sp, #-16]!
		bl		DBG_cout_128bit
		bl		DBG_cout_LF
		bl		DBG_cout_LF
		# ^^^^^^^^^^^^^^^^^^^^^^^^^
*/
