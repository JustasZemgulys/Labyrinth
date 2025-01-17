# Godot Labyrinth Generation System

## Overview
This project implements a labyrinth generation system in Godot. It demonstrates the following features:
- Recursive Backtracking Algorithm for labyrinth path generation.
- Collision-based system integrated with various labyrinth gameplay elements.
- Auditory feedback when items are collected or structures are used.

## Game Mechanics
- Teleporters: These look like blue circles on the ground. Once entered, they teleport the player to the other half of the labyrinth.
- Fake walls: These are the red versions of regular walls. If a player stays next to one for 3 seconds, it disappears and reappears 5 seconds later. They are one-sided. When their collision zone is entered, they play a sound of rocks falling and another rock sound once disappeared.
- Ghost walls: These are blue versions of regular walls. Every few seconds, one has a chance to appear in a cell alongside a fake wall. They are impassable and disappear after 10 seconds. 
- Key: This is a golden key, and there is only one per labyrinth. If the player is near it, a small tune plays. Once collected, a "ding" sound is played, and the exit door disappears. More likely to spawn in the first half of the labyrinth.
- Exit door: The exit door is identical to regular walls, it blocks the exit.
- Exit: The exit itself is represented by a green circle on the ground. It always spawns at the farthest path end from the entrance. 

### Controls
- Arrow Keys: Moves the player.
- Mouse: Controls the player's camera. 
- Home: Returns to main menu.
- End: Quits the game.
- Escape: Unlocks the mouse from the game screen.
