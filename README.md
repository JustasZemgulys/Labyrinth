# Godot Labyrinth Generation System

## Overview
This project implements a labyrinth generation system in Godot. It demonstrates the following features:
- Recursive Backtracking Algorithm for labyrinth path generation.
- Collision-based system integrated with various labyrinth gameplay elements.
- Auditory feedback when items are collected or structures are used.

## Game Mechanics
- Teleporters: These are blue circles on the ground. Once entered, they teleport the player to the second half of the labyrinth.
- Fake walls: These are darker versions of regular walls. If a player stays next to one for 3 seconds, it disappears and reappears 5 seconds later. They are one-sided. When their collision zone is entered, they play a sound of rocks falling.
- Ghost walls: These are bluer versions of regular walls. Every few seconds, one has a chance to appear in a cell alongside a fake wall. They are impassable and disappear after 10 seconds. 
- Key: This is a golden key, and there is only one per labyrinth. If the player is near it, a small tune plays. Once collected, a "ding" sound is played, and the exit door disappears.
- Exit door: The exit door is identical to regular walls, it blocks the exit.
- Exit: The exit itself is represented by a green circle on the ground. It always spawns at the farthest path end from the entrance. 

## Controls
- Arrow Keys: Moves the player.
- Mouse: Controls the player's camera. 
- Home: Returns to main menu.
- End: Quits the game.
- Escape: Unlocks the mouse from the game screen.

## Versions
- The regular: has high walls, darker enviroment, less visible special wall colours.
- The simplified: has low walls, lighter enviroment, more visible special wall colours.
