# Pieces (stats and explanation)

> - [Pawn](#pawn)
> - [Rook](#rook)
> - [Bishop](#bishop)
> - [Knight](#knight)
> - [Queen](#queen)
> - [Jumper](#jumper)

## Pawn

> - Weak piece, with strong ability
> - HP: __5__
> - DMG: __3__
>
> ### Movement
>
> - __Move__: vertical only
> - __Attack__: diagonal, 1 reach
>
> ### Ability
>
> __"Promotion"__
>
> - can be promoted to a stronger piece
> - Requirements:
>   - Roll Cost: 3
>   - Has to be on the opponents last row
> - Extra:
>   - its HP will remain the same
>   - its damage will be the selected piece's `base DMG + 2`

## Rook

> - Average DMG, High HP
> - HP: __9__
> - DMG: __4__
>
> ### Movement
>
> - __Move__: horizontal and vertical
> - __Attack__: horizontal and vertical, no limit
>
> ### Ability
>
> __"Charge Attack"__
>
> - Can attack with double DMG
> - Requirements:
>   - Roll Cost: 5
>   - opponent must be in reach
> - Extra:
>   - can do collateral damage

## Bishop

> - Average HP, Average DMG
> - HP: __8__
> - DMG: __5__
>
> ### Movement
>
> - __Move__: diagonal
> - __Attack__: diagonal, no limit
>
> ### Ability
>
> __"Color Swap"__
>
> - Can change it's tile color (moving 1 tile horizontally or vertically)
> - Requirements:
>   - Roll Cost: 3
>   - at least 1 neighbouring tile must be free
> - Extra:
>   - This will allow the bishop to stay relevant, if the other bishop is dead

## Knight

> - Low HP, High DMG
> - HP: __5__
> - DMG: __8__
>
> ### Movement
>
> - __Move__: L shape, 1 in a row
> - __Attack__: L shape, 1 in a row
> - can jump over pieces
>
> ### Ability
>
> __"Knight's Blink"__
>
> - Can move to a different any other tile in a limited range depending on roll
> - Requirements:
>   - Roll Cost: 5
>   - tile of choice must be free
> - Extra:
>   - can allow the knight to get into better position, while risking getting hit

## Queen

> - Very High HP, Very Low DMG
> - HP: __15__
> - DMG: __2__
>
> ### Movement
>
> - __Move__: both diagonal, vertical and horizontal, no limit
> - __Attack__: both diagonal, vertical and horizontal, no limit
>
> ### Ability
>
> __"Healing Aura"__
>
> - The Queen can emit a healing aura that restores the health of all friendly pieces within a certain radius of her. 
> - Requirements:
>   - Roll Cost: 5
>   - At least one friendly piece must be within range of the Queen's aura.
> - Extra:
>   - The amount of health restored is based on the Queen's roll and the distance of the friendly piece from the Queen.

# Custom Pieces

## Warrioress

> - Average HP, Average DMG, High mobility
> - HP: __7__
> - DMG: __4__
>
> ### Movement
>
> - __Move__: Distance of thrown dice with euclidean distance
> - __Attack__: Distance of thrown dice with euclidean distance
> - can jump over pieces
> - can move through enemy pieces
> - can't attack through enemy pieces
>
> ### Ability
>
> __"Divine Blessing"__
>
> - By sacrificing 2 HP, the Warrioress can respawn back after death
> - Requirements:
>  - Roll Cost: 6
> - Extra:
> - The Warrioress will next to the King after respawning
> - The Warrioress will have 1 HP after respawning
> - The Warrioress can't use this ability if the King is dead

## Sniper

> - Average HP, High DMG, Low mobility
> - HP: __6__
> - DMG: __15__
>
> ### Movement
>
> - __Move__: Only on rows
> - __Attack__: Only on columns
>
> ### Ability
>
> __"Piercing Shot"__
>
> - Can attack collinear pieces in a straight line
> - Requirements:
>  - Roll Cost: 6
> - Extra:
> - The first piece hit will die, the rest will take high dmg
> - Will damage friendly pieces as well
> - Will not move the Sniper

# ChatGPT suggestions

## Jumper

> - Average HP, Average DMG
> - HP: 8
> - DMG: 5
>
> ### Movement
>
> - __Move__: Jump to any tile on the board
> - __Attack__: Jump to any tile on the board, 3 reach (manhattan distance)
>
> ### Ability
>
> __"Stalker"__
>
> - Can teleport behind an enemy piece and attack them from behind
> - Requirements:
>   - Roll Cost: 5
>   - The target piece must be within 5 tiles of the Jumper
> - Extra:
>   - If the attack is successful, the target piece will be stunned and unable to move on their next turn.