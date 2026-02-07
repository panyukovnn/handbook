
## Relations

Examples of relations representation in code.

### one-to-one

- One-to-one is declared only in host entity, which contains reference id field

```java
@Entity
public class Address {

    // ...
    
    @OneToOne(fetch = FetchType.LAZY)
    private User user;
}

```

### one-to-many, many-to-one

```java
// ...
@Entity
public class CompanyName {

    // ...

    @ManyToOne(fetch = FetchType.LAZY)
    private Company company;
}
```

```java
@Entity
public class Company {

    // ...

    @OneToMany(mappedBy = "company")
    private Set<CompanyName> companyNames;
}
```

### many-to-many

```java
@Entity
public class Company {

    // ...

    @ManyToMany
    @JoinTable(
        name = "user_companies",
        joinColumns = @JoinColumn(name = "company_id"),
        inverseJoinColumns = @JoinColumn(name = "user_id")
    )
    private Set<User> users;
}
```

```java
@Entity
@Table(name = "users")
public class User {

    // ...
    
    @ManyToMany
    @JoinTable(
        name = "user_companies",
        joinColumns = @JoinColumn(name = "user_id"),
        inverseJoinColumns = @JoinColumn(name = "company_id")
    )
    private List<Company> companies;
}
```

## Simple Join table entity example

```java
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "transaction_counters")
public class TransactionCounters {

    @EmbeddedId
    private TransactionCountersId id;

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @EqualsAndHashCode
    @Embeddable
    public static class TransactionCountersId implements Serializable {

        @Column(name = "transaction_id")
        private UUID transactionId;

        @Column(name = "counter_id")
        private UUID counterId;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;

        TransactionCounters that = (TransactionCounters) o;
        return Objects.equals(id, that.id);
    }

    @Override
    public int hashCode() {
        return getClass().hashCode();
    }
}
```

## Join table entity with audit fields example

```java
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "transaction_counters")
public class TransactionCounters extends AuditableEntity {

    @EmbeddedId
    private TransactionCountersId id;

    @ManyToOne(fetch = FetchType.LAZY)
    @MapsId("transactionId")
    @JoinColumn(name = "transaction_id")
    private Transaction transaction;

    @ManyToOne(fetch = FetchType.LAZY)
    @MapsId("counterId")
    @JoinColumn(name = "counter_id")
    private Counter counter;

    @Getter
    @Setter
    @NoArgsConstructor
    @EqualsAndHashCode
    @AllArgsConstructor
    @Embeddable
    public static class TransactionCountersId implements Serializable {

        @Column(name = "transaction_id")
        private UUID transactionId;

        @Column(name = "counter_id")
        private UUID counterId;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;

        TransactionCounters that = (TransactionCounters) o;
        return Objects.equals(id, that.id);
    }

    @Override
    public int hashCode() {
        return getClass().hashCode();
    }
}
```
