extends CharacterBody3D

@export var move_speed: float = 4.0
@export var gravity: float = 18.0
@export var look_sensitivity: float = 0.0035

var joystick: Node = null
var camera: Camera3D = null
var look_touch_id: int = -1
var last_look_pos: Vector2 = Vector2.ZERO
var pitch: float = 0.0

func _ready() -> void:
    joystick = get_node_or_null("../HUD/Joystick")
    camera = get_node_or_null("Camera3D") as Camera3D
    if camera == null:
        push_error("Player: не найдена Camera3D. Проверь дочерний узел камеры.")
    else:
        camera.current = true

func _input(event: InputEvent) -> void:
    var viewport_size: Vector2 = get_viewport().get_visible_rect().size

    if event is InputEventScreenTouch:
        var touch := event as InputEventScreenTouch
        if touch.pressed:
            if touch.position.x > viewport_size.x * 0.42 and look_touch_id == -1:
                look_touch_id = touch.index
                last_look_pos = touch.position
        elif touch.index == look_touch_id:
            look_touch_id = -1

    elif event is InputEventScreenDrag:
        var drag := event as InputEventScreenDrag
        if drag.index == look_touch_id:
            var delta_pos: Vector2 = drag.position - last_look_pos
            last_look_pos = drag.position
            _rotate_view(delta_pos)

    elif event is InputEventMouseMotion:
        var motion := event as InputEventMouseMotion
        if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
            _rotate_view(motion.relative)

func _rotate_view(delta_pos: Vector2) -> void:
    if not is_instance_valid(camera):
        return
    rotate_y(-delta_pos.x * look_sensitivity)
    pitch = clamp(
        pitch - delta_pos.y * look_sensitivity,
        deg_to_rad(-78.0),
        deg_to_rad(78.0)
    )
    camera.rotation.x = pitch

func _physics_process(delta: float) -> void:
    var input_vector: Vector2 = Vector2.ZERO

    if is_instance_valid(joystick) and joystick.has_method("get_output"):
        input_vector = joystick.get_output()

    if input_vector.length() < 0.05:
        input_vector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

    input_vector = input_vector.limit_length(1.0)

    # Вперёд — по направлению взгляда, но без наклона камеры вверх/вниз.
    var forward: Vector3 = -global_transform.basis.z
    forward.y = 0.0
    forward = forward.normalized()
    var right: Vector3 = global_transform.basis.x
    right.y = 0.0
    right = right.normalized()

    var direction: Vector3 = right * input_vector.x + forward * -input_vector.y
    if direction.length() > 1.0:
        direction = direction.normalized()

    velocity.x = direction.x * move_speed
    velocity.z = direction.z * move_speed

    if not is_on_floor():
        velocity.y -= gravity * delta
    else:
        velocity.y = 0.0

    move_and_slide()
