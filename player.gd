extends CharacterBody3D

@export var move_speed: float = 3.8
@export var gravity: float = 18.0
@export var look_sensitivity: float = 0.003

var joystick: Control
var camera: Camera3D
var _look_touch_id: int = -1
var _last_look_pos: Vector2 = Vector2.ZERO
var _pitch: float = 0.0

func _ready() -> void:
    joystick = get_node("../HUD/Joystick")
    camera = $Camera3D
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _unhandled_input(event: InputEvent) -> void:
    var screen_width := get_viewport().get_visible_rect().size.x
    if event is InputEventScreenTouch:
        if event.pressed and event.position.x > screen_width * 0.42 and _look_touch_id == -1:
            _look_touch_id = event.index
            _last_look_pos = event.position
        elif not event.pressed and event.index == _look_touch_id:
            _look_touch_id = -1
    elif event is InputEventScreenDrag and event.index == _look_touch_id:
        var delta_pos: Vector2 = event.position - _last_look_pos
        _last_look_pos = event.position
        _rotate_view(delta_pos)
    elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
        _rotate_view(event.relative)

func _rotate_view(delta_pos: Vector2) -> void:
    rotation.y -= delta_pos.x * look_sensitivity
    _pitch = clamp(_pitch - delta_pos.y * look_sensitivity, deg_to_rad(-78.0), deg_to_rad(78.0))
    camera.rotation.x = _pitch

func _physics_process(delta: float) -> void:
    var input_vector := Vector2.ZERO
    if is_instance_valid(joystick):
        input_vector = joystick.get_output()
    if input_vector.length() < 0.05:
        input_vector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

    var local_dir := Vector3(input_vector.x, 0.0, input_vector.y)
    if local_dir.length() > 1.0:
        local_dir = local_dir.normalized()
    var direction := local_dir.rotated(Vector3.UP, rotation.y)
    velocity.x = direction.x * move_speed
    velocity.z = direction.z * move_speed
    if not is_on_floor():
        velocity.y -= gravity * delta
    else:
        velocity.y = 0.0
    move_and_slide()
