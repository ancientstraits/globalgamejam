extends Node3D
class_name MapGenerator

const TILE_EMPTY = -1

class PlacedRoom:
	var room
	var x
	var y
	var w
	var h

# ----------------------------------------------------------------------
# PUBLIC API
# ----------------------------------------------------------------------

func generate_map(width, height, mandatory_rooms, straight_bias = 0.85):
	randomize()

	# assign ids (0..n-1) to rooms so tiles can store them
	for i in range(mandatory_rooms.size()):
		mandatory_rooms[i].id = i

	var tiles = _create_tiles(width, height)
	var placed_rooms = _place_rooms(width, height, tiles, mandatory_rooms)
	if placed_rooms.size() != mandatory_rooms.size():
		push_error("Failed to place all mandatory rooms")
		return {}

	var h_walls = []
	var v_walls = []
	_init_walls(width, height, h_walls, v_walls)

	_generate_maze(width, height, h_walls, v_walls, straight_bias)
	_open_room_interior(placed_rooms, h_walls, v_walls)
	_remove_dead_ends(width, height, h_walls, v_walls)
	_ensure_two_exits(width, height, tiles, placed_rooms, h_walls, v_walls)

	return {
		"tiles": tiles,          # 2D: tiles[y][x] = room_id or TILE_EMPTY
		"rooms": placed_rooms,   # Array of PlacedRoom
		"h_walls": h_walls,      # (height+1) x width, true = wall
		"v_walls": v_walls       # height x (width+1), true = wall
	}

# ----------------------------------------------------------------------
# 1. Tiles and room placement
# ----------------------------------------------------------------------

func _create_tiles(width, height):
	var tiles = []
	for y in range(height):
		tiles.append([])
		for x in range(width):
			tiles[y].append(TILE_EMPTY)
	return tiles

func _place_rooms(width, height, tiles, mandatory_rooms):
	var placed_rooms = []
	var max_layout_attempts = 50
	var max_room_attempts = 200

	for attempt in range(max_layout_attempts):
		# clear tiles
		for y in range(height):
			for x in range(width):
				tiles[y][x] = TILE_EMPTY
		placed_rooms.clear()

		var layout_ok = true

		for room_res in mandatory_rooms:
			var placed = false
			for t in range(max_room_attempts):
				var rotated = randf() < 0.5
				var size = room_res.size_for_rotation(rotated)
				var rw = size.x
				var rh = size.y
				if rw > width or rh > height:
					continue

				var x0 = randi() % (width - rw + 1)
				var y0 = randi() % (height - rh + 1)

				# check overlap
				var overlap = false
				for yy in range(rh):
					for xx in range(rw):
						if tiles[y0 + yy][x0 + xx] != TILE_EMPTY:
							overlap = true
							break
					if overlap:
						break
				if overlap:
					continue

				# commit room
				for yy in range(rh):
					for xx in range(rw):
						tiles[y0 + yy][x0 + xx] = room_res.id

				var pr = PlacedRoom.new()
				pr.room = room_res
				pr.x = x0
				pr.y = y0
				pr.w = rw
				pr.h = rh
				placed_rooms.append(pr)

				placed = true
				break

			if not placed:
				layout_ok = false
				break

		if layout_ok:
			return placed_rooms

	# failed after many attempts
	return placed_rooms

# ----------------------------------------------------------------------
# 2. Walls representation
# ----------------------------------------------------------------------

func _init_walls(width, height, h_walls, v_walls):
	h_walls.clear()
	v_walls.clear()

	# horizontal walls: (height+1) x width
	for y in range(height + 1):
		h_walls.append([])
		for x in range(width):
			h_walls[y].append(true)

	# vertical walls: height x (width+1)
	for y in range(height):
		v_walls.append([])
		for x in range(width + 1):
			v_walls[y].append(true)

func _open_wall_between(x1, y1, x2, y2, h_walls, v_walls):
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

func _in_bounds(x, y, width, height):
	return x >= 0 and x < width and y >= 0 and y < height

# ----------------------------------------------------------------------
# 3. Biased DFS maze (straight-ish hallways)
# ----------------------------------------------------------------------

func _generate_maze(width, height, h_walls, v_walls, straight_bias):
	var visited = []
	for y in range(height):
		visited.append([])
		for x in range(width):
			visited[y].append(false)

	# 0=up, 1=down, 2=left, 3=right
	var dir_vecs = [
		Vector2(0, -1),
		Vector2(0, 1),
		Vector2(-1, 0),
		Vector2(1, 0)
	]

	var stack = []

	var sx = randi() % width
	var sy = randi() % height
	stack.append({"x": sx, "y": sy, "last_dir": -1})
	visited[sy][sx] = true

	while stack.size() > 0:
		var cur = stack[stack.size() - 1]
		var cx = cur["x"]
		var cy = cur["y"]
		var last_dir = cur["last_dir"]

		# collect unvisited neighbors
		var candidates = []
		for d in range(4):
			var nx = cx + int(dir_vecs[d].x)
			var ny = cy + int(dir_vecs[d].y)
			if _in_bounds(nx, ny, width, height) and not visited[ny][nx]:
				candidates.append({"dir": d, "x": nx, "y": ny})

		if candidates.is_empty():
			stack.pop_back()
			continue

		# choose direction with bias to continue straight
		var chosen = candidates[randi() % candidates.size()]
		if last_dir != -1 and randf() < straight_bias:
			for c in candidates:
				if c["dir"] == last_dir:
					chosen = c
					break

		var nx2 = chosen["x"]
		var ny2 = chosen["y"]
		var d2 = chosen["dir"]

		_open_wall_between(cx, cy, nx2, ny2, h_walls, v_walls)
		visited[ny2][nx2] = true
		stack.append({"x": nx2, "y": ny2, "last_dir": d2})

# ----------------------------------------------------------------------
# 4. Open room interiors (rooms become big open spaces)
# ----------------------------------------------------------------------

func _open_room_interior(placed_rooms, h_walls, v_walls):
	for pr in placed_rooms:
		var x0 = pr.x
		var y0 = pr.y
		var w = pr.w
		var h = pr.h

		for yy in range(h):
			for xx in range(w):
				var x = x0 + xx
				var y = y0 + yy

				# right neighbor inside room
				if xx + 1 < w:
					_open_wall_between(x, y, x + 1, y, h_walls, v_walls)
				# bottom neighbor inside room
				if yy + 1 < h:
					_open_wall_between(x, y, x, y + 1, h_walls, v_walls)

# ----------------------------------------------------------------------
# 5. Remove dead ends (no cul-de-sacs)
# ----------------------------------------------------------------------

func _open_neighbor_count(x, y, width, height, h_walls, v_walls):
	var c = 0
	if y > 0 and not h_walls[y][x]:
		c += 1
	if y + 1 < height and not h_walls[y + 1][x]:
		c += 1
	if x > 0 and not v_walls[y][x]:
		c += 1
	if x + 1 < width and not v_walls[y][x + 1]:
		c += 1
	return c

func _closed_neighbors(x, y, width, height, h_walls, v_walls):
	var res = []
	if y > 0 and h_walls[y][x]:
		res.append(Vector2(x, y - 1))
	if y + 1 < height and h_walls[y + 1][x]:
		res.append(Vector2(x, y + 1))
	if x > 0 and v_walls[y][x]:
		res.append(Vector2(x - 1, y))
	if x + 1 < width and v_walls[y][x + 1]:
		res.append(Vector2(x + 1, y))
	return res

func _remove_dead_ends(width, height, h_walls, v_walls):
	var changed = true
	while changed:
		changed = false
		for y in range(height):
			for x in range(width):
				var deg = _open_neighbor_count(x, y, width, height, h_walls, v_walls)
				if deg != 1:
					continue

				var closed = _closed_neighbors(x, y, width, height, h_walls, v_walls)
				if closed.is_empty():
					continue

				# prefer neighbors with lower degree (fewer big hubs)
				var best = []
				var min_deg = 99
				for n in closed:
					var nd = _open_neighbor_count(int(n.x), int(n.y), width, height, h_walls, v_walls)
					if nd < min_deg:
						min_deg = nd
						best = [n]
					elif nd == min_deg:
						best.append(n)

				var target = best[randi() % best.size()]
				_open_wall_between(x, y, int(target.x), int(target.y), h_walls, v_walls)
				changed = true

# ----------------------------------------------------------------------
# 6. Ensure each room has at least 2 exits
# ----------------------------------------------------------------------

func _ensure_two_exits(width, height, tiles, placed_rooms, h_walls, v_walls):
	for pr in placed_rooms:
		var room_id = pr.room.id
		var x0 = pr.x
		var y0 = pr.y
		var w = pr.w
		var h = pr.h

		var exits = 0
		var closed_edges = []

		for yy in range(h):
			for xx in range(w):
				var x = x0 + xx
				var y = y0 + yy
				if tiles[y][x] != room_id:
					continue

				var neighbors = [
					Vector2(x, y - 1),
					Vector2(x, y + 1),
					Vector2(x - 1, y),
					Vector2(x + 1, y)
				]

				for n in neighbors:
					var nx = int(n.x)
					var ny = int(n.y)
					if not _in_bounds(nx, ny, width, height):
						continue
					if tiles[ny][nx] == room_id:
						continue  # internal

					# boundary edge: check wall
					var open = false
					if nx == x and ny == y - 1:      # up
						open = not h_walls[y][x]
					elif nx == x and ny == y + 1:    # down
						open = not h_walls[y + 1][x]
					elif ny == y and nx == x - 1:    # left
						open = not v_walls[y][x]
					elif ny == y and nx == x + 1:    # right
						open = not v_walls[y][x + 1]

					if open:
						exits += 1
					else:
						closed_edges.append({
							"ax": x, "ay": y,
							"bx": nx, "by": ny
						})

		closed_edges.shuffle()
		var i = 0
		while exits < 2 and i < closed_edges.size():
			var e = closed_edges[i]
			i += 1
			_open_wall_between(
				e["ax"], e["ay"],
				e["bx"], e["by"],
				h_walls, v_walls
			)
			exits += 1

func _grid_pos_to_world(x, y) -> Vector3:
	return Vector3(-x, 0, -y) * tile_size

func _h_wall_grid_pos_to_world(x, y) -> Vector3:
	var out = _grid_pos_to_world(x, y)
	out.x += 0.5 * tile_size
	return out

func _v_wall_grid_pos_to_world(x, y) -> Vector3:
	var out = _grid_pos_to_world(x, y)
	out.z += 0.5 * tile_size
	return out

@export var height: int
@export var width: int
@export var straightaway_bias: float = 0.85
@export var tile_size: float = 1

@export var mandatory_rooms: Array[MandatoryRoom]

@export var floor: PackedScene
@export var room_floor: PackedScene
@export var wall: PackedScene

func _place_tiles(result) -> void:
	for rm in result['rooms']:
		var node = rm.room.scene.instantiate()
		add_child(node)
		if rm.w < rm.h:
			node.global_position = _grid_pos_to_world(rm.y, rm.x + 1)
			node.rotation_degrees.y = -90
		else:
			node.global_position = _grid_pos_to_world(rm.y, rm.x)

	for y in range(height):
		for x in range(width):
			var node = 0
			if result['tiles'][x][y] == TILE_EMPTY:
				node = floor.instantiate()
				add_child(node)
				node.global_position = _grid_pos_to_world(x, y)

	for y in range(height + 1):
		for x in range(width + 1):
			if y < height and result['h_walls'][x][y]:
				var node = 0
				node = wall.instantiate()
				add_child(node)
				node.global_position = _h_wall_grid_pos_to_world(x, y)

			if x < width and result['v_walls'][x][y]:
				var node = 0
				node = wall.instantiate()
				add_child(node)
				node.global_position = _v_wall_grid_pos_to_world(x, y)
				node.rotation_degrees.y = 90


func _ready() -> void:
	var result: Dictionary = generate_map(height, width, mandatory_rooms, straightaway_bias)
	if result.size() == 0:
		print("generation failed")
	else:
		_place_tiles(result)
		print("success")
