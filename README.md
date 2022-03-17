# Fire-Emblem

![screenshot](Sprites/screenshot.PNG)

## Description
Fire-Emblem is a clone of the real game boy game Fire Emblem. Fire-Emblem is a turn based game where the user controlls several blue-colored 'Players'. The goal of the game is to kill the enemies without dying.

## Install

Prerequisties install opam as per OS instructions, then.

``` shell
# Setup 4.13.1 opam switch
opam switch create 4.13.1-fire-emblem 4.13.1
opam switch link 4.13.1-fire-emblem

# Install ocaml dependencies
opam install . --deps-only --yes --with-test

# Build
dune build @all

# Open index.html in a browser like Chrome
```

## Game Play

### Selection
When in the game, you will see various players, enemies, items, and menus. Using 'Z' you can select players to move by pressing on the currently active character. You can tell who the currently active character is by pressing 'A'. 'A' will automatically transfer the cursor over to the currently active character. You can also use 'Z' on enemies to see their range of movement, on menus when you need to select a choice on the menu, and on the ground when you want to end your turn. You can press 'X' to deselect something that has already been selected.

### Movement
When you press 'Z' when the cursor is on a player, an arrangement of blue and red tiles will appear. The blue tiles signify where the current character can move to. Red tiles signify tiles that the player can attack but cannot move to.

### Attacking
After movement, you have the option to attack. If you click on Attack, you will then have to choose an item to attack with. Once you choose an item, red tiles will appear on the map signifying where attacking is possible. If an enemy is on the red tile, simply press 'Z' when the cursor is on that tile. If no enemies are on any red tiles, you must deselect using 'X' and choose another option

## Authors
- Frank Rodriguez [@frodr33](https://github.com/frodr33)
- Albert Tsao
- Darren Tsai
- Ray Gu

## NOTE
Albert Tsao is not included in the statistics for some reason



