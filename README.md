<p align="center">
<img src="pletory-logo.png" width="400">

---

Pletory is an independent developer, publisher, and distributor targeting the global market with 3D and games.
We combine craftsmanship with a meticulous process and a deep commitment to quality. Our team, a blend of creative minds and technical experts, focuses on breakthrough technologies to deliver real value for our community and partners.

For the creation of our multiplayer hover-car racing game, we needed a system that allows for placing and deforming objects along 3D curves, making track design more intuitive within the engine.
The Curve Deformer plugin simplifies this task by offering features like the deformation of Node3Ds and MeshInstances, as well as collision management.

---

A big thanks 🙏 to @[addmix](https://github.com/addmix) who support the development of the pluging!

---

# Curve Deformer
 A Godot plugin for placing and deforming Node3Ds and MeshInstances along 3D curves.

## Features:
- Deform node positions along a curve.
- Deform meshes.
- Deform concave and convex collision shapes.
- Improved usability of Path3D nodes.
- Automatic duplication and sizing to fit curve length.

## Installation:
1. Download the plugin.
2. Unzip the files, and place the `curve_deformer` folder inside your project's `res://addons` folder.
3. Enable the plugin in your project settings.

## Basic Usage:
- Add a `Path3D` or `Path3DImproved` node to your 3D scene.
- Assign or create a new curve in the `Path3D`'s `curve` property.
- Add a `CurveDeformer` as a child of the `Path3D`.
- Add any amount of 3D nodes, MeshInstance3Ds, or CollisionShape3Ds, as children to the CurveDeformer.
- Enable the `enable_in_editor` property on the `CurveDeformer` node.
- Child nodes will be repositioned and deformed by the curve.

## Advanced configuration:
Node list:
- [`CurveDeformer`](#curvedeformer-properties)
- [`ArrayModifier`](#arraymodifier-properties)
- [`Path3DImproved`](#path3dimproved-properties)
- [`CurveDeformerAllowTreeSearch`](#configuration-nodes)
- [`CurveDeformerDisableMesh`](#configuration-nodes)
- [`CurveDeformerDisableTransform`](#configuration-nodes)
- [`CurveDeformerDisableAll`](#configuration-nodes)

### Configuration nodes:
Nodes with specific names can be added to nodes to enable or disable certain features. The valid types of configuration nodes are:
- `CurveDeformerAllowTreeSearch`: Allows the CurveDeformer to modify that node's children. These can be used to allow all descendant nodes to be repositioned/deformed.
- `CurveDeformerDisableMesh`: Disables mesh deformation of the parent MeshInstance3D or CollisionShape3D.
- `CurveDeformerDisableTransform`: Disables repositioning of the parent Node3D.
- `CurveDeformerDisableAll`: Disables all repositioning/deformation of the parent node.
### CurveDeformer properties:
- `enable_in_editor`: Enables or disables CurveDeformer functionality in the editor.
- `recalculate`: When pressed/changed, causes CurveDeformer to recalculate node deformation. Always remains as `false`.
- `position_on_curve`: The position on the curve (default Godot units, Meters) which the CurveDeformer is positioned.
- `use_looping`: If enabled, nodes and meshes beyond the ends of the curve will be seamlessly looped to the other end of the curve. When disabled, nodes and meshes will continue linearly along the curve's start/end tangents.
- `offset_position`: Offsets the CurveDeformer relative to the curve.
### ArrayModifier properties:
Children nodes can be duplicated and arranged in a linear array.
- `recalculate`: When pressed/changed, causes ArrayModifier to reset, and duplicate child nodes. Always remains as `false`.
- `array_count`: Amount of duplicated instances to create.
- `fit_curve_length`: When enabled, `array_count` and `scale.z` will be adjusted to optimally fit instances into the total curve length.
- `offset_type`: Controls how `offset_distance` is interpreted. When set to `Constant`, duplicated instances are positioned using default Godot units (Meters). When set to `Relative`, `offset_distance` is interpreted as child node lengths. Relative offset of 1.0 will always cause duplicated instances to be arranged end-to-end, without overlap or gaps.
- `offset_distance`: Expressed as either Meters, when `offset_type` is set to `Constant`, or as a percentage of child node lengths when `offset_type` is set to `Relative`.
### Path3DImproved properties:
Path3D node extended with extra functionality for ease of use.
- `close_curve`: When enabled, the first and last curve positions will be aligned.
- `match_tangents`: When enabled, the first and last curve points tangents will be aligned.
- `match_tilt`: When enabled, the first and last curve points tilts will be aligned.
- `symmetrical_tangents`: When enabled, the first and last curve points tangents will be symmetrized (same length).

## License
The plugin is distributed under the terms of the MIT license.
