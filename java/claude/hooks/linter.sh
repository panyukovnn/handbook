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

if ! ./gradlew codeQuality 2>&1; then
  err "===== CODE QUALITY CHECKS FAILED ====="
  err ""

  REPORTS_DIR="./build/reports"

  # Checkstyle reports
  if [[ -d "$REPORTS_DIR/checkstyle" ]]; then
    for report in "$REPORTS_DIR/checkstyle"/*.xml; do
      err "=== Checkstyle: $(basename "$report") ==="
      # Извлекаем ошибки из XML в читаемом формате
      err "$(awk '
        /<file name=/ { gsub(/.*name="|">.*/, ""); file=$0 }
        /<error/ {
          line=$0; gsub(/.*line="|".*/, "", line)
          msg=$0; gsub(/.*message="|" source.*/, "", msg)
          print file ":" line ": " msg
        }
      ' "$report")"
      err ""
    done
  fi

  err "===== Please fix the issues above ====="
  exit 2
fi

exit 0
