//
// Copyright 2021 Sergey Penkovsky (sergey.penkovsky@gmail.com)
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//      https://www.apache.org/licenses/LICENSE-2.0
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import 'package:meta/meta.dart';

/// One link of a dependency resolution chain: a key, and the chain it extends.
///
/// Chains are immutable and shared. Extending one allocates a single link that
/// points at the existing chain instead of copying it, so entering a nested
/// resolve costs the same whatever the depth — which matters because both cycle
/// detectors extend a chain once per guarded resolve. Links are materialised
/// into a [List] only for diagnostics and for the exception message.
///
/// This type is shared by the per-scope and the cross-scope detector; it is
/// internal to the package and not part of the public API.
@internal
class ResolutionChain {
  /// Key of the dependency this link stands for.
  final String key;

  /// The chain this link extends, or null if it is the outermost link.
  final ResolutionChain? parent;

  const ResolutionChain(this.key, this.parent);

  /// Whether [candidate] appears anywhere in this chain.
  bool contains(String candidate) {
    for (ResolutionChain? link = this; link != null; link = link.parent) {
      if (link.key == candidate) return true;
    }
    return false;
  }

  /// The chain as a list, outermost key first.
  List<String> toList() {
    final keys = <String>[];
    for (ResolutionChain? link = this; link != null; link = link.parent) {
      keys.add(link.key);
    }
    return keys.reversed.toList();
  }
}
