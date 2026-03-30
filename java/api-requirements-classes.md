# API Requirements Java realization

Based on api design instruction: https://raw.githubusercontent.com/panyukovnn/handbook/refs/heads/main/common/ai/api-requirements-ai-rules.md

---

## Request Classes (Request DTOs)

### CommonRequest

Common wrapper for requests with data.

```java
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Schema(description = "Общая обертка запроса")
public class CommonRequest<T> {

    @Valid
    @Schema(description = "Данные запроса")
    private T data;
}
```

---

### CommonFilterRequest

Wrapper for requests with filtering, pagination, and sorting.

```java
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Schema(description = "Тело запроса с параметрами поиска по фильтру и пагинацией")
public class CommonFilterRequest<T> {

    @Valid
    @Schema(description = "Параметры фильтрации")
    private T filter;

    @Valid
    @Schema(description = "Пагинация")
    private CommonPaging paging;

    @Builder.Default
    @Schema(description = "Сортировка")
    private List<@Valid CommonOrdering> order = new ArrayList<>();
}
```

---

### CommonPaging

Pagination parameters.

```java
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Schema(description = "Параметры пагинации")
public class CommonPaging {

    @Schema(description = "Смещение")
    @PositiveOrZero(message = "Смещение не может быть меньше 0")
    private Integer offset;

    @Schema(description = "Количество запрашиваемых записей")
    @Positive(message = "Количество запрашиваемых записей должно быть больше 0")
    private Integer size;
}
```

---

### CommonOrdering

Sorting parameters.

```java
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Schema(description = "Параметры сортировки")
public class CommonOrdering {

    @Schema(description = "Наименование поля сортировки")
    @NotEmpty(message = "Наименование поля сортировки не может быть пустым")
    private String sortBy;

    @Schema(description = "Порядок сортировки")
    @Pattern(regexp = "^ASC|DESC$", message = "Недопустимое значение порядка сортировки, возможные значения: ASC, DESC")
    private String orderBy;
}
```

---

## Response Classes (Response DTOs)

### CommonResponse

Common wrapper for responses.

```java
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@JsonInclude(JsonInclude.Include.NON_NULL)
@Schema(description = "Общая обертка ответа")
public class CommonResponse<T> {

    @Builder.Default
    @Schema(description = "Уникальный идентификатор ответа")
    private UUID id = UUID.randomUUID();

    @Builder.Default
    @Schema(description = "Время ответа (в UTC)")
    private OffsetDateTime timestamp = OffsetDateTime.now(ZoneOffset.UTC);

    @Schema(description = "Данные ответа")
    private T data;

    @Schema(description = "Информация об ошибке")
    private CommonResponseError error;
}
```

---

### CommonItemsResponse

Wrapper for returning a list of items with pagination.

```java
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@JsonInclude(JsonInclude.Include.NON_NULL)
@Schema(description = "Общая обертка для возврата списка элементов")
public class CommonItemsResponse<T> {

    @Valid
    @Schema(description = "Список элементов")
    private List<T> items;

    @Schema(description = "Количество возвращаемых элементов")
    private Integer itemsCount;

    @Schema(description = "Общее количество элементов на всех страницах")
    private Integer totalCount;
}
```

---

### CommonResponseError

Error information.

```java
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@JsonInclude(JsonInclude.Include.NON_NULL)
@Schema(description = "Информация об ошибке в ответе")
public class CommonResponseError {

    @Schema(description = "Уникальный идентификатор ошибки, для удобства определения места возникновения")
    private String location;

    @Schema(description = "Человекочитаемый код ошибки")
    private String code;

    @Schema(description = "Данные ошибок валидации")
    private List<CommonResponseFieldValidation> validations;

    @Schema(description = "Отображаемый текст ошибки")
    private String message;
}
```

---

### CommonResponseFieldValidation

Field validation error.

```java
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@JsonInclude(JsonInclude.Include.NON_NULL)
@Schema(description = "Ошибка валидации поля")
public class CommonResponseFieldValidation {

    @Schema(description = "Путь до поля, не прошедшего валидацию")
    private String path;

    @Schema(description = "Отображаемый текст ошибки")
    private String message;
}
```

---

### CommonResponseDefaultErrorCode

Standard error codes.

```java
@Getter
@RequiredArgsConstructor
public enum CommonResponseDefaultErrorCode {

    BUSINESS("business"),
    VALIDATION("validation"),
    FATAL("fatal");

    private final String code;
}
```

---

## Controller Usage Examples

### Simple request with data

```java
@PostMapping("/operations")
public CommonResponse<OperationDto> createOperation(
        @Valid @RequestBody CommonRequest<CreateOperationRequest> request) {
    OperationDto result = operationService.create(request.getData());

    return CommonResponse.<OperationDto>builder()
        .data(result)
        .build();
}
```