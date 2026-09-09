## ADDED Requirements

---

### Requirement: module_requires_part_directive

Библиотека, содержащая класс с аннотацией `@module`, MUST объявлять part-директиву генератора: `part '<имя файла без .dart>.module.cherrypick.g.dart';`.

`moduleBuilder` — это `PartBuilder`, поэтому без директивы сборка завершается успешно, не создав ни одного файла, и сообщает об этом только предупреждением в логе `build_runner`.

#### Scenario: @module без part-директивы
- **WHEN** библиотека содержит `@module`-класс и не объявляет `part '<файл>.module.cherrypick.g.dart';`
- **THEN** репортируется `module_requires_part_directive` с severity `error`
- **AND** предлагается quick fix «Add the generated part directive»

#### Scenario: part-директива с другим именем
- **WHEN** библиотека объявляет part-директиву, имя которой не совпадает с ожидаемым для этого файла
- **THEN** репортируется `module_requires_part_directive`

#### Scenario: part-директива объявлена
- **WHEN** библиотека объявляет ожидаемую part-директиву
- **THEN** диагностика не репортируется

#### Scenario: @module-класс в part-файле
- **WHEN** `@module`-класс объявлен в юните, содержащем `part of`
- **THEN** диагностика не репортируется — директива принадлежит владеющей библиотеке

---

### Requirement: module_must_extend_module

Класс, аннотированный `@module`, MUST иметь `Module` из `package:cherrypick` в цепочке супертипов.

Генерируемый part — `final class $Foo extends Foo`, где тело `@override void builder(Scope currentScope)` состоит из вызовов `bind<T>()`; оба члена объявлены в `Module`. Без наследования генератор молча пишет part, который не компилируется.

#### Scenario: @module без наследования Module
- **WHEN** `@module`-класс не наследует `Module` ни прямо, ни через промежуточный класс
- **THEN** репортируется `module_must_extend_module` с severity `error`
- **AND** quick fix не предлагается

#### Scenario: @module наследует Module напрямую
- **WHEN** `@module`-класс объявлен как `extends Module`
- **THEN** диагностика не репортируется

#### Scenario: @module наследует Module через промежуточный класс
- **WHEN** `@module`-класс наследует класс, который сам наследует `Module`
- **THEN** диагностика не репортируется

## MODIFIED Requirements

---

### Requirement: module_method_missing_binding

Каждый неабстрактный метод в классе, аннотированном `@module`, MUST иметь аннотацию `@provide` или `@instance` — независимо от видимости и от модификатора `static`.

`GeneratedClass.fromClassElement` собирает `ClassElement.methods` с фильтром только по `!isAbstract`, без проверки видимости, и передаёт каждый метод в `AnnotationValidator.validateMethodAnnotations`, который бросает исключение на методе без обеих аннотаций. Геттеры и сеттеры исключены: они лежат в `ClassElement.getters`/`.setters` и генератором не читаются.

#### Scenario: Публичный метод без DI-аннотации
- **WHEN** `@module`-класс содержит публичный метод без `@provide` и без `@instance`
- **THEN** репортируется `module_method_missing_binding` с severity `error`

#### Scenario: Приватный метод без DI-аннотации
- **WHEN** `@module`-класс содержит приватный метод без `@provide` и без `@instance`
- **THEN** репортируется `module_method_missing_binding` — кодогенерация падает на нём так же, как на публичном

#### Scenario: static-метод без DI-аннотации
- **WHEN** `@module`-класс содержит `static`-метод без `@provide` и без `@instance`
- **THEN** репортируется `module_method_missing_binding`

#### Scenario: Метод с DI-аннотацией
- **WHEN** метод `@module`-класса аннотирован `@provide` или `@instance`
- **THEN** диагностика не репортируется

#### Scenario: Геттер или сеттер без DI-аннотации
- **WHEN** `@module`-класс содержит геттер или сеттер без DI-аннотации
- **THEN** диагностика не репортируется

---

### Requirement: module_must_be_abstract

Класс, аннотированный `@module`, MUST быть объявлен как `abstract`.

Сам генератор модификатор не проверяет: он собирает неабстрактные методы и эмитит `final class $Foo extends Foo` в любом случае. Требование сохраняется потому, что рабочего конкретного варианта не существует: `Module.builder` абстрактный, поэтому без переопределения класс отвергает Dart (`non_abstract_class_inherits_abstract_member`), а с переопределением генератор падает на `builder` как на неабстрактном методе без `@provide` и `@instance`.

#### Scenario: @module на конкретном классе
- **WHEN** класс аннотирован `@module()` и не имеет модификатора `abstract`
- **THEN** репортируется `module_must_be_abstract` с severity `error`
- **AND** предлагается quick fix «Make class abstract»

#### Scenario: @module на abstract классе
- **WHEN** класс аннотирован `@module()` и объявлен как `abstract class`
- **THEN** диагностика не репортируется
