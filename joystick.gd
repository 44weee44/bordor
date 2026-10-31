extends Control

@export var base_radius: float = 76.0
@export var knob_radius: float = 31.0
@export var deadzone: float = 0.12

var _output := Vector2.ZERO
var _active := false
var _touch_index := -1
var _knob_position := Vector2.ZERO

func _ready() -> void:
    custom_minimum_size = Vector2(180, 180)
    mouse_filter = Control.MOUSE_FILTER_STOP
    _knob_position = size * 0.5
    queue_redraw()

func get_output() -> Vector2:
    return _output

func _gui_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed and not _active:
            _active = true
            _touch_index = event.index
            _update_stick(event.position)
            accept_event()
        elif not event.pressed and event.index == _touch_index:
            _release_stick()
            accept_event()
    elif event is InputEventScreenDrag and _active and event.index == _touch_index:
        _update_stick(event.position)
        accept_event()
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if event.pressed:
            _active = true
            _update_stick(event.position)
        else:
            _release_stick()
        accept_event()
    elif event is InputEventMouseMotion and _active:
        _update_stick(event.position)
        accept_event()

func _update_stick(point: Vector2) -> void:
    var center := size * 0.5
    var offset := point - center
    if offset.length() > base_radius:
        offset = offset.normalized() * base_radius
    _knob_position = center + offset
    _output = Vector2(offset.x / base_radius, offset.y / base_radius)
    if _output.length() < deadzone:
        _output = Vector2.ZERO
    queue_redraw()

func _release_stick() -> void:
    _active = false
    _touch_index = -1
    _output = Vector2.ZERO
    _knob_position = size * 0.5
    queue_redraw()

func _draw() -> void:
    var center := size * 0.5
    draw_circle(center, base_radius, Color(0.05, 0.07, 0.09, 0.48))
    draw_arc(center, base_radius, 0.0, TAU, 64, Color(0.8, 0.9, 1.0, 0.65), 3.0)
    draw_circle(_knob_position, knob_radius, Color(0.2, 0.55, 0.9, 0.9))
    draw_arc(_knob_position, knob_radius, 0.0, TAU, 48, Color(1, 1, 1, 0.85), 2.0)
