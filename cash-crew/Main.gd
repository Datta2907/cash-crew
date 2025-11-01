extends Control

@onready var top_view = $VBoxContainer/TopViewContainer/TopView
@onready var bottom_view = $VBoxContainer/BottomViewContainer/BottomView

@onready var p1_camera = $VBoxContainer/TopViewContainer/TopView/P1_Camera
@onready var p2_camera = $VBoxContainer/BottomViewContainer/BottomView/P2_Camera

var top_view_size: Vector2
var bottom_view_size: Vector2

@export var enemy_scene: PackedScene
@onready var spawn_timer = $SpawnTimer
var max_enemies_alive := 3
var total_enemies_per_location := 15
var current_enemies_alive := 0
var top_spawned_count := 0
var bottom_spawned_count := 0
var spawn_from_top := true

var player_top: Node2D
var player_bottom: Node2D
var deliver_1_area: Area2D
var deliver_2_area: Area2D

var top_spawner: Marker2D
var topp_spawner: Marker2D
var bottom_spawner: Marker2D
var bottomm_spawner: Marker2D

@onready var success_screen = $UI/SuccessScreen
@onready var fail_screen = $UI/FailScreen

var bruce_in_win_area := false
var robin_in_win_area := false
var game_is_over := false

func _ready():
	await get_tree().create_timer(0.1).timeout
	update_viewport_sizes()
	get_tree().get_root().size_changed.connect(update_viewport_sizes)
	
	bottom_view.world_2d = top_view.world_2d
	
	var world_node = $VBoxContainer/TopViewContainer/TopView/World
	
	player_top = world_node.get_node("Bruce")
	player_bottom = world_node.get_node("Robin")
	
	deliver_1_area = world_node.get_node("WinAreas/deliver_1")
	deliver_2_area = world_node.get_node("WinAreas/deliver_2")
	
	top_spawner = world_node.get_node("top")
	topp_spawner = world_node.get_node("topp")
	bottom_spawner = world_node.get_node("bottom")
	bottomm_spawner = world_node.get_node("bottomm")
	
	player_top.global_position = world_node.get_node("Bruce").global_position
	player_bottom.global_position = world_node.get_node("Robin").global_position

	player_top.player_died.connect(_on_player_died)
	player_bottom.player_died.connect(_on_player_died)
	
	deliver_1_area.body_entered.connect(_on_deliver_1_entered)
	deliver_1_area.body_exited.connect(_on_deliver_1_exited)
	deliver_2_area.body_entered.connect(_on_deliver_2_entered)
	deliver_2_area.body_exited.connect(_on_deliver_2_exited)
	
	success_screen.visible = false
	fail_screen.visible = false

func _physics_process(_delta: float):
	if is_instance_valid(player_top):
		p1_camera.position = player_top.position
	
	if is_instance_valid(player_bottom):
		p2_camera.position = player_bottom.position

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

func _on_spawn_timer_timeout():
	if game_is_over:
		spawn_timer.stop()
		return
	if current_enemies_alive >= max_enemies_alive:
		return
	var all_spawned = (top_spawned_count >= total_enemies_per_location) and (bottom_spawned_count >= total_enemies_per_location)
	if all_spawned:
		return
	
	var spawn_point_node = null
	var player_to_follow = null
	
	if spawn_from_top:
		if top_spawned_count < 6:
			spawn_point_node = top_spawner
			top_spawned_count += 1
		elif top_spawned_count < total_enemies_per_location:
			spawn_point_node = topp_spawner
			top_spawned_count += 1
		
		player_to_follow = player_top
		spawn_from_top = false
		
	else:
		if bottom_spawned_count < 6:
			spawn_point_node = bottom_spawner
			bottom_spawned_count += 1
		elif bottom_spawned_count < total_enemies_per_location:
			spawn_point_node = bottomm_spawner
			bottom_spawned_count += 1
			
		player_to_follow = player_bottom
		spawn_from_top = true
	
	if spawn_point_node != null:
		current_enemies_alive += 1
		var enemy = enemy_scene.instantiate()
		enemy.global_position = spawn_point_node.global_position
		
		if is_instance_valid(player_to_follow):
			enemy.player_target = player_to_follow
		else: 
			enemy.player_target = player_top if player_to_follow == player_bottom else player_bottom
		
		enemy.enemy_died.connect(_on_enemy_died)
		$VBoxContainer/TopViewContainer/TopView/World.add_child(enemy) 
	elif not all_spawned:
		spawn_from_top = not spawn_from_top

func _on_enemy_died():
	current_enemies_alive -= 1
	check_for_win_condition()

func _on_player_died():
	if game_is_over: return
	game_is_over = true
	fail_screen.visible = true
	get_tree().paused = true

func _on_deliver_1_entered(body):
	if body == player_top:
		bruce_in_win_area = true
		check_for_win_condition()
		
func _on_deliver_1_exited(body):
	if body == player_top:
		bruce_in_win_area = false
		check_for_win_condition()
		
func _on_deliver_2_entered(body):
	if body == player_bottom:
		robin_in_win_area = true
		check_for_win_condition()
		
func _on_deliver_2_exited(body):
	if body == player_bottom:
		robin_in_win_area = false
		check_for_win_condition()

func check_for_win_condition():
	if game_is_over: return
	var all_enemies_spawned = (top_spawned_count == total_enemies_per_location) and (bottom_spawned_count == total_enemies_per_location)
	var all_enemies_dead = current_enemies_alive == 0
	var both_players_in_area = bruce_in_win_area and robin_in_win_area
	
	if all_enemies_spawned and all_enemies_dead and both_players_in_area:
		game_is_over = true
		success_screen.visible = true
		get_tree().paused = true
