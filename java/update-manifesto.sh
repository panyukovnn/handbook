#!/bin/bash

# Флаги
ENABLE_QWEN=false  # установите true, чтобы включить создание/обновление QWEN.md

# URL для загрузки правил
URL="https://raw.githubusercontent.com/panyukovnn/handbook/refs/heads/main/java/java-ai-manifesto.md"
AGENTS_FILE="AGENTS.md"
MARKER="# Manifesto: Java AI Rules for code generation"
AGENTS_REF="@AGENTS.md"

# Загружаем новое содержимое
echo "Загрузка актуальных правил..."
NEW_CONTENT=$(curl -s "$URL")

if [ -z "$NEW_CONTENT" ]; then
    echo "Ошибка: не удалось загрузить содержимое по ссылке"
    exit 1
fi

# Обновляем AGENTS.md — заменяем часть начиная с маркера
if [ -f "$AGENTS_FILE" ]; then
    echo "Обновление существующего файла $AGENTS_FILE..."
    TMP=$(mktemp)
    sed -n "/^${MARKER}/q;p" "$AGENTS_FILE" > "$TMP"
    echo "$NEW_CONTENT" >> "$TMP"
    mv "$TMP" "$AGENTS_FILE"
else
    echo "Создание нового файла $AGENTS_FILE..."
    {
        echo "# AGENTS.md"
        echo ""
        echo "$NEW_CONTENT"
    } > "$AGENTS_FILE"
fi

echo "Готово! Файл $AGENTS_FILE обновлен."

# Функция: убедиться, что файл содержит @AGENTS.md в самом начале
ensure_agents_ref() {
    local FILE="$1"
    if [ ! -f "$FILE" ]; then
        echo "Создание $FILE с ссылкой на $AGENTS_REF..."
        echo "$AGENTS_REF" > "$FILE"
    elif ! grep -qF "$AGENTS_REF" "$FILE"; then
        echo "Добавление ссылки $AGENTS_REF в начало $FILE..."
        TMP=$(mktemp)
        { echo "$AGENTS_REF"; cat "$FILE"; } > "$TMP"
        mv "$TMP" "$FILE"
    else
        echo "$FILE уже содержит ссылку на $AGENTS_REF."
    fi
}

ensure_agents_ref "CLAUDE.md"
if [ "$ENABLE_QWEN" = true ]; then
    ensure_agents_ref "QWEN.md"
else
    echo "QWEN.md пропущен (ENABLE_QWEN=false)."
fi

# Самообновление скрипта из приватного GitHub репозитория
SELF_REPO="panyukovnn/personal-environment"
SELF_PATH="claude/update-manifesto.sh"
SELF_FILE="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"

echo "Самообновление скрипта из $SELF_REPO..."
NEW_SCRIPT=$(gh api "repos/${SELF_REPO}/contents/${SELF_PATH}" --jq '.content' | base64 --decode)

if [ -z "$NEW_SCRIPT" ]; then
    echo "Предупреждение: не удалось загрузить обновление скрипта из $SELF_REPO"
else
    echo "$NEW_SCRIPT" > "$SELF_FILE"
    chmod +x "$SELF_FILE"
    echo "Скрипт обновлен: $SELF_FILE"
fi