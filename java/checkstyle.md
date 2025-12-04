# Конфигурация Checkstyle

Конфигурация Checkstyle на основе требований из `java/code-style.md`. Покрывает ~70-75% правил стиля кода.

## Файлы

- `checkstyle.xml` - основная конфигурация
- `suppressions.xml` - исключения для тестов и сгенерированного кода

## Поддерживаемые правила

### ✅ Полностью поддерживаемые

1. Длина строк: 250 символов
2. Именование: пакеты (lowercase), классы (PascalCase), методы/поля (camelCase), константы (UPPER_SNAKE_CASE)
3. Длина методов: 20 строк
4. Параметры метода: не более 7
5. Длина файлов: 250 строк
6. Отступы: 4 пробела, запрет табуляции
7. Фигурные скобки: обязательны всегда, открывающая на той же строке
8. Запрет var в production (разрешено в тестах)
9. Порядок модификаторов, полей (static → non-static)
10. Equals safety (константа слева)
11. Импорты: без звездочек
12. Пустые блоки: требуют комментарий
13. Javadoc: для public классов/интерфейсов

### ⚠️ Частично поддерживаемые

1. Порядок методов (public → private) - через DeclarationOrder
2. Пустые строки - через EmptyLineSeparator
3. Enum naming - через ConstantName
4. Аннотации на отдельных строках

### ❌ Требуют ручного code review

1. Перенос операторов (&&, ||)
2. Функциональные цепочки (каждый вызов на новой строке)
3. Вынесение сложных условий
4. Порядок методов внутри модификатора доступа
5. Порядок аннотаций по длине
6. Современный синтаксис switch
7. Комментарии на русском
8. Нейминг тестов (when_then)
9. Форматирование SQL

## Использование

### Maven
```bash
mvn checkstyle:check          # проверка
mvn checkstyle:checkstyle     # отчет в target/site/checkstyle.html
```

### Gradle
```bash
./gradlew checkstyleMain
./gradlew checkstyleTest
```

### IntelliJ IDEA
1. Установить плагин: `Settings` → `Plugins` → "CheckStyle-IDEA"
2. Настроить: `Settings` → `Tools` → `Checkstyle` → добавить `checkstyle.xml`

### VS Code
```bash
code --install-extension shengchen.vscode-checkstyle
```