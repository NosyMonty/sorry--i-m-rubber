extends Node
## Autoload this as "Game" (Project Settings -> Globals -> Autoload).
## Holds fight progress, all enemy data (edit the jokes here!), and helpers.

var fight_index := 0
var music := AudioStreamPlayer.new()
var current_track := ""

# need      = frustration required before the correct Act works
# hit_gain  = frustration added each time a bullet bounces off Noah
# interval  = seconds between bullet spawns (lower = harder)
# patterns  = method names in Battle.gd, cycled in order
var enemies := [
	{
		"name": "TODD (INTERN)",
		"color": Color(0.95, 0.6, 0.2),
		"need": 30.0,
		"hit_gain": 10.0,
		"interval": 0.55,
		"patterns": ["p_pin_drop", "p_pin_drop", "p_aimed"],
		"bullet": "pin",
		"music": "battle",
		"intro": [
			"* Noah Sinclair just wants a sick day.\n* All he needs is one tiny injury.",
			"* Todd the intern blocks the way.\n* He is holding a single pin.",
		],
		"turn_lines": [
			"* Todd lunges again. Nothing happens.",
			"* The pin bends slightly.",
			"* Todd whispers 'please'.",
		],
		"ready_lines": [
			"* Todd is sweating through his lanyard.",
			"* He is at his wit's end.",
		],
		"acts": [
			{"label": "Check", "gain": 0.0, "lines": ["* TODD - ATK 1 DEF 0\n* Has tried to pop you 14 times today."]},
			{"label": "Compliment Pin", "gain": 5.0, "lines": ["* 'Nice pin,' you say.", "* Todd stands taller and tries harder."]},
			{
				"label": "Offer Coffee",
				"correct": true,
				"early": ["* You offer Todd a coffee.", "* 'Can't. Busy ruining your day,' he says.", "* He does not look busy."],
				"lines": ["* You hand Todd a coffee.", "* His eyes well up.", "* 'Nobody's ever been nice to me here.'"],
			},
		],
		"win": ["* Todd goes on his break.", "* Noah is still unscathed."],
	},
	{
		"name": "STEVE (STEAMROLLER)",
		"color": Color(0.95, 0.85, 0.2),
		"need": 40.0,
		"hit_gain": 10.0,
		"interval": 1.3,
		"patterns": ["p_roller", "p_roller", "p_pin_drop"],
		"bullet": "pin",
		"music": "battle",
		"intro": [
			"* Steve rumbles in on a steamroller.\n* Indoors.",
			"* The floor is not happy about it.",
		],
		"turn_lines": [
			"* Steve flattens you. You are now a rug.",
			"* You reinflate. Steve looks hurt.",
			"* The steamroller makes a sad beep.",
		],
		"ready_lines": [
			"* Steve has run you over 9 times.",
			"* He is at his wit's end.",
		],
		"acts": [
			{"label": "Check", "gain": 0.0, "lines": ["* STEVE - ATK 8 DEF 3\n* Has never lost a flattening contest."]},
			{
				"label": "Lie Down",
				"correct": true,
				"early": ["* You lie down in front of the steamroller.", "* 'Wait, I'm not warmed up,' says Steve."],
				"lines": ["* You lie down. Steve rolls right over you.", "* You pop back up with a boing.", "* Steve turns off the engine and stares into the distance."],
			},
			{"label": "Flex", "gain": 5.0, "lines": ["* You flex. Rubber doesn't flex like that.", "* Steve revs the engine, offended."]},
		],
		"win": ["* Steve takes the bus home.", "* Noah is still entirely unscathed."],
	},
	{
		"name": "MERLOT (ANVIL WIZARD)",
		"color": Color(0.6, 0.4, 0.9),
		"need": 50.0,
		"hit_gain": 10.0,
		"interval": 0.9,
		"patterns": ["p_anvil", "p_anvil", "p_piano", "p_aimed"],
		"bullet": "anvil",
		"music": "battle",
		"intro": [
			"* Merlot the Anvil Wizard appears in a puff of smoke.",
			"* There is a lot of smoke. You cough. So does he.",
			"* Anvils start falling from nowhere.",
		],
		"turn_lines": [
			"* Merlot casts ANVIL. It's an anvil.",
			"* A piano falls. It's out of tune.",
			"* Merlot checks his spellbook. Page 1 just says 'anvil'.",
		],
		"ready_lines": [
			"* Merlot is running low on anvils.",
			"* He is at his wit's end.",
		],
		"acts": [
			{"label": "Applaud", "gain": 5.0, "lines": ["* You applaud politely.", "* Merlot bows and misses his own anvil."]},
			{"label": "Check", "gain": 0.0, "lines": ["* MERLOT - ATK 12 DEF 0\n* Knows exactly two spells."]},
			{
				"label": "Ask for a Piano",
				"correct": true,
				"early": ["* 'Got a piano?' you ask.", "* 'I have SEVERAL,' says Merlot, and throws one at you."],
				"lines": ["* You ask Merlot for a piano.", "* He checks his robe. He's all out.", "* 'I threw everything at you,' he sobs. 'I have nothing left.'"],
			},
		],
		"win": ["* Merlot vanishes in another puff of smoke.", "* The smoke is mostly sad."],
	},
	{
		"name": "THE NEEDLE",
		"color": Color(0.3, 0.9, 0.95),
		"need": 50.0,
		"hit_gain": 10.0,
		"interval": 0.8,
		"patterns": ["p_needle_fan", "p_aimed", "p_needle_fan"],
		"bullet": "needle",
		"music": "boss",
		"intro": [
			"* A giant needle blocks the doorway.",
			"* It is the only thing here that could actually hurt you.",
			"* It looks very, very nervous.",
		],
		"turn_lines": [
			"* The Needle swings wildly. And misses.",
			"* It is shaking.",
			"* 'Hold still,' it says. You are holding still.",
		],
		"ready_lines": [
			"* The Needle is breathing heavily.\n* Needles don't breathe.",
			"* It is at its wit's end.",
		],
		"acts": [
			{"label": "Check", "gain": 0.0, "lines": ["* THE NEEDLE - ATK 99 DEF 0\n* Sharp. Lonely. Has never been invited anywhere."]},
			{"label": "Get Poked", "gain": 5.0, "lines": ["* You offer your arm.", "* The Needle flinches. 'Don't make this weird.'"]},
			{
				"label": "Offer Friendship",
				"correct": true,
				"early": ["* 'Want to hang out?' you ask.", "* 'Not yet,' it says. 'I have to be MENACING first.'"],
				"lines": ["* 'Want to hang out?' you ask.", "* The Needle goes quiet.", "* 'Nobody ever asked,' it says."],
			},
		],
		"win": ["* The Needle lowers its guard.", "* You and the Needle are now friends.", "* Noah is still entirely unscathed."],
	},
]


func _ready() -> void:
	add_child(music)


func start() -> void:
	fight_index = 0
	get_tree().change_scene_to_file("res://Battle.tscn")


func to_title() -> void:
	get_tree().change_scene_to_file("res://Title.tscn")


## Returns a Sprite2D if the PNG exists, otherwise a coloured placeholder box.
## This means the game runs before any art exists, and art just drops in.
func make_visual(path: String, color: Color, size: Vector2) -> Node2D:
	if ResourceLoader.exists(path):
		var s := Sprite2D.new()
		s.texture = load(path)
		var tex: Vector2 = s.texture.get_size()
		s.scale = Vector2.ONE * minf(size.x / tex.x, size.y / tex.y)
		return s
	var p := Polygon2D.new()
	var h := size / 2.0
	p.polygon = PackedVector2Array([Vector2(-h.x, -h.y), Vector2(h.x, -h.y), h, Vector2(-h.x, h.y)])
	p.color = color
	return p


func _find_audio(audio_name: String) -> String:
	for ext in ["ogg", "wav", "mp3"]:
		var path := "res://audio/%s.%s" % [audio_name, ext]
		if ResourceLoader.exists(path):
			return path
	return ""


func sfx(audio_name: String) -> void:
	var path := _find_audio(audio_name)
	if path == "":
		return
	var p := AudioStreamPlayer.new()
	p.stream = load(path)
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play()


func play_music(audio_name: String) -> void:
	if audio_name == current_track:
		return
	current_track = audio_name
	var path := _find_audio(audio_name)
	if path == "":
		music.stop()
		return
	music.stream = load(path)
	music.play()
