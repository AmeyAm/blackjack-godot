extends Control

const STARTING_BALANCE := 100.0
const DEALER_STAND_VALUE := 17
const CARD_MIN_SIZE := Vector2(86, 122)
const SUITS := [
	{"symbol": "S", "name": "Spades", "color": Color(0.08, 0.09, 0.11)},
	{"symbol": "H", "name": "Hearts", "color": Color(0.78, 0.08, 0.15)},
	{"symbol": "D", "name": "Diamonds", "color": Color(0.78, 0.08, 0.15)},
	{"symbol": "C", "name": "Clubs", "color": Color(0.08, 0.09, 0.11)},
]
const RANK_NAMES := {
	11: "J",
	12: "Q",
	13: "K",
	14: "A",
}

var rng := RandomNumberGenerator.new()
var deck: Array[Dictionary] = []
var player_hand: Array[Dictionary] = []
var dealer_hand: Array[Dictionary] = []
var balance := STARTING_BALANCE
var current_bet := 10.0
var round_active := false
var dealer_revealed := false

var balance_label: Label
var deck_label: Label
var dealer_cards: HBoxContainer
var dealer_value_label: Label
var player_cards: HBoxContainer
var player_value_label: Label
var message_label: Label
var bet_spin: SpinBox
var deal_button: Button
var hit_button: Button
var stand_button: Button
var double_button: Button
var new_game_button: Button


func _ready() -> void:
	rng.randomize()
	_build_ui()
	_reset_game()


func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color(0.055, 0.09, 0.075)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 16)
	margin.add_child(layout)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	layout.add_child(header)

	var title := Label.new()
	title.text = "Blackjack"
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color(0.96, 0.92, 0.82))
	header.add_child(title)

	var header_spacer := Control.new()
	header_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(header_spacer)

	balance_label = Label.new()
	balance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	balance_label.add_theme_font_size_override("font_size", 22)
	balance_label.add_theme_color_override("font_color", Color(0.96, 0.92, 0.82))
	header.add_child(balance_label)

	deck_label = Label.new()
	deck_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	deck_label.add_theme_font_size_override("font_size", 18)
	deck_label.add_theme_color_override("font_color", Color(0.68, 0.78, 0.72))
	header.add_child(deck_label)

	var table_panel := PanelContainer.new()
	table_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	table_panel.add_theme_stylebox_override("panel", _stylebox(Color(0.07, 0.28, 0.19), Color(0.80, 0.67, 0.36), 2, 8))
	layout.add_child(table_panel)

	var table_margin := MarginContainer.new()
	table_margin.add_theme_constant_override("margin_left", 20)
	table_margin.add_theme_constant_override("margin_top", 18)
	table_margin.add_theme_constant_override("margin_right", 20)
	table_margin.add_theme_constant_override("margin_bottom", 18)
	table_panel.add_child(table_margin)

	var table := VBoxContainer.new()
	table.add_theme_constant_override("separation", 16)
	table_margin.add_child(table)

	table.add_child(_hand_title("Dealer"))
	dealer_cards = HBoxContainer.new()
	dealer_cards.add_theme_constant_override("separation", 10)
	dealer_cards.custom_minimum_size = Vector2(0, CARD_MIN_SIZE.y)
	table.add_child(dealer_cards)

	dealer_value_label = _value_label()
	table.add_child(dealer_value_label)

	var separator := HSeparator.new()
	table.add_child(separator)

	table.add_child(_hand_title("Player"))
	player_cards = HBoxContainer.new()
	player_cards.add_theme_constant_override("separation", 10)
	player_cards.custom_minimum_size = Vector2(0, CARD_MIN_SIZE.y)
	table.add_child(player_cards)

	player_value_label = _value_label()
	table.add_child(player_value_label)

	var controls := HBoxContainer.new()
	controls.add_theme_constant_override("separation", 10)
	layout.add_child(controls)

	var bet_label := Label.new()
	bet_label.text = "Bet"
	bet_label.add_theme_font_size_override("font_size", 18)
	bet_label.add_theme_color_override("font_color", Color(0.96, 0.92, 0.82))
	controls.add_child(bet_label)

	bet_spin = SpinBox.new()
	bet_spin.min_value = 1
	bet_spin.max_value = STARTING_BALANCE
	bet_spin.step = 5
	bet_spin.value = 10
	bet_spin.custom_minimum_size = Vector2(110, 42)
	controls.add_child(bet_spin)

	deal_button = _action_button("Deal")
	deal_button.pressed.connect(_start_round)
	controls.add_child(deal_button)

	hit_button = _action_button("Hit")
	hit_button.pressed.connect(_hit)
	controls.add_child(hit_button)

	stand_button = _action_button("Stand")
	stand_button.pressed.connect(_stand)
	controls.add_child(stand_button)

	double_button = _action_button("Double")
	double_button.tooltip_text = "Double your bet, take one card, then stand."
	double_button.pressed.connect(_double_down)
	controls.add_child(double_button)

	var controls_spacer := Control.new()
	controls_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controls.add_child(controls_spacer)

	new_game_button = _action_button("New Game")
	new_game_button.pressed.connect(_reset_game)
	controls.add_child(new_game_button)

	message_label = Label.new()
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.add_theme_font_size_override("font_size", 20)
	message_label.add_theme_color_override("font_color", Color(0.96, 0.92, 0.82))
	message_label.custom_minimum_size = Vector2(0, 34)
	layout.add_child(message_label)


func _hand_title(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color(0.96, 0.92, 0.82))
	return label


func _value_label() -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(0.82, 0.88, 0.82))
	return label


func _action_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(104, 42)
	button.add_theme_font_size_override("font_size", 17)
	return button


func _stylebox(background: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = background
	box.border_color = border
	box.set_border_width_all(border_width)
	box.set_corner_radius_all(radius)
	return box


func _reset_game() -> void:
	balance = STARTING_BALANCE
	current_bet = 10
	round_active = false
	dealer_revealed = false
	player_hand.clear()
	dealer_hand.clear()
	_build_deck()
	_shuffle_deck()
	message_label.text = "Place a bet and deal."
	_update_ui()


func _start_round() -> void:
	if round_active:
		return

	current_bet = bet_spin.value
	if current_bet > balance:
		message_label.text = "You cannot bet more than you have."
		return

	balance -= current_bet
	round_active = true
	dealer_revealed = false
	player_hand.clear()
	dealer_hand.clear()
	_build_deck()
	_shuffle_deck()

	player_hand.append(_deal_card())
	dealer_hand.append(_deal_card())
	player_hand.append(_deal_card())
	dealer_hand.append(_deal_card())

	message_label.text = "Your move."
	_update_ui()


func _hit() -> void:
	if not round_active:
		return

	player_hand.append(_deal_card())
	if _hand_value(player_hand) > 21:
		dealer_revealed = true
		round_active = false
		message_label.text = "Bust. You lose."
	_update_ui()


func _stand() -> void:
	if not round_active:
		return
	_resolve_round()


func _double_down() -> void:
	if not round_active:
		return

	if player_hand.size() != 2:
		message_label.text = "Double is only available on your first move."
		return

	if current_bet > balance:
		message_label.text = "You need enough balance to match your bet."
		return

	balance -= current_bet
	current_bet *= 2
	player_hand.append(_deal_card())

	if _hand_value(player_hand) > 21:
		dealer_revealed = true
		round_active = false
		message_label.text = "Double down bust. You lose."
		_update_ui()
		return

	_resolve_round()


func _resolve_round() -> void:
	dealer_revealed = true
	var dealer_total := _hand_value(dealer_hand)
	while dealer_total < DEALER_STAND_VALUE:
		dealer_hand.append(_deal_card())
		dealer_total = _hand_value(dealer_hand)

	var player_total := _hand_value(player_hand)
	round_active = false

	if dealer_total > 21 or player_total > dealer_total:
		balance += current_bet * 2
		message_label.text = "You win %s." % _money_text(current_bet)
	elif player_total == dealer_total:
		var interest := current_bet * 0.1
		balance += current_bet + interest
		message_label.text = "Push. You earn 10%% interest: %s." % _money_text(interest)
	else:
		message_label.text = "You lose."

	if balance <= 0:
		message_label.text += " Start a new game to reload your bankroll."

	_update_ui()


func _build_deck() -> void:
	deck.clear()
	for suit in SUITS:
		for rank in range(2, 15):
			deck.append({
				"rank": rank,
				"suit": suit["symbol"],
				"suit_name": suit["name"],
				"color": suit["color"],
			})


func _shuffle_deck() -> void:
	for index in range(deck.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var card := deck[index]
		deck[index] = deck[swap_index]
		deck[swap_index] = card


func _deal_card() -> Dictionary:
	if deck.is_empty():
		_build_deck()
		_shuffle_deck()
	return deck.pop_back()


func _hand_value(cards: Array[Dictionary]) -> int:
	var total := 0
	var aces := 0

	for card in cards:
		var rank := int(card["rank"])
		if rank == 14:
			aces += 1
			total += 11
		else:
			total += mini(rank, 10)

	while total > 21 and aces > 0:
		total -= 10
		aces -= 1

	return total


func _update_ui() -> void:
	balance_label.text = "Money: %s" % _money_text(balance)
	deck_label.text = "Deck: %d" % deck.size()

	var available_balance := maxf(1.0, floorf(balance))
	bet_spin.max_value = available_balance
	if not round_active and bet_spin.value > available_balance:
		bet_spin.value = available_balance
	bet_spin.editable = not round_active and balance > 0

	deal_button.disabled = round_active or balance <= 0
	hit_button.disabled = not round_active
	stand_button.disabled = not round_active
	double_button.disabled = not round_active or player_hand.size() != 2 or current_bet > balance
	new_game_button.disabled = false

	_render_hand(player_cards, player_hand, false)
	_render_hand(dealer_cards, dealer_hand, round_active and not dealer_revealed)

	player_value_label.text = "Value: %s" % _visible_value_text(player_hand, false)
	dealer_value_label.text = "Value: %s" % _visible_value_text(dealer_hand, round_active and not dealer_revealed)


func _visible_value_text(cards: Array[Dictionary], hide_second_card: bool) -> String:
	if cards.is_empty():
		return "-"
	if hide_second_card:
		return "?"
	return str(_hand_value(cards))


func _render_hand(container: HBoxContainer, cards: Array[Dictionary], hide_second_card: bool) -> void:
	for child in container.get_children():
		child.queue_free()

	if cards.is_empty():
		var placeholder := Label.new()
		placeholder.text = "No cards yet"
		placeholder.add_theme_font_size_override("font_size", 18)
		placeholder.add_theme_color_override("font_color", Color(0.70, 0.78, 0.72))
		container.add_child(placeholder)
		return

	for index in cards.size():
		container.add_child(_card_view(cards[index], hide_second_card and index > 0))


func _card_view(card: Dictionary, hidden: bool) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = CARD_MIN_SIZE

	if hidden:
		panel.add_theme_stylebox_override("panel", _stylebox(Color(0.10, 0.15, 0.22), Color(0.64, 0.75, 0.83), 2, 8))
	else:
		panel.add_theme_stylebox_override("panel", _stylebox(Color(0.98, 0.96, 0.90), Color(0.18, 0.16, 0.12), 2, 8))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 9)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 9)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)

	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(content)

	var top := Label.new()
	top.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_theme_font_size_override("font_size", 30)
	content.add_child(top)

	var middle := Label.new()
	middle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	middle.add_theme_font_size_override("font_size", 20)
	content.add_child(middle)

	var bottom := Label.new()
	bottom.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bottom.add_theme_font_size_override("font_size", 16)
	content.add_child(bottom)

	if hidden:
		top.text = "?"
		middle.text = "Hidden"
		bottom.text = "Card"
		top.add_theme_color_override("font_color", Color(0.88, 0.93, 0.96))
		middle.add_theme_color_override("font_color", Color(0.70, 0.82, 0.90))
		bottom.add_theme_color_override("font_color", Color(0.70, 0.82, 0.90))
	else:
		var card_color := card["color"] as Color
		top.text = _rank_text(int(card["rank"]))
		middle.text = str(card["suit"])
		bottom.text = str(card["suit_name"])
		top.add_theme_color_override("font_color", card_color)
		middle.add_theme_color_override("font_color", card_color)
		bottom.add_theme_color_override("font_color", card_color)

	return panel


func _rank_text(rank: int) -> String:
	if RANK_NAMES.has(rank):
		return RANK_NAMES[rank]
	return str(rank)


func _money_text(amount: float) -> String:
	if is_equal_approx(amount, roundf(amount)):
		return "$%d" % int(roundf(amount))
	return "$%.1f" % amount
