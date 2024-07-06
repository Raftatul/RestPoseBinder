@tool
extends Control

var valid_files: PackedStringArray


func _is_file_valid(section, config) -> bool:
	return config.get_value(section, "importer") == "scene" and config.get_value(section, "type") == "PackedScene"


func _set_rest_pos(file_path: String, rest_pos_animation_path: String) -> int:
	var config := ConfigFile.new()
	var raw_path := file_path.replace(".import", "")
	
	var err = config.load(file_path)
	
	if err != OK:
		print("Error on loading file ", file_path)
		return FAILED
		
	for section in config.get_sections():
		if section == "remap":
			if not _is_file_valid(section, config):
				printerr("File is not valid: ", file_path)
				break
				
		if section == "params":
			var _subresources = config.get_value(section, "_subresources")
			if _subresources.is_empty():
				printerr("Error while readind import file. Make sure to reimport correctly ", raw_path)
				return FAILED
			
			_subresources["nodes"]["PATH:Skeleton3D"]["rest_pose/load_pose"] = 2
			_subresources["nodes"]["PATH:Skeleton3D"]["rest_pose/external_animation_library"] = load(rest_pos_animation_path)
			
			config.set_value(section, "_subresources", _subresources)
			config.set_value(section, "nodes/import_as_skeleton_bones", true)
			
			config.save(file_path)
			break
	
	valid_files.append(raw_path)
	print_rich("[color=green]Succesfully convert {file_path}[/color]".format([["file_path", raw_path]]))
	return OK


func _convert_directory(path: String, rest_pos_animation_path: String):
	var dir := DirAccess.open(path)
	
	dir.list_dir_begin()
	var file := dir.get_next()
	
	while file != "":
		if dir.current_is_dir():
			_convert_directory(path + file + "/", rest_pos_animation_path)
		
		if file.contains(".import"):
			var import_path = path + file
			var err := _set_rest_pos(import_path, rest_pos_animation_path)
			
			if err != OK:
				printerr("Error while converting animations ", import_path)
				break
		
		file = dir.get_next()
		
	dir.list_dir_end()


func _on_folder_btn_pressed() -> void:
	$FileDialog.visible = true


func _on_animation_btn_pressed() -> void:
	$ResPosPathDialog.visible = true


func _on_file_dialog_dir_selected(dir: String) -> void:
	%Directory.text = dir


func _on_res_pos_path_dialog_file_selected(path: String) -> void:
	%RestPosePath.text = path


func _on_button_pressed() -> void:
	var path = %Directory.text
	var rest_pos_animation_path = %RestPosePath.text
	
	var dir = DirAccess.open(path)
	
	if not dir:
		printerr("Error while opening the file path")
		return
	
	if not rest_pos_animation_path:
		printerr("Error while opening the rest pos animation path")
		return
	
	_convert_directory(path, rest_pos_animation_path)
	
	EditorInterface.get_resource_filesystem().reimport_files(valid_files)
	valid_files.clear()
