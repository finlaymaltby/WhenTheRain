TODO:
- Action/Ability resource 
    - store range, cooldown etc.
    - Finish writing sword and shield

- UI
    - Get buttons to use godot native focus + fix hacky pressed focus 'solution'
    - Attach health display to player instance in scene. Make it a child in the big scene.

- PEvent system
    - Attach pevent update to a state update signal
    - actually make it

- Hitbox
    - Better define hitbox and melee_hitbox
    
find . -type f -name '*.gd' -not -path './addons/*' -print0 | xargs -0 cat | wc -l