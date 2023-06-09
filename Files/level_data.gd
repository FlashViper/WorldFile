@icon("../Icons/icon_leveldata.tres")
class_name LevelData extends Resource

@export var name : StringName = &""
@export var file_path : String = &""

@export var position : Vector2i = Vector2i.ZERO
@export var size : Vector2i = Vector2i.ONE * 2
@export var connections : PackedInt64Array

func get_rect() -> Rect2i:
	return Rect2i(position, size)
