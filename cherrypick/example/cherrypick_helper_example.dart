import 'package:cherrypick/cherrypick.dart';

// Пример сервисов для демонстрации
class DatabaseService {
  void connect() => print('🔌 Connecting to database');
}

class ApiService {
  final DatabaseService database;
  ApiService(this.database);

  void fetchData() {
    database.connect();
    print('📡 Fetching data via API');
  }
}

class UserService {
  final ApiService apiService;
  UserService(this.apiService);

  void getUser(String id) {
    apiService.fetchData();
    print('👤 Fetching user: $id');
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
    bind<ApiService>()
        .toProvide(() => ApiService(currentScope.resolve<DatabaseService>()));
  }
}

class UserModule extends Module {
  @override
  void builder(Scope currentScope) {
    bind<UserService>()
        .toProvide(() => UserService(currentScope.resolve<ApiService>()));
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
    bind<CircularServiceA>().toProvide(
        () => CircularServiceA(currentScope.resolve<CircularServiceB>()));
  }
}

class CircularModuleB extends Module {
  @override
  void builder(Scope currentScope) {
    bind<CircularServiceB>().toProvide(
        () => CircularServiceB(currentScope.resolve<CircularServiceA>()));
  }
}

void main() {
  print('=== Improved CherryPick Helper Demonstration ===\n');

  // Example 1: Global enabling of cycle detection
  print('1. Globally enable cycle detection:');

  CherryPick.enableGlobalCycleDetection();
  print(
      '✅ Global cycle detection enabled: ${CherryPick.isGlobalCycleDetectionEnabled}');

  // All new scopes will automatically have cycle detection enabled
  final globalScope = CherryPick.openRootScope();
  print(
      '✅ Root scope has cycle detection enabled: ${globalScope.isCycleDetectionEnabled}');

  // Install modules without circular dependencies
  globalScope.installModules([
    DatabaseModule(),
    ApiModule(),
    UserModule(),
  ]);

  final userService = globalScope.resolve<UserService>();
  userService.getUser('user123');
  print('');

  // Example 2: Safe scope creation
  print('2. Creating safe scopes:');

  CherryPick.closeRootScope(); // Закрываем предыдущий скоуп
  CherryPick.disableGlobalCycleDetection(); // Отключаем глобальную настройку

  // Создаем безопасный скоуп (с автоматически включенным обнаружением)
  final safeScope = CherryPick.openSafeRootScope();
  print(
      '✅ Safe scope created with cycle detection: ${safeScope.isCycleDetectionEnabled}');

  safeScope.installModules([
    DatabaseModule(),
    ApiModule(),
    UserModule(),
  ]);

  final safeUserService = safeScope.resolve<UserService>();
  safeUserService.getUser('safe_user456');
  print('');

  // Example 3: Detecting cycles
  print('3. Detecting circular dependencies:');

  final cyclicScope = CherryPick.openSafeRootScope();
  cyclicScope.installModules([
    CircularModuleA(),
    CircularModuleB(),
  ]);

  try {
    cyclicScope.resolve<CircularServiceA>();
    print('❌ This should not be executed');
  } catch (e) {
    if (e is CircularDependencyException) {
      print('❌ Circular dependency detected!');
      print('   Message: ${e.message}');
      print('   Chain: ${e.dependencyChain.join(' -> ')}');
    }
  }
  print('');

  // Example 4: Managing detection for specific scopes
  print('4. Managing detection for specific scopes:');

  CherryPick.closeRootScope();

  // Создаем скоуп без обнаружения
  // ignore: unused_local_variable
  final specificScope = CherryPick.openRootScope();
  print(
      '   Detection in root scope: ${CherryPick.isCycleDetectionEnabledForScope()}');

  // Включаем обнаружение для конкретного скоупа
  CherryPick.enableCycleDetectionForScope();
  print(
      '✅ Detection enabled for root scope: ${CherryPick.isCycleDetectionEnabledForScope()}');

  // Создаем дочерний скоуп
  // ignore: unused_local_variable, experimental_member_use
  final featureScope = CherryPick.openScope(scopeName: 'feature.auth');
  print(
      '   Detection in feature.auth scope: ${CherryPick.isCycleDetectionEnabledForScope(scopeName: 'feature.auth')}');

  // Включаем обнаружение для дочернего скоупа
  CherryPick.enableCycleDetectionForScope(scopeName: 'feature.auth');
  print(
      '✅ Detection enabled for feature.auth scope: ${CherryPick.isCycleDetectionEnabledForScope(scopeName: 'feature.auth')}');
  print('');

  // Example 5: Creating safe child scopes
  print('5. Creating safe child scopes:');

  final safeFeatureScope =
      CherryPick.openSafeScope(scopeName: 'feature.payments');
  print(
      '✅ Safe feature scope created: ${safeFeatureScope.isCycleDetectionEnabled}');

  // You can create a complex hierarchy of scopes
  final complexScope =
      CherryPick.openSafeScope(scopeName: 'app.feature.auth.login');
  print('✅ Complex scope created: ${complexScope.isCycleDetectionEnabled}');
  print('');

  // Example 6: Tracking resolution chains
  print('6. Tracking dependency resolution chains:');

  final trackingScope = CherryPick.openSafeRootScope();
  trackingScope.installModules([
    DatabaseModule(),
    ApiModule(),
    UserModule(),
  ]);

  print('   Chain before resolve: ${CherryPick.getCurrentResolutionChain()}');

  // The chain is populated during resolution, but cleared after completion
  // ignore: unused_local_variable
  final trackedUserService = trackingScope.resolve<UserService>();
  print('   Chain after resolve: ${CherryPick.getCurrentResolutionChain()}');
  print('');

  // Example 7: Usage recommendations
  print('7. Recommended usage:');
  print('');

  print('🔧 Development mode:');
  print('   CherryPick.enableGlobalCycleDetection(); // Enable globally');
  print('   or');
  print('   final scope = CherryPick.openSafeRootScope(); // Safe scope');
  print('');

  print('🚀 Production mode:');
  print(
      '   CherryPick.disableGlobalCycleDetection(); // Disable for performance');
  print('   final scope = CherryPick.openRootScope(); // Regular scope');
  print('');

  print('🧪 Testing:');
  print('   setUp(() => CherryPick.enableGlobalCycleDetection());');
  print('   tearDown(() => CherryPick.closeRootScope());');
  print('');

  print('🎯 Feature-specific:');
  print(
      '   CherryPick.enableCycleDetectionForScope(scopeName: "feature.critical");');
  print('   // Enable only for critical features');

  // Cleanup
  CherryPick.closeRootScope();
  CherryPick.disableGlobalCycleDetection();

  print('\n=== Demonstration complete ===');
}
