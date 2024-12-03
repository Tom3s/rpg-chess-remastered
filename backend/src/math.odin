package main

import "core:math"
import "core:math/linalg"

v2 :: [2]f32;
v3 :: [3]f32;
v4 :: [4]f32;
v2i :: [2]int;
v3i :: [3]int;
v4i :: [4]int;

remap :: proc(x, froma, toa, fromb, tob: f32) -> f32 {
	return linalg.lerp(
		fromb, tob, \
		linalg.unlerp(froma, toa, x), \
	);
}

// easing functions
ease_in_out_cubic :: proc(x: f32) -> f32 {
	if x < 0.5 {
		return 4 * x * x * x;
	} else {
		return 1 - linalg.pow(-2 * x + 2, 3) / 2;
	}
}

ease_out_cubic :: proc(x: f32) -> f32 {
	return 1 - linalg.pow(1 - x, 3);
}

normalize_int :: proc(v: v2i) -> v2i {
	v := v;
	// can't divide by zero smh
	if v.x != 0 {
		v.x = v.x / abs(v.x);
	}
	if v.y != 0 {
		v.y = v.y / abs(v.y);
	}

	return v;
}


length :: proc(v: v2i) -> f32 {
	return linalg.sqrt(cast(f32) (v.x * v.x) + cast(f32) (v.y * v.y));
}

distance :: proc(v1, v2: v2i) -> f32 {
	return length(v1 - v2);
}
