extends Node3D

const PlayerScript = preload("res://scripts/player.gd")
const JoystickScript = preload("res://scripts/joystick.gd")

var steel: StandardMaterial3D
var dark_steel: StandardMaterial3D
var floor_mat: StandardMaterial3D
var hazard_mat: StandardMaterial3D
var red_light_mat: StandardMaterial3D
var green_light_mat: StandardMaterial3D
var screen_mat: StandardMaterial3D

func _ready() -> void:
    _make_materials()
    _build_submarine()
    _build_player()
    _build_hud()

func _make_materials() -> void:
    steel = _mat(Color(0.48, 0.55, 0.58), "res://textures/steel.png", 0.72, 0.48)
    dark_steel = _mat(Color(0.12, 0.17, 0.19), "res://textures/steel.png", 0.8, 0.65)
    floor_mat = _mat(Color(0.48, 0.52, 0.51), "res://textures/grate.png", 0.45, 0.82)
    hazard_mat = _mat(Color.WHITE, "res://textures/hazard.png", 0.0, 0.8)
    red_light_mat = StandardMaterial3D.new()
    red_light_mat.albedo_color = Color(0.9, 0.035, 0.02)
    red_light_mat.emission_enabled = true
    red_light_mat.emission = Color(1.0, 0.025, 0.01)
    red_light_mat.emission_energy_multiplier = 2.5
    green_light_mat = StandardMaterial3D.new()
    green_light_mat.albedo_color = Color(0.05, 0.8, 0.24)
    green_light_mat.emission_enabled = true
    green_light_mat.emission = Color(0.03, 1.0, 0.12)
    green_light_mat.emission_energy_multiplier = 1.8
    screen_mat = StandardMaterial3D.new()
    screen_mat.albedo_color = Color(0.01, 0.18, 0.24)
    screen_mat.emission_enabled = true
    screen_mat.emission = Color(0.0, 0.42, 0.75)
    screen_mat.emission_energy_multiplier = 1.2

func _mat(tint: Color, texture_path: String, metallic_value: float, roughness_value: float) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = tint
    var tex := load(texture_path) as Texture2D
    if tex:
        m.albedo_texture = tex
        m.uv1_scale = Vector3(2.0, 2.0, 2.0)
    m.metallic = metallic_value
    m.roughness = roughness_value
    return m

func _build_submarine() -> void:
    var world := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color(0.008, 0.018, 0.028)
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.32, 0.39, 0.43)
    env.ambient_light_energy = 0.55
    world.environment = env
    add_child(world)

    # Main pressure hull: walkable corridor, enclosed by steel.
    _box("Floor", Vector3(0, -0.18, 0), Vector3(6.2, 0.36, 24.0), floor_mat, true)
    _box("Ceiling", Vector3(0, 3.8, 0), Vector3(6.2, 0.28, 24.0), dark_steel, true)
    _box("LeftHull", Vector3(-3.15, 1.8, 0), Vector3(0.3, 3.8, 24.0), steel, true)
    _box("RightHull", Vector3(3.15, 1.8, 0), Vector3(0.3, 3.8, 24.0), steel, true)
    _box("RearBulkhead", Vector3(0, 1.8, 12.0), Vector3(6.2, 3.8, 0.3), steel, true)

    # Reinforcing ribs along the corridor.
    for z in [-10.0, -6.0, -2.0, 2.0, 6.0, 10.0]:
        _box("CeilingRib", Vector3(0, 3.55, z), Vector3(6.1, 0.16, 0.22), dark_steel)
        _box("LeftRib", Vector3(-2.96, 1.8, z), Vector3(0.16, 3.5, 0.22), dark_steel)
        _box("RightRib", Vector3(2.96, 1.8, z), Vector3(0.16, 3.5, 0.22), dark_steel)

    # Hazard strips along the walkway.
    _box("HazardLeft", Vector3(-2.55, 0.012, 0), Vector3(0.22, 0.025, 23.0), hazard_mat)
    _box("HazardRight", Vector3(2.55, 0.012, 0), Vector3(0.22, 0.025, 23.0), hazard_mat)

    # Overhead pipe runs.
    for x in [-2.35, -1.65, 1.65, 2.35]:
        _cylinder("OverheadPipe", Vector3(x, 3.32, 0), 0.12 if abs(x) < 2.0 else 0.17, 23.0, dark_steel, Vector3(90, 0, 0))
    _cylinder("RedMainPipe", Vector3(-2.55, 2.95, -1.0), 0.10, 20.0, steel, Vector3(90, 0, 0))

    # Hatch frame at the forward end, opening into another compartment.
    _box("HatchTop", Vector3(0, 3.1, -8.8), Vector3(2.4, 0.32, 0.38), dark_steel)
    _box("HatchLeft", Vector3(-1.05, 1.55, -8.8), Vector3(0.32, 3.1, 0.38), dark_steel)
    _box("HatchRight", Vector3(1.05, 1.55, -8.8), Vector3(0.32, 3.1, 0.38), dark_steel)
    _box("HatchSill", Vector3(0, 0.12, -8.8), Vector3(2.1, 0.22, 0.48), hazard_mat)
    _box("NextRoomWall", Vector3(0, 1.8, -10.0), Vector3(6.2, 3.8, 0.3), steel, true)
    _box("NextRoomDoorTop", Vector3(0, 3.05, -10.0), Vector3(2.2, 0.45, 0.35), dark_steel)
    _box("NextRoomDoorLeft", Vector3(-1.2, 1.5, -10.0), Vector3(0.3, 3.0, 0.35), dark_steel)
    _box("NextRoomDoorRight", Vector3(1.2, 1.5, -10.0), Vector3(0.3, 3.0, 0.35), dark_steel)

    # Consoles on both sides.
    for side in [-1.0, 1.0]:
        var x := side * 2.55
        _box("ConsoleCabinet", Vector3(x, 1.0, -3.0), Vector3(0.62, 1.45, 1.5), dark_steel)
        var panel := _box("ConsoleScreen", Vector3(x - side * 0.325, 1.65, -3.0), Vector3(0.035, 0.72, 1.0), screen_mat)
        panel.rotation.y = deg_to_rad(90.0) if side < 0.0 else deg_to_rad(-90.0)
        for i in range(3):
            _sphere("StatusLamp", Vector3(x - side * 0.36, 1.2 + i * 0.18, -2.45), 0.055, green_light_mat if i != 1 else red_light_mat)

    # Gauge clusters, valve wheels and storage cylinders.
    for side in [-1.0, 1.0]:
        var gx := side * 2.78
        for z in [-5.2, -4.25, -3.3]:
            _cylinder("PressureGauge", Vector3(gx, 2.55, z), 0.25, 0.10, steel, Vector3(0, 0, 90))
            _cylinder("GaugeFace", Vector3(gx - side * 0.065, 2.55, z), 0.19, 0.025, floor_mat, Vector3(0, 0, 90))
        _cylinder("ValveHub", Vector3(side * 2.68, 1.15, 1.7), 0.12, 0.22, red_light_mat, Vector3(0, 0, 90))
        _cylinder("ValveBar", Vector3(side * 2.68, 1.15, 1.7), 0.045, 0.85, red_light_mat, Vector3(0, 0, 90))
        _box("PipeBracket", Vector3(side * 2.72, 0.55, 4.0), Vector3(0.28, 0.12, 2.5), dark_steel)

    # Emergency lamps and work lights.
    for z in [-7.0, -1.0, 5.0, 10.0]:
        _box("LampHousing", Vector3(0, 3.55, z), Vector3(0.9, 0.18, 0.35), dark_steel)
        _sphere("EmergencyLamp", Vector3(0, 3.38, z), 0.16, red_light_mat)
        var light := OmniLight3D.new()
        light.position = Vector3(0, 3.15, z)
        light.light_color = Color(1.0, 0.12, 0.07)
        light.light_energy = 1.1
        light.omni_range = 5.0
        add_child(light)

    # Yellow pressure tank at the rear.
    var tank_mat := StandardMaterial3D.new()
    tank_mat.albedo_color = Color(0.72, 0.39, 0.06)
    tank_mat.metallic = 0.55
    tank_mat.roughness = 0.62
    _cylinder("PressureTank", Vector3(2.15, 1.0, 7.5), 0.48, 1.8, tank_mat, Vector3.ZERO)
    _cylinder("TankCap", Vector3(2.15, 1.95, 7.5), 0.25, 0.18, dark_steel, Vector3.ZERO)

    # A few floor panels and bolts add scale.
    for z in range(-10, 12, 2):
        _box("FloorSeam", Vector3(0, 0.008, float(z)), Vector3(5.9, 0.012, 0.035), dark_steel)

    var sun := DirectionalLight3D.new()
    sun.rotation = Vector3(deg_to_rad(-55), deg_to_rad(25), 0)
    sun.light_color = Color(0.48, 0.61, 0.68)
    sun.light_energy = 0.22
    add_child(sun)

func _build_player() -> void:
    var body := CharacterBody3D.new()
    body.name = "Player"
    body.position = Vector3(0, 0.12, 5.5)
    body.set_script(PlayerScript)
    body.floor_snap_length = 0.25
    add_child(body)

    var collision := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.32
    capsule.height = 1.75
    collision.shape = capsule
    collision.position.y = 0.88
    body.add_child(collision)

    var cam := Camera3D.new()
    cam.name = "Camera3D"
    cam.position = Vector3(0, 1.62, 0)
    cam.current = true
    cam.fov = 82.0
    body.add_child(cam)

func _build_hud() -> void:
    var hud := CanvasLayer.new()
    hud.name = "HUD"
    add_child(hud)

    var stick := Control.new()
    stick.name = "Joystick"
    stick.set_script(JoystickScript)
    stick.anchor_left = 0.0
    stick.anchor_top = 1.0
    stick.anchor_right = 0.0
    stick.anchor_bottom = 1.0
    stick.offset_left = 28.0
    stick.offset_top = -190.0
    stick.offset_right = 192.0
    stick.offset_bottom = -26.0
    hud.add_child(stick)

    var crosshair := Label.new()
    crosshair.text = "+"
    crosshair.add_theme_font_size_override("font_size", 30)
    crosshair.add_theme_color_override("font_color", Color(0.9, 0.96, 1.0, 0.85))
    crosshair.anchor_left = 0.5
    crosshair.anchor_top = 0.5
    crosshair.anchor_right = 0.5
    crosshair.anchor_bottom = 0.5
    crosshair.offset_left = -9
    crosshair.offset_top = -20
    crosshair.offset_right = 9
    crosshair.offset_bottom = 20
    crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud.add_child(crosshair)

    var title := Label.new()
    title.text = "ПОДВОДНАЯ ЛОДКА  •  СЕКТОР 01"
    title.position = Vector2(24, 20)
    title.add_theme_font_size_override("font_size", 18)
    title.add_theme_color_override("font_color", Color(0.76, 0.88, 0.91))
    title.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud.add_child(title)

func _box(label: String, pos: Vector3, dimensions: Vector3, material: Material, collision: bool = false) -> MeshInstance3D:
    var mesh_instance := MeshInstance3D.new()
    mesh_instance.name = label
    var box := BoxMesh.new()
    box.size = dimensions
    mesh_instance.mesh = box
    mesh_instance.position = pos
    mesh_instance.material_override = material
    add_child(mesh_instance)
    if collision:
        var body := StaticBody3D.new()
        body.name = label + "Body"
        body.position = pos
        var shape_node := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = dimensions
        shape_node.shape = shape
        body.add_child(shape_node)
        add_child(body)
    return mesh_instance

func _cylinder(label: String, pos: Vector3, radius: float, height: float, material: Material, rot_degrees: Vector3) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    node.name = label
    var mesh := CylinderMesh.new()
    mesh.top_radius = radius
    mesh.bottom_radius = radius
    mesh.height = height
    node.mesh = mesh
    node.position = pos
    node.rotation = Vector3(deg_to_rad(rot_degrees.x), deg_to_rad(rot_degrees.y), deg_to_rad(rot_degrees.z))
    node.material_override = material
    add_child(node)
    return node

func _sphere(label: String, pos: Vector3, radius: float, material: Material) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    node.name = label
    var mesh := SphereMesh.new()
    mesh.radius = radius
    mesh.height = radius * 2.0
    node.mesh = mesh
    node.position = pos
    node.material_override = material
    add_child(node)
    return node
