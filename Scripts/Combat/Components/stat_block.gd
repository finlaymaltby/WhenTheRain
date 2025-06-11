extends Resource
class_name StatBlock


## Slicey, sharp type damage
## Imagine how good the attack would be at cutting into steak
@export var slice: float
## Smash:
## Smashy, bash type damage
## Imagine hwo good the attack would be at destroying an aluminium tin
@export var smash: float

static func from_vec(damage: Vector3) -> StatBlock:
	var stats := StatBlock.new()
	stats.damage = damage
	return stats

	
func dot(other: StatBlock) -> float:
	return (slice * other.slice) + (smash * other.smash)

func reduce(other: StatBlock) -> void:
	slice = clampf(slice - other.slice, 0, INF)
	smash = clampf(smash - other.smash, 0, INF)

func sum() -> float:
	return slice + smash
	
## 1 - v
func complement() -> StatBlock:
	var stats := StatBlock.new()
	stats.slice = 1 - slice
	stats.smash = 1 - smash
	return stats

func is_zero() -> bool:
	return slice == 0 and smash == 0
