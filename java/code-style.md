# Code Style

Данные рекомендации были составлены мной, по опыту работы на монолитном проекте, со строгими требованиями к стилю кода.

Однако с тех пор я менее строго стал относиться к соблюдению данных правил, например, перестал писать javadoc'и.

Связано это с тем, что в микросервисах объем кода меньше, соответственно читать и поддерживать его проще, и требования не должны быть жесткими.

Тем не менее, я уверен, что вы сможете подчерпнуть для себя полезные правила и применять их в работе.

### Именование пакетов
Без тире, в нижнем регистре

Пример:
`ru.panyukovnn.ssocontroller`

### Именование ресурсов
В нижнем регистре через знак тире (kebab-case):

`logback-spring.xml`

Длина строк не более 250 символов

Ограничение можно задать в настройках IDEA:

`Settings -> Editor -> Code Style -> Hard wrap at`

Переносы строк
Открывающая фигурная скобка не переносится на новую строку:

```java
for (String line : input) {
    ...
}
```

Если выражение не умещается на одной строке, то строка переносится:

Перед оператором:
```java
boolean isActive = conditionA
    && conditionB
    && !conditionC;
```

После запятой:
```java
someMethod(longExpression1, longExpression2,
    longExpression3);
```

### Отступы и пустые строки
1. Отступы состоят из 4 пробелов.

При переносе строки следует либо начинать новую строку с той же позиции, где начинается разбиваемое выражение в предыдущей строке, либо оставить отступ в 8 пробелов (примеры можно посмотреть в п.5.2 Стандарта).

Табуляция не используется.

2. Необходимо оставлять пустую строку перед ключевым словом return, а также после закрывающих фигурных скобок (если это не конец метода):
```java
public List<Integer> createSomeList(int size) {
    List<Integer> result = new ArrayList<>();

    for (int i = 0; i < size; i++) {
        result.add(i);
    }

    result.add(size);

    return result;
}
```
также рекомендуется оставлять пустую строку перед началом конструкций (if, for, try и др.)



3. Рекомендуется оставлять одну пустую строку:

- после констант
- после полей класса
- между методами
- после объявления класса
- после блока импортов

Образец синтаксиса:
```java
@Service
@RequiredArgsConstructor
public class UserApiServiceImpl implements UserApiService {

    private static final String DEFAULT_PAGE_SIZE = 10;
 
    private final UserApi userApi;
    private final SearchRequestMapper searchRequestMapper;
 
    @Override
    public List<IoUser> searchUsers(String filterQuery, Integer pageNumber, Integer pageSize) {
        Integer definedPageSize = pageSize == null
            ? DEFAULT_PAGE_SIZE
            : pageSize;
 
        IoSearchRequest request = searchRequestMapper.toSearchRequest(filterQuery, pageNumber, pageSize);
        IoSearchUserListResponse response = userApi.searchUser(request);
 
        return Optional.ofNullable(response)
            .map(IoSearchUserListResponse::getObject)
            .map(IoSearchUserListResponseObject::getObject)
            .orElse(List.of());
    }
 
    @Override
    public void updateUser(UUID id, UserModificationRequest userModificationRequest) {
        IoItemUserDelta itemDelta = toItemUserDelta(userModificationRequest);
 
        if (itemDelta == null) {
            return;
        }
 
        IoUpdateUserRequest request = createUpdateUserRequest(itemDelta);
 
        userApi.updateUser(id, request);
    }
}
```

4. Между полями класса оставлять пустую строку не нужно

### Конструкции
1. Трудночитаемые булевые выражения, а также длинные цепочки вызова функций, рекомендовано выносить либо в отдельную переменную, либо в метод, имеющие хорошо читаемое наименование.

Пример вынесения в переменную:
```java
boolean isValidCondition = (conditionA && conditionB) || (conditionC && conditionD && conditionE) || conditionF;

if (isValidCondition) {
    ...
}

boolean valueAlreadyExists = values.stream()
    .filter(...)
    .anyMatch(...);

if (valueAlreadyExists) {       
    ...
}
```

Пример вынесения в метод:
```java
public void process() {
    if (isValidCondition(1, 2, 3)) {
        ...
    }
}

public boolean isValidCondition(int a, int c, int b) {
    return a == 1 && b == 2 && c == 3;
}
```

2. В однострочных конструкциях фигурные скобки ставятся всегда:
```java
for (int i = 0; i < 10; i++) {
    doWork();
}
```

3. Пример синтаксиса оператора switch:
```java
switch (condition) {
    case ABC:
        statements;
        break;
    case DEF:
    case GHI:
        statements;
        break;
    default:
        statements;
}
```
Каждая альтернатива содержит ключевое слово break


### Константы
Не следует выносить значение в константу, если она используется менее чем в двух местах в коде.

Однако, даже если константа используется в коде только один раз, ее вынесение допустимо, если это улучшит читаемость кода:
```java
public class Parser {

    private static final String FRONT_DELIMITER = "|";
     
    public String[] splitInput(String input) {
        return input.split(FRONT_DELIMITER);
    }
}
```
Поля класса
Расставляются в следующем порядке:

1. По принадлежности классу:
- статические (сначала)
- нестатические (в конце)
2. По модификаторам доступа:
- private (сначала)
- package-private
- protected
- public (в конце)

### Методы
Методы следует располагать в зависимости от модификаторов доступа:

- public (сначала)
- protected
- package-private
- private (в конце)

### Аннотации
Аннотации рекомендуется располагать в порядке возрастания длины строки, если это не ухудшает читаемости кода (это только мой прикол, можете его не придерживаться):

```java
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class Request {
    ...
}
```
### Функциональные цепочки вызовов
Цепочки функциональных вызовов необходимо переносить на новые строки:
```java
List<CharacterDto> list = characters.stream()
    .filter(character -> House.STARK.equals(character.getHouse()))
    .map(CharacterDto::new)
    .collect(Collectors.toList());
```

### Избежание NullPointerException при сравнениях по equals
При справнении equals, первым аргументом следует указывать объект, который гарантированно не будет равен null

Например, при сравнении enum'ов по equals, первым должно идти ожидаемое значение enum:

```java
if (House.STARK.equals(character.getHouse())) {} // Правильно

if (character.getHouse().equals(House.STARK)) {} // Неправильно, т.к. если character будет null, то возникнет NPE
```

### Javadoc
Javadoc и комментарии следует писать на русском языке.

Следует документировать:
- классы/интерфейсы
- методы/поля с неочевидной логикой, чтобы понимать что имел в виду разработчик

Документирование остальных полей/публичных методов/конструкторов носит рекомендательный характер.

Не рекомендуется документировать:
- общеупотребительные шаблоны
- одноразовые классы/методы которые никуда не пойдут и не будут тестироваться сопровождением


**Пример документирования класса/интерфейса:**
```java
/**
 * Сервис по работе с пользователями.
 */
public class UserService {

    private final UserRepository userRepository;

    public UserService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    /**
     * Обновить пользователя по идентификатору.
     *
     * @param id идентификатор
     * @param name имя
     * @return пользователь
     * @throws BusinessException исключение бизнес логики
     */
    public User updateUser(long id, String name) throws BusinessException {
        ...
    }
}
```
Писать автора и дату изменения допустимо, если вы разрабатываете библиотеку

private методы рекомендуется документировать в случаях, когда это необходимо для разъяснения контракта данного метода

Нет необходимости документировать методы, помеченные аннотацией @Override



**Поля сущностей:**
```java
/**
 * Пользователь.
 */
@Getter
@Setter
public class User {

    /**
     * Идентификатор.
     */
    private long id;
    /**
     * Имя.
     */
    private String name;
    /**
     * Список комментариев.
     */
    private List<String> commentList;
}
```

### Комментарии
Комментарии необходимы:

1. Внутри метода с пустой реализацией:
```java
@Override
protected void checkValue(int value) {
   // реализация не требуется
}
```

Не следует писать методы с пустой реализацией следующим образом:
```java
@Override
protected void checkValue(int value) {} // недопустимо
```

2. Рядом с неочевидной логикой, которую не следует упрощать при рефакторинге:
```java
// Строку необходимо создавать именно через new для корректной работы
String key = new String("key");
```

3. В остальных случаях избегать использования комментариев, стараться писать самодокументируемый и читаемый код.


### Нейминг тестов
1. Название тестов должно соответствовать содержанию
2. Каждая команда/разработчик выбирают свой стиль нейминга, не нарушающий общепринятых конвенций
3. В рамках одного проекта следует поддерживать единый стиль

Я придерживаюсь следующего стиля: when_имяТестируемогоМетода_условие_then_ожидаемый_результат

Пример:

- when_findUsers_filteredByName_then_success
- when_sendNotification_withoutEmail_then_illegalArgumentsException

### SQL
При необходимости писать код на SQL (hql, jpql), следует придерживаться следующего форматирования:
Пример 1:
```sql
SELECT e.*
FROM employee e
JOIN department d ON e.department_id = d.id
WHERE e.age > 25
  AND e.name = 'John'
  AND d.name = 'Департамент цифровых технологий'
ORDER BY e.name
```

Пример 2:
```sql
SELECT d.name department_name,
       COUNT(e.id) employee_count,
       AVG(e.salary) avg_salary,
       MAX(e.salary) max_salary
FROM department d
LEFT JOIN employee e ON d.id = e.department_id
WHERE d.created_date >= '2020-01-01'
  AND d.is_active = true
  AND e.id IN (
      SELECT emp.id
      FROM employee emp
      WHERE emp.hire_date >= '2022-01-01'
        AND emp.status = 'ACTIVE'
  )
GROUP BY d.id, d.name
HAVING COUNT(e.id) > 5
ORDER BY avg_salary DESC, d.name ASC
LIMIT 10
```

### Доработать
- добавить про records
- добавить про var
- пример с современным switch