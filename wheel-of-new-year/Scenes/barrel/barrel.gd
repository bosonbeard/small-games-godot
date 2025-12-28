extends Node2D




@export var max_rotation_speed = 25.5 # Максимальная скорость вращения
@export var min_rotation_speed = 0.5 # Минимальная скорость вращения
@export var friction_coefficient = 0.990  # Коэффициент замедления вращения
@export var touch_slow_down_coefficient = 5




var touch_start_position = Vector2.ZERO  # Начало касания
var touch_end_position = Vector2.ZERO  # Конечная позиция касания
var current_rotation_speed = 0  # Текущая скорость вращения
var last_touch_time = 0  # Время начала касания
var is_rotating = false  # Флаг вращения
var spin_sign = 1



	
var sectors_count = global.sectors.size()


func _ready():
	set_process_input(true)  # Включаем обработку событий ввода
	
	print(sectors_count)

func is_point_over_barrel(point):
	var rect = $ClickArea.get_global_rect()
	return rect.has_point(point)

func _input(event):
	if !is_point_over_barrel(event.position):
		return
	if event is InputEventMouseButton:
		if event.pressed:
			handle_touch_start(event.position)
		#	print("Нажата кнопка мыши.")
		elif event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:  # Левая кнопка мыши отпущена
			handle_touch_release()
		#	print("Кнопка мыши отпущена.")
	elif event is InputEventScreenTouch:
		if event.pressed:
			handle_touch_start(event.position)
		#	print("Прикоснулся к экрану.")
		elif not event.pressed:  # Сенсорное событие отпущено
			handle_touch_release()
		#	print("Сенсорное касание отменено.")
	elif event is InputEventMouseMotion or event is InputEventScreenDrag:
		touch_end_position = event.position
	#	print("Перемещается мышь или палец.")

func handle_touch_start(touch_position):
	touch_start_position = touch_position
	last_touch_time = Time.get_ticks_msec()
	global.spin_started.emit()
	print("Начало касания:", touch_start_position)

func handle_touch_release():
	var time_diff_ms = Time.get_ticks_msec() - last_touch_time
	var distance = touch_start_position.distance_to(touch_end_position)

	var speed = clamp(max_rotation_speed * (distance / (time_diff_ms * touch_slow_down_coefficient)), min_rotation_speed, max_rotation_speed)
	if is_rotating == false:
		spin_sign =  sign(touch_start_position.normalized().angle_to(touch_end_position.normalized()) )
		current_rotation_speed = speed * spin_sign
		is_rotating = true
		global.spin_started.emit()
		global.init_ui.emit()
		print("Запуск вращения с начальной скоростью:", current_rotation_speed)
		print("Трение: ", friction_coefficient )
	
		
func slow_down():
	if is_rotating == true:
		current_rotation_speed *= friction_coefficient 
		if abs(current_rotation_speed) < 0.1:
			is_rotating = false
			determine_sector()

func determine_sector():
	var sector_size = 360.0 / sectors_count
	# Приведение угла к положительным значениям с учетом направления вращения
	var wheel_angle = $Wheel.rotation_degrees * spin_sign
	print( spin_sign)
	# Применение поправки на знак вращения
	if spin_sign > 0:
		wheel_angle = 360 - wheel_angle  # Инвертируем угол при вращении против часовой стрелки
	# Центрирование границы секторов
	var centered_angle = wheel_angle + (sector_size / 2)
	# Определение сектора
	var result_sector = floori(centered_angle / sector_size) % sectors_count
	print( $Wheel.rotation_degrees )
	global.spin_finished.emit(result_sector)
	print("Выпал сектор: " +str(global.sectors[result_sector]))
	

func _process(delta):
	if is_rotating:
		# print("Вращаемся со скоростью:", current_rotation_speed)
		$Wheel.rotate(current_rotation_speed * delta)
		slow_down()
