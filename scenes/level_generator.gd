extends Node3D
class_name LevelGenerator

const TILE_EMPTY = -1

class PlacedRoom:
	var room      # MandatoryRoom resource
	var x         # top-left tile x
	var y         # top-left tile y
	var w         # width in tiles
	var h         # height in tiles

func _create_tiles(width, height):
	var tiles = []
	for y in range(height):
		tiles.append([])
		for x in range(width):
			tiles[y].append(TILE_EMPTY)
	return tiles

func _place_rooms(width, height, tiles, mandatory_rooms):
	var placed_rooms = []
	var max_layout_attempts = 500
	var max_room_attempts = 10000

	for attempt in range(max_layout_attempts):
		# clear tiles
		for y in range(height):
			for x in range(width):
				tiles[y][x] = TILE_EMPTY
		placed_rooms.clear()

		var layout_ok = true

		for i in range(mandatory_rooms.size()):
			var room_res = mandatory_rooms[i]
			room_res.id = i  # assign a stable id

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

				# overlap check
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

				# commit this room
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

	# Failed after many attempts (e.g. rooms too big for grid)
	return placed_rooms

func generate_base_layout(width, height, mandatory_rooms):
	randomize()

	var tiles = _create_tiles(width, height)
	var placed_rooms = _place_rooms(width, height, tiles, mandatory_rooms)

	if placed_rooms.size() != mandatory_rooms.size():
		push_error("Could not place all mandatory rooms with given constraints.")
		return {}

	# At this point:
	# tiles[y][x] is either TILE_EMPTY or a room id (0..mandatory_rooms.size()-1)
	# placed_rooms has the bounds and MandatoryRoom refs.

	return {
		"width": width,
		"height": height,
		"tiles": tiles,
		"rooms": placed_rooms
	} 

# ----------------------------------------------------------------------
# WALL ARRAYS
# ----------------------------------------------------------------------

func _init_walls(width, height, h_walls, v_walls):
	h_walls.clear()
	v_walls.clear()

	# Horizontal walls: (height+1) x width
	for y in range(height + 1):
		h_walls.append([])
		for x in range(width):
			h_walls[y].append(true)  # true = wall present

	# Vertical walls: height x (width+1)
	for y in range(height):
		v_walls.append([])
		for x in range(width + 1):
			v_walls[y].append(true)  # true = wall present

func _open_wall_between(x1, y1, x2, y2, h_walls, v_walls):
	# Opens the wall between two neighboring tiles
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

# 0=up, 1=down, 2=left, 3=right

func _generate_maze(width, height, h_walls, v_walls, straight_bias):
	var visited = []
	for y in range(height):
		visited.append([])
		for x in range(width):
			visited[y].append(false)

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

		# choose neighbor, biased to keep going straight
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

func _open_neighbor_count(x, y, width, height, h_walls, v_walls):
	var c = 0
	# up
	if y > 0 and not h_walls[y][x]:
		c += 1
	# down
	if y < height - 1 and not h_walls[y + 1][x]:
		c += 1
	# left
	if x > 0 and not v_walls[y][x]:
		c += 1
	# right
	if x < width - 1 and not v_walls[y][x + 1]:
		c += 1
	return c

func _closed_neighbors(x, y, width, height, h_walls, v_walls):
	var res = []
	# up
	if y > 0 and h_walls[y][x]:
		res.append(Vector2(x, y - 1))
	# down
	if y < height - 1 and h_walls[y + 1][x]:
		res.append(Vector2(x, y + 1))
	# left
	if x > 0 and v_walls[y][x]:
		res.append(Vector2(x - 1, y))
	# right
	if x < width - 1 and v_walls[y][x + 1]:
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

				# Prefer neighbors with lower degree to avoid huge hubs
				var best = []
				var min_deg = 99
				for n in closed:
					var nx = int(n.x)
					var ny = int(n.y)
					var nd = _open_neighbor_count(nx, ny, width, height, h_walls, v_walls)
					if nd < min_deg:
						min_deg = nd
						best = [n]
					elif nd == min_deg:
						best.append(n)

				var target = best[randi() % best.size()]
				_open_wall_between(x, y, int(target.x), int(target.y), h_walls, v_walls)
				changed = true

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
						continue  # neighbor inside same room

					# boundary edge: check if wall between them is open
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

func add_walls_to_layout(layout, straight_bias = 0.85):
	var width = layout["width"]
	var height = layout["height"]
	var tiles = layout["tiles"]
	var rooms = layout["rooms"]

	var h_walls = []
	var v_walls = []
	_init_walls(width, height, h_walls, v_walls)

	_generate_maze(width, height, h_walls, v_walls, straight_bias)
	_open_room_interior(rooms, h_walls, v_walls)
	_remove_dead_ends(width, height, h_walls, v_walls)
	_ensure_two_exits(width, height, tiles, rooms, h_walls, v_walls)

	layout["h_walls"] = h_walls
	layout["v_walls"] = v_walls
	return layout

func _create_gas_layer(width, height):
	var gas = []
	for y in height:
		gas.append([])
		for x in width:
			gas[y].append(false)
	return gas

func add_gas_to_layout(layout, target_ratio = 0.3):
	var width = layout["width"]
	var height = layout["height"]
	var tiles = layout["tiles"]
	var rooms = layout["rooms"]   # not used yet, but handy if you want to avoid certain rooms

	var gas = _create_gas_layer(width, height)

	# collect all candidate tiles
	var coords = []
	for y in height:
		for x in width:
			coords.append(Vector2(x, y))

	if coords.size() == 0:
		layout["gas"] = gas
		return layout

	var target = int(target_ratio * coords.size())
	if target <= 0:
		layout["gas"] = gas
		return layout

	# optional: avoid certain room types
	# var forbidden_room_ids = []
	# for pr in rooms:
	#     if pr.room.type == MandatoryRoom.RoomType.CONTROL:
	#         forbidden_room_ids.append(pr.room.id)
	#
	# func _is_valid_gas_tile(x, y):
	#     if tiles[y][x] in forbidden_room_ids:
	#         return false
	#     return true

	# for now, allow gas anywhere:
	var _is_valid_gas_tile = func _is_valid_gas_tile(x, y):
		return true

	coords.shuffle()

	var filled = 0
	var max_patch_attempts = 1000

	# parameters controlling blob sizes
	var min_patch_size = 5
	var max_patch_size = 25

	var dirs = [
		Vector2(0, -1),
		Vector2(0, 1),
		Vector2(-1, 0),
		Vector2(1, 0)
	]

	var attempt = 0
	while filled < target and attempt < max_patch_attempts:
		attempt += 1

		# pick a random seed tile that is not yet gas
		var seed = coords[randi() % coords.size()]
		var sx = int(seed.x)
		var sy = int(seed.y)

		if gas[sy][sx]:
			continue
		if not _is_valid_gas_tile.call(sx, sy):
			continue

		# decide patch size (clamped by remaining capacity)
		var remaining = target - filled
		var desired = min_patch_size + randi() % max(1, (max_patch_size - min_patch_size + 1))
		var patch_target = min(desired, remaining)
		if patch_target <= 0:
			break

		# grow a local patch via BFS from this seed
		var queue = [Vector2(sx, sy)]
		gas[sy][sx] = true
		filled += 1
		var patch_size = 1

		while queue.size() > 0 and patch_size < patch_target:
			var cur = queue.pop_back()
			var cx = int(cur.x)
			var cy = int(cur.y)

			# randomize neighbor order for organic shapes
			var local_dirs = dirs.duplicate()
			local_dirs.shuffle()

			for d in local_dirs:
				var nx = cx + int(d.x)
				var ny = cy + int(d.y)
				if nx < 0 or nx >= width or ny < 0 or ny >= height:
					continue
				if gas[ny][nx]:
					continue
				if not _is_valid_gas_tile.call(nx, ny):
					continue

				gas[ny][nx] = true
				filled += 1
				patch_size += 1
				queue.append(Vector2(nx, ny))

				if patch_size >= patch_target or filled >= target:
					break

			if filled >= target or patch_size >= patch_target:
				break

	layout["gas"] = gas
	return layout

func _create_bool_grid(width, height):
	var grid = []
	for y in height:
		grid.append([])
		for x in width:
			grid[y].append(false)
	return grid

func add_enemy_spawns_to_layout(layout, desired_count, min_distance):
	var width = layout["width"]
	var height = layout["height"]
	var tiles = layout["tiles"]
	var gas = layout["gas"] if layout.has("gas") else null

	var enemy_spawns = _create_bool_grid(width, height)

	# collect all candidate tiles
	var candidates = []
	for y in height:
		for x in width:
			candidates.append(Vector2(x, y))

	candidates.shuffle()

	var positions = []

	var too_close = func too_close(px, py):
		for p in positions:
			var dx = int(p.x) - px
			var dy = int(p.y) - py
			if abs(dx) + abs(dy) < min_distance:
				return true
		return false

	for pos in candidates:
		if positions.size() >= desired_count:
			break

		var x = int(pos.x)
		var y = int(pos.y)

		# optional: avoid gas tiles for enemies
		# if gas != null and gas[y][x]:
		#     continue

		# optional: avoid certain room types
		# if tiles[y][x] != TILE_EMPTY:
		#     continue

		if too_close.call(x, y):
			continue

		positions.append(Vector2(x, y))
		enemy_spawns[y][x] = true

	layout["enemy_spawns"] = enemy_spawns
	return layout

func _open_neighbors(x, y, width, height, h_walls, v_walls):
	var res = []
	# up: (x, y-1)
	if y > 0 and not h_walls[y][x]:
		res.append(Vector2(x, y - 1))
	# down: (x, y+1)
	if y < height - 1 and not h_walls[y + 1][x]:
		res.append(Vector2(x, y + 1))
	# left: (x-1, y)
	if x > 0 and not v_walls[y][x]:
		res.append(Vector2(x - 1, y))
	# right: (x+1, y)
	if x < width - 1 and not v_walls[y][x + 1]:
		res.append(Vector2(x + 1, y))
	return res

func _bfs_distances_from(sx, sy, width, height, h_walls, v_walls):
	var dist = []
	for y in height:
		dist.append([])
		for x in width:
			dist[y].append(-1)  # -1 = unreachable/unvisited

	var queue = []
	queue.append(Vector2(sx, sy))
	dist[sy][sx] = 0

	while queue.size() > 0:
		var cur = queue.pop_front()
		var cx = int(cur.x)
		var cy = int(cur.y)
		var cd = dist[cy][cx]

		var neighs = _open_neighbors(cx, cy, width, height, h_walls, v_walls)
		for n in neighs:
			var nx = int(n.x)
			var ny = int(n.y)
			if dist[ny][nx] != -1:
				continue
			dist[ny][nx] = cd + 1
			queue.append(Vector2(nx, ny))

	return dist

func add_bosses_to_layout(layout):
	var width = layout["width"]
	var height = layout["height"]
	var tiles = layout["tiles"]
	var gas = layout["gas"] if layout.has("gas") else null
	var h_walls = layout["h_walls"]
	var v_walls = layout["v_walls"]

	# collect candidate tiles for bosses
	var candidates = []
	for y in height:
		for x in width:
			# skip gas tiles
			if gas != null and gas[y][x]:
				continue
			# optional: prefer/require rooms or hallways, etc.
			# for now, allow any non-gas floor:
			candidates.append(Vector2(x, y))

	if candidates.size() < 2:
		layout["boss_positions"] = []
		return layout

	candidates.shuffle()
	var boss1 = candidates[0]

	# BFS from boss1 to get path distances
	var dist = _bfs_distances_from(int(boss1.x), int(boss1.y), width, height, h_walls, v_walls)

	var best_dist = -1
	var boss2 = candidates[1]

	for c in candidates:
		var x = int(c.x)
		var y = int(c.y)
		var d = dist[y][x]
		if d > best_dist:
			best_dist = d
			boss2 = c

	layout["boss_positions"] = [boss1, boss2]
	return layout

func _wall_sides_for_tile(x, y, width, height, h_walls, v_walls):
	# Returns an Array of side strings: "up", "down", "left", "right" for walls that touch this tile.
	var sides = []

	var up_wall = (y == 0) or h_walls[y][x]
	var down_wall = (y == height - 1) or h_walls[y + 1][x]
	var left_wall = (x == 0) or v_walls[y][x]
	var right_wall = (x == width - 1) or v_walls[y][x + 1]

	if up_wall:
		sides.append("up")
	if down_wall:
		sides.append("down")
	if left_wall:
		sides.append("left")
	if right_wall:
		sides.append("right")

	return sides

## CON

@export var width: int = 12
@export var height: int = 8
@export var straightaway_weight: float = 0.3
@export var grid_size: float = 5
@export var mandatory_rooms: Array[MandatoryRoom]

@export var placeholder_visual: PackedScene
@export var placeholder_gas: PackedScene

@export var floor_tile: PackedScene
@export var wall_tile: PackedScene

@export var gas_ratio: float = 0.3

@export var enemy_count: int = 20
@export var enemy_min_distance: int = 4

@export var enemy_placeholder: PackedScene
@export var boss_placeholder: PackedScene

@export var wall_decos: Array[PackedScene] = []
@export var free_decos: Array[PackedScene] = []

@export var wall_deco_chance: float = 0.4
@export var free_deco_chance: float = 0.1

func _grid2world(x: int, y: int) -> Vector3:
	return Vector3(-x, 0, -y) * grid_size

func _hwgrid2world(x: int, y: int) -> Vector3:
	var out = _grid2world(x, y)
	out.z += 0.5 * grid_size
	return out

func _vwgrid2world(x: int, y: int) -> Vector3:
	var out = _grid2world(x, y)
	out.x += 0.5 * grid_size
	return out

func _populate(layout) -> void:
	var tiles = layout["tiles"]
	var h_walls = layout["h_walls"]
	var v_walls = layout["v_walls"]

	var gas = layout["gas"] if layout.has("gas") else null
	var enemy_spawns = layout["enemy_spawns"] if layout.has("enemy_spawns") else null
	var boss_positions = layout["boss_positions"] if layout.has("boss_positions") else []

	# Build a quick grid to mark boss tiles (so we can avoid decorating them)
	var boss_grid = []
	for y in height:
		boss_grid.append([])
		for x in width:
			boss_grid[y].append(false)

	for bp in boss_positions:
		var bx = int(bp.x)
		var by = int(bp.y)
		if bx >= 0 and bx < width and by >= 0 and by < height:
			boss_grid[by][bx] = true

	# 1) Floors, gas, enemies, bosses, decorations
	for y in height:
		for x in width:
			# Floor (your existing logic)
			if tiles[y][x] == TILE_EMPTY:
				var floor_node = floor_tile.instantiate()
				add_child(floor_node)
				floor_node.global_position = _grid2world(x, y)

			# Gas
			if gas != null and gas[y][x] and placeholder_gas != null:
				var g = placeholder_gas.instantiate()
				add_child(g)
				g.global_position = _grid2world(x, y) + Vector3(0, 0.5 * grid_size, 0)

			# Enemies
			if enemy_spawns != null and enemy_spawns[y][x] and enemy_placeholder != null:
				var e = enemy_placeholder.instantiate()
				add_child(e)
				e.global_position = _grid2world(x, y)

			# Boss markers will be spawned later, but we mark them in boss_grid

			# DECORATIONS (skip important tiles)
			if gas != null and gas[y][x]:
				continue
			if enemy_spawns != null and enemy_spawns[y][x]:
				continue
			if boss_grid[y][x]:
				continue

			# Decide if we spawn any deco here
			# First see if this tile touches any wall edges
			var wall_sides = _wall_sides_for_tile(x, y, width, height, h_walls, v_walls)
			var has_wall = wall_sides.size() > 0

			# If there is a wall and we have wall decos and random roll passes -> wall deco
			if has_wall and wall_decos.size() > 0 and randf() < wall_deco_chance:
				var scene = wall_decos[randi() % wall_decos.size()]
				var deco = scene.instantiate()
				add_child(deco)

				var pos = _grid2world(x, y)
				deco.global_position = pos

				# Choose a side to attach to, randomly among walls present
				var side = wall_sides[randi() % wall_sides.size()]

				# Rough orientation; you can tweak these to match your asset facing
				# Remember: _grid2world(x,y) = Vector3(-x, 0, -y) * grid_size
				# So:
				# - "up" = towards y-1 (positive Z), wall above tile => deco can face down (negative Z)
				# - etc.
				if side == "up":
					deco.rotation_degrees.y = 0
					# If you want to push it toward the wall:
					# deco.global_position += Vector3(0, 0, 0.5 * grid_size)
				elif side == "down":
					deco.rotation_degrees.y = 180
					# deco.global_position += Vector3(0, 0, -0.5 * grid_size)
				elif side == "left":
					deco.rotation_degrees.y = 90
					# deco.global_position += Vector3(0.5 * grid_size, 0, 0)
				elif side == "right":
					deco.rotation_degrees.y = -90
					# deco.global_position += Vector3(-0.5 * grid_size, 0, 0)

			# Otherwise, maybe place a free‑standing deco
			elif free_decos.size() > 0 and randf() < free_deco_chance:
				var scene2 = free_decos[randi() % free_decos.size()]
				var deco2 = scene2.instantiate()
				add_child(deco2)
				deco2.global_position = _grid2world(x, y)
				# Random yaw so they don't all line up
				deco2.rotation_degrees.y = randf() * 360.0

	# 2) Bosses
	if boss_placeholder != null:
		for bp in boss_positions:
			var bx = int(bp.x)
			var by = int(bp.y)
			var b = boss_placeholder.instantiate()
			add_child(b)
			b.global_position = _grid2world(bx, by)

	# 3) Walls (unchanged)
	for y in height + 1:
		for x in width + 1:
			if y < height and v_walls[y][x]:
				var node_v = wall_tile.instantiate()
				add_child(node_v)
				node_v.global_position = _vwgrid2world(x, y)
			if x < width and h_walls[y][x]:
				var node_h = wall_tile.instantiate()
				add_child(node_h)
				node_h.global_position = _hwgrid2world(x, y)
				node_h.rotation_degrees.y = 90

func _ready() -> void:
	var base = generate_base_layout(width, height, mandatory_rooms)
	if base.size() == 0:
		push_error("Base failed")
		return

	var full = add_walls_to_layout(base, straightaway_weight)
	full = add_gas_to_layout(full, gas_ratio)
	full = add_enemy_spawns_to_layout(full, enemy_count, enemy_min_distance)
	full = add_bosses_to_layout(full)

	var tiles   = full["tiles"]
	var rooms   = full["rooms"]
	var h_walls = full["h_walls"]
	var v_walls = full["v_walls"]
	var gas     = full["gas"]
	var enemy_spawns  = full["enemy_spawns"]
	var boss_positions = full["boss_positions"]

	_populate(full)
