package main

import "core:fmt"
import "core:math/rand"
import "core:os"

App_State :: struct {
	current_player: u8,
	// board: 
	p1dice: [6]int,
	p2dice: [6]int,

}

reset_dice :: proc(dice: ^[6]int) {
	dice^ = {1, 2, 3, 4, 5, 6};
	rand.shuffle(dice[:]);
	fmt.println("New dice bag: ", dice);
}

init_app_state :: proc(state: ^App_State) {
	reset_dice(&state.p1dice);
	reset_dice(&state.p2dice);
}

get_next_dice_throw :: proc(state: ^App_State) -> int {
	throw: int = -1;

	if state.p1dice[5] == -1 do reset_dice(&state.p1dice);
	if state.p2dice[5] == -1 do reset_dice(&state.p2dice);

	for i in 0..<6 {
		if state.current_player == 0 {
			if state.p1dice[i] != -1 {
				throw = state.p1dice[i];
				state.p1dice[i] = -1;
				return throw;
			}
		} else {
			if state.p2dice[i] != -1 {
				throw = state.p2dice[i];
				state.p2dice[i] = -1;
				return throw;
			}
		}
	}
	return -1;
}

main :: proc() {
	// initialize game

	state: App_State;
	init_app_state(&state);

	// fmt.println(state.p1dice);
	// fmt.println(state.p2dice);

	for i in 0..<24{
		// get input

		// buf: [256]byte
		// fmt.println("Press enter:")
		// n, err := os.read(os.stdin, buf[:])
		// if err != nil {
		// 	fmt.eprintln("Error reading: ", err)
		// 	return
		// }
		// str := string(buf[:n])
		
		// update game logic
		current_throw := get_next_dice_throw(&state);
		fmt.println("Player ", state.current_player+1, ": ", current_throw);

		state.current_player = (state.current_player + 1) % 2;
		// broadcast changes
	}
}