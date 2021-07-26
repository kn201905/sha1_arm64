#!/bin/bash

function assert() {
	str_to_hash=$1
	hash_val=$2
	result=$(echo $str_to_hash | ./main)
		
	if [ "$hash_val" = "$result" ]; then
		echo -e "ooo ハッシュ値 OK\n"
	else
		echo -e "xxx ハッシュ値 NG\n"
	fi
}

assert 'dGhlIHNhbXBsZSBub25jZQ' 'b37a4f2c c0624f16 90f64606 cf385945 b2bec4ea'
assert 'E4WSEcseoWr4csPLS2QJHA' 'ede40286 00ad40c9 d520b79f 2403ba74 ae49c0f7'
assert 'zYuFKiL/3y3UA63cCi8V6g' '7f8bceb1 ca9fabb2 faab7af2 79894a73 dbf698e5'

