extends RigidBody2D

var size
var tilenum

func makeRoom(_pos, _size, _tilenum):
	position = _pos
	size = _size
	tilenum = _tilenum
	var s = RectangleShape2D.new()
	s.extents = size
	$CollisionShape2D.shape = s
