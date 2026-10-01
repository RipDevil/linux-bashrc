#!/bin/bash

# === НАСТРОЙКИ ===
LOCAL_NAME=""
LOCAL_EMAIL=""

# Функция для обработки одной папки
process_dir() {
    local dir="$1"
    
    # Проверяем, есть ли в этой папке .git (т.е. это git-репозиторий)
    if [ -d "$dir/.git" ]; then
        echo "Настраиваю: $dir"
        cd "$dir"
        git config user.name "$LOCAL_NAME"
        git config user.email "$LOCAL_EMAIL"
        # Возвращаемся в исходную директорию (важно для корректной работы find)
        cd - > /dev/null
    fi
}

# Проверка аргументов
if [ $# -eq 0 ]; then
    echo "Использование: $0 <путь_к_папке>"
    echo "Пример: $0 ~/projects"
    exit 1
fi

TARGET_DIR="$1"

# Проверяем существование директории
if [ ! -d "$TARGET_DIR" ]; then
    echo "Ошибка: Директория '$TARGET_DIR' не найдена."
    exit 1
fi

echo "Начинаю поиск Git-репозиториев в: $TARGET_DIR"
echo "----------------------------------------"

# Используем find для рекурсивного поиска всех папок .git
# -path '*/.git' — ищем именно папки .git
# -prune — не заходим внутрь .git (оптимизация)
find "$TARGET_DIR" -type d -name ".git" -print0 | while IFS= read -r -d '' git_dir; do
    # Отсекаем /.git от пути, чтобы получить путь к корню репозитория
    repo_root="${git_dir%/.git}"
    process_dir "$repo_root"
done

echo "----------------------------------------"
echo "Готово! Все найденные репозитории настроены."
