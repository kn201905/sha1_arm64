
	.global	G_base64_20bytes
	
# ---------------------------------
// >>> IN
// x0 : base64 変換元アドレス（24bytes バッファ（先頭 20bytes が有効値））
// x1 : base64 変換後アドレス（32bytes バッファ（先頭 27bytes が有効値））

// <<< OUT
// x1 で示されるバッファに 27文字 の結果が格納される

// *** 破壊
// x0 : ワーキング

G_base64_20bytes:
		// この関数内で DBG ルーチンをコールしないのであれば、stp は削除可
		stp		x0, lr, [sp, #-16]!
		
		ld3		{v16.8b, v17.8b, v18.8b}, [x0]
		// v16 = aaaa aaaa
		// v17 = bbbb bbbb
		// v18 = cccc cccc
		
/*
		str		q16, [sp, #-16]!
		bl		DBG_cout_128bit
		bl		DBG_cout_LF

		str		q17, [sp, #-16]!
		bl		DBG_cout_128bit
		bl		DBG_cout_LF

		str		q18, [sp, #-16]!
		bl		DBG_cout_128bit
		bl		DBG_cout_LF
*/
		ushr	v20.8b, v16.8b, #2	// v20 = 00aa aaaa
		
		ushr	v21.8b, v17.8b, #2	// v21 = 00bb bbbb
		sli		v21.8b, v16.8b, #6	// v21 = aabb bbbb
		ushr	v21.8b, v21.8b, #2  // v21 = 00aa bbbb

		ushr	v22.8b, v18.8b, #4	// v22 = 0000 cccc
		sli		v22.8b, v17.8b, #4	// v22 = bbbb cccc
		ushr	v22.8b, v22.8b, #2	// v22 = 00bb bbcc
		
		shl		v23.8b, v18.8b, #2	// v23 = cccc cc00
		ushr	v23.8b, v23.8b, #2	// v23 = 00cc cccc

/*		
		// ++++++++++++++++++++++++++++++++
		str		d20, [sp, #-16]!
		bl		DBG_cout_64bit
		bl		DBG_cout_LF
		// ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
*/
		adr		x0, L_base64_table
		ld1		{v16.16b}, [x0], #16
		ld1		{v17.16b}, [x0], #16
		ld1		{v18.16b}, [x0], #16
		ld1		{v19.16b}, [x0]
		
		tbl		v20.8b, {v16.16b, v17.16b, v18.16b, v19.16b}, v20.8b
		tbl		v21.8b, {v16.16b, v17.16b, v18.16b, v19.16b}, v21.8b
		tbl		v22.8b, {v16.16b, v17.16b, v18.16b, v19.16b}, v22.8b
		tbl		v23.8b, {v16.16b, v17.16b, v18.16b, v19.16b}, v23.8b
/*
		// ++++++++++++++++++++++++++++++++
		str		d20, [sp, #-16]!
		bl		DBG_cout_64bit
		bl		DBG_cout_LF
		// ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
*/
		st4		{v20.8b, v21.8b, v22.8b, v23.8b}, [x1]
		
		// この関数内で DBG ルーチンをコールしないのであれば、ldp は削除可
		ldp		x0, lr, [sp], #16
		ret
		
# ---------------------------------

	.align 4
L_base64_table:
	.ascii "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	.ascii "abcdefghijklmnopqrstuvwxyz"
	.ascii "0123456789+/"

