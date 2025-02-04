@tool
extends EditorPlugin

func _enter_tree() -> void:
	add_custom_type("Controler2D", "Node2D",  preload("BaseControler2D.gd"), preload("icons/Base2D.svg"))	
	add_custom_type("SideScrollingControler2D", "ControlBase2D",  preload("SideScrollingControler2D.gd"), preload("icons/SideScroller2D.svg"))
	add_custom_type("TopDownControler2D", "ControlBase2D",  preload("TopDownControler2D.gd"), preload("icons/TopDown2D.svg"))

func _exit_tree() -> void:	
	remove_custom_type("SideScrollingControler2D")
	remove_custom_type("TopDownControler2D")
	remove_custom_type("Controler2D")
