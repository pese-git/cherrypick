import 'package:cherrypick/cherrypick.dart';

// Пример сервисов для демонстрации
class DatabaseService {
  void connect() => print('🔌 Подключение к базе данных');
}

class ApiService {
  final DatabaseService database;
  ApiService(this.database);
  
  void fetchData() {
    database.connect();
    print('📡 Получение данных через API');
  }
}

class UserService {
  final ApiService apiService;
  UserService(this.apiService);
  
  void getUser(String id) {
    apiService.fetchData();
    print('👤 Получение пользователя: $id');
  }
}

// Модули для различных feature
class DatabaseModule extends Module {
  @override
  void builder(Scope currentScope) {
    bind<DatabaseService>().singleton().toProvide(() => DatabaseService());
  }
}

class ApiModule extends Module {
  @override
  void builder(Scope currentScope) {
    bind<ApiService>().toProvide(() => ApiService(
      currentScope.resolve<DatabaseService>()
    ));
  }
}

class UserModule extends Module {
  @override
  void builder(Scope currentScope) {
    bind<UserService>().toProvide(() => UserService(
      currentScope.resolve<ApiService>()
    ));
  }
}

// Пример циклических зависимостей для демонстрации обнаружения
class CircularServiceA {
  final CircularServiceB serviceB;
  CircularServiceA(this.serviceB);
}

class CircularServiceB {
  final CircularServiceA serviceA;
  CircularServiceB(this.serviceA);
}

class CircularModuleA extends Module {
  @override
  void builder(Scope currentScope) {
    bind<CircularServiceA>().toProvide(() => CircularServiceA(
      currentScope.resolve<CircularServiceB>()
    ));
  }
}

class CircularModuleB extends Module {
  @override
  void builder(Scope currentScope) {
    bind<CircularServiceB>().toProvide(() => CircularServiceB(
      currentScope.resolve<CircularServiceA>()
    ));
  }
}

void main() {
  print('=== Демонстрация улучшенного CherryPick Helper ===\n');
  
  // Пример 1: Глобальное включение обнаружения циклических зависимостей
  print('1. Глобальное включение обнаружения циклических зависимостей:');
  
  CherryPick.enableGlobalCycleDetection();
  print('✅ Глобальное обнаружение включено: ${CherryPick.isGlobalCycleDetectionEnabled}');
  
  // Все новые скоупы будут автоматически иметь включенное обнаружение
  final globalScope = CherryPick.openRootScope();
  print('✅ Root scope автоматически имеет обнаружение: ${globalScope.isCycleDetectionEnabled}');
  
  // Установка модулей без циклических зависимостей
  globalScope.installModules([
    DatabaseModule(),
    ApiModule(),
    UserModule(),
  ]);
  
  final userService = globalScope.resolve<UserService>();
  userService.getUser('user123');
  print('');
  
  // Пример 2: Безопасное создание скоупов
  print('2. Создание безопасных скоупов:');
  
  CherryPick.closeRootScope(); // Закрываем предыдущий скоуп
  CherryPick.disableGlobalCycleDetection(); // Отключаем глобальную настройку
  
  // Создаем безопасный скоуп (с автоматически включенным обнаружением)
  final safeScope = CherryPick.openSafeRootScope();
  print('✅ Безопасный scope создан с обнаружением: ${safeScope.isCycleDetectionEnabled}');
  
  safeScope.installModules([
    DatabaseModule(),
    ApiModule(),
    UserModule(),
  ]);
  
  final safeUserService = safeScope.resolve<UserService>();
  safeUserService.getUser('safe_user456');
  print('');
  
  // Пример 3: Обнаружение циклических зависимостей
  print('3. Обнаружение циклических зависимостей:');
  
  final cyclicScope = CherryPick.openSafeRootScope();
  cyclicScope.installModules([
    CircularModuleA(),
    CircularModuleB(),
  ]);
  
  try {
    cyclicScope.resolve<CircularServiceA>();
    print('❌ Это не должно выполниться');
  } catch (e) {
    if (e is CircularDependencyException) {
      print('❌ Обнаружена циклическая зависимость!');
      print('   Сообщение: ${e.message}');
      print('   Цепочка: ${e.dependencyChain.join(' -> ')}');
    }
  }
  print('');
  
  // Пример 4: Управление обнаружением для конкретных скоупов
  print('4. Управление обнаружением для конкретных скоупов:');
  
  CherryPick.closeRootScope();
  
  // Создаем скоуп без обнаружения
  final specificScope = CherryPick.openRootScope();
  print('   Обнаружение в root scope: ${CherryPick.isCycleDetectionEnabledForScope()}');
  
  // Включаем обнаружение для конкретного скоупа
  CherryPick.enableCycleDetectionForScope();
  print('✅ Обнаружение включено для root scope: ${CherryPick.isCycleDetectionEnabledForScope()}');
  
  // Создаем дочерний скоуп
  final featureScope = CherryPick.openScope(scopeName: 'feature.auth');
  print('   Обнаружение в feature.auth scope: ${CherryPick.isCycleDetectionEnabledForScope(scopeName: 'feature.auth')}');
  
  // Включаем обнаружение для дочернего скоупа
  CherryPick.enableCycleDetectionForScope(scopeName: 'feature.auth');
  print('✅ Обнаружение включено для feature.auth scope: ${CherryPick.isCycleDetectionEnabledForScope(scopeName: 'feature.auth')}');
  print('');
  
  // Пример 5: Создание безопасных дочерних скоупов
  print('5. Создание безопасных дочерних скоупов:');
  
  final safeFeatureScope = CherryPick.openSafeScope(scopeName: 'feature.payments');
  print('✅ Безопасный feature scope создан: ${safeFeatureScope.isCycleDetectionEnabled}');
  
  // Можем создать сложную иерархию скоупов
  final complexScope = CherryPick.openSafeScope(scopeName: 'app.feature.auth.login');
  print('✅ Сложный scope создан: ${complexScope.isCycleDetectionEnabled}');
  print('');
  
  // Пример 6: Отслеживание цепочки разрешения
  print('6. Отслеживание цепочки разрешения:');
  
  final trackingScope = CherryPick.openSafeRootScope();
  trackingScope.installModules([
    DatabaseModule(),
    ApiModule(),
    UserModule(),
  ]);
  
  print('   Цепочка разрешения до resolve: ${CherryPick.getCurrentResolutionChain()}');
  
  // Во время разрешения цепочка будет заполнена, но после завершения - очищена
  final trackedUserService = trackingScope.resolve<UserService>();
  print('   Цепочка разрешения после resolve: ${CherryPick.getCurrentResolutionChain()}');
  print('');
  
  // Пример 7: Рекомендации по использованию
  print('7. Рекомендации по использованию:');
  print('');
  
  print('🔧 Development режим:');
  print('   CherryPick.enableGlobalCycleDetection(); // Включить глобально');
  print('   или');
  print('   final scope = CherryPick.openSafeRootScope(); // Безопасный скоуп');
  print('');
  
  print('🚀 Production режим:');
  print('   CherryPick.disableGlobalCycleDetection(); // Отключить для производительности');
  print('   final scope = CherryPick.openRootScope(); // Обычный скоуп');
  print('');
  
  print('🧪 Testing:');
  print('   setUp(() => CherryPick.enableGlobalCycleDetection());');
  print('   tearDown(() => CherryPick.closeRootScope());');
  print('');
  
  print('🎯 Feature-specific:');
  print('   CherryPick.enableCycleDetectionForScope(scopeName: "feature.critical");');
  print('   // Включить только для критически важных feature');
  
  // Очистка
  CherryPick.closeRootScope();
  CherryPick.disableGlobalCycleDetection();
  
  print('\n=== Демонстрация завершена ===');
}
