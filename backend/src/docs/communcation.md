USE BINARY DATA WHERE POSSIBLE
Fuck string parsing

- open tcp connection to start server

- wait for players to connect
  - receive player data (tbd)
  - example: 

| data | type |
|-|-|
| packet type (player connected) | 8bit integer | 
| player name length _(pl_n_len)_| 8bit int|
| player name | _pl_n_len_ bytes|
| player id | 64bit identifier |
| selected skin (or color) | 64bit identifier (skin id or 3x8bit color)|

rest can be fetched from server with player id


- wait for player's starting setup

| data | type |
|-|-|
| packet type (starting setup) | 8bit int |
| repeat n times | ... |
| piece type | 8bit int |
| position | 2 x 8bit int |



- start game when both done
- broadcast init board state (no effects)
  
| data | type |
|-|-|
| packet type (init board state) | 8bit int |
| player id (owner) | 64bit identifier |
| repeat n times | ... |
| piece type | 8bit int |
| position | 2 x 8bit int |
| player id (owner) | 64bit identifier |
| repeat n times | ... |
| piece type | 8bit int |
| position | 2 x 8bit int |

- broadcast current throw

| data | type |
|-|-|
| packet type (new round) | 8bit int |
| player id (current) | 64bit identifier |
| throw | 8bit int |

- handle player request for available moves for a piece (might add client side calculation as well)

| data | type |
|-|-|
| packet type (available moves) | 8bit int |
| piece id | 8bit int |
| repeat n times | ... |
| available move | 2 x 8bit int |
| cost | 8bit int |

- wait for player's move

| data | type |
|-|-|
| packet type (player move) | 8bit int |
| piece id | 8bit int |
| target square | 2 x 8bit int |

- broadcast changed board state

| data | type |
|-|-|
| packet type (board state) | 8bit int |
| player id (owner) | 64bit identifier |
| piece id | 8bit int |
| new position | 2 x 8bit int |
| damages (dmg) | 8bit int |
| repeat _dmg_ times | ... |
| target piece id | 8bit int |
| damage done | 8bit int |
| effects applied (fx) | 8bit int |
| repeat _fx_ times | ... |
| effect type | 8bit int |
...

