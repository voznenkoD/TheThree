extends CharacterBody2D

const SPEED = 800.0
const JUMP_VELOCITY = -1400.0
const WEIGHT = 4
@export var dead_texture: Texture2D


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += (get_gravity() * delta) * WEIGHT

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	move_and_slide()

	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider.is_in_group("enemy") and _is_stomping(collision):
			collider.die()
			velocity.y = -300.0
			
func _is_stomping(collision: KinematicCollision2D) -> bool:
	return collision.get_normal().y < -0.5
	
func die() -> void:
	$Sprite2D.texture = dead_texture
	$Sprite2D.offset = Vector2(0, 30)  # tweak until grounded
	$Sprite2D.centered = false
	set_physics_process(false)
