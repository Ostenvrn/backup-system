#!/bin/bash

# ============================================================
# Имя: backup.sh
# Назначение: Создает сжатый бэкап папки с логированием
# Версия: 2.0 (исправлена для CI/CD)
# ============================================================

set -euo pipefail  # Режим строгих ошибок: скрипт падает при любой ошибке

# --- 0. Создаем необходимые папки, если их нет ---
LOG_DIR="$HOME/devops/backup-system/logs"
BACKUP_DIR="$HOME/backups"

if [ ! -d "$LOG_DIR" ]; then
    mkdir -p "$LOG_DIR"
    echo "📁 Создана папка для логов: $LOG_DIR"
fi

if [ ! -d "$BACKUP_DIR" ]; then
    mkdir -p "$BACKUP_DIR"
    echo "📁 Создана папка для бэкапов: $BACKUP_DIR"
fi

# --- 1. Конфигурация ---
SOURCE_DIR="${1:-}"  # Папка для бэкапа (первый аргумент)
LOG_FILE="$LOG_DIR/backup.log"
DATE=$(date +"%Y-%m-%d_%H-%M")
BACKUP_NAME="backup_$DATE.tar.gz"
BACKUP_PATH="$BACKUP_DIR/$BACKUP_NAME"
MAX_BACKUPS=5  # Сколько последних бэкапов хранить

# --- 2. Проверка аргументов ---
if [ -z "$SOURCE_DIR" ]; then
    echo "🔧 Использование: $0 /путь/к/папке"
    echo "📁 Пример: $0 ~/Документы"
    echo "📁 Пример: $0 ~/projects/test-app"
    exit 1
fi

if [ ! -d "$SOURCE_DIR" ]; then
    echo "❌ ОШИБКА: Папка '$SOURCE_DIR' не существует!"
    exit 1
fi

# --- 3. Логируем начало работы ---
echo "[$(date '+%Y-%m-%d %H:%M:%S')] ===== НАЧАЛО БЭКАПА =====" >> "$LOG_FILE"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Папка: $SOURCE_DIR" >> "$LOG_FILE"

# --- 4. Создаем архив ---
echo "🔄 Создаю архив: $BACKUP_NAME"
if tar -czf "$BACKUP_PATH" -C "$SOURCE_DIR" . 2>> "$LOG_FILE"; then
    SIZE=$(du -k "$BACKUP_PATH" | cut -f1)
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ УСПЕХ! Создан архив: $BACKUP_NAME (Размер: ${SIZE} KB)" >> "$LOG_FILE"
    echo "✅ Готово! Бэкап сохранен: $BACKUP_PATH"
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ❌ ОШИБКА! Не удалось создать архив" >> "$LOG_FILE"
    echo "❌ Ошибка при создании архива. Смотри лог: $LOG_FILE"
    exit 1
fi

# --- 5. Чистка старых бэкапов (оставляем только последние N) ---
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Чистка старых бэкапов (оставляю $MAX_BACKUPS)" >> "$LOG_FILE"

# Переходим в папку с бэкапами и удаляем лишние
cd "$BACKUP_DIR" || {
    echo "❌ Не могу перейти в папку $BACKUP_DIR"
    exit 1
}

# Находим все backup_*.tar.gz, сортируем по времени (новые сверху),
# пропускаем первые N (оставляем), удаляем остальные
ls -1t backup_*.tar.gz 2>/dev/null | tail -n +$((MAX_BACKUPS + 1)) | while read -r old_backup; do
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Удаляю старый бэкап: $old_backup" >> "$LOG_FILE"
    rm -f "$old_backup"
done

# --- 6. Финальное логирование ---
echo "[$(date '+%Y-%m-%d %H:%M:%S')] ===== КОНЕЦ БЭКАПА =====" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"  # Пустая строка для читаемости

exit 0
