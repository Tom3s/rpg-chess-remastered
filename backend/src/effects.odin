package main

EFFECT_TYPE :: enum {
	STUNNED,
}

Effect :: struct {
	type: EFFECT_TYPE,

	remaining: int,
}