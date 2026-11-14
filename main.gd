extends Node2D

const MAP_WIDTH = 10
const MAP_HEIGHT = 6

const TILE_WIDTH = 64
const TILE_HEIGHT = 32

const MAP_ORIGIN = Vector2(480,75)

const GOBLIN_DAMAGE = 5

const INCAPACITATION_LIMIT = 3

enum Team {
	ALLIES,
	ENEMIES,
	NEUTRAL
}

var current_turn_team:Team = Team.ALLIES

var hovered_cell = Vector2i(-1,-1)
var selected_cell = Vector2i(-1,-1)

var units = [
	{
		"id" = "hero",
		"name" = "Aldric",
		"team" = Team.ALLIES,
		"cell" = Vector2i(3,2),
		"hp" = 20,
		"max_hp" = 20,
		"has_moved" = false,
		"has_acted" = false,
		"is_alive" = true,
		"is_incapacitated" = false,
		"incapacitation_turns" = 0
	},
	{
		"id" = "enemy_01",
		"name" = "Goblin",
		"team" = Team.ENEMIES,
		"cell" = Vector2i(6,3),
		"hp" = 12,
		"max_hp" = 20,
		"has_moved" = false,
		"has_acted" = false,
		"is_alive" = true,
		"is_incapacitated" = false,
		"incapacitation_turns" = 0
	},
	{
		"id" = "elara",
		"name" = "Elara",
		"team" = Team.ALLIES,
		"cell" = Vector2i(2, 4),
		"hp"= 16,
		"max_hp" = 16,
		"has_moved" = false,
		"has_acted" = false,
		"is_alive" = true,
		"is_incapacitated"= false,
		"incapacitation_turns" = 0
	}
]
var selected_unit_index = -1

var unit_cell = Vector2i(3,2)
var unit_selected = false

@onready var name_label: Label = $CanvasLayer/UnitInfoPanel/InfoVBox/NameLabel
@onready var team_label: Label = $CanvasLayer/UnitInfoPanel/InfoVBox/TeamLabel
@onready var hp_label: Label = $CanvasLayer/UnitInfoPanel/InfoVBox/HPLabel
@onready var new_turno_button: Button = $CanvasLayer/UnitInfoPanel/InfoVBox/NewTurnButton
@onready var turn_label: Label = $CanvasLayer/UnitInfoPanel/InfoVBox/TurnLabel
@onready var revive_button: Button = $CanvasLayer/UnitInfoPanel/InfoVBox/ReviveButton

func _draw() -> void:
	draw_battlefield()
	draw_movement_range()
	draw_selected_tile()
	draw_hovered_tile()
	
	for i in range(units.size()):
		var cell = units[i]["cell"]
		
		if is_incapacitated(i) or not is_alive(i):
			draw_incapacitated_unit(cell)
		else:
			draw_unit(cell)
		
		if i == selected_unit_index and is_unit_active(i):
			draw_selected_unit(cell)

func _ready() -> void:
	print(grid_distance(Vector2i(3, 2), Vector2i(5, 3)))
	new_turno_button.pressed.connect(reset_turn)
	revive_button.pressed.connect(_on_revive_button_pressed)	

func _on_revive_button_pressed() -> void:
	revive_unit(0)

func grid_to_screen(cell: Vector2i) -> Vector2:
	var screen_x = (cell.x - cell.y) * TILE_WIDTH / 2.0
	var screen_y = (cell.x + cell.y) * TILE_HEIGHT / 2.0
	return MAP_ORIGIN + Vector2(screen_x, screen_y)

func screen_to_grid(mouse_pos: Vector2) ->Vector2i:
	var local_pos = mouse_pos - MAP_ORIGIN
	
	var u = local_pos.x / (TILE_WIDTH / 2)
	var v = local_pos.y / (TILE_HEIGHT / 2)
	
	var grid_x = (u + v) / 2.0
	var grid_y = (v - u) / 2.0
	
	return Vector2i(
		roundi(grid_x),
		roundi(grid_y)
	)

func grid_distance(a: Vector2i, b: Vector2i) -> int:
	return abs(a.x - b.x) + abs(a.y - b.y)

func is_cell_occupied(cell: Vector2i) -> bool:
	for i in range(units.size()):
		if units[i]["cell"] == cell and is_unit_active(i):
			return true
	return false

func draw_tile(
	center: Vector2,
	fill_color: Color,
	outline_color: Color,
	outline_width: float = 1.0
):
	var points = PackedVector2Array([
		center + Vector2(0, -TILE_HEIGHT/2.0),
		center + Vector2(TILE_WIDTH/2.0, 0),
		center + Vector2(0, TILE_HEIGHT/2.0),
		center + Vector2(-TILE_WIDTH/2.0, 0)
	])
	
	draw_colored_polygon(points,fill_color)
	
	var outline = PackedVector2Array([
		points[0],
		points[1],
		points[2],
		points[3],
		points[0]
	])
	
	draw_polyline(
		outline, outline_color, outline_width, true
	)

func draw_battlefield():
	for y in range(MAP_HEIGHT):
		for x in range(MAP_WIDTH):
			var center = grid_to_screen(Vector2i(x,y))
			
			var tile_color = Color("#668f50")
			
			if (x + y) % 2 == 0:
				tile_color = Color("#729c59")
			
			draw_tile(center, tile_color, Color("#405d38"))

func draw_unit(cell: Vector2i):
	var center = grid_to_screen(cell)
	
	#sombra da unidade
	draw_circle(
		center + Vector2(0,7),
		9,
		Color("#344b30")
	)
	
	# Corpo da unidade
	var body = PackedVector2Array([
		center + Vector2(-7, 1),
		center + Vector2(7, 1),
		center + Vector2(5, -12),
		center + Vector2(-5, -12)
		])
	
	draw_colored_polygon(body, Color("#365fb8"))
	# Cabeça
	draw_circle(
		center + Vector2(0, -17),
		5,
		Color("#e8bd91")
		)

func draw_incapacitated_unit(cell: Vector2i) -> void:
	var center = grid_to_screen(cell)
	
	# Sombra elíptica
	var shadow_points = PackedVector2Array()
	
	for angle in range(16):
		var point_angle = TAU * angle / 16.0
		shadow_points.append(
			center + Vector2(0, 6) +
			Vector2(cos(point_angle) * 12, sin(point_angle) * 5)
		)
	
	draw_colored_polygon(shadow_points, Color("#344b30"))
	
	#corpo deitado da unidade
	var body = PackedVector2Array([
		center + Vector2(-11,-3),
		center + Vector2(7,-5),
		center + Vector2(11,2),
		center + Vector2(-7,5)
	])
	
	draw_colored_polygon(body, Color("#365fb8"))
	
	#cabeça
	draw_circle(
		center + Vector2(12, -3),
		5,
		Color("#e8bd91")
	)

func _process(_delta: float) -> void:
	var mouse_pos = get_local_mouse_position()
	var cell = screen_to_grid(mouse_pos)
	
	if cell.x >= 0 and cell.x < MAP_WIDTH and cell.y >= 0 and cell.y < MAP_HEIGHT:
		hovered_cell = cell
	else:
		hovered_cell = Vector2i(-1, -1)
	
	queue_redraw()

func draw_hovered_tile():
	if hovered_cell.x < 0:
		return
	
	var center = grid_to_screen(hovered_cell)
	
	draw_tile(
		center,
		Color(1.0, 0.85, 0.2, 0.45),
		Color("#fff2a0"),
		2.0)

func draw_selected_tile():
	if selected_cell.x < 0:
		return
	
	var center = grid_to_screen(selected_cell)
	
	draw_tile(
		center,
		Color(0.2, 0.5, 1.0, 0.45),
		Color("#9cc9ff"),
		2.0
	)

func draw_selected_unit(cell: Vector2i):
	var center = grid_to_screen(cell)
	
	draw_arc(
		center + Vector2(0,2),
		14.0,
		0.0,
		TAU,
		32,
		Color("#8de5ff"),
		2.0,
		true
	)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var mouse_pos = get_local_mouse_position()
			var cell = screen_to_grid(mouse_pos)
			
			if cell.x >= 0 and cell.x < MAP_WIDTH and cell.y >= 0 and cell.y < MAP_HEIGHT:
				selected_cell = cell
				
				var clicked_unit_index = -1
				
				# Descobre se existe uma unidade na célula clicada.
				for i in range(units.size()):
					if units[i]["cell"] == cell and is_unit_active(i):
						clicked_unit_index = i
						break
				
				if clicked_unit_index != -1:
					#o clique foi em uma unidade
					var clicked_unit = units[clicked_unit_index]
					
					if clicked_unit_index == selected_unit_index:
						selected_unit_index = -1
					elif clicked_unit["team"] != current_turn_team:
						print("Esta unidade não pertence à equipe do turno atual")
					elif selected_unit_index == -1:
						selected_unit_index = clicked_unit_index					
					else:
						print("Esta célula já está ocupada!")
						
				elif selected_unit_index != -1:
					var unit = units[selected_unit_index]
					
					if unit["has_moved"]:
						print("Esta unidade já se moveu neste turno")
					else:
						var current_cell : Vector2i = units[selected_unit_index]["cell"]
						#unidade pode se deslocar até lá?
						var distance = grid_distance(current_cell, cell)
						
						if distance > 3:
							print("Destino fora do alcance do movimento!")
						elif is_cell_occupied(cell):
							print("Esta célula já está ocupada!")
						else:
							unit["cell"] = cell
							unit["has_moved"] = true
				
				update_unit_info()				
				queue_redraw()


func update_unit_info(unit_index: int = -1):
	var index_to_display = selected_unit_index if unit_index == -1 else unit_index
	
	if index_to_display == -1:
		name_label.text = "Nenhuma unidade"
		team_label.text = "Equipe: —"
		hp_label.text = "HP: —"
		return
	
	var unit = units[index_to_display]
	name_label.text = unit["name"]
	
	match unit["team"]:
		Team.ALLIES:
			team_label.text = "Equipe: Aliados"
		Team.ENEMIES:
			team_label.text = "Equipe: Inimigos"
		Team.NEUTRAL:
			team_label.text = "Equipe: Neutros"
		_:
			team_label.text = "Equipe: Desconhecida"
	
	hp_label.text = "HP: %d / %d" % [unit["hp"], unit["max_hp"]	]

func update_turn_info() -> void:
	if current_turn_team == Team.ALLIES:
		turn_label.text = "TURNO DOS ALIADOS"
	elif current_turn_team == Team.ENEMIES:
		turn_label.text = "TURNO DOS INIMIGOS"
	else:
		turn_label.text = "TURNO NEUTRO"	

func is_cell_in_movement_range(cell: Vector2i) -> bool:
	if selected_unit_index == -1:
		return false
	
	if units[selected_unit_index]["has_moved"]:
		return false
	
	var unit_cell: Vector2i = units[selected_unit_index]["cell"]
	var distance = grid_distance(unit_cell, cell)
	
	return distance <= 3
	
func draw_movement_range() -> void:
	if selected_unit_index == -1:
		return
	
	for x in range(MAP_WIDTH):
		for y in range(MAP_HEIGHT):
			var cell = Vector2i(x, y)
			
			if is_cell_in_movement_range(cell):
				var center = grid_to_screen(cell)
				
				if is_cell_occupied(cell):
					draw_tile(
					center,
					Color(1.0, 0.2, 0.2, 0.35),
					Color(1.0, 0.2, 0.2, 0.8),
					1.0 )
				else:
					draw_tile(
					center,
					Color(0.2, 0.7, 1.0, 0.25),
					Color(0.2, 0.7, 1.0, 0.65),
					1.0 )

func reset_turn() ->void:
	if current_turn_team != Team.ALLIES:
		return
	
	print("Encerrando turno de Aliados!")
	start_turn(Team.ENEMIES)

func start_turn(team: Team) -> void:
	current_turn_team = team
	
	selected_unit_index = -1
	selected_cell = Vector2i(-1, -1)
	
	for i in range(units.size()):
		if units[i]["team"] == current_turn_team:
			units[i]["has_moved"] = false
			
			if is_alive(i) and is_incapacitated(i):
				units[i]["incapacitation_turns"] -= 1
				print(
					units[i]["name"],
					" possui ",
					units[i]["incapacitation_turns"],
					" restantes!"
				)
				
				if units[i]["incapacitation_turns"] <= 0:
					units[i]["is_alive"] = false
					print(
						units[i]["name"],
						"morreu definitivamente!"
					)
			
	
	update_unit_info()
	update_turn_info()
	queue_redraw()
	
	if current_turn_team == Team.ENEMIES:
		run_enemy_turn()

func run_enemy_turn() ->void:
	print("Iniciando turno dos inimigos")
	
	for i in range(units.size()):
		if units[i]["team"] == Team.ENEMIES:
			var enemy = units[i]
			var target_index = find_nearest_ally(enemy["cell"])
						
			if target_index != -1:
				#inimigo escolhe o alvo
				var target = units[target_index]
				print(
					enemy["name"],
					" escolheu ",
					target["name"],
					" como alvo!"
				)
				#inimigo se move para próximo ao alvo
				var destination = find_best_move(enemy["cell"], target["cell"])
				
				if destination != enemy["cell"]:
					units[i]["cell"] = destination
					units[i]["has_moved"] = true
					
					print(enemy["name"], " se moveu para ", destination)					
				else:
					print(enemy["name"], " não encontrou um movimento válido")
				
				# Verifica o alcance de ataque após a movimentação.
				if can_attack(enemy["cell"], target["cell"]):
						print(enemy["name"]," está ao alcance do ataque! ")
						attack(i, target_index)
				else:
						print(enemy["name"], " ainda está longe demais para atacar! ")
			else:
				print(enemy["name"], " não encontrou aliados!")	
	
	print("Turno dos inimigos concluído!")
	start_turn(Team.ALLIES)

func find_nearest_ally(enemy_cell: Vector2i) -> int:
	var nearest_ally_index = -1
	var shortest_distance = 999999
	
	for i in range(units.size()):
		if units[i]["team"] == Team.ALLIES and is_unit_active(i):
			var ally_cell : Vector2i = units[i]["cell"]
			var distance = grid_distance(enemy_cell, ally_cell)
			
			if distance < shortest_distance:
				shortest_distance = distance
				nearest_ally_index = i
	
	return nearest_ally_index

func find_best_move(enemy_cell: Vector2i, target_cell: Vector2i) -> Vector2i:
	var best_cell = enemy_cell
	var shortest_distance = grid_distance(enemy_cell, target_cell)
	
	for x in range(MAP_WIDTH):
		for y in range(MAP_HEIGHT):
			var candidate_cell = Vector2i(x,y)
			
			if is_cell_occupied(candidate_cell):
				continue
			
			var movement_distance = grid_distance(enemy_cell, candidate_cell)
			
			if movement_distance > 3:
				continue
			
			var distance_to_target = grid_distance(candidate_cell, target_cell)
			
			if distance_to_target < shortest_distance:
				shortest_distance = distance_to_target
				best_cell = candidate_cell
	
	return best_cell
	
func can_attack(attacker_cell: Vector2i, target_cell: Vector2i) -> bool:
	return grid_distance(attacker_cell, target_cell) == 1
	
func attack(attacker_index:int, target_index: int) -> void:
	var attacker = units[attacker_index]
	var target = units[target_index]
	
	if not is_unit_active(attacker_index):
		return
	
	if not is_unit_active(target_index):
		return
	
	target["hp"] = max(0, target["hp"] - GOBLIN_DAMAGE)
	
	print(
		attacker["name"],
		" atacou ",
		target["name"],
		" causando ",
		GOBLIN_DAMAGE,
		" pontos de dano!"
	)
	print(
		target["name"],
		" possui agora ",
		target["hp"],
		" HP."
	)
	
	if target["hp"] == 0 and not is_incapacitated(target_index):
		target["is_incapacitated"] = true
		target["incapacitation_turns"] = INCAPACITATION_LIMIT
		
		print(target["name"], " foi incapacitado! ")
		print(
			" Tempo restante para ",
			target["name"],
			" : ",
			target["incapacitation_turns"],
			" turnos!"
		)		
	update_unit_info(target_index)

func is_alive(unit_index: int) -> bool:
	return units[unit_index]["is_alive"]

func is_incapacitated(unit_index: int) -> bool:
	return units[unit_index]["is_incapacitated"]

func is_unit_active(unit_index: int) -> bool:
	return is_alive(unit_index) and not is_incapacitated(unit_index)

func revive_unit(unit_index: int) -> void:
	if not is_alive(unit_index):
		print("Esta unidade morreu definitivamente!")
		return
	
	if not is_incapacitated(unit_index):
		print("Esta unidade não está incapacitada!")
		return
	
	var unit = units[unit_index]
	unit["hp"] = ceili(unit["max_hp"] * 0.5)
	unit["is_incapacitated"] = false
	unit["incapacitation_turns"] = 0
	
	print(
		unit["name"],
		" retornou com ",
		unit["hp"],
		" HP."
	)
	
	update_unit_info(unit_index)
	queue_redraw()
