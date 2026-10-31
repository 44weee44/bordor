extends CharacterBody3D

@export var move_speed: float = 5.0
@export var gravity: float = 18.0

@onready var joystick: Control = get_node("../HUD/Joystick")

func _physics_process(delta: float) -> void:
    var input_vector: Vector2 = joystick.get_output()

    # Keyboard fallback for testing in the editor.
    if input_vector.length() < 0.05:
        input_vector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

    var direction := Vector3(input_vector.x, 0.0, input_vector.y)
    if direction.length() > 1.0:
        direction = direction.normalized()

    velocity.x = direction.x * move_speed
    velocity.z = direction.z * move_speed

    if not is_on_floor():
        velocity.y -= gravity * delta
    else:
        velocity.y = 0.0

    move_and_slide()
