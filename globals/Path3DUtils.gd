# the returned transform is in local space relative to the Path3D node.
static func sample_path_transform(path : Path3D, _position_on_curve : float = 0.0, cubic : bool = false, apply_tilt : bool = false, _use_looping : bool = false) -> Transform3D:
	if _use_looping:
		_position_on_curve = fposmod(_position_on_curve, path.curve.get_baked_length())
	
	var _transform := path.curve.sample_baked_with_rotation(_position_on_curve, cubic, apply_tilt)
	
	if _position_on_curve < 0.0:
		_transform.origin += _position_on_curve * -_transform.basis.z
	elif _position_on_curve > path.curve.get_baked_length():
		_transform.origin += (_position_on_curve - path.curve.get_baked_length()) * -_transform.basis.z
	
	return _transform

#returns in local space, relative to parent_transform
#parent_transform is optional. If _transform is a child of a node, use the parent's global_transform
static func deform_transform_to_path(path : Path3D, _position_on_curve : float, _transform : Transform3D, parent_transform : Transform3D = Transform3D(), _use_looping : bool = false) -> Transform3D:
	var end_transform : Transform3D = sample_path_transform(path, _position_on_curve, false, true, _use_looping)
	
	# _transform.origin.z isn't used here because the depth is included in `end_transform`
	_transform.origin.z = 0.0
	return end_transform * _transform * parent_transform.inverse()

static func deform_node_to_path(deformer : CurveDeformer, path : Path3D, node : Node3D) -> Transform3D:
	return deform_transform_to_path(path, deformer.position_on_curve, node.transform, node.get_parent().global_transform) * deformer.offset

static func deform_mesh_to_path(path : Path3D, _position_on_curve : float, node : GeometryInstance3D, offset : Transform3D = Transform3D(), _use_looping : bool = false) -> Mesh:
	var array_mesh := ArrayMesh.new()
	
	for surface : int in node.mesh.get_surface_count():
		var new_vertex_array : PackedVector3Array = []
		var new_normal_array : PackedVector3Array = []
		
		var arrays : Array = node.mesh.surface_get_arrays(surface)
		
		#for index : int in arrays[Mesh.ARRAY_VERTEX].size():
			#var vertex : Vector3 = arrays[Mesh.ARRAY_VERTEX][index]
			#var normal : Vector3 = arrays[Mesh.ARRAY_NORMAL][index]
			#
			#var vertex_transform : Transform3D = deform_transform_to_path(path, _position_on_curve, Transform3D(Basis(), Vector3(0, 0, vertex.z)), node.get_parent().global_transform) * offset
			#vertex_transform.origin += Vector3(vertex.x, vertex.y, 0.0) * vertex_transform.basis.inverse()
			#new_vertex_array.append(vertex_transform.origin)
			#new_normal_array.append(normal * vertex_transform.basis.inverse())
		
		for index : int in arrays[Mesh.ARRAY_VERTEX].size():
			var vertex : Vector3 = arrays[Mesh.ARRAY_VERTEX][index]
			var normal : Vector3 = arrays[Mesh.ARRAY_NORMAL][index]
			var offset_copy : Transform3D = offset
			
			var global_vertex : Vector3 = vertex * offset_copy.basis.inverse().get_rotation_quaternion()
			var vertex_offset : Vector3 = global_vertex * offset_copy.basis.get_scale() * Vector3(1, 1, 0)
			var vertex_depth : float = -(global_vertex * offset_copy.basis.get_scale()).z
			
			var path_transform : Transform3D = sample_path_transform(path, _position_on_curve, false, true, _use_looping).inverse() * sample_path_transform(path, _position_on_curve + vertex_depth, false, true, _use_looping) * Transform3D(Basis(), offset.origin)
			#path_transform.origin.z = 0.0
			
			offset_copy.basis = Basis(offset_copy.basis.get_rotation_quaternion())
			new_vertex_array.append((path_transform.origin + vertex_offset * path_transform.basis.inverse()) * offset_copy / offset.basis.get_scale())
			new_normal_array.append(normal * path_transform.basis.inverse())
		
		var new_arrays : Array = arrays.duplicate(true)
		new_arrays.resize(Mesh.ARRAY_MAX)
		new_arrays[Mesh.ARRAY_VERTEX] = new_vertex_array
		new_arrays[Mesh.ARRAY_NORMAL] = new_normal_array
		
		array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, new_arrays)
		array_mesh.surface_set_material(array_mesh.get_surface_count() - 1, node.mesh.surface_get_material(array_mesh.get_surface_count() - 1))
	
	return array_mesh

static func deform_points_to_path(path : Path3D, _position_on_curve : float, points : PackedVector3Array, offset : Transform3D = Transform3D(), _use_looping : bool = false) -> PackedVector3Array:
	var new_vertex_array := PackedVector3Array()
	
	for vertex : Vector3 in points:
		var offset_copy : Transform3D = offset
		
		var global_vertex : Vector3 = vertex * offset_copy.basis.inverse().get_rotation_quaternion()
		var vertex_offset : Vector3 = global_vertex * offset_copy.basis.get_scale() * Vector3(1, 1, 0)
		var vertex_depth : float = -(global_vertex * offset_copy.basis.get_scale()).z
		
		var path_transform : Transform3D = sample_path_transform(path, _position_on_curve, false, true, _use_looping).inverse() * sample_path_transform(path, _position_on_curve + vertex_depth, false, true, _use_looping) * Transform3D(Basis(), offset.origin)
		
		offset_copy.basis = Basis(offset_copy.basis.get_rotation_quaternion())
		new_vertex_array.append((path_transform.origin + vertex_offset * path_transform.basis.inverse()) * offset_copy / offset.basis.get_scale())
	
	return new_vertex_array