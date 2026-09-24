import 'package:benchmark_di/scenarios/universal_binding_mode.dart';
import 'package:benchmark_di/scenarios/universal_scenario.dart';
import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:benchmark_di/di_adapters/di_adapter.dart';
import 'package:benchmark_di/scenarios/universal_service.dart';

class UniversalChainBenchmark<TContainer> extends BenchmarkBase {
  final DIAdapter<TContainer> _di;
  final int chainCount;
  final int nestingDepth;
  final UniversalBindingMode mode;
  final UniversalScenario scenario;
  DIAdapter<TContainer>? _childDi;

  /// Имя целевого биндинга steady-фазы (null для безымянного резолва) и
  /// имена всех голов окна. Вычисляются один раз в setup(): интерполяция
  /// строки внутри run() добавляла бы в секундомер ~40-50 ns аллокации,
  /// не имеющей отношения к работе контейнера.
  String? _targetName;
  List<String> _headNames = const [];

  /// Нативные хендлы биндингов (Dep для yx_scope, ProviderBase для
  /// riverpod), полученные в setup() вне секундомера. null — адаптер
  /// хендлов не держит (service locator'ы), измеряемый путь — named resolve.
  Object? _targetHandle;
  List<Object?> _headHandles = const [];

  /// Сверка «хендл резолвит тот же биндинг, что named» выполняется один раз —
  /// на первом (прогревочном) setup(). Каждая сверка резолвит биндинг и
  /// заполняет его кеш: делай мы это перед каждым сэмплом, измеряемый
  /// «первый резолв» читал бы кеш, а не строил объект.
  bool _validated = false;

  UniversalChainBenchmark(
    this._di, {
    this.chainCount = 1,
    this.nestingDepth = 3,
    this.mode = UniversalBindingMode.singletonStrategy,
    this.scenario = UniversalScenario.chain,
  }) : super('Universal: $scenario/$mode CD=$chainCount/$nestingDepth');

  @override
  void setup() {
    switch (scenario) {
      case UniversalScenario.override:
        _di.setupDependencies(_di.universalRegistration(
          chainCount: chainCount,
          nestingDepth: nestingDepth,
          bindingMode: UniversalBindingMode.singletonStrategy,
          scenario: UniversalScenario.chain,
        ));
        // Родитель держит всю цепочку; ребёнок переопределяет только
        // последнее звено. Так резолв проходит через границу scope, а не
        // остаётся внутри полной копии графа — раньше ребёнок регистрировал
        // копию всей цепочки, и override повторял chainSingleton.
        _childDi = _di.openSubScope('child');
        _childDi!.setupDependencies(_childDi!.universalRegistration(
          chainCount: chainCount,
          nestingDepth: nestingDepth,
          bindingMode: UniversalBindingMode.singletonStrategy,
          scenario: UniversalScenario.override,
        ));
        break;
      default:
        _di.setupDependencies(_di.universalRegistration(
          chainCount: chainCount,
          nestingDepth: nestingDepth,
          bindingMode: mode,
          scenario: scenario,
        ));
        break;
    }
    _prepareAccessors();
  }

  /// Предвычисляет имена и запрашивает нативные хендлы — всё вне секундомера.
  ///
  /// Хендлы запрашиваются у адаптера, через который пойдёт измеряемый
  /// резолв: для override это дочерний scope. Решение «хендловый или
  /// named-путь» принимается здесь один раз и не меняется между итерациями.
  void _prepareAccessors() {
    final measured = scenario == UniversalScenario.override ? _childDi! : _di;
    switch (scenario) {
      case UniversalScenario.chain:
        _targetName = '${chainCount}_$nestingDepth';
        _headNames = [
          for (var chain = 1; chain <= chainCount; chain++)
            '${chain}_$nestingDepth'
        ];
        break;
      case UniversalScenario.named:
        _targetName = 'impl$chainCount';
        _headNames = [
          for (var chain = 1; chain <= chainCount; chain++) 'impl$chain'
        ];
        break;
      case UniversalScenario.register:
        _targetName = null;
        _headNames = const [];
        break;
      case UniversalScenario.override:
        _targetName = null;
        _headNames = [
          for (var chain = 1; chain <= chainCount; chain++)
            '${chain}_$nestingDepth'
        ];
        break;
      case UniversalScenario.asyncChain:
        throw UnsupportedError(
            'asyncChain supported only in UniversalChainAsyncBenchmark');
    }
    _targetHandle = measured.nativeBindingFor(named: _targetName);
    _headHandles = [
      for (final name in _headNames) measured.nativeBindingFor(named: name)
    ];
    final targetHandle = _targetHandle;
    if (targetHandle != null) {
      // Страховка от молчаливого фолбэка: если адаптер держит хендлы, он
      // обязан вернуть их для всех измеряемых биндингов. Проверка не
      // резолвит ничего и поэтому выполняется в каждом setup().
      for (var i = 0; i < _headNames.length; i++) {
        if (_headHandles[i] == null) {
          throw StateError('${measured.runtimeType} вернул хендл цели, но не '
              'головы ${_headNames[i]} — молчаливый фолбэк исказил бы замер');
        }
      }
      if (!_validated) {
        _validated = true;
        // Сверка путей резолвит биндинг и наполняет его кеш, поэтому — один
        // раз на прогреве, и по голове, которая не является целью: иначе
        // целевой «первый резолв» каждого сэмпла читал бы кеш, построенный
        // здесь. У register голов нет — пробуется сама цель, прогревочная
        // итерация не измеряется.
        final probeHandle =
            _headHandles.isNotEmpty ? _headHandles[0]! : targetHandle;
        final probeName = _headNames.isNotEmpty ? _headNames[0] : _targetName;
        final viaHandle = measured.resolveNative<UniversalService>(probeHandle,
            named: probeName);
        final viaNamed = measured.resolve<UniversalService>(named: probeName);
        if (!identical(viaHandle, viaNamed) &&
            viaHandle.value != viaNamed.value) {
          throw StateError('${measured.runtimeType}: хендловый путь резолвит '
              'другой биндинг, чем named ("${viaHandle.value}" vs '
              '"${viaNamed.value}")');
        }
      }
    }
  }

  @override
  void teardown() {
    // BenchmarkBase требует синхронную сигнатуру. Раннер её не использует —
    // он вызывает teardownAsync, чтобы дождаться освобождения контейнера.
    // Пустое тело оставлено, чтобы наследуемый measure() из benchmark_harness
    // не падал, если его когда-нибудь вызовут.
  }

  /// Освобождает контейнер и ждёт завершения.
  ///
  /// Без ожидания CherryPick.closeRootScope() не успевает обнулить root scope
  /// до следующего setup(), и модули накапливаются в одном scope.
  Future<void> teardownAsync() async {
    await _childDi?.teardown();
    await _di.teardown();
    // Хендлы ссылаются на биндинги освобождённого контейнера: у yx_scope
    // протухший Dep не бросил бы, а молча вернул старое значение.
    _targetHandle = null;
    _headHandles = const [];
  }

  void prewarm() {
    run();
  }

  /// Резолвит голову [chain]-й цепочки.
  ///
  /// В окне первых резолвов вызывается по одному разу для каждой из
  /// chainCount независимых цепочек: каждая голова резолвится ровно один раз,
  /// поэтому измерение остаётся честным первым резолвом, а шаг таймера
  /// делится на размер окна. Для override голова ищется через границу
  /// дочернего scope к регистрации родителя.
  void runHead(int chain) {
    switch (scenario) {
      case UniversalScenario.chain:
      case UniversalScenario.named:
        _resolveHead(_di, chain);
        break;
      case UniversalScenario.override:
        _resolveHead(_childDi!, chain);
        break;
      default:
        throw UnsupportedError(
            'Окно первых резолвов применимо только к цепочечным и named-сценариям, '
            'получен $scenario');
    }
  }

  void _resolveHead(DIAdapter<TContainer> di, int chain) {
    final handle = _headHandles[chain - 1];
    if (handle != null) {
      di.resolveNative<UniversalService>(handle, named: _headNames[chain - 1]);
    } else {
      di.resolve<UniversalService>(named: _headNames[chain - 1]);
    }
  }

  @override
  void run() {
    switch (scenario) {
      case UniversalScenario.register:
      case UniversalScenario.named:
      case UniversalScenario.chain:
        _resolveTarget(_di);
        break;
      case UniversalScenario.override:
        _resolveTarget(_childDi!);
        break;
      case UniversalScenario.asyncChain:
        throw UnsupportedError(
            'asyncChain supported only in UniversalChainAsyncBenchmark');
    }
  }

  /// Измеряемый резолв цели: по нативному хендлу, если адаптер его выдал
  /// в setup(), иначе по предвычисленному имени — родной путь service
  /// locator'ов. Оба пути — нативный потребительский API своего контейнера.
  void _resolveTarget(DIAdapter<TContainer> di) {
    final handle = _targetHandle;
    if (handle != null) {
      di.resolveNative<UniversalService>(handle, named: _targetName);
    } else {
      di.resolve<UniversalService>(named: _targetName);
    }
  }
}
