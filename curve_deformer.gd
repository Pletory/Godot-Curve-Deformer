@tool
extends EditorPlugin

const Node3DIcon = preload("icons/node3d.svg")

const CurveDeformerScript = preload("nodes/curve_deformer.gd")

func _enter_tree() -> void:
	add_custom_type("CurveDeformer", "Node3D", CurveDeformerScript, Node3DIcon)

func _exit_tree() -> void:
	remove_custom_type("CurveDeformer")
