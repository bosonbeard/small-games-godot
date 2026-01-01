extends Node

const SECTOR_ROTATION_SIGNS = - 1 #сли сектора заданы по часовой стрелке

# Сектора для барабана, по приязке к категориям API, идут по часовой
var sectors = [
	"cinema",
	"theater",
	"concert",
	"quest",
	"exhibition",
	"party,social-activity",
	"education",
	"entertainment,festival,other"
]

# Массив с городами
var locations = []

# Глобальный флаг,  разрешающий вращать барабан
var can_spin = true

# Общий сигнал очистки UI
signal init_ui()

# Общий сигнал начала вращения барабана
signal spin_started()

# Общий сигнал завершения вращения барабана
signal spin_finished(sector:int)
