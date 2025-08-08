import 'package:cherrypick/cherrypick.dart';

// Пример сервисов с циклической зависимостью
class UserService {
  final OrderService orderService;
  
  UserService(this.orderService);
  
  void createUser(String name) {
    print('Creating user: $name');
    // Пытаемся получить заказы пользователя, что создает циклическую зависимость
    orderService.getOrdersForUser(name);
  }
}

class OrderService {
  final UserService userService;
  
  OrderService(this.userService);
  
  void getOrdersForUser(String userName) {
    print('Getting orders for user: $userName');
    // Пытаемся получить информацию о пользователе, что создает циклическую зависимость
    userService.createUser(userName);
  }
}

// Модули с циклическими зависимостями
class UserModule extends Module {
  @override
  void builder(Scope currentScope) {
    bind<UserService>().toProvide(() => UserService(
      currentScope.resolve<OrderService>()
    ));
  }
}

class OrderModule extends Module {
  @override
  void builder(Scope currentScope) {
    bind<OrderService>().toProvide(() => OrderService(
      currentScope.resolve<UserService>()
    ));
  }
}

// Правильная реализация без циклических зависимостей
class UserRepository {
  void createUser(String name) {
    print('Creating user in repository: $name');
  }
  
  String getUserInfo(String name) {
    return 'User info for: $name';
  }
}

class OrderRepository {
  void createOrder(String orderId, String userName) {
    print('Creating order $orderId for user: $userName');
  }
  
  List<String> getOrdersForUser(String userName) {
    return ['order1', 'order2', 'order3'];
  }
}

class ImprovedUserService {
  final UserRepository userRepository;
  
  ImprovedUserService(this.userRepository);
  
  void createUser(String name) {
    userRepository.createUser(name);
  }
  
  String getUserInfo(String name) {
    return userRepository.getUserInfo(name);
  }
}

class ImprovedOrderService {
  final OrderRepository orderRepository;
  final ImprovedUserService userService;
  
  ImprovedOrderService(this.orderRepository, this.userService);
  
  void createOrder(String orderId, String userName) {
    // Проверяем, что пользователь существует
    final userInfo = userService.getUserInfo(userName);
    print('User exists: $userInfo');
    
    orderRepository.createOrder(orderId, userName);
  }
  
  List<String> getOrdersForUser(String userName) {
    return orderRepository.getOrdersForUser(userName);
  }
}

// Правильные модули без циклических зависимостей
class ImprovedUserModule extends Module {
  @override
  void builder(Scope currentScope) {
    bind<UserRepository>().singleton().toProvide(() => UserRepository());
    bind<ImprovedUserService>().toProvide(() => ImprovedUserService(
      currentScope.resolve<UserRepository>()
    ));
  }
}

class ImprovedOrderModule extends Module {
  @override
  void builder(Scope currentScope) {
    bind<OrderRepository>().singleton().toProvide(() => OrderRepository());
    bind<ImprovedOrderService>().toProvide(() => ImprovedOrderService(
      currentScope.resolve<OrderRepository>(),
      currentScope.resolve<ImprovedUserService>()
    ));
  }
}

void main() {
  print('=== Circular Dependency Detection Example ===\n');
  
  // Example 1: Demonstrate circular dependency
  print('1. Attempt to create a scope with circular dependencies:');
  try {
    final scope = CherryPick.openRootScope();
    scope.enableCycleDetection(); // Включаем обнаружение циклических зависимостей
    
    scope.installModules([
      UserModule(),
      OrderModule(),
    ]);
    
    // Это должно выбросить CircularDependencyException
    final userService = scope.resolve<UserService>();
    print('UserService created: $userService');
  } catch (e) {
    print('❌ Circular dependency detected: $e\n');
  }
  
  // Example 2: Without circular dependency detection (dangerous!)
  print('2. Same code without circular dependency detection:');
  try {
    final scope = CherryPick.openRootScope();
    // НЕ включаем обнаружение циклических зависимостей
    
    scope.installModules([
      UserModule(),
      OrderModule(),
    ]);
    
    // Это приведет к StackOverflowError при попытке использования
    final userService = scope.resolve<UserService>();
    print('UserService создан: $userService');
    
    // Попытка использовать сервис приведет к бесконечной рекурсии
    // userService.createUser('John'); // Раскомментируйте для демонстрации StackOverflow
    print('⚠️  UserService created, but using it will cause StackOverflow\n');
  } catch (e) {
    print('❌ Error: $e\n');
  }
  
  // Example 3: Correct architecture without circular dependencies
  print('3. Correct architecture without circular dependencies:');
  try {
    final scope = CherryPick.openRootScope();
    scope.enableCycleDetection(); // Включаем для безопасности
    
    scope.installModules([
      ImprovedUserModule(),
      ImprovedOrderModule(),
    ]);
    
    final userService = scope.resolve<ImprovedUserService>();
    final orderService = scope.resolve<ImprovedOrderService>();
    
    print('✅ Services created successfully');
    
    // Демонстрация работы
    userService.createUser('John');
    orderService.createOrder('ORD-001', 'John');
    final orders = orderService.getOrdersForUser('John');
    print('✅ Orders for user John: $orders');
    
  } catch (e) {
    print('❌ Error: $e');
  }
  
  print('\n=== Recommendations ===');
  print('1. Always enable circular dependency detection in development mode.');
  print('2. Use repositories and services to separate concerns.');
  print('3. Avoid mutual dependencies between services at the same level.');
  print('4. Use events or mediators to decouple components.');
}
