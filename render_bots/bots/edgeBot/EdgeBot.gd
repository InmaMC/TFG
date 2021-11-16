extends "res://render_bots/bots/Bot.gd"

# States of the bot
enum States{
	SEARCHING,
	DRAWING
} 

# onready var n : Node2D = get_node("/root/RenderBots/PreviewSprite/Node2D")


var state = States.SEARCHING
var max_velocity = 100.0
var max_acceleration = 9000.0
var target_velocity = Vector2.ZERO
var current_velocity = Vector2.ZERO
var direction_vector = Vector2.ZERO
var previous_direction : Vector2 = Vector2.ZERO
var correction_vector : Vector2 = Vector2.ZERO
var markers : Array = Array()
var markers_distance = 2.0
var thickness : float = 1

var image_size : Vector2 = Vector2.ZERO
var searching_frames : int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	color = GlobalConfig.edge_color
	thickness = GlobalConfig.edge_thick

func _draw():
	draw_line(Vector2.ZERO, direction_vector*max_velocity, Color.chartreuse, 2.0, true)
	draw_line(Vector2.ZERO, current_velocity, Color.orangered, 2.0, true)
	draw_line(Vector2.ZERO, correction_vector*max_velocity, Color.blueviolet, 2.0, true)

#func _process(delta: float) -> void:
#	pass

# gradient calculation of the position of the bot
func gradient(render_bots : RenderBots, offset : Vector2 = Vector2.ZERO) -> Vector2:
#	var right = position + Vector2(1.0, 0.0)
#	var left = position - Vector2(1.0, 0.0)
#	right.x = clamp(right.x, 0.0, render_bots.target_image.get_width() - 1)
#	left.x = clamp(left.x, 0.0, render_bots.target_image.get_width() - 1)
#	var dx = render_bots.g_buffer.dist_edge.get_pixelv(right).r
#	dx -= render_bots.g_buffer.dist_edge.get_pixelv(left).r
#
#	var up = position + Vector2(0.0, 1.0)
#	var down = position - Vector2(0.0, 1.0)
#	up.y = clamp(up.y, 0.0, render_bots.target_image.get_height() - 1)
#	down.y = clamp(down.y, 0.0, render_bots.target_image.get_height() - 1)
#	var dy = render_bots.g_buffer.dist_edge.get_pixelv(up).r
#	dy -= render_bots.g_buffer.dist_edge.get_pixelv(down).r
#
	var sample = render_bots.g_buffer.dist_edge.get_pixelv(clamp_position(position + offset))
	
	return -Vector2(sample.g, sample.b)


func total_error_function(ang : float, grad_array : Array) -> float:
	var total = 0
	for i in grad_array.size():
		total += pow(sin(grad_array[i].angle() - ang), 2)
	
	return total


func clamp_position(pos : Vector2) -> Vector2:
	pos.x = clamp(pos.x, 0, image_size.x - 1)
	pos.y = clamp(pos.y, 0, image_size.y -1)
	return pos


# calculates direction of the edge based on the gradient 
func get_edge_direction(render_bots : RenderBots) -> Vector2:
	var grad : Vector2 = gradient(render_bots)
	var direction : Vector2 = Vector2.ZERO
	if grad != Vector2.ZERO:
		direction = grad.rotated(PI*0.5)
		return direction
	
	#################### DX DY
	# change across 2 pixels
	grad.x = render_bots.g_buffer.dist_edge.get_pixelv(clamp_position(position + Vector2(1.0, 0.0))).r
	grad.y = render_bots.g_buffer.dist_edge.get_pixelv(clamp_position(position + Vector2(0.0, 1.0))).r
	grad.x -= render_bots.g_buffer.dist_edge.get_pixelv(clamp_position(position - Vector2(1.0, 0.0))).r
	grad.y -= render_bots.g_buffer.dist_edge.get_pixelv(clamp_position(position - Vector2(0.0, 1.0))).r
	grad = grad.normalized()
	if grad != Vector2.ZERO:
		direction = grad.rotated(PI*0.5)  # 
		return direction
	
	#################### SPIRAL SEARCH
	var searching = true
	var grad_array : Array  # an array to keep the gradients of the square
	var x : int= 1   
	var y : int= 0   # current offset (x,y)
	var d : int= 1   # pivot
	var c : int= 1   # counter
	var s : int= 1   # chain size
	var a : int = 3  # pivot for size
	var aux : Vector2  # pivot
	var zero = true    # check if there is a gradient different than 0
	var non_zero_count = 0
	
	# spiral search
	while searching:
		while 2*x*d < s:
			aux = gradient(render_bots, Vector2(x,y))
			#print(x,"," ,y, ": ", aux)
			if aux != Vector2.ZERO:
				zero = false   # if there is a gradient different than 0 we can calculate a direction
				non_zero_count += 1
			grad_array.push_back(gradient(render_bots, Vector2(x,y)))
			x += d
			c += 1
			# if we finish a level of the square and there is a gradient different than 0 we calculate the direciton
			if c == a*a :
				a+=2
				if non_zero_count > 63:
					#print("___END OF LOOP___")
					var dir = Vector2.ZERO
					var b = 0
					for i in grad_array.size():
						if grad_array[i] != Vector2.ZERO:
							dir += grad_array[i]
							b += 1
					
					# calculate constants
					var A = 0
					var B = 0
					for g in grad_array.size():
						A += 2 * grad_array[g].x * grad_array[g].y 
						B += pow(grad_array[g].x, 2) - pow(grad_array[g].y , 2)
					A *= A
					B *= B
					
					if A + B != 0:
						# which angle has the maximal deviation
						var ang1 = asin(sqrt(A/(B+A))) / 2
						var ang2 = -ang1
						var ang3 = ang1 + PI/2
						var ang4 = ang2 + PI/2
						
						
						var e_ang1 = total_error_function(ang1, grad_array)
						var max_error = e_ang1
						var max_ang = ang1
						var e_ang2 = total_error_function(ang2, grad_array)
						if e_ang2 > max_error:
							max_error = e_ang2
							max_ang = ang2
						var e_ang3 = total_error_function(ang3, grad_array)
						if e_ang3 > max_error:
							max_error = e_ang3
							max_ang = ang3
						var e_ang4 = total_error_function(ang4, grad_array)
						if e_ang4 > max_error:
							max_error = e_ang4
							max_ang = ang4
						
						direction = Vector2(cos(max_ang), sin(max_ang))
						return direction
		
		while 2*y*d < s:
			aux = gradient(render_bots, Vector2(x,y))
			#print(x,"," ,y, ": ", aux)
			if aux != Vector2.ZERO:
				zero = false   # if there is a gradient different than 0 we can calculate a direction
			grad_array.push_back(gradient(render_bots, Vector2(x,y)))
			y += d
			c += 1
		d = -1 * d
		s = s + 1
			
	return direction


# each step the bot makes to search and draw the edges
func step_bot(render_bots : RenderBots):
	image_size = render_bots.target_image.get_size()
	position = clamp_position(position)
#	position.x = clamp(position.x, 0.0, render_bots.target_image.get_width() - 1)
#	position.y = clamp(position.y, 0.0, render_bots.target_image.get_height() - 1)
	match state:
		States.SEARCHING: 
			searching_frames += 1
			self.modulate = Color.red
			# distance and direction to the closest edge and we move it proporcionally to them
			var distance = render_bots.g_buffer.dist_edge.get_pixelv(position).r
			var direction = -gradient(render_bots) * ( distance / 64.0 + 1) #distance is in pixels, so usully very big
#			markers = render_bots.get_markers(position,distance)
#			if markers.has(position):
#				queue_free()
			#render_bots.put_marker(position) NO markers on the searching part
			position += direction * max_velocity * get_physics_process_delta_time()
			# if distance is < 4 we swith to drawing
			if distance == 0:
				markers = render_bots.get_markers(position, 2, RenderBots.Markers.RED)
				if markers.size() > 2:
					position = Vector2(randf(), randf()) * image_size
					searching_frames = 0
				else:
					state = States.DRAWING
				
			if searching_frames >= 120 and state == States.SEARCHING:
				position = Vector2(randf(), randf()) * image_size
				searching_frames = 0
				
		
		States.DRAWING:
			searching_frames = 0
			self.modulate = Color.white
			var grad = gradient(render_bots)
			previous_direction = direction_vector.normalized()
			var direction = get_edge_direction(render_bots)
#			var direction = grad.rotated(PI*0.5)
			###############################
			if direction.dot(current_velocity) < 0: # pointing away from each other, prevent turnign around
				direction = -direction 
				######
			direction_vector = direction.normalized()
			################ we may not be in the edge, so we check it for correcting the direction
			var distance = render_bots.g_buffer.dist_edge.get_pixelv(position).r  
			correction_vector = -grad * distance
			################
			direction += correction_vector
			direction = direction.normalized()
			var previous_position = position
#			markers = render_bots.get_markers(position, 5)
#			var sum_markers : Vector2 = Vector2.ZERO
#			for i in markers.size():
#				  sum_markers += markers[i] * (1/(1 + position.distance_squared_to(markers[i])))
#			var markers_direction = sum_markers / markers.size()
#			markers_direction = -markers_direction
			target_velocity = direction * max_velocity
			var velocity_dif = target_velocity - current_velocity
			var velocity_step = velocity_dif.normalized() * min(velocity_dif.length(), max_acceleration * get_physics_process_delta_time())
			current_velocity += velocity_step
			render_bots.put_marker(position, RenderBots.Markers.RED)
			# position += direction * max_velocity * get_physics_process_delta_time()
			position += current_velocity * get_physics_process_delta_time()
			
			if previous_position == position:
				queue_free()
			
				
				
#				var b_up = 
#				b_up.initialize(position + Vector2(0,1))
#				var b_down = bot.instance()
#				b_down.initialize(position + Vector2(0,-1))
#				var b_right = bot.instance()
#				b_right.initialize(position + Vector2(1,0))
#				var b_left = bot.instance()
#				b_left.initialize(position + Vector2(-1,0))
#				#n.add_child()
#				queue_free()

			var thick_factor =(thickness + 1)*0.5 #
			
			# ceil(thick_factor) hace que el rectangulo en el que nos movemos sea más o menos grande para aumentar el tamaño de la linea
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
					if dist_line <= markers_distance:
						if render_bots.temp_image.get_pixel(x,y).r > 0.5:
							marker_count += 1
							
					###########################################33
					var alpha = clamp(thick_factor - dist_line, 0, 1) # smooth but not too much bc blurr
					############################################
					var color1 = render_bots.target_image.get_pixel(x,y)
					var color2 = Color(color.r, color.g, color.b, alpha)  
					var blended_color = color1.blend(color2) #min(color1, color2)
					render_bots.target_image.set_pixel(x,y, blended_color) 
			
			# more than one markers we do...
			if marker_count > 4:
				state = States.SEARCHING
				position += Vector2(randf(), randf()) * 64.0
	update()
