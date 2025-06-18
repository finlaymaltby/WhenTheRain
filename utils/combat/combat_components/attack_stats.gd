class_name AttackStats extends Resource

## the damage the attack will do 
@export var damage: DamageStats

## how many pixels you would have to be away 
@export var attack_range: float

## how long it takes until the attack is live from rest
@export var prep_time: float

## how long it takes to return to rest after live
@export var recovery_time: float

## classify the type of attack
@export var attack_type: AttackType


enum AttackType {
	Melee,
	Projectile
}