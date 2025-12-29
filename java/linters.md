
# Linters

- Use Checkstyle, PMD and SpotBugs linters.
- These configurations cover ~70-75% of [code-style](code-style.md) requirements.
- Put directories [checkstyle](./linters/checkstyle), [pmd](./linters/pmd), [spotbugs](./linters/spotbugs) under ./config directory of the project.

## Use

Add file linters.gradle to project root:
```groovy
apply plugin: 'pmd'
apply plugin: 'checkstyle'
apply plugin: 'com.github.spotbugs'

// Checkstyle

checkstyle {
    toolVersion = '12.2.0'
    maxWarnings = 0
    ignoreFailures = false
    showViolations = true
}

tasks.named('checkstyleMain') {
    configFile = file("${rootDir}/config/checkstyle/checkstyle.xml")
}

tasks.named('checkstyleTest') {
    configFile = file("${rootDir}/config/checkstyle/checkstyle-test.xml")
}

tasks.withType(Checkstyle).configureEach {
    reports {
        xml.required = true
        html.required = true
    }
}

// PMD

pmd {
    toolVersion = '7.19.0'
    ignoreFailures = false
    consoleOutput = true
    ruleSets = []
}

pmdMain {
    ruleSetFiles = files("${rootDir}/config/pmd/ruleset.xml")
}

pmdTest {
    ruleSetFiles = files("${rootDir}/config/pmd/ruleset-test.xml")
}

tasks.register('codeQuality') {
    dependsOn 'pmdMain', 'pmdTest', 'checkstyleMain', 'checkstyleTest'
    group = 'verification'
}

// SpotBugs

spotbugs {
    toolVersion = '4.8.6'
    excludeFilter = file('config/spotbugs/exclude.xml')
    includeFilter = file('config/spotbugs/include.xml')
}

```

Add include linters.gradle to build.gradle file and spotbuts plugin:
```groovy
plugins {
    // ...
    id 'com.github.spotbugs' version '6.4.7'
}

apply from: 'linters.gradle'
```

## IntelliJ IDEA

1. Install plugins: `CheckStyle-IDEA`, `spotbuts-idea`, `PMD`
2. Checkstyle: `Settings` → `Tools` → `Checkstyle` → add `./config/checkstyle/checkstyle.xml`
3. PMD: `Settings` → `Tools` → `PMD` → add `./config/pmd/ruleset.xml`
4. SpotBugs: `Settings` → `Tools` → `Spotbugs` → `Filters` → add `./config/spotbugs/include.xml` and `./config/spotbugs/exclude.xml` to include/exclude filters
