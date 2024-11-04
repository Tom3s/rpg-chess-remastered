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
