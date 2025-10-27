extends CharacterBody2D

var health: int = 100

var gravity = 400
var walkingVelocity = 100
var sprintingVelocity = 200
var jumpVelocity = -250
var facing_right = true
var jumpCount = 0
var isDead = false
var isHurt = false
signal player_died
var bullet_scene = preload("res://bullet.tscn")
@export var shoot_cooldown := 0.1
var can_shoot := true

@onready var sprite = $AnimatedSprite2D
@onready var shoot_timer = $ShootTimer

func _ready():
	sprite.connect("animation_finished", _on_animation_finished)
	if shoot_timer:
		shoot_timer.wait_time = shoot_cooldown
		shoot_timer.connect("timeout", _on_shoot_timer_timeout)

func shoot():
	var bullet = bullet_scene.instantiate()
	bullet.global_position = $muzzle.global_position
	
	if facing_right:
		bullet.direction = Vector2.RIGHT
		bullet.rotation = 0
	else:
		bullet.global_position += Vector2(-30, 2)
		bullet.direction = Vector2.LEFT
		bullet.rotation = PI
	get_parent().add_child(bullet)
	
	can_shoot = false
	if shoot_timer:
		shoot_timer.start()

func _physics_process(delta: float) -> void:
	if isDead:
		if !is_on_floor():
			velocity.y += gravity * delta
		velocity.x = 0
		move_and_slide()
		_set_anim("Dead")
		return

	if !is_on_floor():
		velocity.y += gravity * delta
	else:
		jumpCount = 0

	var did_shoot_this_frame = false
	if Input.is_action_just_pressed("p2_shoot") and can_shoot:
		shoot()
		did_shoot_this_frame = true

	if Input.is_action_pressed("p2_right"):
		velocity.x = sprintingVelocity if Input.is_action_pressed("p2_run") else walkingVelocity
		facing_right = true
		$AnimatedSprite2D.flip_h = false
	elif Input.is_action_pressed("p2_left"):
		velocity.x = -sprintingVelocity if Input.is_action_pressed("p2_run") else -walkingVelocity
		facing_right = false
		$AnimatedSprite2D.flip_h = true
	else:
		velocity.x = 0
	
	if Input.is_action_pressed("p2_jump") and (is_on_floor() or jumpCount < 2):
		velocity.y = jumpVelocity
		jumpCount += 1

	if Input.is_action_pressed("p2_down") and !is_on_floor():
		velocity.y += gravity * 2 * delta

	move_and_slide()

	if did_shoot_this_frame:
		_set_anim("Shot")
	elif isHurt:
		_set_anim("Hurt")
	elif !is_on_floor():
		_set_anim("Jump")
	elif velocity.x != 0:
		_set_anim("run" if Input.is_action_pressed("p2_run") else "Walk")
	else:
		_set_anim("Idle")

func _set_anim(anim_name: String) -> void:
	if $AnimatedSprite2D.animation != anim_name:
		$AnimatedSprite2D.animation = anim_name
		$AnimatedSprite2D.play()

func _on_animation_finished():
	var anim_name = sprite.animation
	
	if anim_name == "Hurt":
		isHurt = false
		_set_anim("Idle")
	
	if anim_name == "Shot":
		_set_anim("Idle")

func _on_shoot_timer_timeout():
	can_shoot = true

func take_damage(amount: int):
	if isDead or isHurt:
		return

	health -= amount
	print("Robin health: ", health)
	
	if health <= 0:
		health = 0
		die()
	else:
		isHurt = true

func die() -> void:
	if isDead:
		return
	player_died.emit()
	isDead = true
	velocity = Vector2.ZERO
	print("Robin has died.")
