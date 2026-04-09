extends CharacterBody2D

const SPEED = 100.0
const CHASE_SPEED = 300.0
const GRAVITY_WEIGHT = 8
const PATROL_DISTANCE = 200.0
const CHASE_RANGE = 700.0
const COOLDOWN_RANGE = 1000.0

var direction := 1.0
var start_position := Vector2.ZERO
var is_chasing := false
var is_dead := false

@export var patrol_texture: Texture2D
@export var chase_texture: Texture2D
@export var dead_texture: Texture2D

@onready var target = $"../Player"

func _ready() -> void:
	start_position = global_position
	$Area2D.body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta * GRAVITY_WEIGHT
	_update_chase_state()
	if is_chasing:
		_chase_player()
	else:
		_patrol()
	if velocity.x != 0:
		$Sprite2D.flip_h = velocity.x > 0
	move_and_slide()
	if not is_chasing:
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			if abs(collision.get_normal().x) > 0.5:
				direction *= -1.0
				break

func _patrol() -> void:
	var distance_from_start = global_position.x - start_position.x
	if distance_from_start >= PATROL_DISTANCE:
		direction = -1.0
	elif distance_from_start <= -PATROL_DISTANCE:
		direction = 1.0
	velocity.x = SPEED * direction

func _update_chase_state() -> void:
	var dist = global_position.distance_to(target.global_position)
	if not is_chasing and dist <= CHASE_RANGE:
		is_chasing = true
		$Sprite2D.texture = chase_texture
	elif is_chasing and dist >= COOLDOWN_RANGE:
		is_chasing = false
		$Sprite2D.texture = patrol_texture
		direction = sign(global_position.x - start_position.x) * -1.0

func _chase_player() -> void:
	var diff = target.global_position.x - global_position.x
	velocity.x = sign(diff) * CHASE_SPEED

func _on_body_entered(body: Node2D) -> void:
	if is_dead:
		return
	if body == target:
		target.die()

func die() -> void:
	is_dead = true
	$Area2D/CollisionShape2D.set_deferred("disabled", true)
	# Disable main collision so player doesn't bump into the corpse
	$CollisionShape2D.set_deferred("disabled", true)
	$Sprite2D.texture = dead_texture
	$Sprite2D.offset = Vector2(0, 50)
	set_physics_process(false)

	# Body disappears after 2 seconds
	await get_tree().create_timer(2.0).timeout
	$Sprite2D.visible = false

	# Respawn 3 seconds later (5s total from death)
	await get_tree().create_timer(3.0).timeout
	_respawn()

func _respawn() -> void:
	is_dead = false
	is_chasing = false
	direction = 1.0
	velocity = Vector2.ZERO
	# Return to spawn position
	global_position = start_position
	# Re-enable collisions
	$Area2D/CollisionShape2D.set_deferred("disabled", false)
	$CollisionShape2D.set_deferred("disabled", false)
	# Restore patrol sprite and visibility
	$Sprite2D.texture = patrol_texture
	$Sprite2D.offset = Vector2.ZERO
	$Sprite2D.visible = true
	$Sprite2D.flip_h = false
	set_physics_process(true)
