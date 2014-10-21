extends Node2D

const SHORT_ANIM_TIME = 0.2
const SHORT_ANIM_TIME_2 = 0.25
const MEDIUM_ANIM_TIME = 0.4
const LONG_ANIM_TIME = 0.5

const TWEEN_POSITION_METHOD = "set_pos"
const TWEEN_SCALE_METHOD = "set_scale"
const TWEEN_COLOR_METHOD = "set_modulate"

const SCORE_LABEL_TEXT = "score:"

var screen_size

var cell_obj = null

var screen_bg = null
var grid_bg = null
var cell_array = null

var min_grid_size = 2
var max_grid_size = 7
var curr_grid_size = min_grid_size

var level = 1
var level_diff_cell = null
var level_color_modifer = 1

# test
var tween = null
var tween_cell = null

# ui
var score_label = null


func _ready():
	# get screen size
	screen_size = get_viewport_rect().size
	
	# preload cell resource
	cell_obj = preload("res://cell.res")
	
	grid_bg = get_node("grid_bg")
	var grid_bg_scale = Vector2(screen_size.x * 0.95, screen_size.x * 0.95)
	grid_bg.set_scale(grid_bg_scale)
	var grid_bg_pos = (screen_size - grid_bg_scale) / 2
	grid_bg.set_pos(grid_bg_pos)
	
	# create array of cells
	cell_array = Array()

	var fib = fib(curr_grid_size)
	if (fib < level):
		level_color_modifer = 1
		curr_grid_size = curr_grid_size + 1
	var grid_size = min(curr_grid_size, max_grid_size)
	generate_grid(grid_size, grid_bg)
	
	tween = get_node("tween")
	
	score_label = get_node("ui_layer/score_label")
	score_label.set_size(Vector2(screen_size.x, (screen_size.y - grid_bg_scale.y) / 2))
	
	set_process(true)
	set_process_input(true)
	

func _input(event):
	if (event.type == InputEvent.MOUSE_BUTTON || event.type == InputEvent.SCREEN_TOUCH) && event.is_pressed():
		# clicked
		var rect = get_cell_rect(level_diff_cell)
		if rect.has_point(event.pos):
			# animate score label
			# tween.interpolate_method(score_layer, TWEEN_SCALE_METHOD, Vector2(1.1, 1.1), Vector2(1.0, 1.0), SHORT_ANIM_TIME, Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
			# copy cell for tween animation 
			tween_cell = level_diff_cell.duplicate()
			add_child(tween_cell)
			tween.interpolate_method(tween_cell, TWEEN_SCALE_METHOD, tween_cell.get_scale(), grid_bg.get_scale(), SHORT_ANIM_TIME, Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
			tween.interpolate_method(tween_cell, TWEEN_POSITION_METHOD, tween_cell.get_pos(), grid_bg.get_pos(), SHORT_ANIM_TIME, Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
			tween.interpolate_method(tween_cell, TWEEN_COLOR_METHOD, tween_cell.get_modulate(), grid_bg.get_modulate(), SHORT_ANIM_TIME_2, Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
			tween.start()
			print(str(get_child_count()))
	

func _on_tween_complete(node, key):
	if node == tween_cell:
		if key == TWEEN_SCALE_METHOD:
			print("")
		elif key == TWEEN_COLOR_METHOD:
			tween.stop_all()
			remove_child(tween_cell)
			score_label.set_text(SCORE_LABEL_TEXT + str(level))
			level = level + 1
			level_color_modifer = level_color_modifer + 1
			var fib = fib(curr_grid_size)
			if (fib < level):
				level_color_modifer = 1
				curr_grid_size = curr_grid_size + 1
			var grid_size = min(curr_grid_size, max_grid_size)
			generate_grid(grid_size, grid_bg)
	

func generate_grid(grid_size, grid_bg):
	clear_grid()
	
	var cell_diff_index = get_cell_diff_index(grid_size)
	
	var cell_color = get_cell_color()
	var cell_diff_color = get_cell_diff_color(cell_color)
	
	var grid_bg_scale = grid_bg.get_scale()
	var def_cell_scale = grid_bg_scale / grid_size
	var cell_scale = def_cell_scale * 0.95
	var cell_offset = (grid_bg_scale - cell_scale * grid_size) / (grid_size + 1)
	for i in range(grid_size):
		for j in range(grid_size):
			var cell_inst = cell_obj.instance()
			cell_inst.set_scale(cell_scale)
			var cell_pos = (grid_bg.get_pos() + cell_offset) + (cell_scale + cell_offset) * Vector2(j, i)
			cell_inst.set_pos(cell_pos)
			
			if i * grid_size + j == cell_diff_index:
				cell_inst.set_modulate(cell_diff_color)
				level_diff_cell = cell_inst
			else:
				cell_inst.set_modulate(cell_color)
				
			cell_array.push_back(cell_inst)
			add_child(cell_inst)
	

func clear_grid():
	for i in range(cell_array.size()):
		var cell = cell_array[i]
		remove_child(cell)
		cell = null
	cell_array.clear()
	

func get_cell_diff_index(grid_size):
	randomize()
	return floor(rand_range(0, grid_size * grid_size))
	

func get_cell_color():
	var h = get_cell_color_component()
	return hsv_to_rgb(h, 0.5, 0.5)
	

func get_cell_diff_color(cell_color):
	return hsv_to_rgb(cell_color.h, cell_color.s, cell_color.v + 1.0 / level_color_modifer)
	

func get_cell_color_component():
	randomize()
	return rand_range(0.0, 1.0)
	

func get_cell_rect(cell):
	return Rect2(cell.get_pos(), cell.get_scale())
	

func fib(n):
	var a = 1
	var b = 1
	for i in range(n):
		var c = a + b
		a = b
		b = c
	return b
	

func hsv_to_rgb(h, s, v):
	var c = v * s
	h = fmod((h * 6.0), 6.0)
	var x = c * (1.0 - abs(fmod(h, 2.0) - 1.0))
	
	var color 
	if in_range(h, 0.0, 1.0):
		color = Color(c, x, 0.0)
	elif in_range(h, 1.0, 2.0):
		color = Color(x, c, 0.0)
	elif in_range(h, 2.0, 3.0):
		color = Color(0.0, c, x)
	elif in_range(h, 3.0, 4.0):
		color = Color(0.0, x, c)
	elif in_range(h, 4.0, 5.0):
		color = Color(x, 0.0, c)
	elif in_range(h, 5.0, 6.0):
		color = Color(c, 0.0, x)
	else:
		color = Color(0.0, 0.0, 0.0)
 
	color.r += v - c
	color.g += v - c
	color.b += v - c

	return color
	

func in_range(val, min_val, max_val):
	return min_val <= val && val < max_val
	
