# arpi-stress
**AksTis Raspberry Pi stress test**

## Описание
Скрипт выполняет стресс-тест Raspberry Pi, собирая данные о температуре процессора, частоте и статусе троттлинга в течение трех этапов:
- Бездействие (60 секунд)
- Cтресс-тест (300 секунд)
- Охлаждение (60 секунд)
Результаты сохраняются в CSV-файл для дальнейшего анализа

## Зависимости:
- stress (установите: sudo apt install stress)
- vcgencmd (доступен на Raspberry Pi с Raspberry Pi OS)

## Использование:
1. Загрузите скрипт:
   git clone https://github.com/akstis-su/arpi-stress.git
2. Дайте права на выполнение:
   chmod +x arpi-stress.sh
3. Запустите:
   ./arpi-stress.sh
