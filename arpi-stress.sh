#!/bin/bash
#
# AksTis Raspberry Pi stress test
#
# Описание:
#   Скрипт выполняет стресс-тест Raspberry Pi, собирая данные о температуре процессора, частоте и статусе троттлинга в течение трех этапов:
#   - Бездействие (60 секунд)
#   - Cтресс-тест (300 секунд)
#   - Охлаждение (60 секунд)
#  Результаты сохраняются в CSV-файл для дальнейшего анализа
#
# Зависимости:
#   - stress (установите: sudo apt install stress)
#   - vcgencmd (доступен на Raspberry Pi с Raspberry Pi OS)
#
# Использование:
#   1. Загрузите скрипт:
#      wget https://github.com/akstis-su/arpi-stress
#   2. Дайте права на выполнение:
#      chmod +x arpi-stress.sh
#   3. Запустите:
#      ./arpi-stress.sh
#
# Автор: AksTis
# https://akstis.su/
#
# Версия: 1.0
# Дата: 30 июня 2025
# Лицензия: MIT

readonly RED='\e[91m'
readonly GREEN='\e[38;5;154m'
readonly YELLOW='\033[0;33m'
readonly GREY='\e[90m'
readonly NC='\e[0m'

readonly GREEN_LINE_DASH=" ${GREEN}─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─${NC}"
readonly GREEN_BULLET=" ${GREEN}─${NC}"
readonly GREEN_SEPARATOR="${GREEN}:${NC}"
error()  { echo -e    "${GREY}[${RED}FAILED${GREY}]${NC} $1"; exit 1; }

command -v stress &>/dev/null || error "stress не установлен. Установите: sudo apt install stress"

collect_metrics() {
    timestamp=$(date +"%Y-%m-%d %H:%M:%S") || error "Не удалось получить временную метку."
    cpu_temp=$(vcgencmd measure_temp | awk -F'[=°]' '{print $2}') || error "Не удалось получить температуру процессора."
    cpu_clock_speed=$(vcgencmd measure_clock arm | awk -F= '{print $2 / 1000000}') || error "Не удалось получить частоту процессора."
    throttled_status=$(vcgencmd get_throttled | awk -F= '{print $2}') || error "Не удалось получить статус троттлинга."
}


print_status() {
    local timestamp=$1 cpu_temp=$2 cpu_clock_speed=$3 throttled_status=$4 t=$5 stage=$6
    echo "            AksTis Raspberry Pi stress test"
    echo -e "$GREEN_LINE_DASH"
	case "$stage" in
	"idle")
		echo -e "${GREEN_BULLET} Стадия 1 ${GREEN_SEPARATOR}"
		echo -e "${GREEN_BULLET} Бездействие в течении ${idle_duration} секунд"
		echo -e "${GREEN_BULLET} Запуск стресс-теста через ${YELLOW}$t${NC}"
		;;
	"stress")
		echo -e "${GREEN_BULLET} Стадия 2 ${GREEN_SEPARATOR}"
		echo -e "${GREEN_BULLET} ${RED}Стресс-тест${NC} в течении ${stress_duration} секунд"
		echo -e "${GREEN_BULLET} Остановка стресс-теста через ${RED}$t${NC}"
		;;
	"cooldown")
		echo -e "${GREEN_BULLET} Стадия 3 ${GREEN_SEPARATOR}"
		echo -e "${GREEN_BULLET} Охлаждение в течении ${cooldown_duration} секунд"
		echo -e "${GREEN_BULLET} Завершение через ${YELLOW}$t${NC}"
		;;
	"end")
		echo -e "${GREEN_BULLET}"
		echo -e "${GREEN_BULLET} Стресс-тест завершён!"
		echo -e "${GREEN_BULLET}"
		;;
    esac
    echo -e "$GREEN_LINE_DASH"
	echo -e "${GREEN_BULLET} Timestamp              ${GREEN_SEPARATOR} $timestamp"
	echo -e "${GREEN_BULLET} CPU Temperature (C)    ${GREEN_SEPARATOR} $cpu_temp"
	echo -e "${GREEN_BULLET} CPU Clock Speed (MHz)  ${GREEN_SEPARATOR} $cpu_clock_speed"
	echo -e "${GREEN_BULLET} CPU Throttled          ${GREEN_SEPARATOR} $throttled_status"
    echo -e "$GREEN_LINE_DASH"
}

run_phase() {
    local phase=$1 duration=$2
    for i in $(seq 1 "$duration"); do
        collect_metrics
        t=$((duration + 1 - i))

        tput cup 0 0
		tput ed
        print_status "$timestamp" "$cpu_temp" "$cpu_clock_speed" "$throttled_status" "$t" "$phase"
        echo "$timestamp,$cpu_temp,$cpu_clock_speed,$throttled_status" >> "$output_file"
        sleep 1
    done
}

# Инициализация
clear
idle_duration=60        #60
stress_duration=300      #300
cooldown_duration=60    #60
time_file=$(date +"%Y-%m-%d_%H:%M:%S")
output_file="$(dirname "$(realpath "${BASH_SOURCE[0]}")")/stress-${time_file}.csv"

echo "Timestamp,CPU Temperature (C),CPU Clock Speed (MHz),CPU Throttled Status" > "$output_file"

# Этап 1: Бездействие
run_phase "idle" "$idle_duration"

# Этап 2: Стресс-тест
stress --cpu 4 -t "${stress_duration}" &>/dev/null &
stress_pid=$!

run_phase "stress" "$stress_duration"

wait "$stress_pid" || error "Процесс stress завершился с ошибкой."

# Этап 3: Охлаждение
run_phase "cooldown" "$cooldown_duration"

# Этап 3: Конец
run_phase "end" "1"
