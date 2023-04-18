extends EditorInspectorPlugin

var GIZMO := preload("./Inspector/display_levelfile.tscn")

var interface : EditorInterface
var show_details : bool


func _can_handle(object) -> bool:
	return object is LevelFile


func _parse_property(object: Object, type: Variant.Type, name: String, hint_type: PropertyHint, hint_string: String, usage_flags: PropertyUsageFlags, wide: bool) -> bool:
	return !show_details


func _parse_begin(object: Object) -> void:
	var gizmo := GIZMO.instantiate()
	gizmo.display_toggled.connect(toggle_details.bind(object), CONNECT_DEFERRED)
	gizmo.display(object)
	add_custom_control(gizmo)


func toggle_details(object: Object) -> void:
	show_details = !show_details
	interface.inspect_object(object)
