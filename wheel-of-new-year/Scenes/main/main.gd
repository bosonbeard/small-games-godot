extends Node2D

var rng = RandomNumberGenerator.new()

@onready var UI = $UI
var event
var http_request_location = HTTPRequest.new()
var http_request_event = HTTPRequest.new()
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
	http_request_location.request("https://kudago.com/public-api/v1.2/locations/?lang=ru&fields=slug,name")
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_spin_started ():
	$UI.init_ui()

func _on_spin_finished (sector:int):
	var city_idx = $UI/VBoxContainer/Cities.selected
	var city = global.locations[city_idx].slug
	var requset="https://kudago.com/public-api/v1.4/events/?categories=theater&actual_until=1690664400&fields=title,description,site_url&actual_since=1690647857&text_format=text&location={city}".format({"city":city})
	print(requset)
	await http_request_event.request(requset)
	print(event)
	
	

func _on_location_request_completed(result, response_code, headers, body):

	if response_code == 200:
		var json = JSON.new()
		json.parse(body.get_string_from_utf8())
		var response = json.get_data()
		if  response.size()>0:
			update_locations(response)
			global.locations = response
			print(response)

	# Will print the user agent string used by the HTTPRequest node (as recognized by httpbin.org).
	
func _on_event_request_completed(result, response_code, headers, body):

	
	var json = JSON.new()
	json.parse(body.get_string_from_utf8())
	var response = json.get_data()
	if response.count>0:
		var rnd_event =  response.results[ rng.randi_range(0, response.count-1)]  
		print (rnd_event)
		event = {
			"title": rnd_event.title,
			"url": rnd_event.site_url,
			"desc": rnd_event.description
		}
		$UI.show_event(event)
	# Will print the user agent string used by the HTTPRequest node (as recognized by httpbin.org).
		print(response)
	
func update_locations(locations:Array):
	var cities = UI.get_node("VBoxContainer/Cities")
	cities.clear()
	for i in range(locations.size()):
		if locations[i].slug != "interesting":
			cities.add_item(locations[i].name,i)
