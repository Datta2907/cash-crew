extends Control

# --- Viewport Setup ---
@onready var top_view = $VBoxContainer/TopViewContainer/TopView
@onready var bottom_view = $VBoxContainer/BottomViewContainer/BottomView
var top_view_size: Vector2
var bottom_view_size: Vector2

# --- Spawning Logic ---
@export var enemy_scene: PackedScene
var max_enemies_per_world := 3
var total_waves := 5

var top_world_spawner = { "total_to_spawn": 0, "spawned_count": 0, "alive_count": 0 }
var bottom_world_spawner = { "total_to_spawn": 0, "spawned_count": 0, "alive_count": 0 }

# --- Player/World References ---
var player_top: Node2D
var player_bottom: Node2D
var world_top: Node
var world_bottom: Node

# --- Map Boundary Variables ---
var top_map_start_x: float
var top_map_end_x: float
var bottom_map_start_x: float
var bottom_map_end_x: float

# --- NEW: Win/Lose Scene Variables ---
@export var success_scene: PackedScene
@export var fail_scene: PackedScene
var game_is_over = false


func _ready():
	# Calculate total enemies
	top_world_spawner.total_to_spawn = max_enemies_per_world * total_waves
	bottom_world_spawner.total_to_spawn = max_enemies_per_world * total_waves
	
	await get_tree().create_timer(0.1).timeout
	update_viewport_sizes()
	get_tree().get_root().size_changed.connect(update_viewport_sizes)
	
	world_top = top_view.get_node("World")
	player_top = world_top.get_node("Bruce")
	world_bottom = bottom_view.get_node("World2")
	player_bottom = world_bottom.get_node("Robin")
	
	top_map_start_x = world_top.get_node("MapStart").global_position.x
	top_map_end_x = world_top.get_node("MapEnd").global_position.x
	bottom_map_start_x = world_bottom.get_node("MapStart").global_position.x
	bottom_map_end_x = world_bottom.get_node("MapEnd").global_position.x

	# --- NEW: Connect the player death signals ---
	if is_instance_valid(player_top):
		player_top.player_died.connect(_on_player_died)
	if is_instance_valid(player_bottom):
		player_bottom.player_died.connect(_on_player_died)


func _on_spawn_timer_timeout():
	try_spawn_enemy(world_top, player_top, top_world_spawner, top_view_size, top_map_start_x, top_map_end_x)
	try_spawn_enemy(world_bottom, player_bottom, bottom_world_spawner, bottom_view_size, bottom_map_start_x, bottom_map_end_x)


func try_spawn_enemy(world_node, player_node, spawner, view_size, map_start, map_end):
	if game_is_over: return # Don't spawn if game is over
	
	if spawner.alive_count >= max_enemies_per_world:
		return 
	if spawner.spawned_count >= spawner.total_to_spawn:
		return
	if not is_instance_valid(player_node):
		return

	spawner.alive_count += 1
	spawner.spawned_count += 1
	
	var enemy = enemy_scene.instantiate()

	var x_offset = (view_size.x / 2) + 100
	var y_top_of_screen = player_node.global_position.y - (view_size.y / 2)
	var y_pos = y_top_of_screen - 100 
	var x_pos = 0.0
	
	var spawn_pos_right = player_node.global_position.x + x_offset
	
	if spawn_pos_right < map_end:
		x_pos = spawn_pos_right
	else:
		var spawn_pos_left = player_node.global_position.x - x_offset
		x_pos = clamp(spawn_pos_left, map_start, map_end) 

	enemy.global_position = Vector2(x_pos, y_pos)
	enemy.player_target = player_node 
	enemy.enemy_died.connect(_on_enemy_died.bind(spawner))
	world_node.add_child(enemy)
	
	print("Spawned enemy. Total alive: ", spawner.alive_count, " / Total spawned: ", spawner.spawned_count)


func _on_enemy_died(spawner):
	if game_is_over: return
	
	spawner.alive_count -= 1
	print("Enemy died. Total alive: ", spawner.alive_count)

	# --- NEW: Check for success ---
	check_for_win_condition()


# --- NEW: Win/Lose Functions ---

func check_for_win_condition():
	# Check if all spawners are finished AND all enemies are dead
	var top_complete = top_world_spawner.spawned_count == top_world_spawner.total_to_spawn and top_world_spawner.alive_count == 0
	var bottom_complete = bottom_world_spawner.spawned_count == bottom_world_spawner.total_to_spawn and bottom_world_spawner.alive_count == 0
	if top_complete and bottom_complete:
		_game_over(true) # Pass 'true' for success

func _on_player_died():
	_game_over(false) # Pass 'false' for fail
	
func _game_over(did_win: bool):
	if game_is_over:
		return # Avoid running twice
	get_tree().paused = true
	game_is_over = true
	$SpawnTimer.stop() # Stop spawning new enemies
	
	if did_win:
		print("--- GAME WON! ---")
		if success_scene:
			add_child(success_scene.instantiate())
	else:
		print("--- GAME FAILED! ---")
		if fail_scene:
			add_child(fail_scene.instantiate())

# --- Viewport Sizing (no changes) ---
func update_viewport_sizes():
	var top_container = $VBoxContainer/TopViewContainer
	var bottom_container = $VBoxContainer/BottomViewContainer
	if top_container:
		top_view_size = top_container.size
		if top_view_size.x > 0 and top_view_size.y > 0:
			top_view.size = top_view_size
	if bottom_container:
		bottom_view_size = bottom_container.size
		if bottom_view_size.x > 0 and bottom_view_size.y > 0:
			bottom_view.size = bottom_view_size
