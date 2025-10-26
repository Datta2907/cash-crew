extends Area2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 1000.0
var damage: int = 10

func _ready():
	pass

func _physics_process(delta: float):
	global_position += direction * speed * delta

func _on_body_entered(body):
	if body.is_in_group("enemy"):
		body.take_damage(damage)

	queue_free()

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()
