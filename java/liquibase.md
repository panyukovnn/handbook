
# Правила ведения Liquibase скриптов

## Добавление liquibase

### build.gradle
```gradle
dependencies {
    implementation "org.liquibase:liquibase-core"
    implementation "org.postgresql:postgresql:${postgresVersion}"
}
```

### application.yml
```yaml
spring:
  liquibase:
    change-log: ./db/changelog/changelog-master.yml
    contexts: postgres
  jpa:
    hibernate:
      ddl-auto: validate
```

**Для тестов с H2:** `contexts: h2` (что позволяет отключить `postgres` changeset'ы)

## Структура директорий

```
src/main/resources/db/changelog/
├── changelog-master.yml
├── v1.0.0/
│   ├── changelog.yml
│   ├── sql/
│   │   └── 20251202_01_update_currency.sql
│   ├── 01.create_currency.yml
│   └── 02.add_index_currency.yml
└── v1.1.0/
    ├── changelog.yml
    └── 01.create_country.yml
```

### Контексты

- Указывать `context: postgres` для postgres специфичных сущностей (тип jsonb, GIN/GiST индексы и др.)
- Без контекста - для стандартных yml инструкций, которые применимы к любым хранилищам

## Правила именования

### ChangeSet файлы: `{номер}.{действие}_{объект}.yml`
- Номер: 01, 02, 03...
- Действия: create, alter, add, drop, update, insert
- Примеры:
    - `01.create_currency.yml` - добавить таблицу currency
    - `02.add_index_users.yml` - добавить индекс на таблицу users

### SQL файлы: `YYYYMMDD_NN_action_table_name.sql`
- Дата создания + порядковый номер + действие + таблица
- Примеры:
    - `20251202_01_insert_currency.sql` - наполнить таблицу currency
    - `20251205_01_update_currency.sql` - обновить записи в таблице currency

## Формат файлов

### changelog-master.yml
```yaml
databaseChangeLog:
  - include:
      file: "v1.0.0/changelog.yml"
      relativeToChangelogFile: true
  - include:
      file: "v1.1.0/changelog.yml"
      relativeToChangelogFile: true
```

### v{version}/changelog.yml

```yaml
databaseChangeLog:
  - changeSet:
      id: release/{version}
      author: "Panyukov NN"
      changes:
        - tagDatabase:
            tag: release/{version}
  - include:
      file: 01.create_currency.yml
      relativeToChangelogFile: true
  - include:
      file: 02.add_index_currency.yml
      relativeToChangelogFile: true
```

### ChangeSet с таблицей

```yaml
databaseChangeLog:
  - changeSet:
      id: "01.create_currency.yml"
      author: "Panyukov NN"
      changes:
        - createTable:
            tableName: currency
            remarks: "Справочник валют"
            columns:
              - column:
                  name: id
                  type: UUID
                  constraints:
                    primaryKey: true
              - column:
                  name: code
                  type: varchar
                  remarks: "Iso Код валюты"
              - column:
                  name: name
                  type: varchar
                  remarks: "Наименование валюты"
                  
              - column:
                  name: create_time
                  type: timestamp
                  defaultValueComputed: CURRENT_TIMESTAMP AT TIME ZONE 'UTC'
                  constraints:
                    nullable: false
                  remarks: "Время создания"
              - column:
                  name: create_user
                  type: varchar
                  constraints:
                    nullable: false
                  remarks: "Пользователь, создавший запись"
              - column:
                  name: last_update_time
                  type: timestamp
                  defaultValueComputed: CURRENT_TIMESTAMP AT TIME ZONE 'UTC'
                  constraints:
                    nullable: false
                  remarks: "Время обновления"
              - column:
                  name: last_update_user
                  type: varchar
                  constraints:
                    nullable: false
                  remarks: "Пользователь, изменивший запись"
```

**Требования:**
- `id` = имя файла с .yml
- `author` = корпоративная почта или "Фамилия И.О."
- `remarks` на русском языке
- Все таблицы имеют 4 аудит-поля (create_time, create_user, last_update_time, last_update_user)
- Все колонки (за исключением `id`) и таблицы должны иметь комментарий `remarks`

### ChangeSet с SQL файлом
```yaml
databaseChangeLog:
  - changeSet:
      id: "02.update_currency.yml"
      author: "Panyukov NN"
      changes:
        - sqlFile:
            path: ./sql/20251201_01_update_currency.sql
            relativeToChangelogFile: true
```

### SQL файл
```sql
UPDATE currency
SET code = 'RUB', name = 'Российский рубль'
WHERE code = 'RUR';
```

**Требования для SQL:**
- Операции должны быть идемпотентны

## Типы данных

- `UUID` - первичные ключи (PostgreSQL)
- `jsonb` - JSON (PostgreSQL)
- `varchar` - строки
- `timestamp` - дата/время
- `bigint` / `integer` - числа
- `boolean` - логические

## Workflow

**Новый релиз:**
1. Создать `v{version}/` и `v{version}/changelog.yml` с tagDatabase
2. Добавить changeSet'ы (01, 02, 03...)
3. Добавить include changeSet'ов в `v{version}/changelog.yml`
4. Добавить include `v{version}/changelog.yml` в `changelog-master.yml`

**Текущий релиз:**
1. Добавить файл со следующим номером
2. Добавить include в `v{version}/changelog.yml`

## Ограничения

- **НИКОГДА** не изменять примененные changeSet'ы
- **НИКОГДА** не менять id changeSet'ов
- **НИКОГДА** не удалять файлы changeSet'ов
- Для исправлений создавать новый changeSet
- Не использовать foreign key и ограничения на длину строки/ размер числа
- Запрещено использовать constraints (NOT NULL, UNIQUE, CHECK и т.п.) без явного указания пользователя, исключение составляют primary key и аудируемые поля (create_time, create_user, last_update_time, last_update_user)
