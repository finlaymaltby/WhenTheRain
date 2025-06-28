TODO:
- Action/Ability resource 
    - store range, cooldown etc.
    - Finish writing sword and shield
	- Cancel weapon should have to await. Overhaul for auto_weapon as well
	- use a mutex for focus https://docs.godotengine.org/en/stable/classes/class_mutex.html#class-mutex

- UI
    - Get buttons to use godot native focus + fix hacky pressed focus 'solution'
    - Attach health display to player instance in scene. Make it a child in the big scene.

- PEvent system
    - Attach pevent update to a state update signal
    - actually make it

- Hitbox
    - Better define hitbox and melee_hitbox
    

GET RID OFO ALL STATIC FUNC FROM. REMOVE PRINTS AND BREAKPOOINT S
investigate abstract classes
find . -type f -name '*.gd' -not -path './addons/*' -print0 | xargs -0 cat | wc

Dialogue balloon
- waiting for auto advance should be done by the dialogue label

should just write my own dialogue system at this point
- Fix messed up naming system, alias, name, ident, q ident, 
- Add global signal jumps
- title is a label or a heading
- make it so you can create variables in dialogue
- 