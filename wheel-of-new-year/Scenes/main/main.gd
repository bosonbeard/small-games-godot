extends Node2D

var rng = RandomNumberGenerator.new()

@onready var UI = $UI
var event
var http_request_location = HTTPRequest.new()
var http_request_event = HTTPRequest.new()
const USER_CONFIG = "user://config.json"
const API_LOCATIONS_URL = "https://kudago.com/public-api/v1.2/locations/?lang=ru&fields=slug,name"
const API_EVENTS_TEMPLATE = "https://kudago.com/public-api/v1.4/events/?categories={category}&actual_since={current_dt}&actual_until={next_day}&fields=title,description,site_url&text_format=text&location={city}"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	rng.randomize()  # Автоматически установит случайное зерно
	# rng.seed = 12345
	global.spin_started.connect(_on_spin_started)
	global.spin_finished.connect(_on_spin_finished)
	$UI.init_ui()
	
	add_child(http_request_location)
	add_child(http_request_event)
	
	http_request_location.request_completed.connect(_on_location_request_completed)
	http_request_event.request_completed.connect(_on_event_request_completed)
	http_request_location.request(API_LOCATIONS_URL)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_spin_started ():
	$UI.init_ui()

func _on_spin_finished (sector:int):
	var current_dt = int(Time.get_unix_time_from_system())
	var next_day= current_dt+(24*60*60)
	var category = global.sectors[sector]
	var city_idx = $UI/VBoxContainer/Cities.selected
	var city = global.locations[city_idx].slug
	var requset=API_EVENTS_TEMPLATE.format({ "category":category, "city":city, "current_dt":current_dt, "next_day":next_day})

	http_request_event.request(requset)

func _on_location_request_completed(result, response_code, headers, body):

	if response_code == 200:
		var json = JSON.new()
		json.parse(body.get_string_from_utf8())
		var response = json.get_data()
		if  response.size()>0:
			var cities = response.filter(	(func(element): return element.slug != "interesting"))
			update_locations(cities)
			global.locations = cities
		#	print(global.locations )
		else:
			error_locations_handler()
	else:
			error_locations_handler()
			
	# Will print the user agent string used by the HTTPRequest node (as recognized by httpbin.org).
func error_locations_handler():
	var cities=UI.get_node("VBoxContainer/Cities")
	cities.clear()
	cities.add_item("Город не загрузился")
	global.can_spin = false
	var barrel_text=get_node("Barrel/Label")
	barrel_text.text = "Ошибка. Перезапустите приложение"

func _on_event_request_completed(result, response_code, headers, body):
	var json = JSON.new()
	json.parse(body.get_string_from_utf8())
	var response = json.get_data()
	if  response_code == 200:
		if response.count>0:
			var rnd_event =  response.results[ rng.randi_range(0, response.results.size()-1)]
		#	print (rnd_event)
			event = {
				"title": rnd_event.title[0].to_upper() + rnd_event.title.substr(1,-1),
				"url": rnd_event.site_url,
				"desc": rnd_event.description
			}
		# Will print the user agent string used by the HTTPRequest node (as recognized by httpbin.org).
		else:
			event = {
				"desc": "Событий нет. Попробуйте еще!"
			}
	else:
		event = {
			"desc": "Ошибка при получении событий"
		}
	$UI.show_event(event)
	#print(response_code)
	var selected_city = $UI.get_selected_city_name()
	write_json_data(USER_CONFIG, selected_city)
	
func update_locations(locations:Array):
	var cities = UI.get_node("VBoxContainer/Cities")
	cities.clear()
	for i in range(locations.size()):
		if locations[i].slug != "interesting":
			cities.add_item(locations[i].name,i)
	var config=read_json_data(USER_CONFIG)
	if config.has("city"):
		UI.select_city_by_name(config.city)
			
func write_json_data(filename: String, data: Dictionary) -> bool:
	var file = FileAccess.open(filename, FileAccess.WRITE)
	if file.is_open():
		var json_str = JSON.stringify(data)
		file.store_string(json_str)
		#print(file.get_path_absolute())
		file.close()
		return true
	else:
		print("Ошибка открытия файла для записи:", filename)
		return false
		
func read_json_data(filename: String) -> Dictionary:
	if FileAccess.file_exists(filename):
		var file = FileAccess.open(filename, FileAccess.READ)
		if file.is_open():
			var content = file.get_as_text()
			file.close()
			var json = JSON.new()
			var result = json.parse(content)
			
			if result == Error.OK:
				return  json.get_data()
			else:
				print("Ошибка парсинга JSON файла:", filename)
				return {}
		else:
			print("Файл не найден:", filename)
			return {}
	else:
		return {}
