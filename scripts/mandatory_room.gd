extends Resource
class_name MandatoryRoom

enum RoomType {
	GENERATOR,
	CONTROL,
	SPAWN,
}

@export var type: RoomType
@export var width: int
@export var height: int
@export var scene: PackedScene

var id: int

func size_for_rotation(rotated: bool) -> Vector2i:
	return Vector2i(height, width) if rotated else Vector2i(width, height)
