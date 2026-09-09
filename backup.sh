#!/bin/bash

# =============================================
# Имя: backup.sh
# Назначение: Создает сжатый бэкап папки с логом
# =============================================

# --- 0. Убедимся, что папка для логов существует ---
LOG_DIR="$HOME/devops/backup-system/logs"
if [ ! -d "$LOG_DIR" ]; then
    mkdir -p "$LOG_DIR"
fi

# --- 1. Конфигурация (измени под себя) ---
SOURCE_DIR="$1"  # берем папку из первого аргумента командной строки
BACKUP_DIR="$HOME/backups"
LOG_FILE="$LOG_DIR/backup.log"
DATE=$(date +"%Y-%m-%d_%H-%M")
BACKUP_NAME="backup_$DATE.tar.gz"

# --- 1. Конфигурация (измени под себя) ---
SOURCE_DIR="$1"  # берем папку из первого аргумента командной строки
BACKUP_DIR="$HOME/backups"
LOG_FILE="$HOME/devops/backup-system/logs/backup.log"
DATE=$(date +"%Y-%m-%d_%H-%M")
BACKUP_NAME="backup_$DATE.tar.gz"

# --- 2. Проверка ошибок (чтобы скрипт не сломался) ---
if [ -z "$SOURCE_DIR" ]; then
    echo "ОШИБКА: Укажи папку для бэкапа!"
    echo "Пример: ./backup.sh /home/user/Документы"
    exit 1
fi

if [ ! -d "$SOURCE_DIR" ]; then
    echo "ОШИБКА: Папка '$SOURCE_DIR' не существует!"
    exit 1
fi

# --- 3. Создаем архив ---
echo "[$(date)] Начинаю бэкап папки: $SOURCE_DIR" >> "$LOG_FILE"

tar -czf "$BACKUP_DIR/$BACKUP_NAME" -C "$SOURCE_DIR" . 2>> "$LOG_FILE"

# Проверяем, успешно ли создался архив
if [ $? -eq 0 ]; then
    # Считаем размер архива в килобайтах
    SIZE=$(du -k "$BACKUP_DIR/$BACKUP_NAME" | cut -f1)
    echo "[$(date)] ✅ УСПЕХ! Создан архив: $BACKUP_NAME (Размер: ${SIZE} KB)" >> "$LOG_FILE"
    echo "✅ Готово! Бэкап сохранен: $BACKUP_DIR/$BACKUP_NAME"
else
    echo "[$(date)] ❌ ОШИБКА! Не удалось создать архив" >> "$LOG_FILE"
    echo "❌ Ошибка при создании архива. Смотри лог: $LOG_FILE"
    exit 1
fi

# --- 4. Чистка старых бэкапов (оставляем только 5 последних) ---
echo "[$(date)] Чистка старых бэкапов (оставляю 5)" >> "$LOG_FILE"
cd "$BACKUP_DIR" || exit
ls -1t backup_*.tar.gz | tail -n +6 | xargs rm -f 2>> "$LOG_FILE"

echo "[$(date)] -------------------------" >> "$LOG_FILE"
