
## Правила работы с базами данных

### Общие правила

- для первичного ключа следует использовать тип `UUID`, автоинкрементальные типы могут быть допустимы только при наличии явного требования 
- запрещено использовать enum в качестве типа данных на уровне бд
- все поля и таблицы должны содержать комментарии
- запрещены аннотации: `@OneToMany`, `@ManyToMany`, `@OneToOne`, `@Lazy`, `@Eager`
- необходимо отключить настройку `spring.jpa.open-in-view`, иначе за каждым входящим http запросом будет закреплена сессия, что приводит к ограничению пропускной способности
- необходимо указывать настройку для автоматического создания схемы бд с помощью настройки `spring.datasource.hikari.connection-init-sql: CREATE SCHEMA IF NOT EXISTS ${spring.datasource.hikari.schema};`
- необходимо включать валидацию схемы бд с помощью настройки `spring.jpa.hibernate.ddl-auto: validate`
- запрещено использовать автоинкременты, поскольку при миграции данных между серверами требуется сохранять идентификаторы
- запрещено использовать триггеры и курсоры — БД работает как хранилище, логика в микросервисах
- запрещено использовать constraints на типы, например `varchar(255)`

### Правила именования

- использовать `snake_case`
- не следует использовать зарезервированные слова SQL и СУБД: limit, offset, user, order, column, table, index
- не следует использовать общеупотребительные слова: entity, record, value, data, row, class

#### Схемы

- соответствует названию микросервиса в `snake_case`
- примеры: `team_mdm_adapter`, `team_notification`, `team_payment_limit`

#### Таблицы

- существительное в единственном числе, также допускается во множественном числе, если так принято в команде
- примеры: `operation_type`, `counter`

#### Связующие таблицы (many-to-many)

- `table1_table2`, в алфавитном порядке или по логике связи, имя второй таблицы во множественном числе
- примеры: `transaction_counters`, `user_roles`

#### Колонки

- существительное, отражающее хранимые данные
- primary key именуется `id`
- внешний ключ: имя таблицы + `_id` (например, `counter_type_id`, `operation_limit_id`)
- булевы поля без приставки `is_` и суффикса `_flag` (например, `active`)
- примеры: `actual_amount`, `start_time`, `end_time`

#### Индексы и ограничения

- формулируются по паттерну: **префикс_имя_таблицы_колонка1_колонка2**
- префиксы:
  - `pkey_` — Primary Key
  - `key_` — Unique
  - `excl_` — Exclusion
  - `idx_` — Index
  - `fkey_` — Foreign Key
  - `check_` — Check constraint
- иногда префиксы располагают в конце названия как суффиксы, это допустимо, если принято в команде
- примеры:
  - `pkey_operation_type` — первичный ключ для таблицы operation_type
  - `idx_counter_guid_end_time_counter_type_id` — индекс для таблицы counter
  - `link_info_short_link_key` — уникальное ограничение для таблицы link_info

### Первичные ключи

- рекомендуется использовать синтетические (суррогатные) ключи — UUID, генерируется в коде
- натуральные ключи не рекомендуются, допустимы только для при наличии явного требования
- составные ключи не рекомендуются из-за проблем расширяемости (исключение: many-to-many таблицы)

### Вторичные (внешние) ключи

- запрещено использование Foreign Key constraints на уровне БД из-за: триггеров, блокировок, усложнения DDL, партиционирования, замедления вставок, миграций
- консистентность обеспечивает код приложения
- исключение: справочные данные, где нарушение может быть фатальным

### Many-to-many связи

- реализуются через отдельную таблицу
- учитывать направление запросов при выборе порядка полей в составном ключе
- основная таблица в имени выбирается эмпирически (accounts_contracts, accounts_branches)

### Служебные поля

- **create_time** — Unix-время (не меняется), формат целое число
- **create_user** — VARCHAR, идентификатор добавившего запись
- **last_modify_time** — обновляется при каждом изменении
- **last_modify_user** — идентификатор последнего редактора
- **note** (опционально) — техническое описание в справочниках

### Подключение базы данных на примере postgresql

1. Зависимость:
```groovy
implementation "org.postgresql:postgresql:${postgresqlVersion}"
```

2. Добавляем настройки:
```yaml
spring:
  datasource:
    url: ${POSTGRES_URL}
    username: ${POSTGRES_USER}
    password: ${POSTGRES_PASSWORD}
    hikari:
      schema: link_shortener
      connection-init-sql: CREATE SCHEMA IF NOT EXISTS ${spring.datasource.hikari.schema};
  liquibase:
    change-log: ./db/changelog/changelog-master.yml
    contexts: "postgres"
  jpa:
    open-in-view: false
    hibernate:
      ddl-auto: validate
```

вот правильно:
```yaml
spring:
  application:
    name: reference-feedback
  datasource:
    url: jdbc:postgresql://${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}
    username: ${POSTGRES_USER}
    password: ${POSTGRES_PASSWORD}
    hikari:
      schema: reference_feedback
      connection-init-sql: CREATE SCHEMA IF NOT EXISTS ${spring.datasource.hikari.schema};
  liquibase:
    change-log: ./db/changelog/changelog-master.yml
    contexts: "postgres"
  jpa:
    open-in-view: false
    hibernate:
      ddl-auto: validate
```