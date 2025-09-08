---
sidebar_position: 1
---

# Привязка (Binding)

**Binding** — это конфигурация, которая определяет, как создавать или предоставлять конкретную зависимость. Binding поддерживает:

* Прямое присваивание экземпляра (`toInstance()`, `toInstanceAsync()`)
* Ленивые провайдеры (синхронные/асинхронные функции)
* Провайдеры с поддержкой динамических параметров
* Именованные экземпляры для получения по строковому ключу
* Необязательное управление жизненным циклом синглтона

#### Пример

```dart
void builder(Scope scope) {
  // Прямое предоставление экземпляра
  bind<String>().toInstance("Hello world");

  // Асинхронное предоставление экземпляра
  bind<String>().toInstanceAsync(Future.value("Hello world"));

  // Ленивое создание синхронного экземпляра через фабрику
  bind<String>().toProvide(() => "Hello world");

  // Ленивое создание асинхронного экземпляра через фабрику
  bind<String>().toProvideAsync(() async => "Hello async world");

  // Предоставление экземпляра с динамическими параметрами (синхронно)
  bind<String>().toProvideWithParams((params) => "Hello $params");

  // Предоставление экземпляра с динамическими параметрами (асинхронно)
  bind<String>().toProvideAsyncWithParams((params) async => "Hello $params");

  // Именованный экземпляр для получения по имени
  bind<String>().toProvide(() => "Hello world").withName("my_string");

  // Пометить как синглтон (только один экземпляр в пределах скоупа)
  bind<String>().toProvide(() => "Hello world").singleton();
}
```

> ⚠️ **Важное примечание об использовании `toInstance` в `builder` модуля:**
>
> Если вы регистрируете цепочку зависимостей через `toInstance` внутри `builder` модуля, **не вызывайте** `scope.resolve<T>()` для типов, которые также регистрируются в том же builder — в момент их регистрации.
>
> CherryPick инициализирует все привязки в builder последовательно. Зависимости, зарегистрированные ранее, еще не доступны для `resolve` в рамках того же выполнения builder. Попытка разрешить только что зарегистрированные типы приведет к ошибке (`Can't resolve dependency ...`).
>
> **Как делать правильно:**  
> Вручную создайте полную цепочку зависимостей перед вызовом `toInstance`:
>
> ```dart
> void builder(Scope scope) {
>   final a = A();
>   final b = B(a);
>   final c = C(b);
>   bind<A>().toInstance(a);
>   bind<B>().toInstance(b);
>   bind<C>().toInstance(c);
> }
> ```
>
> **Неправильно:**
> ```dart
> void builder(Scope scope) {
>   bind<A>().toInstance(A());
>   // Ошибка! В этот момент A еще не зарегистрирован.
>   bind<B>().toInstance(B(scope.resolve<A>()));
> }
> ```
>
> **Неправильно:**
> ```dart
> void builder(Scope scope) {
>   bind<A>().toProvide(() => A());
>   // Ошибка! В этот момент A еще не зарегистрирован.
>   bind<B>().toInstance(B(scope.resolve<A>()));
> }
> ```
>
> **Примечание:** Это ограничение применяется **только** к `toInstance`. С `toProvide`/`toProvideAsync` и подобными провайдерами вы можете безопасно использовать `scope.resolve<T>()` внутри builder.


  > ⚠️ **Особое примечание относительно `.singleton()` с `toProvideWithParams()` / `toProvideAsyncWithParams()`:**
  >
  > Если вы объявляете привязку с помощью `.toProvideWithParams(...)` (или его асинхронного варианта) и затем добавляете `.singleton()`, только **самый первый** вызов `resolve<T>(params: ...)` использует свои параметры; каждый последующий вызов (независимо от параметров) вернет тот же (кешированный) экземпляр.
  >
  > **Пример:**
  > ```dart
  > bind<Service>().toProvideWithParams((params) => Service(params)).singleton();
  > final a = scope.resolve<Service>(params: 1); // создает Service(1)
  > final b = scope.resolve<Service>(params: 2); // возвращает Service(1)
  > print(identical(a, b)); // true
  > ```
  >
  > Используйте этот паттерн только когда хотите получить "главный" синглтон. Если вы ожидаете новый экземпляр для каждого набора параметров, **не используйте** `.singleton()` с параметризованными провайдерами.


> ℹ️ **Примечание о `.singleton()` и `.toInstance()`:**
>
> Вызов `.singleton()` после `.toInstance()` **не** меняет поведение привязки: объект, переданный с `toInstance()`, уже является единым, постоянным экземпляром, который всегда будет возвращаться при каждом resolve.
>
> Не обязательно использовать `.singleton()` с существующим объектом — этот вызов не имеет эффекта.
>
> `.singleton()` имеет смысл только с провайдерами (такими как `toProvide`/`toProvideAsync`), чтобы гарантировать создание только одного экземпляра фабрикой.
