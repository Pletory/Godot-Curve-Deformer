@tool
extends Node3D
class_name CurveDeformer

const Path3DUtils = preload("../globals/Path3DUtils.gd")

signal calculate

@export var enable_in_editor : bool = false:
	set(x):
		var before_value : bool = enable_in_editor
		enable_in_editor = x
		
		if not Engine.is_editor_hint():
			destroy_edited_visualization()
			return
		
		if enable_in_editor and not before_value:
			recalculation_queued = true
		elif not enable_in_editor and before_value:
			destroy_edited_visualization()
@export var _recalculate : bool = false:
	set(x):
		if Engine.is_editor_hint() and enable_in_editor:
			create_edited_visualization()
@export var position_on_curve : float = 0.0:
	set(x):
		position_on_curve = x
		recalculation_queued = true
@export var use_looping : bool = true:
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

var recalculation_queued : bool = not Engine.is_editor_hint()

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

func _physics_process(delta: float) -> void:
	if _get_configuration_warnings().size() > 0:
		return
	
	transform = Path3DUtils.sample_path_transform(get_parent(), position_on_curve, false, true, use_looping) * offset
	
	if not is_node_ready():
		return
	
	if not Engine.is_editor_hint() and recalculation_queued:
		recalculate.call_deferred(self, get_parent(), position_on_curve)
		return
	
	if Engine.is_editor_hint() and enable_in_editor and recalculation_queued:
		create_edited_visualization.call_deferred()
		return

func recalculate(deformer : Node3D, path : Path3D, _position_on_curve : float) -> void:
	calculate.emit()
	recalculate_node_data_recursive(path, _position_on_curve, deformer)
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
	if node is MeshInstance3D or node is CSGMesh3D and not node.has_node("CurveDeformerDisableMesh"):
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
		for child : Node in node.get_children(true):
			if not child is Node3D:
				continue
			
			recalculate_node_data_recursive(path, _position_on_curve, child, transform_relative_to_deformer * child.transform, node_offset)
		

var edited_duplicate : Node = null
func create_edited_visualization() -> void:
	visible = false
	if is_instance_valid(edited_duplicate):
		edited_duplicate.queue_free()
	
	edited_duplicate = self.duplicate(0)
	get_parent().add_child(edited_duplicate, false, Node.INTERNAL_MODE_BACK)
	edited_duplicate.visible = true
	recalculate(edited_duplicate, get_parent(), position_on_curve)

func destroy_edited_visualization() -> void:
	visible = true
	if is_instance_valid(edited_duplicate):
		edited_duplicate.queue_free()
