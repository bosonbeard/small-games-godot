extends Node2D

@export var max_rotation_speed = 25.5 # Максимальная скорость вращения
@export var min_rotation_speed = 0.5 # Минимальная скорость вращения
@export var friction_coefficient = 0.990  # Коэффициент замедления вращения
@export var touch_slow_down_coefficient = 5 # Уменьшает скорость вращения при раскрутке барабана

var touch_start_position = Vector2.ZERO  # Начало касания
var touch_end_position = Vector2.ZERO  # Конечная позиция касания
var current_rotation_speed = 0  # Текущая скорость вращения
var last_touch_time = 0  # Время начала касания
var is_rotating = false  # Флаг вращения
var spin_sign # в какую сторону вращается барабан
var sectors_count = global.sectors.size() # количество секторов на барабане

func _ready():
	set_process_input(true)  # Включаем обработку событий ввода

## Функцйия чтобы понять попали ли мы в зону около барабана при раскрутке
## Нужна чтобы не мешать нажатия на кнопку ссылку афиши
func is_point_over_barrel(point):
	var rect = $ClickArea.get_global_rect()
	return rect.has_point(point)

func _input(event):
	# нажали мышкой в зоне прикосновения
	if event is InputEventMouseButton and is_point_over_barrel(event.position):
		if event.pressed: # ЛКМ нажата
			handle_touch_start(event.position)
		elif event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:  # Левая кнопка мыши отпущена
			handle_touch_release()
	elif event is InputEventScreenTouch and is_point_over_barrel(event.position):
		if event.pressed:
			handle_touch_start(event.position)
		elif not event.pressed:  # Сенсорное событие отпущено
			handle_touch_release()
	elif event is InputEventMouseMotion or event is InputEventScreenDrag:
		touch_end_position = event.position

## обработка начала  движения уазателя (пальца)
func handle_touch_start(touch_position):
	if global.can_spin==true:
		touch_start_position = touch_position
		last_touch_time = Time.get_ticks_msec()
		global.spin_started.emit() 

## Обработка начала  движения уазателя (пальца)
func handle_touch_release():
	if global.can_spin==true:
		var time_diff_ms = Time.get_ticks_msec() - last_touch_time
		var distance = touch_start_position.distance_to(touch_end_position)
		var speed = clamp(max_rotation_speed * (distance / (time_diff_ms * touch_slow_down_coefficient)), min_rotation_speed, max_rotation_speed)
		if is_rotating == false:
			spin_sign =  sign(touch_start_position.normalized().angle_to(touch_end_position.normalized()) )
			current_rotation_speed = speed * spin_sign
			is_rotating = true
			global.spin_started.emit()
	
## Замелояем движене барабана
func slow_down():
	if is_rotating == true:
		current_rotation_speed *= friction_coefficient 
		if abs(current_rotation_speed) < 0.25:
			is_rotating = false
			determine_sector()

## определяем свыпавший сектор и запускаем дальнейшую обработку
func determine_sector():
	
	var sector_size = 360.0 / sectors_count # Размер сектора
	
	var rotation_deg = $Wheel.rotation_degrees # сохранячем угол поворта
	var wheel_angle =  rotation_deg * spin_sign # Применение поправки на знак вращения
	
	if spin_sign > 0:
		wheel_angle = 360 - wheel_angle  # Инвертируем угол при вращении против часовой стрелки
	

	var centered_angle = wheel_angle + (sector_size / 2) 	# Центрирование границы секторов	# Центрирование границы секторов
	
	var result_sector = floori(centered_angle / sector_size) % sectors_count # Определение сектора
	global.spin_finished.emit(result_sector) # отправляе сигнал
	rocking_wheel(rotation_deg,spin_sign) # делаем покачивание барабана у стрелки

## Покачивание берабана у стрелки
## Нужно чтобы задержка от запроса к API не бросалась в глаза
## final_rotation -- настоящий угол поворота который определен у барабана
## spin_sig -- направление вращения барабана
func rocking_wheel(final_rotation,spin_sign):
	var transition_duration = 1.0 # Длительность перехода в секундах
	var rotation_span = 1.5  # Макс разброс покачивываания у стрелки
	var wheel = $Wheel
	var tween = create_tween() # создаем анимацию
	var first_step= wheel.rotation_degrees - rotation_span * spin_sign  # угол для первой анимации
	var second_step = wheel.rotation_degrees  + (rotation_span / 4.0 * spin_sign ) #угол для второй анимации
	global.can_spin=false # чтобы не пытались запутсить вращение во время покачивания
	tween.finished.connect(_on_wheel_tween_finished) # разрешаем вщать барабан после завршения качения
	tween.tween_property(wheel, "rotation_degrees", first_step , transition_duration) # Качаем против движения
	tween.tween_property(wheel, "rotation_degrees", second_step , transition_duration) # качаем по движению
	tween.tween_property(wheel, "rotation_degrees", final_rotation  , transition_duration) # приводим в конечное состояние
	
## разрешаем вщать барабан после завршения качения
func _on_wheel_tween_finished():
	global.can_spin=true

func _process(delta):
	if is_rotating:
		$Wheel.rotate(current_rotation_speed * delta)
		slow_down()
