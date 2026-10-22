extends Node2D

const MAP_WIDTH = 10
const MAP_HEIGHT = 6

const TILE_WIDTH = 64
const TILE_HEIGHT = 32

const MAP_ORIGIN = Vector2(480,75)

var hovered_cell = Vector2i(-1,-1)
var selected_cell = Vector2i(-1,-1)
var unit_cell = Vector2i(3,2)
var unit_selected = false

func _draw() -> void:
	draw_battlefield()
	draw_selected_tile()
	draw_hovered_tile()
	draw_unit(unit_cell)

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

func draw_battlefield():
	for y in range(MAP_HEIGHT):
		for x in range(MAP_WIDTH):
			var center = grid_to_screen(Vector2i(x,y))
			
			var points = PackedVector2Array([
				center + Vector2(0, -TILE_HEIGHT/2.0),
				center + Vector2(TILE_WIDTH/2.0, 0),
				center + Vector2(0, TILE_HEIGHT/2.0),
				center + Vector2(-TILE_WIDTH/2.0, 0)
			])
			
			var tile_color = Color("#668f50")
			
			if (x + y) % 2 == 0:
				tile_color = Color("#729c59")
			
			draw_colored_polygon(points,tile_color)
			
			var outline = PackedVector2Array([
				points[0],
				points[1],
				points[2],
				points[3],
				points[0]
			])
			
			draw_polyline(outline,Color("#405d38"),1.0,true)

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
	
	var points = PackedVector2Array([
		center + Vector2(0, -TILE_HEIGHT/2.0),
		center + Vector2(TILE_WIDTH/2.0, 0),
		center + Vector2(0, TILE_HEIGHT/2.0),
		center + Vector2(-TILE_WIDTH/2.0, 0)
		])
	
	draw_colored_polygon(points, Color(1.0, 0.85, 0.2, 0.45))
	
	draw_polyline(
		PackedVector2Array([
			points[0],
			points[1],
			points[2],
			points[3],
			points[0],
			]),
		Color("#405d38"),
		2.0,
		true
		)

func draw_selected_tile():
	if selected_cell.x < 0:
		return
	
	var center = grid_to_screen(selected_cell)
	
	var points = PackedVector2Array([
		center + Vector2(0, -TILE_HEIGHT/2.0),
		center + Vector2(TILE_WIDTH/2.0, 0),
		center + Vector2(0, TILE_HEIGHT/2.0),
		center + Vector2(-TILE_WIDTH/2.0, 0)
		])
	
	draw_colored_polygon(points, Color(0.2, 0.5, 1.0, 0.45))
	
	draw_polyline(
		PackedVector2Array([
			points[0],
			points[1],
			points[2],
			points[3],
			points[0],
			]),
		Color("#9cc9ff"),
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
				queue_redraw()
