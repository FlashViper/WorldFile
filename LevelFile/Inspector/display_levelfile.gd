@tool
extends Control

signal display_toggled

@onready var toggle_details: Button = %ToggleDetails


func _ready() -> void:
	toggle_details.pressed.connect(func(): display_toggled.emit(), CONNECT_DEFERRED)


func display(level: LevelFile) -> void:
	%LevelName.text = level.name if level.name != "" else "Untitled Level"
	%LevelSize.text = "
		%s[color=darkgrey] by [/color]%s[color=darkgrey] tiles
	" % [level.size.x, level.size.y]
	
	if level.size.x > 1 and level.size.y > 1:
		var img := Image.create(
			level.size.x, 
			level.size.y, 
			false, 
			Image.FORMAT_RGB8
		)
		
		if level.tile_data.size() > 0:
			var index := 0
			for y in level.size.y:
				for x in level.size.x:
					if level.tile_data[index] != 0:
						img.set_pixel(x,y, Color.WHITE)
					index += 1
		
		if level.world_settings:
			var tile_size := level.world_settings.tile_size
			
			for r in level.respawn_points:
				var world_pos := level.respawn_points[r] as Vector2
				if Rect2(Vector2(), level.size * level.world_settings.tile_size).has_point(world_pos):
					var tile_pos := (world_pos / tile_size).floor()
					img.set_pixel(tile_pos.x, tile_pos.y, Color.DARK_OLIVE_GREEN)
		
		var tex := ImageTexture.create_from_image(img)
		%Bitmask.texture = tex
