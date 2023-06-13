@icon("../Icons/icon_levelfile.tres")
class_name LevelFile
extends Resource

const VERSION := &"0.1 development"

const PATTERN_PROPERTY := &"\t*(.*?):[\t ]*(.*)" # [name]: [thing]
const WHITE_SPACE := &" \t"

enum {
	ID_NULL,
	ID_TILEDATA,
	ID_ENTITIES,
	ID_DECORATION,
}

enum {
	DECO_IMAGE,
	DECO_SCENE,
	DECO_ATLAS,
	DECO_PACKED_ATLAS,
}

enum {
	DECO_DATA_FINISHED,
	DECO_DATA_COLOR,
	DECO_DATA_DEPTH,
}

# METADATA
@export var name : StringName
@export var size : Vector2i
@export var world_settings : WorldSettings


# TODO: Compression???
@export var tile_data : PackedByteArray

@export var entity_paths : Dictionary
@export var entities : Array[Dictionary]

@export var deco_textures : Array[String]
@export var decoration : Array[Dictionary]
# {String -> Vector2}
@export var respawn_points : Dictionary


func _init() -> void:
	deco_textures = []
	decoration = []
	
	if !Engine.is_editor_hint() and world_settings:
		size = world_settings.minimum_screen_size


static func load_from_file(path_raw: String) -> LevelFile:
	var path := path_raw.lstrip(WHITE_SPACE).rstrip(WHITE_SPACE)

	if !FileAccess.file_exists(path):
		return LevelFile.new()
	
	var f := FileAccess.open(path, FileAccess.READ)
	var l := LevelFile.new()
	
	var parser := preload("../StringParser.gd").new()
	var r_property := RegEx.create_from_string(PATTERN_PROPERTY)
	var r_datablock := RegEx.create_from_string(&"^\\[(.*)\\]")
	
	# TODO: Throw warning when level is of a different version
	f.get_line() # should be header to designate Level File, but I'm too lazy to check so far
	f.get_line() # should be version, but I'm too lazy to check so far
	
	var new_line := f.get_line()
	var properties := {"":[]}
	var current_property := ""
	
	while f.get_position() < f.get_length():
		var match_data := r_datablock.search(new_line)
		if match_data:
			if match_data.get_string(1) == "DATA":
				break
			else:
				current_property = match_data.get_string(1)
				properties[current_property] = []
		else:
			properties[current_property].append(new_line)
		
		new_line = f.get_line()
	
	for category in properties:
		match category:
			"":
				load_basic_properties(l, properties[category])
			"TEXTURES":
				for prop in properties[category]:
					l.deco_textures.append(prop)
			"RESPAWN":
				l.respawn_points = {}
				for line in properties[category]:
					var m := r_property.search(line)
					if m:
						var position = parser.attempt_parse(m.get_string(2))
						
						if position is Vector2:
							l.respawn_points[m.get_string(1)] = position
			"ENTITY_PATHS":
				l.entity_paths = {}
				for line in properties[category]:
					var m := r_property.search(line)
					if m:
						var id := m.get_string(1)
						var filepath := m.get_string(2)
						l.entity_paths[id] = filepath
			"ENTITIES":
				pass
				
	while f.get_position() < f.get_length():
		var id := f.get_8() # pull one byte from the file to tell us what to parse next
		match id:
			ID_TILEDATA:
				var length := f.get_32()
				l.tile_data = f.get_buffer(length)
			ID_DECORATION:
				load_decoration(l, f)
	
	return l


static func load_basic_properties(l: LevelFile, properties: Array) -> void:
	var r_property := RegEx.create_from_string(PATTERN_PROPERTY) # [name]: [thing]
	var parser := preload("../StringParser.gd").new()
	
	for line in properties:
		var m := r_property.search(line)
		if m:
			var property_id := m.get_string(1)
			match property_id:
				"name":
					l.name = m.get_string(2)
				"world_settings":
					if ResourceLoader.exists(m.get_string(2)):
						l.world_settings = ResourceLoader.load(m.get_string(2))
				_:
					var parsed_value = str_to_var(m.get_string(2))
					l.set(m.get_string(1), parsed_value)


static func load_decoration(l: LevelFile, f: FileAccess) -> void:
	var decoration : Array[Dictionary] = []
	var size := f.get_32()
	
	for i in size:
		var data := {}
		data["decoration_type"] = f.get_16()
		data["filepath_index"] = f.get_32()
		data["transform"] = f.get_var() as Transform2D
		match data["decoration_type"]:
			DECO_ATLAS:
				data["region"] = f.get_var() as Rect2i
		var data_type := f.get_8()
		while data_type != DECO_DATA_FINISHED and f.get_position() < f.get_length():
			match data_type:
				DECO_DATA_COLOR:
					data["color"] = f.get_var() as Color
				DECO_DATA_DEPTH:
					data["depth"] = f.get_float()
			data_type = f.get_8()
		decoration.append(data)
	l.decoration = decoration


func save_to_file(path_raw: String) -> void:
	const HEADER := &"FlashViper WorldFile\nVersion %s\n"
	const PROPERTY_TAG := &"%s: %s"
	
	var path := path_raw.rstrip(WHITE_SPACE).lstrip(WHITE_SPACE)
	var f := FileAccess.open(path, FileAccess.WRITE)
	
	if !f:
		printerr("level_file.gd->save_to_file(): Could not find file at path " + path)
		return
	
	f.store_line(HEADER % VERSION)
	f.store_line(PROPERTY_TAG % ["name", name])
	f.store_line(PROPERTY_TAG % ["size", var_to_str(size)])
	if world_settings:
		f.store_line(PROPERTY_TAG % ["world_settings", world_settings.resource_path])
	
	if entities.size() > 0:
		f.store_line("[ENTITY_PATHS]")
		for p in entity_paths:
			f.store_line(PROPERTY_TAG % [p, entity_paths[p]])
		f.store_line("")
		f.store_line("[ENTITIES]")
		for e in entities:
			f.store_line("%s:" % e["id"])
			for p in e["properties"]:
				f.store_line("\t" + (PROPERTY_TAG % [p, e["properties"][p]]))
		f.store_line("")
	
	if deco_textures.size() > 0:
		f.store_line("[TEXTURES]")
		for d in deco_textures:
			f.store_line(d)
	
	if respawn_points.size() > 0:
		f.store_line("[RESPAWN]")
		for r in respawn_points:
			f.store_line(PROPERTY_TAG % [r, respawn_points[r]])
	
	f.store_line("")
	
	f.store_line("[DATA]")
	# Store Tile Data
	f.store_8(ID_TILEDATA)
	f.store_32(tile_data.size())
	f.store_buffer(tile_data)
	
	# Store Decoration Data
	# TODO
	if decoration.size() > 0:
		f.store_8(ID_DECORATION)
		f.store_32(decoration.size())
		for d in decoration:
			var data_type := d["decoration_type"] as int
			var filepath_index := d["filepath_index"] as int
			var object_transform := d["transform"] as Transform2D
			
			f.store_16(data_type) # Sprite based decoration by default
			f.store_32(filepath_index)
			f.store_var(object_transform)
			match data_type:
				DECO_IMAGE:
					pass
				DECO_ATLAS:
					f.store_var(d["region"] as Rect2i)
				DECO_PACKED_ATLAS:
					pass
				DECO_SCENE:
					pass
				_:
					pass
			
			if d.has("color"):
				f.store_8(DECO_DATA_COLOR)
				f.store_var(d["color"] as Color)
			if d.has("depth"):
				f.store_8(DECO_DATA_DEPTH)
				f.store_float(d["depth"])
			f.store_8(DECO_DATA_FINISHED)
