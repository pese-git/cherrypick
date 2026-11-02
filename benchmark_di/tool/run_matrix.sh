#!/usr/bin/env bash
# Полный прогон матрицы в обоих режимах компиляции.
#
# JIT и AOT дают разные числа, а целевой рантайм Flutter-приложений — AOT.
# Публиковать результаты одного режима без указания, какой это режим, нельзя.
set -euo pipefail
cd "$(dirname "$0")/.."

ARGS="--chainCount=100 --nestingDepth=100 --repeat=31 --warmup=5"

echo "## JIT"
echo
dart run bin/matrix.dart $ARGS --resolvePhase=first --metric=median_ns

echo
echo "## AOT"
echo
mkdir -p build
dart compile exe bin/main.dart -o build/benchmark_di_aot >/dev/null
dart run bin/matrix.dart $ARGS --resolvePhase=first --metric=median_ns \
  --exe=build/benchmark_di_aot
