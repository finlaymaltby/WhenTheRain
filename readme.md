TODO:
- Action/Ability resource 
    - store range, cooldown etc.
    - Finish writing sword and shield
	- Cancel weapon should have to await. Overhaul for auto_weapon as well

- UI
    - Get buttons to use godot native focus + fix hacky pressed focus 'solution'
    - Attach health display to player instance in scene. Make it a child in the big scene.

- PEvent system
    - Attach pevent update to a state update signal
    - actually make it

- Hitbox
    - Better define hitbox and melee_hitbox
    

GET RID OFO ALL STATIC FUNC FROM. REMOVE PRINTS AND BREAKPOOINT S
find . -type f -name '*.gd' -not -path './addons/*' -print0 | xargs -0 cat | wc

should just write my own dialogue system at this point