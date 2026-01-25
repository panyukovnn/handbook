#!/bin/bash

# URL для загрузки правил
URL="https://raw.githubusercontent.com/panyukovnn/handbook/refs/heads/main/java/java-ai-manifesto.md"
TARGET_FILE="CLAUDE.md"
MARKER="# Manifesto: Java AI Rules for code generation"

# Загружаем новое содержимое
echo "Загрузка актуальных правил..."
NEW_CONTENT=$(curl -s "$URL")

if [ -z "$NEW_CONTENT" ]; then
    echo "Ошибка: не удалось загрузить содержимое по ссылке"
    exit 1
fi

# Если файл CLAUDE.md существует, сохраняем часть до маркера
if [ -f "$TARGET_FILE" ]; then
    echo "Обновление существующего файла $TARGET_FILE..."
    # Извлекаем все строки до маркера (не включая его)
    BEFORE_MARKER=$(sed -n "/^${MARKER}/q;p" "$TARGET_FILE")

    # Создаем обновленный файл
    {
        echo "$BEFORE_MARKER"
        echo "$NEW_CONTENT"
    } > "$TARGET_FILE"
else
    echo "Создание нового файла $TARGET_FILE..."
    # Если файла нет, просто создаем его с новым содержимым
    echo "$NEW_CONTENT" > "$TARGET_FILE"
fi

echo "Готово! Файл $TARGET_FILE обновлен."