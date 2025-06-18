class_name DamageStats extends Resource

## Slicey, sharp type damage
## Imagine how good the attack would be at cutting into steak
@export var slice: float
## Smash:
## Smashy, bash type damage
## Imagine hwo good the attack would be at destroying an aluminium tin
@export var smash: float

static func from_vec(damage: Vector3) -> DamageStats:
	var stats := DamageStats.new()
	stats.damage = damage
	return stats

func dot(other: DamageStats) -> float:
	return (slice * other.slice) + (smash * other.smash)

## multiply each component of the stat block by a scalar
func times(scalar: float) -> DamageStats:
	var new := self.duplicate()
	new.slice *= scalar
	new.smash *= scalar
	return new

## subtract another statblock, clamping values to be >= 0
func take(other: DamageStats) -> DamageStats:
	var new := self.duplicate()
	new.slice = clampf(slice - other.slice, 0, INF)
	new.smash = clampf(smash - other.smash, 0, INF)
	return

func sum() -> float:
	return slice + smash
	
## 1 - v
func complement() -> DamageStats:
	var stats := DamageStats.new()
	stats.slice = 1 - slice
	stats.smash = 1 - smash
	return stats

func is_zero() -> bool:
	return slice == 0 and smash == 0
