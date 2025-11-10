
# Правила написания тестов для разработчиков

## Классификация:

Для разработчиков тесты делятся на следующие типы:

- **end-to-end (e2e)** - от вызова контроллера, до возврата ответа, со всеми внешними вызовами и обращениями в базу данных. Нужны для проверки общей работоспособности бизнес-сценария
- **интеграционные тесты** - тесты с поднятием Spring контекста, которые проверяют взаимодействие нескольких классов между собой, но не всего бизнес-сценария целиком. Например, проверка валидации в контроллере, проверка корректности выполняемых SQL запросов в бд, проверка работоспособности вызовов внешних сервисов
- **юнит** - тесты отдельных классов, с мокированием всех зависимостей, нужды для точечной проверки каждого из возможных вариантов вызова методов

## Соотношение количества тестов:

Соотношение количества тестов в зависимости от их типа:

- end-to-end - минимальное количество, выполняются медленнее всего
- интеграционные тесты - среднее количество, выполняются быстрее e2e
- юнит - максимальное количество, выполняются быстрее всего

## Общие правила:

- один тест - один вызов проверяемого метода (или бизнес сценария)
- необходимо проверять как позитивные, так и негативные сценарии работы методов
- тесты должны выполняться быстро - несколько секунд на полный прогон, чтобы разработчик мог их запускать как можно чаще
- тесты следует писать по структуре AAA (Arrange-Act-Assert)
- тесты должны легко читаться
- комментарии к тестам, а также изменение отображаемого имени через @DisplayName являются опциональными. В случае тестирования сложных бизнес-сценариев писать комментарии настоятельно рекомендуется
- тесты должны быть изолированы друг от друга, работать вне зависимости от порядка их запуска, и очищать за собой любое измененное ими общее состояние (бд, кеши)
- в идеале любое изменение в коде должно приводить к падению тестов
- в тестах надо избегать использования логики и констант из основного кода проекта, для вычисления ожидаемого результата
- в CI/CD тесты должны запускаться при создании Merge Request, при коммитах в Merge Request, при создании tag'ов, а также перед каждой сборкой для отправки кода в репозиторий артефактов (Artifactory, Nexus)
- в тестах необходимо избегать явных ожиданий через `Thread.sleep()` и подобных конструкций
- для проверки внутренней логики сервисов с помощью unit тестов, методы можно помечать как protected (вместо private) и размещать класс тестов в той же структуре пакетов, что и проверяемый класс, тогда protected методы будут доступны для вызова
- если для проверки структуры http запросов/ответов вы используете json файлы, то они должны быть изолированы друг от друга в ресурсах и храниться в той же структуре пакетов, что и контроллеры, например: `/test/resources/mock/controller/payment/check` (эндпоинт `/check` в контроллере `PaymentController`)

## Покрытие:

- все публичные методы классов должны быть покрыты тестами
- покрытие кода должно составлять не менее 70%
- покрытие высчитывается с помощью jacoco плагина по линиям кода
- разрешается исключить из покрытия пакеты exception, config, dto и прочие вспомогательные пакеты, которые не тестируются напрямую

## Нейминг:

- в рамках одного микросервиса должны соблюдаться единые правила наименования 
- рекомендуемый нейминг **when_имяМетода_условияТеста_then_ожидаемыйРеузльтат**, примеры:
    - when_searchUser_then_success
    - when_searchUser_withNonExistingId_then_userNotFoundException
- имена классов тестов должны заканчиваться на **Test**
- имена классов юнит-тестов рекомендуется заканчивать на **UnitTest**

## Тесты с поднятием Spring контекста:

Создается общий родительский класс `AbstractTest`, который помечается аннотацией `@SpringBootTest` и в него выполняются все инъекции бинов, а также mock и spy бинов

Все остальные классы тестов, использующие Spring - наследуются от `AbstractTest`

В наследниках `AbstractTest` не должно выполняться инъекций bean'ов, иначе будет загрязняться контекст, что приведёт к значительному замедлению работы тестов

Пример класса `AbstractTest`:

```java
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@AutoConfigureMockMvc
@ActiveProfiles("test")
public abstract class AbstractTest {
    
    @Autowired
    protected MockMvc mockMvc;
    @Autowired
    protected UserService userService;
    
    @Mock
    protected UserClient UserClient;
    
    @SpyBean
    protected AdminsRepoistory adminsRepoistory;
}
```


## Тесты с участием внешних интеграций по http:

Для внешних интеграций должны быть написаны заглушки с использованием wiremock

Настройка wiremock

1. Подключаем зависимость:

```groovy
dependencyManagement { 
    imports { 
        mavenBom "org.springframework.cloud:spring-cloud-dependencies:${springCloudVersion}" 
    } 
} 

dependencies {
    testImplementation 'org.springframework.cloud:spring-cloud-starter-contract-stub-runner' 
}
```

2. Над классом `AbstractTest` добавляем аннотацию `@AutoConfigureWireMock(port = 0)`

3. Создаем класс `AbstractWireMockTest`, который будет инкапсулировать работу wiremock, и он будет отнаследован от `AbstractTest`:

```java
public class AbstractWireMockTest extends AbstractTest {
    
    public static final String IDENTITY_USERS_URL = "/identity/api/v1/users";
    
    @BeforeEach 
    public void setUp() {
        WireMock.reset();
    }
  
    protected void stubResponse(String url, HttpMethod method, String response) {
        stubResponseWithDelay(url, method, response, null, 0);
    }
  
    protected void stubResponseWithRequestBody(String url, HttpMethod method, String response, String requestBody) {
        stubResponseWithDelay(url, method, response, requestBody, 0);
    }
  
    protected void stubResponseWithDelay(String url, HttpMethod method, String response, String requestBody, int delay) {
        MappingBuilder request = request(method.name(), urlPathEqualTo(url));
        
        if (requestBody != null) {
            request.withRequestBody(equalToJson(requestBody));
        }
        
        stubFor(request.willReturn(aResponse()
                .withHeader(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_JSON_VALUE)
                .withBody(response)
                .withFixedDelay(delay)));
    }
  
    protected void stub400Response(String url, HttpMethod method) {
        stubFor(request(method.name(), urlPathEqualTo(url))
          
                .willReturn(badRequest()));
    }
  
    protected void stub500Response(String url, HttpMethod method) {
        stubFor(request(method.name(), urlPathEqualTo(url))
          
                .willReturn(serverError()));
    }
}
```

Прописываем в `application-test.yml` хост и порт wiremock для внешней интеграции:

```yml
mdm-adapter:
  integration:
    identity:
      host: http://localhost:${wiremock.server.port}
```

Пример end-2-end теста с использованием wiremock:

```java
/**
 * Демонстрационный тест с использованием wiremock
 * ОБРАЗЦОВЫЙ ПРИМЕР
 */
class AdminControllerTest extends AbstractWireMockTest {
    
    @Test 
    void when_getAdmins_then_success() throws Exception {
        stubFindAdminUsersResponse();
        
        mockMvc.perform(get("/api/v1/admins")
                .queryParam("name", "John")
                .queryParam("limit", "10")
                .queryParam("offset", "0")
                .queryParam("orderBy", "name")
                .queryParam("sortBy", "ASC"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").isNotEmpty())
                .andExpect(jsonPath("$.body.length()").value(2))
                .andExpect(jsonPath("$.body[0].id").isNotEmpty())
                .andExpect(jsonPath("$.body[0].name").value("John Doe"))
                .andExpect(jsonPath("$.body[0].email").value("john.doe@example.com"))
                .andExpect(jsonPath("$.body[0].isAdmin").value(true))
                .andExpect(jsonPath("$.body[1].id").isNotEmpty())
                .andExpect(jsonPath("$.body[1].name").value("Jane Doe"))
                .andExpect(jsonPath("$.body[1].email").value("jane.doe@example.com"))
                .andExpect(jsonPath("$.body[1].isAdmin").value(true));
        
        Optional<User> firstUser = userRepository.findByExternalId("user-123-abc");
        assertTrue(firstUser.isPresent());
        assertEquals("John Doe", firstUser.get().getName());
        assertEquals("john.doe@example.com", firstUser.get().getEmail());
        assertTrue(firstUser.get().getIsAdmin());
        
        Optional<User> secondUser = userRepository.findByExternalId("user-456-def");
        assertTrue(secondUser.isPresent());
        assertEquals("Jane Doe", secondUser.get().getName());
        assertEquals("jane.doe@example.com", secondUser.get().getEmail());
        assertTrue(secondUser.get().getIsAdmin());
    }
  
    @Test 
    void when_getAdmins_identityReturnsEmptyList_then_emptyResponse() throws Exception {
        stubResponse(IDENTITY_USERS_URL, HttpMethod.POST, "[]");
        
        mockMvc.perform(get("/api/v1/admins")
                .queryParam("name", "NonExistent"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").isNotEmpty())
                .andExpect(jsonPath("$.body.length()").value(0));
    }
  
    @Test 
    void when_getAdmins_identityReturns400status_then_badRequest() throws Exception {
        stub400Response(IDENTITY_USERS_URL, HttpMethod.POST);
        
        mockMvc.perform(get("/api/v1/admins")
                .queryParam("name", "John"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.id").isNotEmpty())
                .andExpect(jsonPath("$.body").doesNotExist())
                .andExpect(jsonPath("$.errorMessage").value("Бизнес исключение: Клиентская ошибка при обращении к внешнему сервису: 400 Bad Request: [no body]"));
    }
  
    @Test 
    void when_getAdmins_identityReturns500status_then_badRequest() throws Exception {
        stub500Response(IDENTITY_USERS_URL, HttpMethod.POST);
        
        mockMvc.perform(get("/api/v1/admins")
                .queryParam("name", "John"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.id").isNotEmpty())
                .andExpect(jsonPath("$.body").doesNotExist())
                .andExpect(jsonPath("$.errorMessage").value("Бизнес исключение: Серверная ошибка при обращении к внешнему сервису: 500 Server Error: [no body]"));
    }
  
    @Test 
    void when_getAdmins_identityTimeout_then_badRequest() throws Exception {
        String requestBody = TestFileUtil.readFileFromResources("mock/controller/identity/getadmins/find-admin-users-request.json");
        String responseBody = TestFileUtil.readFileFromResources("mock/controller/identity/getadmins/find-admin-users-response.json");
        
        stubResponseWithDelay(IDENTITY_USERS_URL, HttpMethod.POST, responseBody, requestBody, 2001);
        
        mockMvc.perform(get("/api/v1/admins")
                .queryParam("name", "John"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.id").isNotEmpty())
                .andExpect(jsonPath("$.body").doesNotExist())
                .andExpect(jsonPath("$.errorMessage", containsStringIgnoringCase("Бизнес исключение: Таймаут обращения к внешнему сервису:")));
    }
  
    private void stubFindAdminUsersResponse() {
        String requestBody = TestFileUtil.readFileFromResources("mock/controller/identity/getadmins/find-admin-users-request.json");
        String responseBody = TestFileUtil.readFileFromResources("mock/controller/identity/getadmins/find-admin-users-response.json");
        
        stubResponseWithRequestBody(IDENTITY_USERS_URL, HttpMethod.POST, responseBody, requestBody);
    }
}
```

**Важно!** Для каждой внешней интеграции должен быть написан ряд типовых тестов:

- таймаут ответа
- ответ со статусом 400
- ответ со статусом 500

## Тесты с использованием баз данных:

Все тесты с использованием базы данных должны быть изолированы друг от друга, для этого:

- каждый тест наполняет бд своими данными с помощью `@Sql` аннотации и отдельных скриптов
- скрипты должны лежать в такой же структуре папок, что и класс теста, чтобы для каждого теста (или класса тестов), набор скриптов был изолирован от других: `/test/resources/sql/controller/payment/check` (для эндпоинта `/check` в контроллере `PaymentController`)
- каждый тест помечается аннотацией `@Transactional` если он выполняется в одном потоке, чтобы откатывать любые изменения, внесенные в бд с помощью скрипта или бизнес-логики

- если в сервисе нет сложных или специфических для хранилища (например с jsonb синтаксисом) sql запросов, то разрешается использовать in-memory базу данных, например h2, что позволяет значительно ускорить выполнение тестов 
- в остальных случаях рекомендуется использовать testcontainers

### Пример использования SQL аннотации

// TODO

### Пример настройки h2 базы данных

1. Подключаем зависимость
```groovy
testRuntimeOnly 'com.h2database:h2'
```

2. Добавляем следующие настройки в application-test.yml:
```yaml
spring:
  datasource:
    driver-class-name: org.h2.Driver
    url: "jdbc:h2:mem:db;DB_CLOSE_DELAY=-1;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE;INIT=create schema if not exists ${spring.datasource.hikari.schema};"
    username: sa
    password: sa
  liquibase:
    contexts: "h2"
```

### Пример настройки Testcontainers

1. Подключаем зависимости
```groovy
testImplementation "org.testcontainers:junit-jupiter:${testContainersVersion}"
testImplementation "org.testcontainers:postgresql:${testContainersVersion}"
```

2. Настраиваем запуск тестконтейнера postgresql в `AbstractTest`:
```java
@SpringBootTest
@ActiveProfiles("test")
public abstract class AbstractTest {

    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16-alpine");

    @BeforeAll
    static void beforeAll() {
        if (!postgres.isRunning()) {
            postgres.start();
        }
    }

    @DynamicPropertySource
    static void configureProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", postgres::getJdbcUrl);
        registry.add("spring.datasource.username", postgres::getUsername);
        registry.add("spring.datasource.password", postgres::getPassword);
    }
}
```

- тестконтейнер должен содержаться в статическом поле, чтобы создавался только один контейнер в рамках запуска всех тестов
- 

## Параметризированные тесты:

Для репетативных сценариев следует использовать парметризированные тесты



Пример реализации:


## Тесты с интеграциями по kafka:

TODO