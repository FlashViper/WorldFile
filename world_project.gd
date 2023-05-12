class_name WorldSettings
extends Resource

@export var project_name := &"New Project"
@export_multiline var description : String
@export var tile_size := 64
@export var screen_size_px : Vector2i

@export var recent_worlds : Array[String] = []
@export var deco_palettes : Array = []

var minimum_screen_size : Vector2i :
	get: return Vector2i((Vector2(screen_size_px) / tile_size).ceil())


static func create_new(p_tile_size: int, p_screen_size: Vector2i) -> WorldSettings:
	var p := WorldSettings.new()
	p.screen_size_px = p_screen_size
	p.tile_size = p_tile_size
	
#	Vector2i(
#		ProjectSettings.get_setting(
#			"display/window/size/viewport_width"
#		),
#		ProjectSettings.get_setting(
#			"display/window/size/viewport_height"
#		)
#	)
	
	return p
