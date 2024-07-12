@tool
class_name TreeManager
extends Node


@export var tree: Tree
@export var path_input: LineEdit

var finite_children: Array[TreeItem] = []


func _ready() -> void:
	tree.item_edited.connect(_on_tree_item_edited)


func get_import_paths() -> PackedStringArray:
	var paths := []
	for child in finite_children:
		if not child.is_checked(0):
			continue
		
		var path := ""
		var current_item = child
		
		while current_item:
			path = path.insert(0, current_item.get_text(0))
			if current_item != tree.get_root():
				path = path.insert(0, "/" )
			
			current_item = current_item.get_parent()
		
		paths.append(path)
	
	return paths


func _clean_up_tree() -> void:
	var root = tree.get_root()
	var children := tree.get_root().get_children()
	var root_text := root.get_text(0)
	
	root.set_text(0, root_text.left(root_text.length() - 1))
	children.reverse()
	
	for child in children:
		for parent in children:
			if parent.get_text(0) != child.get_text(0) and child.get_text(0).contains(parent.get_text(0)):
				child.get_parent().remove_child(child)
				parent.add_child(child)
		
		var child_text := child.get_text(0)
		var slices := child_text.split("/", false)
		slices.reverse()
		
		child.set_text(0, slices[0])


func update_tree(path: String) -> void:
	var paths = [path]
	
	tree.clear()
	finite_children.clear()
	
	while paths.size() > 0:
		var full_path = paths[0]
		var dir := DirAccess.open(full_path)
		
		if not dir:
			printerr("Error, animation directory path is wrong")
			return
		
		dir.list_dir_begin()
		var file := dir.get_next()
		
		var tree_parent = tree.create_item()
		
		tree_parent.set_cell_mode(0, 1)
		tree_parent.set_editable(0, true)
		tree_parent.set_text(0, full_path)
		tree_parent.propagate_check(0)
		
		while file != "":
			if file.ends_with(".import"):
				var child = tree.create_item(tree_parent)
				
				child.set_cell_mode(0, 1)
				child.set_editable(0, true)
				child.set_text(0, file.replace(".import", ""))
				finite_children.append(child)
				
			elif dir.current_is_dir():
				paths.append(full_path + file + "/")
			
			file = dir.get_next()
		
		if tree_parent != tree.get_root() and tree_parent.get_child_count() == 0:
			tree_parent.free()
		
		dir.list_dir_end()
		paths.remove_at(0)
	
	var root = tree.get_root()
	
	if root:
		root.set_checked(0, true)
		root.propagate_check(0)
		
		_clean_up_tree()


#Tree selection
func _on_tree_item_edited() -> void:
	var column = tree.get_edited_column()
	
	tree.get_edited().propagate_check(column)


func refresh_tree() -> void:
	tree.clear()
	update_tree(path_input.text)
