# Project Zomboid In-Game map mod

This is a mod for the game Project Zomboid that adds an in-game map.

# Project Goal

Providing an in-game map with the following capabilities:

- Very important: NO RADAR MAP!
  The map should not automatically show surroundings, player location, zombie location, etc.
- Player must draw map
  This is a direct result of the first bullet. The player must somehow actively engage in map drawing. This might be by manually dragging tiles, starting an action to draw the surroundings or even drawing surroundings while moving around (with limitations).
- Map information is taken directly out of the running game
  This means that destroyed buildings, player-built structures, etc. are correctly displayed on the map.
- Fake drawing
  Overriding the previous bullet, player may fake information on the map for Multiplayer-Role-Playing elements.


# Ideas

Collection of ideas that might be implemented one way or another

- Tile based road/floor drawing that gives it a pen drawn map look
  using high-contrast white-on-transparent PNG images and tinting
- Pen/Paper inventory item related drawing, while you walk around
- Spiffos having a 'you are here' that updates your map with the area, etc
  Somewhat similiar to the map drawing in Miasmata
- Possibility of finding segments of the map around the place
- Basic ability to add notes to a map at locations, tied to inventory item
- Copying of maps to hand to other people, copying map + markers

