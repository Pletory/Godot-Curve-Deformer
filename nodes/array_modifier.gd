@tool
extends Node3D
class_name CurveArray

enum OffsetType{RELATIVE, CONSTANT}
@export var _recalculate : bool = false:
	set(x):
		recalculate()
@export var array_count : int = 0
@export var fit_curve_length : bool = false
@export_group("Offset")
@export var offset_type : OffsetType = OffsetType.RELATIVE
@export var offset_distance : float = 1.0

@onready var original_children : Array[Node] = get_children()
var duplicated_children : Array[Node] = []

func _enter_tree() -> void:
	if Engine.is_editor_hint():
		recalculate.call_deferred()
	
	if get_parent() is CurveDeformer:
		get_parent().calculate.connect(recalculate)
func _exit_tree() -> void:
	if get_parent() is CurveDeformer and get_parent().is_connected("calculate", recalculate):
		get_parent().disconnect("calculate", recalculate)

func _ready() -> void:
	child_entered_tree.connect(_on_child_entered_tree)
	child_exiting_tree.connect(_on_child_exiting_tree)

func _on_child_entered_tree(child : Node) -> void:
	if not is_modifying_internal_children:
		original_children.append(child)
func _on_child_exiting_tree(child : Node) -> void:
	if original_children.has(child):
		original_children.erase(child)

var is_modifying_internal_children : bool = false
func recalculate() -> void:
	#reset
	is_modifying_internal_children = true
	for child : Node in duplicated_children:
		child.queue_free()
	duplicated_children = []
	is_modifying_internal_children = false
	
	var aabb = get_aabb_recursive(self)
	
	#prevents near-infinite recursion.
	if is_equal_approx(aabb.size.z, 0.0):
		print_stack()
		push_error("AABB size.z == 0, aborting.")
		return
	
	var path3d : Path3D = get_first_parent_of_type(self, Path3D)
	var curve : Curve3D = path3d.curve
	if fit_curve_length:
		var nominal_length : float = curve.get_baked_length()
		var instance_count_to_fit : int = int(nominal_length / aabb.size.z)
		var fitting_scale_factor : float = nominal_length / (roundf(instance_count_to_fit) * aabb.size.z)
		
		array_count = instance_count_to_fit - 1
		#array_count = min(array_count, 100) #debug
		scale = Vector3(1, 1, fitting_scale_factor)
	else:
		scale = Vector3.ONE
	
	var offset := Vector3.ZERO
	match offset_type:
		OffsetType.RELATIVE:
			offset = aabb.size * Vector3(0, 0, -1) * offset_distance
		OffsetType.CONSTANT:
			offset = Vector3(0, 0, -1) * offset_distance
	
	is_modifying_internal_children = true
	for index : int in array_count:
		duplicated_children.append_array(create_duplicate_children(Transform3D(Basis(), offset * (index + 1))))
	is_modifying_internal_children = false


func get_aabb_recursive(node : Node3D) -> AABB:
	var total_aabb : AABB
	if node is VisualInstance3D:
		total_aabb = node.get_aabb()
	
	for child : Node in node.get_children():
		if not child is Node3D:
			continue
		
		var child_aabb : AABB = get_aabb_recursive(child)
		child_aabb = child.transform * child_aabb
		
		if total_aabb: total_aabb = total_aabb.merge(child_aabb)
		else: total_aabb = child_aabb
	
	return total_aabb

func create_duplicate_children(offset : Transform3D) -> Array[Node]:
	var duplicated_nodes : Array[Node] = []
	for child : Node in original_children:
		var duplicate : Node = child.duplicate()
		
		if duplicate is Node3D:
			duplicate.transform = duplicate.transform * offset
		
		add_child(duplicate, false, Node.INTERNAL_MODE_BACK)
		duplicated_nodes.append(duplicate)
	
	return duplicated_nodes

static func get_first_parent_of_type(node : Node, type) -> Node:
	var parent := node.get_parent()
	if parent == null:
		return null
	elif is_instance_of(parent, type):
		return parent
	else:
		return get_first_parent_of_type(parent, type)
