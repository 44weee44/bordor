extends Control

@export var base_radius: float = 66.0
@export var knob_radius: float = 27.0
@export var deadzone: float = 0.12

var output_vector: Vector2 = Vector2.ZERO
var active: bool = false
var active_touch_id: int = -1
var knob_position: Vector2 = Vector2.ZERO

func _ready() -> void:
    custom_minimum_size = Vector2(164.0, 164.0)
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    knob_position = size * 0.5
    queue_redraw()

func get_output() -> Vector2:
    return output_vector

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        var touch := event as InputEventScreenTouch
        if touch.pressed:
            if not active and get_global_rect().has_point(touch.position):
                active = true
                active_touch_id = touch.index
                _update_from_screen(touch.position)
                get_viewport().set_input_as_handled()
        elif active and touch.index == active_touch_id:
            _release_stick()
            get_viewport().set_input_as_handled()

    elif event is InputEventScreenDrag:
        var drag := event as InputEventScreenDrag
        if active and drag.index == active_touch_id:
            _update_from_screen(drag.position)
            get_viewport().set_input_as_handled()

    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        var mouse_button := event as InputEventMouseButton
        if mouse_button.pressed:
            if not active and get_global_rect().has_point(mouse_button.position):
                active = true
                active_touch_id = -2
                _update_from_screen(mouse_button.position)
                get_viewport().set_input_as_handled()
        elif active and active_touch_id == -2:
            _release_stick()
            get_viewport().set_input_as_handled()

    elif event is InputEventMouseMotion and active and active_touch_id == -2:
        var mouse_motion := event as InputEventMouseMotion
        _update_from_screen(mouse_motion.position)
        get_viewport().set_input_as_handled()

func _update_from_screen(screen_position: Vector2) -> void:
    var local_position: Vector2 = screen_position - global_position
    var center: Vector2 = size * 0.5
    var offset: Vector2 = local_position - center

    if offset.length() > base_radius:
        offset = offset.normalized() * base_radius

    knob_position = center + offset
    output_vector = Vector2(offset.x / base_radius, offset.y / base_radius)

    if output_vector.length() < deadzone:
        output_vector = Vector2.ZERO

    queue_redraw()

func _release_stick() -> void:
    active = false
    active_touch_id = -1
    output_vector = Vector2.ZERO
    knob_position = size * 0.5
    queue_redraw()

func _draw() -> void:
    var center: Vector2 = size * 0.5
    draw_circle(center, base_radius, Color(0.015, 0.035, 0.05, 0.68))
    draw_arc(center, base_radius, 0.0, TAU, 64, Color(0.65, 0.78, 0.82, 0.85), 3.0)
    draw_circle(knob_position, knob_radius, Color(0.22, 0.48, 0.58, 0.96))
    draw_arc(knob_position, knob_radius, 0.0, TAU, 48, Color(0.9, 0.95, 0.95, 0.95), 2.0)
