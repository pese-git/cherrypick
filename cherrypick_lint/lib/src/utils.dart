import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

/// The display names of every annotation type attached to [element].
List<String> annotationNames(Element element) {
  return element.metadata.annotations
      .map(
        (annotation) =>
            annotation.computeConstantValue()?.type?.getDisplayString(),
      )
      .whereType<String>()
      .toList();
}

/// Whether [element] carries an annotation whose type is named [name].
bool hasAnnotation(Element element, String name) {
  return annotationNames(element).contains(name);
}

/// Whether [node]'s `Future` is handled rather than silently dropped:
/// - it's the direct operand of an `await` expression (`await foo()`);
/// - it's returned to the caller (`return foo();` or `=> foo();`), whose
///   responsibility it then becomes;
/// - it's stored in a variable that is itself awaited later in the same
///   block (`final job = foo(); ... await job;`).
bool isFutureHandled(Expression node) {
  final parent = node.parent;

  if (parent is AwaitExpression && parent.expression == node) return true;

  if (parent is ReturnStatement && parent.expression == node) return true;
  if (parent is ExpressionFunctionBody && parent.expression == node) {
    return true;
  }

  if (parent is VariableDeclaration) {
    final element = parent.declaredFragment?.element;
    final block = parent.thisOrAncestorOfType<Block>();
    if (element != null &&
        block != null &&
        _isElementAwaitedIn(block, element)) {
      return true;
    }
  }

  return false;
}

bool _isElementAwaitedIn(Block block, Element target) {
  final visitor = _AwaitedElementVisitor(target);
  block.accept(visitor);
  return visitor.found;
}

class _AwaitedElementVisitor extends RecursiveAstVisitor<void> {
  _AwaitedElementVisitor(this.target);

  final Element target;
  bool found = false;

  @override
  void visitAwaitExpression(AwaitExpression node) {
    final expression = node.expression;
    if (expression is SimpleIdentifier && expression.element == target) {
      found = true;
      return;
    }
    super.visitAwaitExpression(node);
  }
}

/// Whether [node] is passed as the argument of a call to `unawaited(...)`,
/// which marks a fire-and-forget call as intentional.
bool isWrappedInUnawaited(Expression node) {
  final argumentList = node.parent;
  if (argumentList is! ArgumentList) return false;
  final call = argumentList.parent;
  return call is MethodInvocation && call.methodName.name == 'unawaited';
}

/// The [Element] enclosing [element] (e.g. the class declaring a static
/// method), or `null` if [element] has no enclosing element.
Element? enclosingElementOf(Element? element) => element?.enclosingElement;

/// Whether [element] is declared in the library at package URI [packageUri]
/// (e.g. `package:cherrypick/cherrypick.dart`).
bool isDeclaredInPackage(Element? element, String packageName) {
  final uri = element?.library?.uri;
  return uri != null && uri.toString().startsWith('package:$packageName/');
}

/// Whether [node] statically resolves to a call on the class [className]
/// declared in package [packageName], e.g. `CherryPick.closeScope(...)`.
bool isStaticCallOn(
  MethodInvocation node,
  String className,
  String packageName,
) {
  final owner = enclosingElementOf(node.methodName.element);
  return owner?.name == className && isDeclaredInPackage(owner, packageName);
}
