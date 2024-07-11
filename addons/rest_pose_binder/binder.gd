@tool
extends Control


@export var directory_path_input: LineEdit
@export var animation_path_input: LineEdit
@export var tree: Tree

var valid_files := []
var pre_root_checked := false


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


func _update_tree(path: String) -> void:
	var paths = [path]
	tree.clear()
	valid_files.clear()
	
	while paths.size() > 0:
		var current_path = paths[0]
		var dir := DirAccess.open(current_path)
		dir.list_dir_begin()
		var file := dir.get_next()
		
		var tree_parent = tree.create_item()
		tree_parent.set_cell_mode(0, 1)
		tree_parent.set_editable(0, true)
		tree_parent.set_text(0, current_path)
		tree_parent.propagate_check(0)
		
		while file != "":
			if dir.current_is_dir():
				paths.append(current_path + file + "/")
			elif file.ends_with(".import"):
				var child = tree.create_item(tree_parent)
				child.set_cell_mode(0, 1)
				child.set_editable(0, true)
				child.set_text(0, file)
			
			file = dir.get_next()
		
		if tree_parent.get_child_count() == 0:
			tree_parent.free()
		
		dir.list_dir_end()
		paths.remove_at(0)
	
	var root = tree.get_root()
	if root:
		root.set_checked(0, true)
		root.propagate_check(0)


func _populate_valid_path(item: TreeItem, column: int, path: String) -> void:
	if item.is_checked(column) and not valid_files.has(path):
		valid_files.append(path)
	else:
		valid_files.erase(path)
	print(valid_files)


#Inputs
func _on_folder_btn_pressed() -> void:
	$FileDialog.visible = true


func _on_animation_btn_pressed() -> void:
	$ResPosPathDialog.visible = true


func _on_file_dialog_dir_selected(path: String) -> void:
	directory_path_input.text = path
	_update_tree(path)


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
	
	for p in valid_files:
		_set_rest_pos(p, rest_pos_animation_path)
	
	EditorInterface.get_resource_filesystem().reimport_files(valid_files)


#Tree selection
func _on_tree_item_edited() -> void:
	var column = tree.get_edited_column()
	tree.get_edited().propagate_check(column)


func _on_tree_check_propagated_to_item(item: TreeItem, column: int) -> void:
	if item == tree.get_root():
		return
	
	var path = item.get_parent().get_text(column) + item.get_text(column)
	if path.ends_with(".import"):
		path = path.replace(".import", "")
		_populate_valid_path(item, column, path)


func _on_refresh_tree_btn_pressed() -> void:
	if directory_path_input.text.is_empty():
		tree.clear()
		return
	
	_update_tree(directory_path_input.text)
