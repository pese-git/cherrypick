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

## Пример

```dart
// Прямое создание экземпляра
Binding<String>().toInstance("Hello world");

// Асинхронное создание экземпляра
Binding<String>().toInstanceAsync(Future.value("Hello world"));

// Ленивое создание экземпляра через фабрику (sync)
Binding<String>().toProvide(() => "Hello world");

// Ленивое создание экземпляра через фабрику (async)
Binding<String>().toProvideAsync(() async => "Hello async world");

// Экземпляр с параметрами (sync)
Binding<String>().toProvideWithParams((params) => "Hello $params");

// Экземпляр с параметрами (async)
Binding<String>().toProvideAsyncWithParams((params) async => "Hello $params");

// Именованный экземпляр для получения по имени
Binding<String>().toProvide(() => "Hello world").withName("my_string");

// Синглтон (один экземпляр внутри скоупа)
Binding<String>().toProvide(() => "Hello world").singleton();
```
