extends CharacterBody2D

@export var speed: float = 150.0
var bullet_scene = preload("res://enemy_bullet.tscn")
@export var shoot_cooldown: float = 3.0
@export var far_bullet_speed: float = 800.0
@export var normal_bullet_speed: float = 800.0
signal enemy_died
var health: int = 100

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var has_landed: bool = false

var player_target: Node2D = null
var stop_distance: float = 150.0

var can_shoot: bool = true
var is_dead: bool = false
var is_hurt: bool = false

@onready var sprite = $AnimatedSprite2D 
@onready var shoot_cooldown_timer = $ShootCooldownTimer

func _ready():
	if sprite == null:
		printerr("ERROR: 'AnimatedSprite2D' node not found!")
		return
	if shoot_cooldown_timer == null:
		printerr("ERROR: 'ShootCooldownTimer' node not found!")
		return
		
	sprite.connect("animation_finished", _on_animation_finished)
	shoot_cooldown_timer.connect("timeout", _on_shoot_cooldown_timeout)
	
	stop_distance = 150 if randi() % 2 == 0 else 1000

func _physics_process(delta: float) -> void:
	if is_dead or is_hurt or not player_target:
		if not is_on_floor():
			velocity.y += gravity * delta
		
		velocity.x = 0
		move_and_slide()
		return

	if not is_on_floor():
		velocity.y += gravity * delta

	if player_target.global_position.x < global_position.x:
		sprite.flip_h = true
	else:
		sprite.flip_h = false

	if has_landed and can_shoot:
		shoot()

	var current_animation = sprite.animation
	if current_animation != "shoot" and current_animation != "hurt" and current_animation != "dead":
		
		var distance_to_player = global_position.distance_to(player_target.global_position)
		if has_landed and distance_to_player > stop_distance:
			var dir = (player_target.global_position - global_position).normalized()
			velocity.x = dir.x * speed
			if sprite.animation != "run":
				sprite.play("run")
		else:
			velocity.x = 0
			if has_landed and sprite.animation != "idle":
				sprite.play("idle")
	
	move_and_slide()

	if is_on_floor():
		has_landed = true

func shoot() -> void:
	if is_dead or not player_target:
		return
	
	can_shoot = false
	sprite.play("shoot")
	
	var bullet = bullet_scene.instantiate()
	if bullet == null:
		printerr("ERROR: Bullet scene failed to instantiate!")
		return
		
	bullet.global_position = global_position
	bullet.speed = far_bullet_speed if stop_distance > 500 else normal_bullet_speed
	bullet.direction = (player_target.global_position - global_position).normalized()
	get_parent().add_child(bullet)

func _on_animation_finished():
	var anim_name = sprite.animation
	
	if anim_name == "shoot":
		sprite.play("idle")
		shoot_cooldown_timer.wait_time = shoot_cooldown
		shoot_cooldown_timer.start()
		
	elif anim_name == "hurt":
		is_hurt = false
		sprite.play("idle")

func _on_shoot_cooldown_timeout():
	can_shoot = true

func take_damage(amount: int):
	if is_dead:
		return

	health -= amount

	if health <= 0:
		die()
	else:
		if not is_hurt:
			is_hurt = true
			sprite.play("hurt")
			velocity = Vector2.ZERO

func die():
	if is_dead: return
	is_dead = true
	velocity = Vector2.ZERO
	sprite.play("dead") 
	await get_tree().create_timer(1.0).timeout
	enemy_died.emit()
	queue_free()
