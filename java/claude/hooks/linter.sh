#!/usr/bin/env bash
set -euo pipefail

msg() {
  echo "$*"
}

err() {
  echo "$*" >&2
}

# Получаем рабочую директорию из контекста хука
WORK_DIR=$(jq -r '.cwd // empty')

if [[ -z "$WORK_DIR" ]]; then
  msg "Warning: No working directory provided in hook context"
  exit 0
fi

cd "$WORK_DIR"

# Проверяем, что это Gradle-проект
if [[ ! -f "./gradlew" ]]; then
  # Не Gradle проект - просто выходим
  exit 0
fi

# Проверяем наличие задачи codeQuality
if ! ./gradlew tasks --all 2>/dev/null | grep -q "codeQuality"; then
  # Задача codeQuality не найдена - пропускаем проверку
  exit 0
fi

# Запускаем и сохраняем весь вывод
GRADLE_OUTPUT=$(./gradlew codeQuality 2>&1) || GRADLE_EXIT_CODE=$?

if [[ "${GRADLE_EXIT_CODE:-0}" -ne 0 ]]; then
  err "===== CODE QUALITY CHECKS FAILED ====="
  err ""
  err "Gradle output:"
  err "$GRADLE_OUTPUT"
  err ""
  err "===== PLEASE FIX THE ISSUES ABOVE ====="

  exit 2
fi

exit 0
