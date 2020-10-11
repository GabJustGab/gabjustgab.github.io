extends Node2D

var Room = preload("res://Room.tscn")

onready var Map = $TileMap

var tile_size = 32
var num_rooms
var min_size
var max_size
var hspread
var vspread

var allowGenerate
var toggleOptions = false
var selectedOption = 0
var showLines=true

var maxrooms = 9
var maxitemsXroom = 3
var maxenemXroom = 5


var minpath
var maxpath
var IDpath
var randpath

func _ready():
	randomize()
	make_rooms()

func make_rooms():
	allowGenerate = false
	num_rooms = (randi() % maxrooms-3) + 3
	if(num_rooms<=(maxrooms/2)+1):
		num_rooms = randi() % (maxrooms/2+1) + 3
		if(num_rooms<=(maxrooms/2)-1):
			num_rooms = randi() % (maxrooms/2-1) + 3
	
	hspread = rand_range(250, 750)
	vspread = rand_range(200, 500)
	if(num_rooms<=(maxrooms/2)+1):
		min_size = 4
		max_size = 8
	else: if(num_rooms<=(maxrooms/2)-1):
		min_size = 4
		max_size = 15
	else:
		min_size = 4
		max_size = 6
	
	for i in range(num_rooms):
		var pos = Vector2(rand_range(-hspread, hspread),rand_range(-vspread, vspread))
		var r = Room.instance()
		var w = min_size + randi() % (max_size - min_size)
		var h = min_size + randi() % (max_size - min_size)
		r.makeRoom(pos,Vector2(w,h)*tile_size,w+h)
		$Rooms.add_child(r)
	yield(get_tree().create_timer(1.1), 'timeout')
	var room_positions = []
	for room in $Rooms.get_children():
		room.mode = RigidBody2D.MODE_STATIC
		room_positions.append(Vector3(room.position.x, room.position.y, 0))
	yield(get_tree(), 'idle_frame')
	minpath = create_minPath(room_positions)
	for room in $Rooms.get_children():
		room_positions.append(Vector3(room.position.x, room.position.y, 0))
	maxpath = create_maxPath(room_positions)
	for room in $Rooms.get_children():
		room_positions.append(Vector3(room.position.x, room.position.y, 0))
	IDpath = create_IDPath(room_positions)
	for room in $Rooms.get_children():
		room_positions.append(Vector3(room.position.x, room.position.y, 0))
	randpath = create_randPath(room_positions)
	allowGenerate = true
	
func _draw():
	for room in $Rooms.get_children():
		draw_rect(Rect2(room.position - room.size, room.size*2), Color(0,255,255), false)
	if minpath:
		for p in minpath.get_points():
			for c in minpath.get_point_connections(p):
				var pp = minpath.get_point_position(p)
				var cp = minpath.get_point_position(c)
				draw_line(Vector2(pp.x,pp.y), Vector2(cp.x,cp.y), Color(0,255,255), 15, true)
	if maxpath:
		for p in maxpath.get_points():
			for c in maxpath.get_point_connections(p):
				var pp = maxpath.get_point_position(p)
				var cp = maxpath.get_point_position(c)
				draw_line(Vector2(pp.x,pp.y), Vector2(cp.x,cp.y), Color(0,255,0), 15, true)
	
	if IDpath:
		for p in IDpath.get_points():
			for c in IDpath.get_point_connections(p):
				var pp = IDpath.get_point_position(p)
				var cp = IDpath.get_point_position(c)
				draw_line(Vector2(pp.x,pp.y), Vector2(cp.x,cp.y), Color(255,255,0), 15, true)
	if randpath:
		for p in randpath.get_points():
			for c in randpath.get_point_connections(p):
				var pp = randpath.get_point_position(p)
				var cp = randpath.get_point_position(c)
				draw_line(Vector2(pp.x,pp.y), Vector2(cp.x,cp.y), Color(255,0,0), 15, true)
func _process(delta):
	update()

func _input(event):
	if event.is_action_pressed('ui_zoom_in'):
		if($Camera2D.zoom.x>0.5):$Camera2D.zoom.x -= 0.25
		if($Camera2D.zoom.y>0.5):$Camera2D.zoom.y -= 0.25
		
	if event.is_action_pressed('ui_zoom_out'):
		if($Camera2D.zoom.x<6):$Camera2D.zoom.x += 0.25
		if($Camera2D.zoom.y<6):$Camera2D.zoom.y += 0.25
	
	if event.is_action_pressed('ui_select'):
		for n in $Rooms.get_children():
			n.queue_free()
		minpath = null
		maxpath = null
		IDpath = null
		randpath = null
		make_rooms()
	
	if event.is_action_pressed('ui_cleanLines'):
		if showLines:
			$TextureRect.show_behind_parent = false
			$TileMap.show_behind_parent = false
			$Instructions.show_behind_parent = false
		else:
			$TextureRect.show_behind_parent = true
			$TileMap.show_behind_parent = true
		showLines = !showLines
	
	if event.is_action_pressed('ui_left'):
		if(toggleOptions):
			if(selectedOption==0):
				if(maxrooms!=5):
					maxrooms=maxrooms-1
	
	if event.is_action_pressed('ui_right'):
		if(toggleOptions):
			if(selectedOption==0):
				if(maxrooms!=15):
					maxrooms=maxrooms+1
	
	if event.is_action_pressed("ui_cancel"):
		toggleOptions = !toggleOptions
	
	if (event.is_action_pressed('ui_focus_next') && allowGenerate):
		make_map()

func create_minPath(nodes):
	var path = AStar.new()
	path.add_point(path.get_available_point_id(), nodes.pop_front())
	
	while nodes:
		var min_dist = INF	# Distanza minima fin ora
		var min_p = null	# Nodo più vicino
		var p = null		# Posizione corrente
		
		for p1 in path.get_points():
			p1 = path.get_point_position(p1)
			for p2 in nodes:
				if p1.distance_to(p2) < min_dist:
					min_dist = p1.distance_to(p2)
					min_p = p2
					p = p1
		var n = path.get_available_point_id()
		path.add_point(n, min_p)
		path. connect_points(path.get_closest_point(p), n)
		nodes.erase(min_p)
	return path
	
func create_maxPath(nodes):
	var path = AStar.new()
	path.add_point(path.get_available_point_id(), nodes.pop_front())
	
	while nodes:
		var max_dist = -INF	# Distanza minima fin ora
		var max_p = null	# Nodo più lontano
		var p = null		# Posizione corrente
		
		for p1 in path.get_points():
			p1 = path.get_point_position(p1)
			for p2 in nodes:
				if p1.distance_to(p2) > max_dist:
					max_dist = p1.distance_to(p2)
					max_p = p2
					p = p1
		var n = path.get_available_point_id()
		path.add_point(n, max_p)
		path. connect_points(path.get_closest_point(p), n)
		nodes.erase(max_p)
	return path

func create_IDPath(nodes):
	var path = AStar.new()
	path.add_point(path.get_available_point_id(), nodes.pop_front())
	
	while nodes:
		var isAssigned = false	# Bool: Controlla se il nodo è già stato assegnato
		var ID_p = null			# Nodo per IP
		var p = null			# Posizione corrente
		var nID = 0
		
		for p1 in path.get_points():
			p1 = path.get_point_position(p1)
			isAssigned = false
			nID = 0
			for p2 in nodes:
				if ((nID == 0) && !isAssigned):
					isAssigned=true
					ID_p = p2
					p = p1
				elif ((nID != 0) && !isAssigned):
					nID = nID+1
				
		var n = path.get_available_point_id()
		path.add_point(n, ID_p)
		path. connect_points(path.get_closest_point(p), n)
		nodes.erase(ID_p)
	return path

func create_randPath(nodes):
	var path = AStar.new()
	path.add_point(path.get_available_point_id(), nodes.pop_front())
	
	while nodes:
		var isAssigned = false	# Bool: Controlla se il nodo è già stato assegnato
		var rand_p = null		# Nodo casuale
		var p = null			# Posizione corrente
		var r
		
		for p1 in path.get_points():
			p1 = path.get_point_position(p1)
			isAssigned = false
			r = num_rooms
			for p2 in nodes:
				if (!isAssigned):
					rand_p = p2
					p = p1
				if (randi()%r) == (randi()%r):
					isAssigned = !isAssigned
				
		var n = path.get_available_point_id()
		path.add_point(n, rand_p)
		path. connect_points(path.get_closest_point(p), n)
		nodes.erase(rand_p)
	return path

func make_map():
	Map.clear()
	var startSet = false
	var exitSet = false
	var i = 0
	var start_room = randi()%num_rooms
	var exit_room = randi()%num_rooms
	
	var full_rect = Rect2()
	for room in $Rooms.get_children():
		var r = Rect2(room.position-room.size, room.get_node("CollisionShape2D").shape.extents*2)
		full_rect = full_rect.merge(r)
	var topleft = Map.world_to_map(full_rect.position)
	var bottomright = Map.world_to_map(full_rect.end)
	for x in range(topleft.x,bottomright.x):
		for y in range(topleft.y,bottomright.y):
			Map.set_cell(x,y,0)
			
	var pathSeed=randi()%4+1
	if(pathSeed==1 || (randi()%2==0 && pathSeed!=2)):
		var mincorridors = []
		for room in $Rooms.get_children():
			var iNum = (randi()%(maxitemsXroom+1))
			var eNum = (randi()%(maxenemXroom+1))
			var s = (room.size/tile_size).floor()
			var pos = Map.world_to_map(room.position)
			var ul = (room.position / tile_size).floor() - s
			for x in range(2, s.x*2-1):
				for y in range(2, s.y*2-1):
					if(pathSeed==1):
						if(randi()%room.tilenum==0):
							var tileType=randi()%2
							if(tileType==0 && iNum>0):
								Map.set_cell(ul.x+x, ul.y+y, 5)
								iNum = iNum - 1
							elif(tileType==1 && eNum>0):
								Map.set_cell(ul.x+x, ul.y+y, 6)
								eNum = iNum - 1
							else: Map.set_cell(ul.x+x, ul.y+y, 2)
						elif(randi()%room.tilenum==0 || randi()%room.tilenum/2==0):
							var tileType=randi()%2
							if(tileType==0 && startSet == false && i == start_room):
								Map.set_cell(ul.x+x, ul.y+y, 3)
								startSet = true
							elif(tileType==1 && exitSet == false && i == exit_room):
								Map.set_cell(ul.x+x, ul.y+y, 4)
								exitSet = true
							else: Map.set_cell(ul.x+x, ul.y+y, 2)
						else: Map.set_cell(ul.x+x, ul.y+y, 2)
			var p = minpath.get_closest_point(Vector3(room.position.x, room.position.y, 0))
			for conn in minpath.get_point_connections(p):
				if not conn in mincorridors:
					var start = Map.world_to_map(Vector2(minpath.get_point_position(p).x,minpath.get_point_position(p).y))
					var end = Map.world_to_map(Vector2(minpath.get_point_position(conn).x,minpath.get_point_position(conn).y))
					carve_path(start,end)
				mincorridors.append(p)
			i = i + 1
			if(i%num_rooms==0): i = 0
	
	if(pathSeed==2 || (randi()%4==0 && pathSeed!=1)):
		var maxcorridors = []
		for room in $Rooms.get_children():
			var iNum = (randi()%(maxitemsXroom+1))
			var eNum = (randi()%(maxenemXroom+1))
			var s = (room.size/tile_size).floor()
			var pos = Map.world_to_map(room.position)
			var ul = (room.position / tile_size).floor() - s
			for x in range(2, s.x*2-1):
				for y in range(2, s.y*2-1):
					if(pathSeed==2):
						if(randi()%room.tilenum==0):
							var tileType=randi()%2
							if(tileType==0 && iNum>0):
								Map.set_cell(ul.x+x, ul.y+y, 5)
								iNum = iNum - 1
							elif(tileType==1 && eNum>0):
								Map.set_cell(ul.x+x, ul.y+y, 6)
								eNum = iNum - 1
							else: Map.set_cell(ul.x+x, ul.y+y, 2)
						elif(randi()%room.tilenum==0 || randi()%room.tilenum/2==0):
							var tileType=randi()%2
							if(tileType==0 && startSet == false && i == start_room):
								Map.set_cell(ul.x+x, ul.y+y, 3)
								startSet = true
							elif(tileType==1 && exitSet == false && i == exit_room):
								Map.set_cell(ul.x+x, ul.y+y, 4)
								exitSet = true
							else: Map.set_cell(ul.x+x, ul.y+y, 2)
						else: Map.set_cell(ul.x+x, ul.y+y, 2)
			var p = maxpath.get_closest_point(Vector3(room.position.x, room.position.y, 0))
			for conn in maxpath.get_point_connections(p):
				if not conn in maxcorridors:
					var start = Map.world_to_map(Vector2(maxpath.get_point_position(p).x,maxpath.get_point_position(p).y))
					var end = Map.world_to_map(Vector2(maxpath.get_point_position(conn).x,maxpath.get_point_position(conn).y))
					carve_path(start,end)
				maxcorridors.append(p)
			i = i + 1
			if(i%num_rooms==0): i = 0
	
	if(pathSeed==3 || (randi()%6==0 && pathSeed!=4)):
		var IDcorridors = []
		for room in $Rooms.get_children():
			var iNum = (randi()%(maxitemsXroom+1))
			var eNum = (randi()%(maxenemXroom+1))
			var s = (room.size/tile_size).floor()
			var pos = Map.world_to_map(room.position)
			var ul = (room.position / tile_size).floor() - s
			for x in range(2, s.x*2-1):
				for y in range(2, s.y*2-1):
					if(pathSeed==3):
						if(randi()%room.tilenum==0):
							var tileType=randi()%2
							if(tileType==0 && iNum>0):
								Map.set_cell(ul.x+x, ul.y+y, 5)
								iNum = iNum - 1
							elif(tileType==1 && eNum>0):
								Map.set_cell(ul.x+x, ul.y+y, 6)
								eNum = iNum - 1
							else: Map.set_cell(ul.x+x, ul.y+y, 2)
						elif(randi()%room.tilenum==0  || randi()%room.tilenum/2==0):
							var tileType=randi()%2
							if(tileType==0 && startSet == false && i == start_room):
								Map.set_cell(ul.x+x, ul.y+y, 3)
								startSet = true
							elif(tileType==1 && exitSet == false && i == exit_room):
								Map.set_cell(ul.x+x, ul.y+y, 4)
								exitSet = true
							else: Map.set_cell(ul.x+x, ul.y+y, 2)
						else: Map.set_cell(ul.x+x, ul.y+y, 2)
			var p = IDpath.get_closest_point(Vector3(room.position.x, room.position.y, 0))
			for conn in IDpath.get_point_connections(p):
				if not conn in IDcorridors:
					var start = Map.world_to_map(Vector2(IDpath.get_point_position(p).x,IDpath.get_point_position(p).y))
					var end = Map.world_to_map(Vector2(IDpath.get_point_position(conn).x,IDpath.get_point_position(conn).y))
					carve_path(start,end)
				IDcorridors.append(p)
			i = i + 1
			if(i%num_rooms==0): i = 0
				
	if(pathSeed==4 || (randi()%2==0 && pathSeed!=3)):
		var randcorridors = []
		for room in $Rooms.get_children():
			var iNum = (randi()%(maxitemsXroom+1))
			var eNum = (randi()%(maxenemXroom+1))
			var s = (room.size/tile_size).floor()
			var pos = Map.world_to_map(room.position)
			var ul = (room.position / tile_size).floor() - s
			for x in range(2, s.x*2-1):
				for y in range(2, s.y*2-1):
					if(pathSeed==4):
						if(randi()%room.tilenum==0):
							var tileType=randi()%2
							if(tileType==0 && iNum>0):
								Map.set_cell(ul.x+x, ul.y+y, 5)
								iNum = iNum - 1
							elif(tileType==1 && eNum>0):
								Map.set_cell(ul.x+x, ul.y+y, 6)
								eNum = iNum - 1
							else: Map.set_cell(ul.x+x, ul.y+y, 2)
						elif(randi()%room.tilenum==0  || randi()%room.tilenum/2==0):
							var tileType=randi()%2
							if(tileType==0 && startSet == false && i == start_room):
								Map.set_cell(ul.x+x, ul.y+y, 3)
								startSet = true
							elif(tileType==1 && exitSet == false && i == exit_room):
								Map.set_cell(ul.x+x, ul.y+y, 4)
								exitSet = true
							else: Map.set_cell(ul.x+x, ul.y+y, 2)
						else: Map.set_cell(ul.x+x, ul.y+y, 2)
			var p = randpath.get_closest_point(Vector3(room.position.x, room.position.y, 0))
			for conn in randpath.get_point_connections(p):
				if not conn in randcorridors:
					var start = Map.world_to_map(Vector2(randpath.get_point_position(p).x,randpath.get_point_position(p).y))
					var end = Map.world_to_map(Vector2(randpath.get_point_position(conn).x,randpath.get_point_position(conn).y))
					carve_path(start,end)
				randcorridors.append(p)
			i = i + 1
			if(i%num_rooms==0): i = 0

func carve_path(pos1,pos2):
	var x_diff = sign(pos2.x - pos1.x)
	var y_diff = sign(pos2.y - pos1.y)
	if x_diff == 0: x_diff = pow(-1, randi()% 2)
	if y_diff == 0: y_diff = pow(-1, randi()% 2)
	var x_y = pos1
	var y_x = pos2
	if (randi()%2)>0:
		x_y = pos2
		y_x = pos1
	for x in range(pos1.x, pos2.x, x_diff):
		Map.set_cell(x, x_y.y, 2)
	for y in range(pos1.y, pos2.y, y_diff):
		Map.set_cell(y_x.x, y, 2)
