class_name Unit
extends RefCounted

#identificação
var id: String
var unit_name: String
var team: int

#posição no tabuleiro
var cell: Vector2i

#Atributos básicos
var hp: int
var max_hp: int

#Estado durante a batalha
var has_moved: bool = false
var has_acted: bool = false
var is_alive: bool = true
var is_incapacitated: bool = false
var incapacitation_turns: int = 0

#Construtor
func _init(
	unit_id: String,
	unit_name_value: String,
	unit_team: int,
	initial_cell: Vector2i,
	initial_hp: int,
	maximum_hp: int) -> void:
		id = unit_id
		unit_name = unit_name_value
		team = unit_team
		cell = initial_cell
		hp = initial_hp
		max_hp = maximum_hp
