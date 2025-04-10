extends "res://Scripts/ryu.gd"

# AI-specific variables
var ai_controlled = true
var current_ai_action = "idle"
var action_confidence = 0.0
var ai_controller = null
var is_hurt = false
var is_knocked_down = false
var is_jumping = false
var is_attacking = false
var current_attack = ""
var attack_cooldown = 0.0
const MIN_ATTACK_COOLDOWN = 0.3
var current_difficulty = 0.5  # Default difficulty
const BASE_SPEED = 100.0  # Base movement speed

# Damage values for different attack types
const DAMAGE_VALUES = {
    "basic_punch": 8,
    "heavy_punch": 15,
    "basic_kick": 10,
    "heavy_kick": 18
}

# Attack timing data
const ATTACK_TIMINGS = {
    "basic_punch": {"startup": 0.1, "active": 0.2, "recovery": 0.1},
    "heavy_punch": {"startup": 0.2, "active": 0.3, "recovery": 0.2},
    "basic_kick": {"startup": 0.15, "active": 0.2, "recovery": 0.15},
    "heavy_kick": {"startup": 0.25, "active": 0.3, "recovery": 0.25}
}

# Override the Starthp value from parent
func _init():
    # Set a different starting HP for the dummy
    Starthp = 20  # This will override the parent's 100 HP

# Override the _ready function from parent
func _ready():
    # Initialize animation player
    animation = $Dummy_Animation
    
    # Initialize movement and attack systems with correct animation player
    movement_system = Movements.new($Dummy_Animation, self)
    attack_system = Attacks.new($Dummy_Animation, self)
    
    # Initialize health but use DummyHP instead of PlayerHP
    if has_node("DummyHP"):
        $DummyHP.max_value = Starthp
        $DummyHP.value = Starthp
    else:
        # Create DummyHP if it doesn't exist
        var hp_bar = ProgressBar.new()
        hp_bar.name = "DummyHP"
        hp_bar.max_value = Starthp
        hp_bar.value = Starthp
        
        # Set the position and size similar to PlayerHP in ryu.tscn
        hp_bar.position = Vector2(-39, -92)
        hp_bar.size = Vector2(95, 27)
        
        add_child(hp_bar)
    
    # Initialize hitbox areas
    _init_hitboxes()
    
    # Connect animation signals
    if has_node("Dummy_Animation"):
        if not $Dummy_Animation.is_connected("animation_finished", Callable(self, "_on_animation_finished")):
            $Dummy_Animation.connect("animation_finished", Callable(self, "_on_animation_finished"))

# Helper function for animation handling
func _play_animation(anim_name: String, force: bool = false):
    if has_node("Dummy_Animation"):
        if force or $Dummy_Animation.current_animation != anim_name:
            if $Dummy_Animation.has_animation(anim_name):
                $Dummy_Animation.play(anim_name)
            else:
                print("Warning: Missing animation ", anim_name)
                $Dummy_Animation.play("idle")

# Animation handling
func _on_animation_finished(anim_name: String):
    match anim_name:
        "hurt":
            is_hurt = false
            if has_node("Dummy_Animation"):
                $Dummy_Animation.play("idle")
        "knocked_down":
            is_knocked_down = true
            # Notify AI controller of defeat
            if ai_controller:
                ai_controller.on_action_completed("defeated", false, global_position)
        # Handle attack animations
        "basic_punch", "heavy_punch", "basic_kick", "heavy_kick":
            is_attacking = false
            current_attack = ""
            if has_node("Dummy_Animation") and not is_hurt and not is_knocked_down:
                $Dummy_Animation.play("idle")

# Helper function to initialize hitboxes
func _init_hitboxes():
    # Only create hitboxes if they don't already exist
    if not has_node("PunchHitbox"):
        var punch_hitbox = Area2D.new()
        punch_hitbox.name = "PunchHitbox"
        add_child(punch_hitbox)
        
        var shape = CollisionShape2D.new()
        var rect = RectangleShape2D.new()
        rect.size = Vector2(60, 40)
        shape.shape = rect
        punch_hitbox.add_child(shape)
        punch_hitbox.monitoring = false
        punch_hitbox.connect("area_entered", Callable(self, "_on_punch_hitbox_area_entered"))
    
    if not has_node("KickHitbox"):
        var kick_hitbox = Area2D.new()
        kick_hitbox.name = "KickHitbox"
        add_child(kick_hitbox)
        
        var shape = CollisionShape2D.new()
        var rect = RectangleShape2D.new()
        rect.size = Vector2(60, 40)
        shape.shape = rect
        kick_hitbox.add_child(shape)
        kick_hitbox.monitoring = false
        kick_hitbox.connect("area_entered", Callable(self, "_on_kick_hitbox_area_entered"))

# Add helper functions for health management
func get_health():
    return $DummyHP.value if has_node("DummyHP") else 0

func set_health(value):
    if has_node("DummyHP"):
        $DummyHP.value = clamp(value, 0, Starthp)
        
        # Check for defeat
        if $DummyHP.value <= 0 and not is_knocked_down:
            _on_defeat()

func take_damage(amount):
    if has_node("DummyHP") and not is_knocked_down:
        is_hurt = true
        is_attacking = false  # Interrupt any ongoing attack
        current_attack = ""
        set_health($DummyHP.value - amount)
        
        # Play hurt animation if not already knocked down
        if has_node("Dummy_Animation") and not is_knocked_down:
            $Dummy_Animation.play("hurt")
            
        # Disable any active hitboxes
        for hitbox in ["PunchHitbox", "KickHitbox"]:
            if has_node(hitbox):
                get_node(hitbox).monitoring = false
    
    # Notify AI controller of state change
    if ai_controller and ai_controller.has_method("on_action_completed"):
        ai_controller.on_action_completed("hurt", false, global_position)

func _on_defeat():
    is_knocked_down = true
    if has_node("Dummy_Animation"):
        $Dummy_Animation.play("knocked_down")
    
    # Notify AI controller if it exists
    if ai_controller:
        ai_controller.on_action_completed("defeated", false, global_position)

# Override _physics_process to prevent calling parent method
func _physics_process(delta):
    # Update cooldowns
    if attack_cooldown > 0:
        attack_cooldown -= delta

    # Skip processing if knocked down
    if is_knocked_down:
        return
        
    # Apply gravity
    if not is_on_floor():
        velocity.y += gravity * delta
        if not is_jumping and has_node("Dummy_Animation"):
            is_jumping = true
            if not is_attacking:  # Only play jump if not attacking
                _play_animation("jump")
    else:
        velocity.y = 0
        if is_jumping and has_node("Dummy_Animation"):
            is_jumping = false
            if not is_attacking and not is_hurt:  # Only play idle if not in another state
                _play_animation("idle")
    
    # Apply movement if not hurt or attacking
    if not is_hurt and not is_attacking:
        move_and_slide()
        
        # Update facing direction based on player position if we have an AI controller
        # Update facing direction based on player position if we have an AI controller
        if ai_controller and ai_controller.has_method("get_player_node") and ai_controller.get_player_node():
            var to_player = ai_controller.get_player_node().global_position - global_position
            if has_node("AnimatedSprite2D"):
                $AnimatedSprite2D.flip_h = to_player.x < 0
    # Sync animations with movement
    sync_animation_with_movement()

# Function to handle being hit by player
func _on_hitbox_area_entered(area):
    if (area.name == "PlayerHitbox" or area.name == "Hitbox") and not is_knocked_down:
        # Take damage when hit
        take_damage(10)  # Only call once

# Add reset function for match restart
func reset():
    is_hurt = false
    is_knocked_down = false
    is_jumping = false
    is_attacking = false
    current_attack = ""
    if has_node("DummyHP"):
        $DummyHP.value = Starthp
    if has_node("Dummy_Animation"):
        $Dummy_Animation.play("idle")
    
    # Reset hitboxes
    for hitbox in ["PunchHitbox", "KickHitbox"]:
        if has_node(hitbox):
            get_node(hitbox).monitoring = false

# Function to sync animations with movement
func sync_animation_with_movement():
    if is_hurt or is_knocked_down or not has_node("Dummy_Animation") or is_attacking:
        return
    
    # Add null check for AnimatedSprite2D before using velocity
    if not has_node("AnimatedSprite2D"):
        return
        
    if velocity.x != 0:
        var anim = "walk_forward" if velocity.x > 0 else "walk_backward"
        _play_animation(anim)
    elif is_on_floor():
        # Remove unnecessary current_animation check since _play_animation handles it
        _play_animation("idle")

# Function to position hitboxes based on facing direction
func _position_hitbox(hitbox_node: Node2D, attack_type: String):
    if not hitbox_node or not hitbox_node.has_node("CollisionShape2D") or not has_node("AnimatedSprite2D"):
        return
        
    var base_offset = Vector2(30, -20)
    var size = Vector2(60, 40)
    
    match attack_type:
        "basic_punch":
            base_offset = Vector2(30, -20)
            size = Vector2(50, 30)
        "heavy_punch":
            base_offset = Vector2(40, -20)
            size = Vector2(70, 40)
        "basic_kick":
            base_offset = Vector2(35, 0)
            size = Vector2(60, 30)
        "heavy_kick":
            base_offset = Vector2(45, 0)
            size = Vector2(80, 40)
    
    # Flip offset based on facing direction
    var facing_right = not $AnimatedSprite2D.flip_h
    hitbox_node.position = Vector2(base_offset.x * (1 if facing_right else -1), base_offset.y)
    
    # Update hitbox size
    if hitbox_node.get_node("CollisionShape2D"):
        var shape = hitbox_node.get_node("CollisionShape2D").shape
        if shape is RectangleShape2D:
            shape.size = size

# Add function to handle attack states
func start_attack(attack_type: String):
    if not is_hurt and not is_knocked_down and not is_attacking and attack_cooldown <= 0:
        # Verify we have the animation before proceeding
        if has_node("Dummy_Animation") and not $Dummy_Animation.has_animation(attack_type):
            print("Warning: Missing animation for ", attack_type)
            return
            
        # Set attack state once
        current_attack = attack_type
        var timing = ATTACK_TIMINGS.get(attack_type, {"startup": 0.1, "active": 0.2, "recovery": 0.1})
        var difficulty_scale = lerp(1.2, 0.8, current_difficulty)
        
        # Scale timings with difficulty
        var startup = timing["startup"] * difficulty_scale
        var active = timing["active"] * difficulty_scale
        var recovery = timing["recovery"] * difficulty_scale
        
        # Start attack sequence
        is_attacking = true
        attack_cooldown = (startup + active + recovery) * 2  # Total cooldown
        
        # Play animation
        _play_animation(attack_type)
        
        # Enable hitbox after startup
        var hitbox_name = "PunchHitbox" if "punch" in attack_type else "KickHitbox"
        if has_node(hitbox_name):
            var hitbox = get_node(hitbox_name)
            _position_hitbox(hitbox, attack_type)
            
            # Wait for startup
            await get_tree().create_timer(startup).timeout
            if is_hurt or is_knocked_down or not is_attacking:
                return
            
            # Enable hitbox
            hitbox.monitoring = true
            hitbox.set_meta("damage", DAMAGE_VALUES.get(attack_type, 10))
            
            # Wait for active frames
            await get_tree().create_timer(active).timeout
            if is_hurt or is_knocked_down or not is_attacking:  # Add state check here too
                return
            
            # Disable hitbox
            if has_node(hitbox_name):
                get_node(hitbox_name).monitoring = false
        
        # Notify AI controller of attack completion
        if ai_controller and ai_controller.has_method("on_action_completed"):
            ai_controller.on_action_completed(attack_type, true, global_position)

# Helper function for AI control
func handle_ai_action(action: String, difficulty: float):
    # Skip if knocked down or hurt
    if is_knocked_down or is_hurt:
        return
        
    current_difficulty = difficulty
    match action:
        "walk_forward":
            if not is_attacking:  # Only change velocity if not attacking
                velocity.x = BASE_SPEED * lerp(0.7, 1.3, difficulty)
                if has_node("AnimatedSprite2D"):
                    $AnimatedSprite2D.flip_h = false
        "walk_backward":
            if not is_attacking:  # Only change velocity if not attacking
                velocity.x = -BASE_SPEED * lerp(0.7, 1.3, difficulty)
                if has_node("AnimatedSprite2D"):
                    $AnimatedSprite2D.flip_h = true
        "basic_punch", "heavy_punch", "basic_kick", "heavy_kick":
            start_attack(action)
        "idle":
            if not is_attacking:  # Only change velocity if not attacking
                velocity.x = 0
                if not is_hurt and has_node("Dummy_Animation"):
                    _play_animation("idle")

# Add hit detection for dummy's attacks
func _on_punch_hitbox_area_entered(area):
    if is_knocked_down or is_hurt or not is_attacking or (current_attack != "basic_punch" and current_attack != "heavy_punch"):
        return
    if area.get_parent() and area.get_parent().has_method("take_damage"):
        if has_node("PunchHitbox"):
            var damage = get_node("PunchHitbox").get_meta("damage", 10)
            area.get_parent().take_damage(damage)
            # Notify AI of successful hit
            if ai_controller and ai_controller.has_method("on_action_completed"):
                ai_controller.on_action_completed(current_attack, true, global_position)

func _on_kick_hitbox_area_entered(area):
    if is_knocked_down or is_hurt or not is_attacking or (current_attack != "basic_kick" and current_attack != "heavy_kick"):
        return
    if area.get_parent() and area.get_parent().has_method("take_damage"):
        if has_node("KickHitbox"):
            var damage = get_node("KickHitbox").get_meta("damage", 10)
            area.get_parent().take_damage(damage)
            # Notify AI of successful hit
            if ai_controller and ai_controller.has_method("on_action_completed"):
                ai_controller.on_action_completed(current_attack, true, global_position)
