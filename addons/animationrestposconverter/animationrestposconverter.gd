@tool
extends EditorPlugin

var panel

func _enter_tree() -> void:
	panel = preload("res://addons/animationrestposconverter/panel.tscn").instantiate()
	
	add_control_to_dock(EditorPlugin.DOCK_SLOT_RIGHT_UL, panel)


func _exit_tree() -> void:
	remove_control_from_docks(panel)
	
	panel.free()
