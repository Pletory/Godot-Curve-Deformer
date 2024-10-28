@tool
extends Node3D
class_name CurveDeformer

const Path3DUtils = preload("../globals/Path3DUtils.gd")

signal calculate

@export var enable_in_editor : bool = false:
	set(x):
		var before_value : bool = enable_in_editor
		enable_in_editor = x
		
		if enable_in_editor and not before_value:
			create_editor_visualization.call_deferred()
		elif not enable_in_editor and before_value:
			destroy_editor_visualization()
@export var _recalculate : bool = false:
	set(x):
		if enable_in_editor:
			create_editor_visualization()
@export var position_on_curve : float = 0.0:
	set(x):
		position_on_curve = x
		recalculation_queued = true
@export var use_looping : bool = false:
	set(x):
		use_looping = x
		recalculation_queued = true

@export_group("Offset")
@export var offset_position := Vector3.ZERO:
	set(x):
		offset_position = x
		recalculation_queued = true

var offset := Transform3D():
	get:
		return Transform3D(Basis(), offset_position)

@export_category("")

var original_data : Dictionary = {
	#node : {property_name : value, ...}
}

var modified_data : Dictionary = {
	#node : {property_name : value, ...}
}

var recalculation_queued : bool = false


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	
	var parent : Node = get_parent() as Path3D
	if not parent is Path3D:
		warnings.append("CurveDeformer must be a child of a Path3D node.")
	if not parent.curve:
		warnings.append("Parent Path3D node does not have a valid curve")
	if parent.curve and not parent.curve.get_baked_length() > 0.0:
		warnings.append("Parent Path3D's curve has a length of 0")
	
	return warnings

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	#original_data = {}
	#gather_data_recursive(self, original_data)
	enable_in_editor = false

func _physics_process(delta: float) -> void:
	if _get_configuration_warnings().size() > 0:
		return
	
	#only used for editor visualization
	transform = Path3DUtils.sample_path_transform(get_parent(), position_on_curve, false, true, use_looping) * offset
	
	if not Engine.is_editor_hint() and recalculation_queued:
		recalculate(self, get_parent(), position_on_curve)
	
	if Engine.is_editor_hint() and enable_in_editor and recalculation_queued:
		create_editor_visualization()

func _notification(what: int) -> void:
	#prevent saving/overwriting original data
	if what == NOTIFICATION_EDITOR_PRE_SAVE and enable_in_editor:
		reset_to_original_data()
	if what == NOTIFICATION_EDITOR_POST_SAVE and enable_in_editor:
		reset_to_modified_data()
	if what == NOTIFICATION_CRASH:
		reset_to_original_data()
	if what == NOTIFICATION_PREDELETE:
		reset_to_original_data()

func _enter_tree() -> void:
	reset_to_modified_data()

func _exit_tree() -> void:
	reset_to_original_data()

func recalculate(deformer : Node3D, path : Path3D, _position_on_curve : float) -> void:
	calculate.emit()
	#reset_to_original_data()
		#place self
	#deformer.global_transform = Path3DUtils.sample_path_transform(path, position_on_curve, false, true, use_looping) * offset
	
	#modified_data = {}
	recalculate_node_data_recursive(path, _position_on_curve, deformer)
	#gather_data_recursive(deformer, modified_data)
	#reset_to_modified_data()
	recalculation_queued = false

func recalculate_node_data_recursive(path : Path3D, _position_on_curve : float, node : Node3D, transform_relative_to_deformer : Transform3D = Transform3D(), parent_node_offset : Transform3D = Transform3D()) -> void:
	if node.has_node("CurveDeformerDisableAll"):
		return
	#move self
	var node_depth : float = -(offset * transform_relative_to_deformer).origin.z
	var node_offset : Transform3D = offset * transform_relative_to_deformer
	node_offset.origin.z = 0.0
	
	if not node.has_node("CurveDeformerDisableTransform"):
		node.global_transform = path.global_transform * Path3DUtils.sample_path_transform(path, _position_on_curve + node_depth, false, true, use_looping) * node_offset
		if node.get_parent() == path:
			node.transform = Path3DUtils.sample_path_transform(path, _position_on_curve, false, true, use_looping) * offset
	
	#need to keep track of all parent node offsets, so that the offset info isn't lost
	if node is MeshInstance3D and not node.has_node("CurveDeformerDisableMesh"):
		node.mesh = Path3DUtils.deform_mesh_to_path(path, _position_on_curve + node_depth, node, node_offset, use_looping)
	
	if node is CollisionShape3D and node.shape is ConcavePolygonShape3D and not node.has_node("CurveDeformerDisableMesh"):
		var deformed_faces : PackedVector3Array = Path3DUtils.deform_points_to_path(path, _position_on_curve + node_depth, node.shape.get_faces(), node_offset, use_looping)
		
		node.shape = node.shape.duplicate(true)
		node.shape.set_faces(deformed_faces)
	
	if node is CollisionShape3D and node.shape is ConvexPolygonShape3D and not node.has_node("CurveDeformerDisableMesh"):
		var deformed_faces : PackedVector3Array = Path3DUtils.deform_points_to_path(path, _position_on_curve + node_depth, node.shape.get_points(), node_offset, use_looping)
		
		node.shape = node.shape.duplicate(true)
		node.shape.set_points(deformed_faces)
	
	#should do the same logic for other mesh types
	
	
	
	
	#use nodes to whitelist modifying grandchildren and beyond
	# check grandchild's owner, might be useful to not require using modified_data for more grandchildren
	if node.has_node("CurveDeformerAllowTreeSearch") or node.get_parent() == path:
		for child : Node in node.get_children():
			if not child is Node3D:
				continue
			
			recalculate_node_data_recursive(path, _position_on_curve, child, transform_relative_to_deformer * child.transform, node_offset)
		

var editor_duplicate : Node = null
func create_editor_visualization() -> void:
	if not Engine.is_editor_hint():
		push_warning("Trying to use editor visualization in running project.")
		return
	
	visible = false
	if is_instance_valid(editor_duplicate):
		editor_duplicate.queue_free()
	
	editor_duplicate = self.duplicate(0)
	get_parent().add_child(editor_duplicate, false, Node.INTERNAL_MODE_BACK)
	editor_duplicate.visible = true
	recalculate(editor_duplicate, get_parent(), position_on_curve)

func destroy_editor_visualization() -> void:
	visible = true
	if is_instance_valid(editor_duplicate):
		editor_duplicate.queue_free()



## data management


static func gather_data_recursive(parent : Node, data_dictionary : Dictionary) -> void:
	#need to get all descendant Node3Ds
	for node : Node in parent.get_children():
		if not node is Node3D:
			continue
		
		data_dictionary[node] = get_data_for_node(node)
		
		if node.has_node("CurveDeformerAllowTreeSearch"):
			gather_data_recursive(node, data_dictionary)

static func get_data_for_node(node : Node) -> Dictionary:
	var node_data : Dictionary = {}
	node_data["transform"] = node.transform
	
	if node is MeshInstance3D:
		node_data["mesh"] = node.mesh
	
	return node_data


func reset_to_original_data() -> void:
	for node : Node in original_data.keys():
		var node_data : Dictionary = original_data[node]
		
		for variable_name : StringName in node_data.keys():
			node.set(variable_name, node_data[variable_name])

func reset_to_modified_data() -> void:
	for node : Node in modified_data.keys():
		var node_data : Dictionary = modified_data[node]
		
		for variable_name : StringName in node_data.keys():
			node.set(variable_name, node_data[variable_name])
