
abstract class UniversalService {
  final String value;
  final UniversalService? dependency;
  UniversalService({required this.value, this.dependency});
}

class UniversalServiceImpl extends UniversalService {
  UniversalServiceImpl({required super.value, super.dependency});
}