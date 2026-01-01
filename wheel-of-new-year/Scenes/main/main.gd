extends Node2D

var rng = RandomNumberGenerator.new() # ГСЧ для выбора события

@onready var UI = $UI # ссылка на сцену UI
var event # информация о событии афиши
var http_request_location = HTTPRequest.new() # запрок к API с городами
var http_request_event = HTTPRequest.new() # запрок к API с афишей событий
const USER_CONFIG = "user://config.json" # файл в котором храним город
const API_LOCATIONS_URL = "https://kudago.com/public-api/v1.2/locations/?lang=ru&fields=slug,name" # Шаблон запроса к API для  городов
const API_EVENTS_TEMPLATE = "https://kudago.com/public-api/v1.4/events/?categories={category}&actual_since={current_dt}&actual_until={next_day}&fields=title,description,site_url&text_format=text&location={city}" # Шаблон запроса к API для событий

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	rng.randomize()  # Автоматически установит случайное зерно

	global.spin_started.connect(_on_spin_started) # связываем обработчик с сигналом начала вращеняи барабана
	global.spin_finished.connect(_on_spin_finished) # связываем обработчик с сигналом завершения вращеняи барабана
	$UI.init_ui() # скрпывыаек лишние элементы интерфейса
	
	add_child(http_request_location) # добавляем запросы в древо
	add_child(http_request_event)
	
	# связывае сигналы запросов к API с обработчиками
	http_request_location.request_completed.connect(_on_location_request_completed)
	http_request_event.request_completed.connect(_on_event_request_completed)
	
	http_request_location.request(API_LOCATIONS_URL) # отправляем запрос на получение списка городов

## Обрабокта начала вращения барабана
func _on_spin_started ():
	$UI.init_ui() # скрываем элементы UI

## Обработка завершения вращения барабана (выбран сектор)
func _on_spin_finished (sector:int):
	var current_dt = int(Time.get_unix_time_from_system()) # текущая дата и время
	var next_day= current_dt+(24*60*60)  # + 1 сутки
	var category = global.sectors[sector] # получаем сектор барабана
	var city_idx = $UI/VBoxContainer/Cities.selected # получаем выбранный город
	var city = global.locations[city_idx].slug # сопоставляем выбранный город со словарем городов Афиши
	var requset=API_EVENTS_TEMPLATE.format({ "category":category, "city":city, "current_dt":current_dt, "next_day":next_day}) #подставляем значения в шаблон запроса

	http_request_event.request(requset) # получаем афишу событий

## Обработка ответа на запрос к API по городам
func _on_location_request_completed(result, response_code, headers, body):
	if response_code == 200:
		var json = JSON.new()
		json.parse(body.get_string_from_utf8())
		var response = json.get_data()
		if  response.size()>0: # проверяем что есть города в ответе
			var cities = response.filter(	(func(element): return element.slug != "interesting")) # убираем странный пукнкт "интересные события"
			update_locations(cities) # 
			global.locations = cities # обновляем список городов
		else:
			error_locations_handler() # выве5де ошибку
	else:
			error_locations_handler()
			
## Вывод сообщения об ошибке в списке городов 
func error_locations_handler():
	var cities=UI.get_node("VBoxContainer/Cities")
	cities.clear()
	cities.add_item("Город не загрузился")
	global.can_spin = false
	var barrel_text=get_node("Barrel/Label")
	barrel_text.text = "Ошибка. Перезапустите приложение"

## обработка ответа от API Афиши
func _on_event_request_completed(result, response_code, headers, body):
	# Преобразуем ответ из JSON
	var json = JSON.new()
	json.parse(body.get_string_from_utf8())
	var response = json.get_data()
	if  response_code == 200:
		if response.count>0: # Проверка, что есть хоть 1одно событие
			# Выбиравем случайное событие из ответа
			var rnd_event =  response.results[ rng.randi_range(0, response.results.size()-1)]
			# Формируем наполенние для UI
			event = {
				"title": rnd_event.title[0].to_upper() + rnd_event.title.substr(1,-1),
				"url": rnd_event.site_url,
				"desc": rnd_event.description
			}
		
		else: 
			event = {
				"desc": "Событий нет. Попробуйте еще!" 
			}
	else:
		event = {
			"desc": "Ошибка при получении событий"
		}
	$UI.show_event(event) # Показываем описание событие и ссылку
	var selected_city = $UI.get_selected_city_name() # Сохраняем  город на котором успешно отработал запрос, как город по умолчанию.
	write_json_data(USER_CONFIG, selected_city)
	
## Обновляем список городов
func update_locations(locations:Array):
	var cities = UI.get_node("VBoxContainer/Cities")
	cities.clear()
	for i in range(locations.size()):
		if locations[i].slug != "interesting":
			cities.add_item(locations[i].name,i)
	var config=read_json_data(USER_CONFIG)
	if config.has("city"):
		UI.select_city_by_name(config.city)

## Записываем город в json
func write_json_data(filename: String, data: Dictionary) -> bool:
	var file = FileAccess.open(filename, FileAccess.WRITE)
	if file.is_open():
		var json_str = JSON.stringify(data)
		file.store_string(json_str)
		file.close()
		return true
	else:
		print("Ошибка открытия файла для записи:", filename)
		return false
		
## ЗСчитываем город из json
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
