extends Node2D

export(int) var health

func take_damage(damage):
	health -= damage
	# Can add damage effect here
