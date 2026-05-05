# Spring Data JPA Specification

## Назначение

JPA Specification используется для построения динамических запросов с фильтрацией. Позволяет комбинировать условия через
`and`/`or`, пропуская `null`-параметры.

## Расположение и именование

- Класс располагается в пакете `service` (или вложенном — например, `service.domain`) рядом с сервисом-потребителем
- Имя класса: `<Entity>Specifications` (например, `LinkInfoSpecifications`)
- Имя билдер-метода отражает бизнес-сценарий или домен: `build<Action><Domain>Specification`
  (например, `buildFindLinkInfosSpecification`, `buildSearchActiveUsersSpecification`).

## Правила реализации

1. Класс спецификаций — `@Service`-бин, содержащий публичный метод построения `Specification<T>` и набор приватных
   статических методов-фильтров
2. Каждый фильтр — отдельный `private static` метод, возвращающий `Specification<T>`
3. Если значение фильтра пустое — возвращаем `cb.conjunction()` (условие всегда истинно, фильтр не применяется):
    - для объектов — проверка `value == null`
    - для строк — `!StringUtils.hasText(value)` (`null`, пустые и состоящие из пробелов строки игнорируем)
    - для коллекций — `value == null || value.isEmpty()`
4. Фильтры комбинируются через `Specification.where(...).and(...).and(...)`
5. Для OR-условий используем `a.or(b)`: `Specification.where(a.or(b)).and(c)`
6. Для текстовых полей используем `cb.like` + `cb.lower` для регистронезависимого поиска с `%value%`
7. Для диапазонов дат — `cb.greaterThanOrEqualTo` / `cb.lessThanOrEqualTo`
8. Для точного совпадения — `cb.equal`
9. Для `IN`-фильтров — `root.get(field).in(values)`
10. Для фильтров по полю связанной сущности — `root.join("relation")` + обязательно `query.distinct(true)`,
    иначе при `@OneToMany` в результате будут дубликаты родительской сущности
11. Метод `withEqual` параметризуем через generics (`<T, V>`), чтобы не терять типобезопасность

## Типовые методы-фильтры

| Тип фильтра                 | Метод CriteriaBuilder                | Применение                         |
|-----------------------------|--------------------------------------|------------------------------------|
| Частичное совпадение строки | `cb.like(cb.lower(...), "%value%")`  | Поиск по подстроке                 |
| Дата "от"                   | `cb.greaterThanOrEqualTo(...)`       | Нижняя граница диапазона           |
| Дата "до"                   | `cb.lessThanOrEqualTo(...)`          | Верхняя граница диапазона          |
| Точное совпадение           | `cb.equal(...)`                      | Boolean, Enum, ID поля             |
| Вхождение в коллекцию       | `root.get(field).in(values)`         | Фильтр по списку значений          |
| Поле связанной сущности     | `root.join("relation")` + `distinct` | Фильтр по полю `@OneToMany`        |

## Использование

Репозиторий должен наследовать `JpaSpecificationExecutor<T>`:

```java
public interface LinkInfoRepository extends JpaRepository<LinkInfo, UUID>, JpaSpecificationExecutor<LinkInfo> {
}
```

Вызов в сервисе:

```java
Specification<LinkInfo> spec = linkInfoSpecifications.buildFindLinkInfosSpecification(filterRequest);

// без пагинации
List<LinkInfo> result = linkInfoRepository.findAll(spec);

// с пагинацией и сортировкой
Pageable pageable = PageRequest.of(page, size, Sort.by("endTime").descending());
Page<LinkInfo> pageResult = linkInfoRepository.findAll(spec, pageable);

// только сортировка
List<LinkInfo> sorted = linkInfoRepository.findAll(spec, Sort.by("endTime").descending());
```

## Индексы и производительность

Specification сама по себе индексами не управляет, но сгенерированный JPQL/SQL напрямую определяет, какие индексы будут использованы. Ключевые моменты:

**1. `cb.lower()` + `cb.like('%value%')` ломают B-tree**

- `lower(link)` — обычный B-tree по `link` не используется. Нужен функциональный индекс
  (`CREATE INDEX ... ON link_info (lower(link))`) либо тип `citext`.
- Лидирующий `%` в `LIKE` всё равно отрубает B-tree. Для подстрочного поиска заводим GIN с `pg_trgm`:
  `CREATE INDEX ... USING gin (lower(link) gin_trgm_ops)`.
- По умолчанию `withLike` даёт seq scan, если триграммный индекс не подложен.

**2. Диапазоны дат + equality-фильтры**

- B-tree по `endTime` работает на `>=` / `<=`.
- Для связки `active = ? AND endTime BETWEEN ? AND ?` оптимальный составной индекс — `(active, endTime)`.
  Правило: equality сначала, range потом. Если индекс `(endTime, active)` — диапазон «съест» вторую колонку.

**3. JOIN-фильтры**

- `root.join("tags")` + `IN(:tagIds)` упирается в индекс на FK. Всегда необходимо создавать индекс на FK колонку

**4. `null`-фильтры через `cb.conjunction()`**

- Hibernate схлопывает `1=1`, поэтому conjunction-вариант лучше шаблона `:param IS NULL OR field = :param` —
  последний может мешать планировщику выбрать индекс.

**5. OFFSET-пагинация и keyset**

- `findAll(spec, pageable)` с большим offset работает по индексу, но всё равно сканит и отбрасывает  первые N строк. Для больших таблиц используем keyset pagination.
- В качестве PK по умолчанию используем UUID — он не упорядочен по времени и для курсора не подходит.
  Поэтому для keyset-пагинации заводим отдельную колонку `bigserial` (например, `numeric_id`) и пагинируем по ней:
  `WHERE numeric_id > :lastSeqId ORDER BY numeric_id LIMIT :size`. UUID остаётся первичным ключом.

## Полный пример

```java
package ru.panyukovnn.linkshortener.service.domain;

import jakarta.persistence.criteria.Join;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import ru.panyukovnn.linkshortener.dto.FilterLinkInfoRequest;
import ru.panyukovnn.linkshortener.model.LinkInfo;

import java.time.LocalDateTime;
import java.util.Collection;
import java.util.UUID;

@Service
public class LinkInfoSpecifications {

    /**
     * Формирует запрос вида:
     *  FROM LinkInfo li
     *  [LEFT JOIN li.tags t]
     *  WHERE (:linkPart IS NULL OR lower(link) LIKE '%' || lower(cast(:linkPart AS String)) || '%')
     *    AND (cast(:endTimeFrom AS DATE) IS NULL OR endTime >= :endTimeFrom)
     *    AND (cast(:endTimeTo AS DATE) IS NULL OR endTime <= :endTimeTo)
     *    AND (:descriptionPart IS NULL OR lower(description) LIKE '%' || lower(cast(:descriptionPart AS String)) || '%')
     *    AND (:active IS NULL OR active = :active)
     *    AND (:tagIds IS NULL OR t.id IN :tagIds)
     * @param filterRequest запрос поиск по фильтру
     * @return спецификация
     */
    public Specification<LinkInfo> buildFindLinkInfosSpecification(FilterLinkInfoRequest filterRequest) {
        return Specification.where(withLike("link", filterRequest.getLinkPart()))
                .and(withLike("description", filterRequest.getDescriptionPart()))
                .and(withDateFrom("endTime", filterRequest.getEndTimeFrom()))
                .and(withDateTo("endTime", filterRequest.getEndTimeTo()))
                .and(withEqual("active", filterRequest.getActive()))
                .and(withInJoin("tags", "id", filterRequest.getTagIds()));
    }

    private static Specification<LinkInfo> withLike(String fieldName, String fieldValue) {
        return (root, query, cb) -> {
            if (!StringUtils.hasText(fieldValue)) {
                return cb.conjunction();
            }

            return cb.like(cb.lower(root.get(fieldName)), "%" + fieldValue.toLowerCase() + "%");
        };
    }

    private static Specification<LinkInfo> withDateFrom(String fieldName, LocalDateTime fieldValue) {
        return (root, query, cb) -> {
            if (fieldValue == null) {
                return cb.conjunction();
            }

            return cb.greaterThanOrEqualTo(root.get(fieldName), fieldValue);
        };
    }

    private static Specification<LinkInfo> withDateTo(String fieldName, LocalDateTime fieldValue) {
        return (root, query, cb) -> {
            if (fieldValue == null) {
                return cb.conjunction();
            }

            return cb.lessThanOrEqualTo(root.get(fieldName), fieldValue);
        };
    }

    private static <T, V> Specification<T> withEqual(String fieldName, V fieldValue) {
        return (root, query, cb) -> {
            if (fieldValue == null) {
                return cb.conjunction();
            }

            return cb.equal(root.get(fieldName), fieldValue);
        };
    }

    private static <T, V> Specification<T> withIn(String fieldName, Collection<V> values) {
        return (root, query, cb) -> {
            if (values == null || values.isEmpty()) {
                return cb.conjunction();
            }

            return root.get(fieldName).in(values);
        };
    }

    /**
     * Фильтр по полю связанной сущности через join. query.distinct(true) обязателен,
     * иначе при @OneToMany / @ManyToMany в выборке будут дубликаты родительской сущности.
     */
    private static Specification<LinkInfo> withInJoin(String relation, String fieldName, Collection<UUID> values) {
        return (root, query, cb) -> {
            if (values == null || values.isEmpty()) {
                return cb.conjunction();
            }

            query.distinct(true);
            Join<Object, Object> join = root.join(relation);
            return join.get(fieldName).in(values);
        };
    }
}
```