extends Area2D
class_name Player

# Signals connected to the game's HUD for its various elements
signal hit 
signal gameover
signal specialFired(delay)
signal boosted(delay)

@export var maxspeed = 200 
@export var acceleration = 10
@export var hp = 5 
@export var angular_speed = PI
@export var bullet_scene: PackedScene 
@export var special_scene: PackedScene 
@export var bullet_speed = 400
@export var special_speed = 100
@export var fire_delay = 1.0
@export var special_delay = 1.0
@export var boost_delay = 1.0

var collision = true
var can_move = true
var can_fire = false
var can_special = false
var can_boost = false
var velocity = Vector2.ZERO 
var heading = Vector2.ZERO 
var rs_look = Vector2()
var facing

signal health(hp,hurt) 
var screen_size

func _ready():
	$AnimatedSprite2D.play()

	# Increase player stats based on the upgrades they purchased
	acceleration += (GlobalVariable.accellvl)
	angular_speed += (GlobalVariable.turnlvl * 0.5)
	special_delay -= (GlobalVariable.sCDlvl * 0.10)
	special_speed += (100*GlobalVariable.sSpeedlvl)
	
	# Disables the boost ability if the player hasn't unlocked it, unless they are in the tutorial
	if GlobalVariable.boostlvl == 0 && !GlobalVariable.inTutorial:
		can_boost = false
	else:
		can_boost = true
		boost_delay -= (GlobalVariable.boostlvl * 0.25)
	
func _process(delta):
	GlobalVariable.player_pos = position
	var LTrigger = Input.get_action_strength("key_brake")
	var RTrigger = Input.get_action_strength("key_shoot")
	var turning = 0
	
	# Check if new speed is different to see if the player is accelerating
	var old_velocity = velocity 
	
	facing = global_rotation
	if facing < -PI: 
		facing = PI
	elif facing > PI: 
		facing = -PI
	
	for bodies in get_overlapping_bodies():
		if bodies.is_in_group("pickups") && GlobalVariable.player_alive: 
			if bodies.type == 0 && !bodies.collected: 
				if GlobalVariable.playerHP < GlobalVariable.playerMaxHP:
					bodies.collected = true
					GlobalVariable.playerHP += 1
					health.emit(GlobalVariable.playerHP,false)
					bodies.picked_up(0)
				elif GlobalVariable.stageEnd: # Allows players to collect health drops once the stage ends
					bodies.collected = true
					GlobalVariable.resource += 100
					bodies.picked_up(2)     
	
	if can_move:
		if GlobalVariable.newtonian: #Movement if newtonian physics is active
			heading.x = 0
			heading.y = 0
			if Input.is_action_pressed("key_right") && GlobalVariable.player_alive && LTrigger == 0:
				heading.x += acceleration
				if Input.is_action_pressed("key_boost") && can_boost && velocity.x < maxspeed:
					$Boost2.play()
					boosted.emit(boost_delay)
					can_boost = false
					velocity.x += acceleration * 100
					await get_tree().create_timer(0.2).timeout
					$Boost.play()
					await get_tree().create_timer(boost_delay).timeout
					can_boost = true
				else: velocity.x += acceleration
			if Input.is_action_pressed("key_left") && GlobalVariable.player_alive && LTrigger == 0:
				heading.x -= acceleration
				if Input.is_action_pressed("key_boost") && can_boost && velocity.x > -maxspeed:
					$Boost2.play()
					boosted.emit(boost_delay)
					can_boost = false
					velocity.x -= acceleration * 100
					await get_tree().create_timer(0.2).timeout
					$Boost.play()
					await get_tree().create_timer(boost_delay).timeout
					can_boost = true
				else: velocity.x -= acceleration
			if Input.is_action_pressed("key_down") && GlobalVariable.player_alive && LTrigger == 0:
				heading.y += acceleration
				if Input.is_action_pressed("key_boost") && can_boost && velocity.y < maxspeed:
					$Boost2.play()
					boosted.emit(boost_delay)
					can_boost = false
					velocity.y += acceleration * 100
					await get_tree().create_timer(0.2).timeout
					$Boost.play()
					await get_tree().create_timer(boost_delay).timeout
					can_boost = true
				else: velocity.y += acceleration
			if Input.is_action_pressed("key_up") && GlobalVariable.player_alive && LTrigger == 0:
				heading.y -= acceleration
				if Input.is_action_pressed("key_boost") && can_boost && velocity.y > -maxspeed:
					$Boost2.play()
					boosted.emit(boost_delay)
					can_boost = false
					velocity.y -= acceleration * 100
					await get_tree().create_timer(0.2).timeout
					$Boost.play()
					await get_tree().create_timer(boost_delay).timeout
					can_boost = true
				else: velocity.y -= acceleration
			
			# Braking
			if LTrigger != 0:
				if velocity.x < 0: 
					heading.x += acceleration
					velocity.x += acceleration
					velocity.x = clamp(velocity.x, velocity.x, 0)
				elif velocity.x > 0: 
					heading.x -= acceleration
					velocity.x -= acceleration
					velocity.x = clamp(velocity.x, 0, velocity.x)
				if velocity.y < 0: 
					heading.y += acceleration
					velocity.y += acceleration
					velocity.y = clamp(velocity.y, velocity.y, 0)
				elif velocity.y > 0:
					heading.y -= acceleration
					velocity.y -= acceleration
					velocity.y = clamp(velocity.y, 0, velocity.y)

			if velocity.length() > 0:

				velocity = velocity.clamp(Vector2(-maxspeed, -maxspeed), Vector2(maxspeed,maxspeed))
				
			GlobalVariable.player_vel = velocity
			position += velocity * delta
			position = position.clamp(GlobalVariable.boundTL, GlobalVariable.boundBR)
		
		else: # Movement if newtonian physics is not active
			var NNSpeed = maxspeed/100
			if Input.is_action_pressed("key_right") && GlobalVariable.player_alive && LTrigger == 0:
				position.x += NNSpeed
			if Input.is_action_pressed("key_left") && GlobalVariable.player_alive && LTrigger == 0:
				position.x -= NNSpeed
			if Input.is_action_pressed("key_down") && GlobalVariable.player_alive && LTrigger == 0:
				position.y += NNSpeed
			if Input.is_action_pressed("key_up") && GlobalVariable.player_alive && LTrigger == 0:
				position.y -= NNSpeed
			
			if GlobalVariable.player_alive:
				if Input.is_action_pressed("key_down") || Input.is_action_pressed("key_up") || Input.is_action_pressed("key_left") || Input.is_action_pressed("key_right"):
					$AnimatedSprite2D.animation = "Walk"
				else: $AnimatedSprite2D.animation = "Still"
				
		if Input.is_action_pressed("turn_left") && GlobalVariable.player_alive:
			turning -= 1
		if Input.is_action_pressed("turn_right") && GlobalVariable.player_alive:
			turning += 1
		
		if GlobalVariable.player_alive:
			rs_look.y = Input.get_joy_axis(0, JOY_AXIS_RIGHT_X)
			rs_look.x = -Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
		if rs_look.length() >= 0.3: # Doesn't use 0.0 to prevent small touches from triggering the turn
			var ogrot = rotation
			var angledif
			var new_transform = transform.looking_at(position + rs_look)
			transform  = transform.interpolate_with(new_transform, angular_speed * 0.5 * delta)
			
			# Compare original rotation and current rotation to see which way the player is turning
			angledif = angle_difference(ogrot, rotation)
			if abs(angledif) > 0.00:
				if angledif < 0:
					$"RCS-TR".show()
					$"RCS-BL".show()
					$"RCS-TL".hide()
					$"RCS-BR".hide()
				elif angledif > 0:
					$"RCS-BR".show()
					$"RCS-TL".show()
					$"RCS-TR".hide()
					$"RCS-BL".hide()
			else:
				$"RCS-TL".hide()
				$"RCS-BR".hide()
				$"RCS-TR".hide()
				$"RCS-BL".hide()
		else: 
			rotation += turning * angular_speed * delta
			if turning < 0:
				$"RCS-TR".show()
				$"RCS-BL".show()
				$"RCS-TL".hide()
				$"RCS-BR".hide()
			elif turning > 0:
				$"RCS-BR".show()
				$"RCS-TL".show()
				$"RCS-TR".hide()
				$"RCS-BL".hide()
			else:
				$"RCS-TL".hide()
				$"RCS-BR".hide()
				$"RCS-TR".hide()
				$"RCS-BL".hide()
		
		#RCS/Thruster animations
		if !GlobalVariable.player_alive:
			$FrontThrusters.hide()
			$RearThrusters.hide()
			$"RCS-TL".hide()
			$"RCS-BR".hide()
			$"RCS-TR".hide()
			$"RCS-BL".hide()
		elif heading != Vector2.ZERO && GlobalVariable.player_alive:
			if old_velocity != velocity:
				# Determines which thrusters to show based on the player's facing and which direction they're accelerating towards
				if -PI/4 <= facing && facing <= PI/4:
					if heading.x < 0:
						$"RCS-BR".show()
						$"RCS-TR".show()
						$"RCS-BR".look_at(heading*1000)
						$"RCS-BR".rotation -= PI/2
						$"RCS-TR".look_at(heading*1000)
						$"RCS-TR".rotation -= PI/2
					elif heading.x > 0:
						$"RCS-BL".show()
						$"RCS-TL".show()
						$"RCS-BL".look_at(-heading*1000)
						$"RCS-BL".rotation += PI/2
						$"RCS-TL".look_at(-heading*1000)
						$"RCS-TL".rotation += PI/2
					if heading.y < 0:
						$RearThrusters.show()
						$FrontThrusters.hide()
					elif heading.y > 0:
						$FrontThrusters.show()
						$RearThrusters.hide()
				elif (-3*PI)/4 <= facing && facing < -PI/4:
					if heading.x < 0:
						$RearThrusters.show()
						$FrontThrusters.hide()
					elif heading.x > 0:
						$FrontThrusters.show()
						$RearThrusters.hide()
					if heading.y < 0:
						$"RCS-BL".show()
						$"RCS-TL".show()
						$"RCS-BL".look_at(-heading*1000)
						$"RCS-BL".rotation += PI/2
						$"RCS-TL".look_at(-heading*1000)
						$"RCS-TL".rotation += PI/2
					elif heading.y > 0:
						$"RCS-BR".show()
						$"RCS-TR".show()
						$"RCS-BR".look_at(heading*1000)
						$"RCS-BR".rotation -= PI/2
						$"RCS-TR".look_at(heading*1000)
						$"RCS-TR".rotation -= PI/2
				elif (3*PI)/4 >= facing && facing > PI/4:
					if heading.x < 0:
						$FrontThrusters.show()
						$RearThrusters.hide()
					elif heading.x > 0:
						$RearThrusters.show()
						$FrontThrusters.hide()
					if heading.y < 0:
						$"RCS-BR".show()
						$"RCS-TR".show()
						$"RCS-BR".look_at(heading*1000)
						$"RCS-BR".rotation -= PI/2
						$"RCS-TR".look_at(heading*1000)
						$"RCS-TR".rotation -= PI/2
					elif heading.y > 0:
						$"RCS-BL".show()
						$"RCS-TL".show()
						$"RCS-BL".look_at(-heading*1000)
						$"RCS-BL".rotation += PI/2
						$"RCS-TL".look_at(-heading*1000)
						$"RCS-TL".rotation += PI/2
				elif (-3*PI)/4 > facing || facing > (3*PI)/4:
					if heading.x > 0:
						$"RCS-BR".show()
						$"RCS-TR".show()
						$"RCS-BR".look_at(heading*1000)
						$"RCS-BR".rotation -= PI/2
						$"RCS-TR".look_at(heading*1000)
						$"RCS-TR".rotation -= PI/2
					elif heading.x < 0:
						$"RCS-BL".show()
						$"RCS-TL".show()
						$"RCS-BL".look_at(-heading*1000)
						$"RCS-BL".rotation += PI/2
						$"RCS-TL".look_at(-heading*1000)
						$"RCS-TL".rotation += PI/2
					if heading.y < 0:
						$FrontThrusters.show()
						$RearThrusters.hide()
					elif heading.y > 0:
						$RearThrusters.show()
						$FrontThrusters.hide()
				
				$"RCS-BL".global_rotation = clampf($"RCS-BL".global_rotation,global_rotation - ((5*PI)/6),global_rotation - (PI/6))
				$"RCS-TL".global_rotation = clampf($"RCS-TL".global_rotation,global_rotation - ((5*PI)/6),global_rotation - (PI/6))
				$"RCS-BR".global_rotation = clampf($"RCS-BR".global_rotation,global_rotation + (PI/6),global_rotation + ((5*PI)/6))
				$"RCS-TR".global_rotation = clampf($"RCS-TR".global_rotation,global_rotation + (PI/6),global_rotation + ((5*PI)/6))

			else:
				$FrontThrusters.hide()
				$RearThrusters.hide()
				if turning == 0 && rs_look.length() < 3:
					$"RCS-TL".hide()
					$"RCS-BR".hide()
					$"RCS-TR".hide()
					$"RCS-BL".hide()

		elif heading == Vector2.ZERO && GlobalVariable.player_alive:
			$AnimatedSprite2D.animation = "Still"
			$FrontThrusters.hide()
			$RearThrusters.hide()
			$"RCS-BL".rotation = -PI/2
			$"RCS-TL".rotation = -PI/2
			$"RCS-BR".rotation = PI/2
			$"RCS-TR".rotation = PI/2
			if turning == 0 && rs_look.length() < 3:
				$"RCS-TL".hide()
				$"RCS-BR".hide()
				$"RCS-TR".hide()
				$"RCS-BL".hide()
	
	#Normal weapon
	if RTrigger != 0 && can_fire && GlobalVariable.player_alive:
		var bullet = bullet_scene.instantiate()
		bullet.position = position
		bullet.rotation = rotation
		var b_velocity = Vector2(0.0, -bullet_speed) 
		var b_rotation = randf_range(-PI/50, PI/50)
		bullet.linear_velocity = b_velocity.rotated(rotation + b_rotation)
		bullet.rotation += b_rotation
		add_sibling(bullet)
		can_fire = false
		await get_tree().create_timer(fire_delay).timeout
		can_fire = true
	
	#Special Weapon
	if Input.is_action_pressed("key_special") && GlobalVariable.player_alive && can_special:
		var special = special_scene.instantiate()
		special.position = position
		special.rotation = rotation
		var b_velocity = Vector2(0.0, -special_speed) 
		special.linear_velocity = b_velocity.rotated(rotation)
		special.rotation = rotation
		add_sibling(special)
		specialFired.emit(special_delay)
		can_special = false
		await get_tree().create_timer(special_delay).timeout
		can_special = true
		
func take_damage():
	if collision:
		$Hit.pitch_scale = 1.0
		$Hit.pitch_scale += randf_range(-0.2,0.2)
		$Hit.play()
		collision = false
		if !GlobalVariable.inTutorial: GlobalVariable.playerHP -= 1
		health.emit(GlobalVariable.playerHP,true)
		hit.emit()
		if GlobalVariable.playerHP <= 0: 
			GlobalVariable.player_alive = false
			$FrontThrusters.hide()
			$RearThrusters.hide()
			$"RCS-TL".hide()
			$"RCS-BR".hide()
			$"RCS-TR".hide()
			$"RCS-BL".hide()
			get_node("AnimatedSprite2D").modulate = Color(1,1,1,1)
			gameover.emit()
			$Death.play()
			$AnimatedSprite2D.animation = "Explode"
		else:
			get_node("AnimatedSprite2D").modulate = Color(10,10,10,10)
			await get_tree().create_timer(0.2).timeout
			get_node("AnimatedSprite2D").modulate = Color(1,1,1,1)
			await get_tree().create_timer(0.2).timeout
			get_node("AnimatedSprite2D").modulate = Color(10,10,10,10)
			await get_tree().create_timer(0.2).timeout
			get_node("AnimatedSprite2D").modulate = Color(1,1,1,1)
			await get_tree().create_timer(0.2).timeout
			get_node("AnimatedSprite2D").modulate = Color(10,10,10,10)
			await get_tree().create_timer(0.2).timeout
			get_node("AnimatedSprite2D").modulate = Color(1,1,1,1)
			collision = true

func _on_body_entered(body):
	if body.is_in_group("mobs") || body.is_in_group("ebullet") || body.is_in_group("static"): 
		if collision:
			body.get_bonked()
			take_damage()

func start(pos):
	position = pos
	show()
	$CollisionShape2D.set_deferred("disabled", false)

func _on_death_finished():
	if !GlobalVariable.player_alive: hide()
