@tool
extends Control


@export var directory_path_input: LineEdit
@export var animation_path_input: LineEdit
@export var tree_manager: TreeManager


func _is_file_valid(section, config) -> bool:
	return config.get_value(section, "importer") == "scene" and config.get_value(section, "type") == "PackedScene"


func _set_rest_pos(file_path: String, rest_pos_animation_path: String) -> int:
	var config := ConfigFile.new()
	var import_path := file_path.replace(".import", "") + ".import" #Make sure to not have duplicate of .import
	var err = config.load(import_path)
	
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
				printerr("Error while readind import file. Make sure to reimport correctly ", file_path)
				return FAILED
			
			var skeleton = ""
			
			if not _subresources["nodes"].has("PATH:Skeleton3D"):
				skeleton = _subresources["nodes"]["PATH:RootNode/Skeleton3D"]
			else:
				skeleton = _subresources["nodes"]["PATH:Skeleton3D"]
			
			skeleton["rest_pose/load_pose"] = 2
			skeleton["rest_pose/external_animation_library"] = load(rest_pos_animation_path)
			
			config.set_value(section, "_subresources", _subresources)
			config.set_value(section, "nodes/import_as_skeleton_bones", true)
			
			config.save(import_path)
			break
	
	print_rich("[color=green]Succesfully convert {file_path}[/color]".format([["file_path", file_path]]))
	return OK


#Inputs
func _on_folder_btn_pressed() -> void:
	$FileDialog.visible = true


func _on_animation_btn_pressed() -> void:
	$ResPosPathDialog.visible = true


func _on_file_dialog_dir_selected(path: String) -> void:
	directory_path_input.text = path
	tree_manager.update_tree(path)


func _on_res_pos_path_dialog_file_selected(path: String) -> void:
	animation_path_input.text = path


func _on_button_pressed() -> void:
	var path = directory_path_input.text
	var rest_pos_animation_path = animation_path_input.text
	
	var dir = DirAccess.open(path)
	
	if not dir:
		printerr("Error while opening the file path")
		return
	
	if not rest_pos_animation_path:
		printerr("Error while opening the rest pos animation path")
		return
	
	var paths := tree_manager.get_import_paths()
	
	for p in tree_manager.get_import_paths():
		_set_rest_pos(p, rest_pos_animation_path)
	
	EditorInterface.get_resource_filesystem().reimport_files(paths)
