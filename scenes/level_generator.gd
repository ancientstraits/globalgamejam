extends Node3D

const EMPTY: int = -1

@export var width: int
@export var height: int
@export var mandatory_rooms: Array[MandatoryRoom]

var tiles: Array = []

func _grid_pos_to_world(x: int, y: int) -> Vector3:
	return Vector3(-x, 0, -y)

func _h_wall_pos_to_world(x: int, y: int) -> Vector3:
	var out = _grid_pos_to_world(x, y)
	out.z += 0.5
	return out

func _v_wall_pos_to_world(x: int, y: int) -> Vector3:
	var out = _grid_pos_to_world(x, y)
	out.x += 0.5
	return out

func _init_grid():
	tiles.resize(height)
	for y in height:
		tiles[y] = []
		tiles[y].resize(width)
		for x in width:
			tiles[y][x] = EMPTY

var h_walls: Array = []
var v_walls: Array = []

func _init_walls():
	h_walls.resize(height + 1)
	for y in height + 1:
		h_walls[y] = []
		h_walls[y].resize(width)
		for x in width:
			h_walls[y][x] = true
	
	v_walls.resize(height)
	for y in height:
		v_walls[y] = []
		v_walls[y].resize(width + 1)
		for x in width + 1:
			v_walls[y][x] = true

var placed_rooms: Array = []  # store instances if you need them later

class RoomInstance:
	var preset: MandatoryRoom
	var origin: Vector2i  # top-left tile
	var rotated: bool     # false = (w,h), true = (h,w)

func _room_size(p: MandatoryRoom, rotated: bool) -> Vector2i:
	return Vector2i(p.height, p.width) if rotated else Vector2i(p.width, p.height)

func _can_place_room(preset: MandatoryRoom, origin: Vector2i, rotated: bool) -> bool:
	var size: Vector2i = preset.size_for_rotation(rotated)

	if origin.x < 0 or origin.y < 0:
		return false
	if origin.x + size.x > width or origin.y + size.y > height:
		return false

	for dy in size.y:
		var y := origin.y + dy
		for dx in size.x:
			var x := origin.x + dx
			if tiles[y][x] != EMPTY:
				return false
	return true

func _apply_room(preset: MandatoryRoom, origin: Vector2i, rotated: bool, place: bool) -> void:
	var size := preset.size_for_rotation(rotated)
	var value := preset.id if place else EMPTY
	for dy in size.y:
		var y := origin.y + dy
		for dx in size.x:
			var x := origin.x + dx
			tiles[y][x] = value

func place_mandatory_rooms_random(mandatory: Array[MandatoryRoom]) -> bool:
	_init_grid()
	placed_rooms.clear()

	var max_config_attempts := 1000
	var max_room_tries := 5000 # per room per config

	# Can shuffle order if you want extra randomness:
	var presets := mandatory.duplicate()
	presets.shuffle()

	for attempt in max_config_attempts:
		# clear grid this attempt
		for y in height:
			for x in width:
				tiles[y][x] = EMPTY
		placed_rooms.clear()

		var success_config := true

		for preset in presets:
			var placed := false
			for t in max_room_tries:
				var rotated := bool(randi() & 1)
				var size: Vector2i = preset.size_for_rotation(rotated)

				var x := randi() % (width - size.x + 1)
				var y := randi() % (height - size.y + 1)
				var origin := Vector2i(x, y)

				if not _can_place_room(preset, origin, rotated):
					continue
				# if not _respects_spread(preset, origin, rotated):
				#     continue

				_apply_room(preset, origin, rotated, true)

				var inst := RoomInstance.new()
				inst.preset = preset
				inst.origin = origin
				inst.rotated = rotated
				placed_rooms.append(inst)

				placed = true
				break

			if not placed:
				success_config = false
				break

		if success_config:
			return true  # we got a full, random, valid layout

	return false  # couldn’t place with constraints

class DSU:
	var parent: Array
	var rank: Array

	func _init(size: int) -> void:
		parent.resize(size)
		rank.resize(size)
		for i in size:
			parent[i] = i
			rank[i] = 0

	func find(x: int) -> int:
		if parent[x] != x:
			parent[x] = find(parent[x])
		return parent[x]

	func union(a: int, b: int) -> void:
		var pa = find(a)
		var pb = find(b)
		if pa == pb:
			return
		if rank[pa] < rank[pb]:
			parent[pa] = pb
		elif rank[pb] < rank[pa]:
			parent[pb] = pa
		else:
			parent[pb] = pa
			rank[pa] += 1

func tile_index(x: int, y: int) -> int:
	return y * width + x

func _force_rooms_open(dsu: DSU) -> void:
	for r in placed_rooms:
		var size: Vector2i = r.preset.size_for_rotation(r.rotated)
		for dy in size.y:
			var y: int = r.origin.y + dy
			for dx in size.x:
				var x: int = r.origin.x + dx
				var idx := tile_index(x, y)

				# connect to right neighbor inside same room
				if dx + 1 < size.x:
					var nx := x + 1
					var nidx := tile_index(nx, y)
					dsu.union(idx, nidx)
					v_walls[y][nx] = false

				# connect to bottom neighbor inside same room
				if dy + 1 < size.y:
					var ny := y + 1
					var nidx2 := tile_index(x, ny)
					dsu.union(idx, nidx2)
					h_walls[ny][x] = false

func _is_same_room(x1: int, y1: int, x2: int, y2: int) -> bool:
	return tiles[y1][x1] != EMPTY and tiles[y1][x1] == tiles[y2][x2]

class Edge:
	var ax: int
	var ay: int
	var bx: int
	var by: int

func _collect_edges() -> Array:
	var edges: Array = []
	for y in height:
		for x in width:
			if x + 1 < width and not _is_same_room(x, y, x + 1, y):
				var e := Edge.new()
				e.ax = x; e.ay = y
				e.bx = x + 1; e.by = y
				edges.append(e)
			if y + 1 < height and not _is_same_room(x, y, x, y + 1):
				var e2 := Edge.new()
				e2.ax = x; e2.ay = y
				e2.bx = x; e2.by = y + 1
				edges.append(e2)
	return edges

func _build_edges() -> Array:
	var edges: Array = []
	for y in height:
		for x in width:
			# right neighbor
			if x + 1 < width:
				# skip; internal room edges already handled
				if not _is_same_room(x, y, x + 1, y):
					var e := Edge.new()
					e.a_x = x; e.a_y = y
					e.b_x = x + 1; e.b_y = y
					edges.append(e)
			# bottom neighbor
			if y + 1 < height:
				if not _is_same_room(x, y, x, y + 1):
					var e2 := Edge.new()
					e2.a_x = x; e2.a_y = y
					e2.b_x = x; e2.b_y = y + 1
					edges.append(e2)
	return edges

func generate_maze_walls() -> void:
	_init_walls()

	var dsu := DSU.new(width * height)

	# 1) Rooms fully open inside
	_force_rooms_open(dsu)

	# 2) Random spanning tree over rest (perfect maze)
	var edges := _collect_edges()
	edges.shuffle()

	for e in edges:
		var a_idx := tile_index(e.ax, e.ay)
		var b_idx := tile_index(e.bx, e.by)
		var pa := dsu.find(a_idx)
		var pb := dsu.find(b_idx)
		if pa != pb:
			dsu.union(pa, pb)
			_open_wall_between(e.ax, e.ay, e.bx, e.by)

	# 3) Remove dead ends to get “no cul‑de‑sacs”
	# _remove_dead_ends()

func _open_wall_between(x1: int, y1: int, x2: int, y2: int) -> void:
	if x1 == x2:
		# vertical neighbors -> horizontal wall
		if y2 == y1 + 1:
			h_walls[y2][x1] = false
		elif y1 == y2 + 1:
			h_walls[y1][x1] = false
	elif y1 == y2:
		# horizontal neighbors -> vertical wall
		if x2 == x1 + 1:
			v_walls[y1][x2] = false
		elif x1 == x2 + 1:
			v_walls[y1][x1] = false

func generate_map(w: int, h: int, mandatory_rooms: Array[MandatoryRoom]) -> bool:
	width = w
	height = h

	# 1. random room placement
	if not place_mandatory_rooms_random(mandatory_rooms):
		return false

	# 2. mark all remaining tiles as “hallway” (still floor)
	for y in height:
		for x in width:
			if tiles[y][x] == EMPTY:
				tiles[y][x] = EMPTY  # or some special “hallway” id if you want
									 # but it’s still a walkable tile

	# 3. random walls with connectivity and open rooms
	generate_maze_walls()

	return true

func _in_bounds(x: int, y: int) -> bool:
	return x >= 0 and x < width and y >= 0 and y < height

func _open_neighbor_count(x: int, y: int) -> int:
	var c := 0
	# up
	if y > 0 and not h_walls[y][x]:
		c += 1
	# down
	if y + 1 < height and not h_walls[y + 1][x]:
		c += 1
	# left
	if x > 0 and not v_walls[y][x]:
		c += 1
	# right
	if x + 1 < width and not v_walls[y][x + 1]:
		c += 1
	return c

func _closed_neighbors(x: int, y: int) -> Array:
	var res: Array = []
	# up
	if y > 0 and h_walls[y][x]:
		res.append(Vector2i(x, y - 1))
	# down
	if y + 1 < height and h_walls[y + 1][x]:
		res.append(Vector2i(x, y + 1))
	# left
	if x > 0 and v_walls[y][x]:
		res.append(Vector2i(x - 1, y))
	# right
	if x + 1 < width and v_walls[y][x + 1]:
		res.append(Vector2i(x + 1, y))
	return res

func _remove_dead_ends() -> void:
	# We only need a single pass: each dead end gets 1 extra connection.
	for y in height:
		for x in width:
			var deg := _open_neighbor_count(x, y)
			if deg != 1:
				continue

			var closed := _closed_neighbors(x, y)
			if closed.is_empty():
				continue  # should not happen if deg == 1, but safe

			# Prefer neighbors with smaller degree to avoid huge hubs
			var best_candidates: Array = []
			var min_deg := 99
			for n in closed:
				var nd := _open_neighbor_count(n.x, n.y)
				if nd < min_deg:
					min_deg = nd
					best_candidates = [n]
				elif nd == min_deg:
					best_candidates.append(n)

			var target: Vector2i = best_candidates[randi() % best_candidates.size()]
			_open_wall_between(x, y, target.x, target.y)

func place_placeholders() -> bool:
	for y in height:
		for x in width:
			var node = 0
			if tiles[y][x] == EMPTY:
				node = placeholder_tile.instantiate()
			else:
				node = placeholder_room_tile.instantiate()
			add_child(node)
			node.global_position = _grid_pos_to_world(x, y)
	
	for y in range(height + 1):
		for x in range(width + 1):
			if x < width and h_walls[y][x]:
				var node = 0
				node = placeholder_wall.instantiate()
				add_child(node)
				node.global_position = _h_wall_pos_to_world(x, y)
				node.rotation_degrees.y = 90
			if y < height and v_walls[y][x]:
				var node = 0
				node = placeholder_wall.instantiate()
				add_child(node)
				node.global_position = _v_wall_pos_to_world(x, y)
				# node.rotation_degrees.y = 90
	
	return true

@export var placeholder_wall: PackedScene
@export var placeholder_room_tile: PackedScene
@export var placeholder_tile: PackedScene

func _ready() -> void:
	generate_map(width, height, mandatory_rooms)
	place_placeholders()
