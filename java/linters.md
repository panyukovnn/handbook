
# Linters

- Use Checkstyle, PMD and SpotBugs linters.
- These configurations cover ~70-75% of [code-style](code-style.md) requirements.
- Put directories [checkstyle](./linters/checkstyle), [pmd](./linters/pmd), [spotbugs](./linters/spotbugs) under ./config directory of the project.

## Checkstyle

```groovy
plugins {
    id 'checkstyle'
}

checkstyle {
    toolVersion = '12.2.0'
    maxWarnings = 0
    ignoreFailures = false
}

tasks.named('checkstyleMain') {
    configFile = file("${rootDir}/config/checkstyle/checkstyle.xml")
}

tasks.named('checkstyleTest') {
    configFile = file("${rootDir}/config/checkstyle/checkstyle-test.xml")
}

tasks.withType(Checkstyle) {
    reports {
        xml.required = true
        html.required = true
    }
}
```

### Use

```bash
./gradlew checkstyleMain checkstyleTest
```

## PMD

```groovy
plugins {
    id 'pmd'
}

pmd {
    toolVersion = '7.19.0'
    ruleSetFiles = files("config/pmd/ruleset.xml")
    ignoreFailures = false
}
```

### Use

```bash
./gradlew pmdMain pmdTest
```

## SpotBugs

### Setup
```groovy
plugins {
    id 'com.github.spotbugs' version '6.4.7'
}

spotbugs {
    toolVersion = '4.9.8'
    effort = 'max'
    reportLevel = 'low'
    ignoreFailures = false
    includeFilter = file('config/spotbugs/include.xml')
    excludeFilter = file('config/spotbugs/exclude.xml')
}

dependencies {
    spotbugsPlugins 'com.mebigfatguy.fb-contrib:fb-contrib:7.6.13'
    spotbugsPlugins 'com.h3xstream.findsecbugs:findsecbugs-plugin:1.14.0'
}
```

### Use

```bash
./gradlew spotbugsMain spotbugsTest
```

## Combined task

```groovy
tasks.register('codeQuality') {
    dependsOn 'pmdMain', 'pmdTest', 'spotbugsMain', 'spotbugsTest', 'checkstyleMain', 'checkstyleTest'
    group = 'verification'
}
```

```bash
./gradlew codeQuality
```

## IntelliJ IDEA

1. Install plugins: `CheckStyle-IDEA`, `spotbuts-idea`, `PMD`
2. Checkstyle: `Settings` → `Tools` → `Checkstyle` → add `./config/checkstyle/checkstyle.xml`
3. PMD: `Settings` → `Tools` → `PMD` → add `./config/pmd/ruleset.xml`
4. SpotBugs: `Settings` → `Tools` → `Spotbugs` → `Filters` → add `./config/spotbugs/include.xml` and `./config/spotbugs/exclude.xml` to include/exclude filters
