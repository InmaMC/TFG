###### OUR HATCHBOTS ARE GOING TO BE BOIDS WITH ALIGMENT 
extends "res://render_bots/bots/Bot.gd"

# States of the bot
enum States{
	SEARCHING,
	DRAWING
} 

var const_direction = Vector2.RIGHT  #Vector2(PI, 1).normalized()

var state = States.DRAWING
var max_velocity = 100.0
var max_acceleration = 600.0
var target_velocity = Vector2.ZERO
var current_velocity = const_direction * max_velocity
var length_factor = 2
var markers : Array
var light : Vector3 = Vector3.DOWN
var thickness : float = 1
#var direction_vector = Vector2.ZERO
#var previous_direction : Vector2 = Vector2.ZERO
#var correction_vector : Vector2 = Vector2.ZERO
#var markers : Array = Array()
#var markers_distance = 2.0

var image_size : Vector2 = Vector2.ZERO
var searching_frames : int = 0

# boids parameters
var neighbours : Array  = []
var separation_distance = 10
var separation_weight = 6
var separation : Vector2
var alignment_weight = 4
var alignment : Vector2
var cohesion_weight = 0.0
var cohesion : Vector2
var proj_d : Vector2

# TODO
# use them as forces, add them to calculate velocity, different weights for every parameter
# constantly moving, draw if good htch
# also markers with a different weigth - than bots-> cohesion and separation


func _ready() -> void:
	light = GlobalConfig.light_direction
	separation_distance = GlobalConfig.separation
	thickness = GlobalConfig.hatch_thick
	color = GlobalConfig.hatch_color
	const_direction = GlobalConfig.direction


func clamp_position(pos : Vector2) -> Vector2:
	pos.x = clamp(pos.x, 0, image_size.x - 1)
	pos.y = clamp(pos.y, 0, image_size.y -1)
	return pos
	
# change position to opposite edge of the image to if reach limit
func wrap_position(pos : Vector2) -> Vector2:
	if pos.x > image_size.x - 1:
		pos.x = 1
		pos.y = rand_range(1, image_size.y - 1)
	if pos.x <= 0:
		pos.x = image_size.x - 1
		pos.y = rand_range(1, image_size.y -1)
	if pos.y > image_size.y - 1:
		pos.y = 1
		pos.x = rand_range(1, image_size.x - 1)
	if pos.y <= 0:
		pos.y = image_size.y - 1
		pos.x = rand_range(1, image_size.x - 1)
	
	return clamp_position(pos)
	
	
#func _draw():
#	draw_line(Vector2.ZERO, direction_vector*max_velocity, Color.chartreuse, 2.0, true)
#	draw_line(Vector2.ZERO, current_velocity, Color.orangered, 2.0, true)
#	draw_line(Vector2.ZERO, correction_vector*max_velocity, Color.blueviolet, 2.0, true)


func get_neighbours(render_bots : RenderBots):
	neighbours.clear()
#	for area in get_overlapping_areas():
#		if area.is_in_group("Hatchbots"):
#			neighbours.push_back(area.position)
	neighbours.append_array(markers)


########################################
func get_forces_boids() -> Vector2:
	var pos = position.snapped(Vector2.ONE)
	var force : Vector2 = Vector2.ZERO
	alignment = proj_d * (neighbours.size() + 1) # we don't want the alignment to get a lesser impact when we consider the other forces because when we calculate them we add for every neighbour, +1 is to be consider even if the are no neight
	cohesion = Vector2.ZERO
	separation = Vector2.ZERO
	
	for boid in neighbours:
		var distance = pos.distance_to(boid)
		var weight = abs(pos.direction_to(boid).cross(proj_d)) #cross i s0 is the are paralel
#		alignment += boid.position.direction_to(self.position)
		cohesion += (boid - pos) * weight
		separation += (boid.direction_to(pos) / (1 + distance)) * weight
#		if distance <= separation_distance and distance != 0:
#			separation -= (boid.position - self.position).normalized() * (separation_distance / distance * max_velocity)
	
#	if neighbours.size() > 0:
#		alignment /= neighbours.size()
#		cohesion /= neighbours.size()
#		var center_direction = self.position.direction_to(cohesion)
#		var center_speed = max_velocity * self.position.distance_to(cohesion) / $CollisionShape2D.shape.radius
#		cohesion = center_direction * center_speed
		
	force += separation * separation_weight + alignment * alignment_weight + cohesion * cohesion_weight
	
	return force.normalized()


func get_hatchability_at(pos : Vector2, render_bots : RenderBots) -> float:
	var curvature_sample = render_bots.g_buffer.curvature.get_pixelv(clamp_position(pos))
	var curvature_value = curvature_sample.r + (curvature_sample.g + curvature_sample.b/256.0)/256.0
	
	var normal_sample = render_bots.g_buffer.normal.get_pixelv(clamp_position(pos))
	var normal_value = Vector3(normal_sample.r, normal_sample.g, normal_sample.b)
	normal_value = (normal_value - Vector3(0.5,0.5,0.5)) * 2
	
	var depth_sample = render_bots.g_buffer.depth.get_pixelv(clamp_position(pos))
	var depth_value = depth_sample.r
	
	if depth_value >= 99:			##BACKGROUND
		return -1.0
	
	var curvature_factor = lerp(1.0, -1.0, curvature_value)	# map 0 to 1 and 1 to -1
	var normal_factor = normal_value.dot(light)				# normal_factor == 1 is facing the light, -1 same direction as light, 0 perpendicular
	
	var hatchability = curvature_factor + normal_factor
	hatchability = clamp(hatchability, -1.0, 1.0)
	
	return hatchability



# MAYBE MAKE THE NUMBER OF DESIRED MARKERS IN AREA DEPEND ON HACHABILITY 
func get_higher_hatchability(pos : Vector2, render_bots : RenderBots, distance : int) -> Vector2:
	var max_hatchbility : float = get_hatchability_at(pos, render_bots)
	var position_max_h : Vector2 = pos

	# Search Square
	var start = Vector2.ZERO
	start.x = max(pos.x - distance , 0)
	start.y = max(pos.y - distance, 0)
	var end = Vector2.ZERO
	end.x = min(image_size.x, pos.x + distance + 1)
	end.y = min(image_size.y, pos.y + distance + 1)
	
	for y in range(start.y, end.y, 2):
			for x in range(start.x, end.x, 2):
				var current_pos = Vector2(x,y)
				var current_h = get_hatchability_at(current_pos, render_bots)
				if current_h > max_hatchbility:
					max_hatchbility = current_h
					position_max_h = current_pos
	
	return position_max_h


func get_hatching_strength(render_bots : RenderBots) -> float:
	var strength : float
	var hatchability = get_hatchability_at(position, render_bots)
	
	hatchability -= 2*markers.size() / (separation_distance * length_factor)
	strength = clamp(hatchability, -1, 1) * 0.5 + 0.5  # 0 to 1
	
	return strength



func project_direction(render_bots : RenderBots) -> Vector2:
	var vel3 : Vector3 = Vector3(const_direction.x, -const_direction.y, 0) #direction in 3d space
	
	var normal_sample = render_bots.g_buffer.normal.get_pixelv(clamp_position(position)) 
	var normal = Vector3(normal_sample.r, normal_sample.g, normal_sample.b)
	normal = (normal - Vector3(0.5,0.5,0.5)) * 2
#	normal.z *= 4
	normal = normal.normalized() # normal of the surface 
#	var length_current_vel = current_velocity.length()
	var normal_velocity = vel3.project(normal) # project direction along the normal 
	var tangent_velocity = vel3 - normal_velocity  # we substract the normal component to get the tangent component of the vector in the surface
	return Vector2(tangent_velocity.x, -tangent_velocity.y)  # pass it as 2d 




func project_velocity(render_bots : RenderBots) -> void:
	var vel3 : Vector3 = Vector3(current_velocity.x, -current_velocity.y, 0)
	
	var normal_sample = render_bots.g_buffer.normal.get_pixelv(clamp_position(position))
	var normal = Vector3(normal_sample.r, normal_sample.g, normal_sample.b)
	normal = (normal - Vector3(0.5,0.5,0.5)) * 2
	normal.z *= 4
	normal = normal.normalized()
#	var length_current_vel = current_velocity.length()
	var normal_velocity = vel3.project(normal)
	var tangent_velocity = vel3 - normal_velocity 
	current_velocity = Vector2(tangent_velocity.x, -tangent_velocity.y)    # .normalized() * length_current_vel



# if it's hatchable we draw and we move on the direction of the higher hatchability
# direction = problem --> hatchability not continuous because curvature, maybe always move away from the normals? horizontal,vertical,...
# they move until the can't move anymore edge or markers or constant(background --> with depth)
# markers only if we draw ??
# each step the bot makes to search and draw the edges
func step_bot(render_bots : RenderBots):
	image_size = render_bots.target_image.get_size()
	position = wrap_position(position)
	get_neighbours(render_bots)
	markers = render_bots.get_markers(position, separation_distance, RenderBots.Markers.GREEN)
	proj_d = project_direction(render_bots)
	
	match state:
		States.SEARCHING: 
			state = States.DRAWING
#			searching_frames += 1
#			self.modulate = Color.blue
#			var htch = get_hatchability_at(position, render_bots)
#
#			if htch > 0 :
#				state = States.DRAWING
#				searching_frames = 0
#			else:
#				# find hatchability of big square around position with samples of the square
#				var max_pos : Vector2 = get_higher_hatchability(position, render_bots, 8)
#				var direction = max_pos - position
#				direction = direction.normalized()
#				var force = get_forces_boids()
#				direction = force
#				target_velocity = direction * max_velocity
#				var velocity_dif = target_velocity - current_velocity
#				var velocity_step = velocity_dif.clamped(max_acceleration * get_physics_process_delta_time())   # velocity_dif.normalized() * min(velocity_dif.length(), max_acceleration * get_physics_process_delta_time())
#				current_velocity += velocity_step
#				position += current_velocity * get_physics_process_delta_time() 
#
#				if searching_frames >= 120 and state == States.SEARCHING:
#					queue_free()
#					searching_frames = 0

		States.DRAWING:
			self.modulate = Color.white
#			var direction : Vector2 
			
#			if position.x >= image_size.x - 1:
#				position = Vector2(0, clamp(position.y - 1, 0, image_size.y - 1))
			
			var previous_position = position
			
#			direction = Vector2(image_size.x, position.y) - position
			var direction = get_forces_boids()
			direction = direction.normalized()
#			direction += force
			target_velocity = direction * max_velocity
			var velocity_dif = target_velocity - current_velocity
			var velocity_step = velocity_dif.clamped(max_acceleration* get_physics_process_delta_time())  # velocity_dif.normalized() * min(velocity_dif.length(), max_acceleration * get_physics_process_delta_time())
			current_velocity += velocity_step
			if markers.size() < separation_distance * length_factor:
				render_bots.put_marker(position, RenderBots.Markers.GREEN)
#			project_velocity(render_bots)
			position += current_velocity * get_physics_process_delta_time()
			
			var thick_factor =(thickness + 1)*0.5
			
			var start = Vector2.ZERO
			start.x = min(previous_position.x, position.x) - ceil(thick_factor)
			start.y = min(previous_position.y, position.y) - ceil(thick_factor)
			var end = Vector2.ZERO
			end.x = max(previous_position.x, position.x) + ceil(thick_factor)
			end.y = max(previous_position.y, position.y) + ceil(thick_factor)
			
			start.x = max(start.x, 0)
			start.y = max(start.y, 0)
			end.x = min(end.x + 1, render_bots.target_image.get_width())
			end.y = min(end.y + 1, render_bots.target_image.get_height())
			
			var marker_count : int = 0
			
			for y in range(start.y, end.y):
				for x in range(start.x, end.x):
					# geo.closest_seg gets the point in the segment closest to the point 
					# distance to calculate a color
					var dist_line = Vector2(x,y).distance_to(Geometry.get_closest_point_to_segment_2d(Vector2(x,y), position, previous_position))
#					if dist_line <= markers_distance:
#						if render_bots.temp_image.get_pixel(x,y).r > 0.5:
#							marker_count += 1
					var alpha = clamp(thick_factor - dist_line, 0, 1) * get_hatching_strength(render_bots)
					var color1 = render_bots.target_image.get_pixel(x,y)
					var color2 = Color(color.r, color.g, color.b, alpha)              #  clamp(dist_line + (0.5 - get_hatchability_at(position, render_bots) * 0.5), 0.0, 1.0)
					var blended_color = color1.blend(color2)				# min(color1, color2)
					render_bots.target_image.set_pixel(x,y, blended_color) 

	update()


#func _on_Hatchbot_area_entered(area: Area2D) -> void:
#	if area != self and area.is_in_group("Hatchbots"):
#		neighbours.append(area)
#
#
#func _on_Hatchbot_area_exited(area: Area2D) -> void:
#	if area:
#		neighbours.erase(area)
