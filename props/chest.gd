extends Node2D


## Speed with which the item is thrown out of the chest on opening
@export var item_jump_speed: float = 500.0
## Item will be thrown upward plus or minus this random angle value in degrees
@export var item_random_angle: float = 30.0
## Cost to open the chest
@export var cost: int = 1000
## Amount of time the chest announces that the attempted opener is too poor if they try to open the chest without the necessary monies
@export var too_poor_duration: float = 2
## When the price of this chest is cheapened, it will be multiplied by this number
@export var cheapen_ratio: float = 0.8
## Minimum time between cheapenings
@export var cheapen_min_time: float = 14
## MAximum time between cheapenings
@export var cheapen_max_time: float = 25

var too_poor_time: float = 0
var cheapen_time: float = 0
var current_cost: int = cost


func _ready() -> void:
	show_cost()
	cheapen_time = randf_range(cheapen_min_time, cheapen_max_time)

func _process(delta: float) -> void:
	if too_poor_time > 0:
		too_poor_time -= delta
		if too_poor_time <= 0:
			show_cost()
	
	if cheapen_time > 0:
		cheapen_time -= delta
		
		if cheapen_time <= 0:
			current_cost *= cheapen_ratio
			current_cost = round(current_cost)
			cheapen_time = randf_range(cheapen_min_time, cheapen_max_time)
			show_cost()


func deploy_item(player: int = 0):
	if PlayerManager.players.size() > player:
		# Place this item into the player's hand
		var player_object: Player = PlayerManager.players[player].object
		player_object.spawn_item(BigData.get_random_item_from_pool(Item.POOLS.CHEST))
	else:
		# If there's no player, chuck the item at a suitably amusing speed
		var this_item: PackedScene = BigData.get_random_item_from_pool(Item.POOLS.CHEST)
		var new_item: Item = Game.create_instance(this_item)
		Game.deploy_instance(new_item, global_position)
		var impulse: Vector2 = Vector2(0, -item_jump_speed)
		impulse = impulse.rotated( deg_to_rad(randf_range(-item_random_angle, item_random_angle)) )
		new_item.apply_central_impulse(impulse)

func show_cost():
	%cost.modulate = Color(1, 1, 1, 1)
	%cost.text = "[center][wave]$%s[/wave][/center]" % current_cost

func open():
	%sprite.frame = 1
	%interactable.active = false

func close():
	%sprite.frame = 0
	%interactable.active = true


func _on_interactable_activated(player: int) -> void:
	if PlayerManager.players.size() > player:
		var available_money: int = PlayerManager.players[player].money
		if available_money >= current_cost:
			PlayerManager.players[player].money -= current_cost
			open()
			deploy_item(player)
			current_cost = cost
			%timer.start()
			show_cost()
		else:
			too_poor_time = too_poor_duration
			%cost.text = "[center]TOO POOR![/center]"
			%cost.modulate = Color(1, 0, 0, 1)


func _on_timer_timeout() -> void:
	close()
