@tool
extends Path3D
class_name Path3DImproved

@export var close_curve : bool = true
@export var match_tangents : bool = true
@export var match_tilt : bool = true
@export var symmetrical_tangents : bool = true

var last_point_count : int

var last_start_position : Vector3
var last_start_tangent : Vector3
var last_start_tilt : float
var last_end_position : Vector3
var last_end_tangent : Vector3
var last_end_tilt : float

var modifying_curve : bool = false
#:
	#set(x):
		#modifying_curve = x
		#print("modifyinh_cutve: ", modifying_curve)

func _ready() -> void:
	curve_changed.connect(_curve_changed)

func _curve_changed() -> void:
	if not curve: return
	if not close_curve: return
	if modifying_curve: return
	
	
	var start_position := curve.get_point_position(0)
	var start_tangent := curve.get_point_out(0)
	var start_tilt := curve.get_point_tilt(0)
	var end_position := curve.get_point_position(curve.point_count - 1)
	var end_tangent := curve.get_point_out(curve.point_count - 1)
	var end_tilt := curve.get_point_tilt(curve.point_count - 1)
	
	modifying_curve = true
	#point count changed
	if not curve.point_count == last_point_count:
		#exception for empty curve?
		
		#point count increased
		if curve.point_count > last_point_count:
			#figure out if new point is at the beginning or end of the array
			pass
		#point count decreased
		elif curve.point_count < last_point_count:
			#figure out if remove point is at the beginning or end of the array
			pass
	
	if not start_position == last_start_position:
		#change end position to match
		curve.set_point_position(curve.point_count - 1, start_position)
	elif not end_position == last_end_position:
		#change start position to match
		curve.set_point_position(0, end_position)
	
	if match_tangents:
		if not start_tangent == last_start_tangent:
			var length : float = end_tangent.length()
			if symmetrical_tangents: length = start_tangent.length()
			curve.set_point_in(curve.point_count - 1, -start_tangent.normalized() * length)
		if not end_tangent == last_end_tangent:
			var length : float = start_tangent.length()
			if symmetrical_tangents: length = end_tangent.length()
			curve.set_point_out(0, end_tangent.normalized() * length)
	
	if not start_tilt == last_start_tilt:
		#change end tilt to match
		curve.set_point_tilt(curve.point_count - 1, start_tilt)
	elif not end_tilt == last_end_tilt:
		#change end tilt to match
		curve.set_point_tilt(0, end_tilt)
	
	last_point_count = curve.point_count
	last_start_position = start_position
	last_start_tangent = start_tangent
	last_start_tilt = start_tilt
	last_end_position = end_position
	last_end_tangent = end_tangent
	last_end_tilt = end_tilt
	
	var a = func(): modifying_curve = false
	a.call_deferred()
