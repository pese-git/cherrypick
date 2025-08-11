# Change Log

All notable changes to this project will be documented in this file.
See [Conventional Commits](https://conventionalcommits.org) for commit guidelines.

## 2025-08-11

### Changes

---

Packages with breaking changes:

 - [`cherrypick` - `v3.0.0-dev.7`](#cherrypick---v300-dev7)

Packages with other changes:

 - [`cherrypick_annotations` - `v1.1.1`](#cherrypick_annotations---v111)
 - [`cherrypick_flutter` - `v1.1.3-dev.7`](#cherrypick_flutter---v113-dev7)
 - [`cherrypick_generator` - `v1.1.1`](#cherrypick_generator---v111)

---

#### `cherrypick` - `v3.0.0-dev.7`

 - **FIX**(comment): fix warnings.
 - **FIX**(license): correct urls.
 - **FEAT**: add Disposable interface source and usage example.
 - **DOCS**(readme): add comprehensive section on annotations and DI code generation.
 - **DOCS**(readme): add detailed section and examples for automatic Disposable resource cleanup\n\n- Added a dedicated section with English description and code samples on using Disposable for automatic resource management.\n- Updated Features to include automatic resource cleanup for Disposable dependencies.\n\nHelps developers understand and implement robust DI resource management practices.
 - **DOCS**(faq): add best practice FAQ about using await with scope disposal.
 - **DOCS**(faq): add best practice FAQ about using await with scope disposal.
 - **BREAKING** **REFACTOR**(core): make closeRootScope async and await dispose.
 - **BREAKING** **DOCS**(disposable): add detailed English documentation and usage examples for Disposable interface; chore: update binding_resolver and add explanatory comment in scope_test for deprecated usage.\n\n- Expanded Disposable interface docs, added sync & async example classes, and CherryPick integration sample.\n- Clarified how to implement and use Disposable in DI context.\n- Updated binding_resolver for internal improvements.\n- Added ignore for deprecated member use in scope_test for clarity and future upgrades.\n\nBREAKING CHANGE: Documentation style enhancement and clearer API usage for Disposable implementations.

#### `cherrypick_annotations` - `v1.1.1`

 - **FIX**(license): correct urls.

#### `cherrypick_flutter` - `v1.1.3-dev.7`

 - **FIX**(license): correct urls.

#### `cherrypick_generator` - `v1.1.1`

 - **FIX**(license): correct urls.


## 2025-08-08

### Changes

---

Packages with breaking changes:

 - [`cherrypick` - `v3.0.0-dev.6`](#cherrypick---v300-dev6)

Packages with other changes:

 - [`cherrypick_flutter` - `v1.1.3-dev.6`](#cherrypick_flutter---v113-dev6)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `cherrypick_flutter` - `v1.1.3-dev.6`

---

#### `cherrypick` - `v3.0.0-dev.6`

 - **FIX**: improve global cycle detector logic.
 - **DOCS**(readme): add comprehensive DI state and action logging to features.
 - **DOCS**(helper): add complete DartDoc with real usage examples for CherryPick class.
 - **DOCS**(log_format): add detailed English documentation for formatLogMessage function.
 - **BREAKING** **FEAT**(core): refactor root scope API, improve logger injection, helpers, and tests.
 - **BREAKING** **FEAT**(logger): add extensible logging API, usage examples, and bilingual documentation.


## 2025-08-07

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`cherrypick` - `v3.0.0-dev.5`](#cherrypick---v300-dev5)
 - [`cherrypick_flutter` - `v1.1.3-dev.5`](#cherrypick_flutter---v113-dev5)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `cherrypick_flutter` - `v1.1.3-dev.5`

---

#### `cherrypick` - `v3.0.0-dev.5`

 - **REFACTOR**(scope): simplify _findBindingResolver<T> with one-liner and optional chaining.
 - **PERF**(scope): speed up dependency lookup with Map-based binding resolver index.
 - **DOCS**(perf): clarify Map-based resolver optimization applies since v3.0.0 in all docs.
 - **DOCS**: update EN/RU quick start and tutorial with Fast Map-based lookup section; clarify performance benefit in README.


## 2025-08-07

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`cherrypick` - `v3.0.0-dev.4`](#cherrypick---v300-dev4)
 - [`cherrypick_flutter` - `v1.1.3-dev.4`](#cherrypick_flutter---v113-dev4)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `cherrypick_flutter` - `v1.1.3-dev.4`

---

#### `cherrypick` - `v3.0.0-dev.4`

 - **REFACTOR**(scope): simplify _findBindingResolver<T> with one-liner and optional chaining.
 - **PERF**(scope): speed up dependency lookup with Map-based binding resolver index.
 - **DOCS**(perf): clarify Map-based resolver optimization applies since v3.0.0 in all docs.
 - **DOCS**: update EN/RU quick start and tutorial with Fast Map-based lookup section; clarify performance benefit in README.


## 2025-08-07

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`cherrypick` - `v3.0.0-dev.3`](#cherrypick---v300-dev3)
 - [`cherrypick_flutter` - `v1.1.3-dev.3`](#cherrypick_flutter---v113-dev3)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `cherrypick_flutter` - `v1.1.3-dev.3`

---

#### `cherrypick` - `v3.0.0-dev.3`

 - **REFACTOR**(scope): simplify _findBindingResolver<T> with one-liner and optional chaining.
 - **PERF**(scope): speed up dependency lookup with Map-based binding resolver index.
 - **DOCS**(perf): clarify Map-based resolver optimization applies since v3.0.0 in all docs.
 - **DOCS**: update EN/RU quick start and tutorial with Fast Map-based lookup section; clarify performance benefit in README.


## 2025-08-04

### Changes

---

Packages with breaking changes:

 - [`cherrypick` - `v3.0.0-dev.2`](#cherrypick---v300-dev2)

Packages with other changes:

 - [`cherrypick_flutter` - `v1.1.3-dev.2`](#cherrypick_flutter---v113-dev2)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `cherrypick_flutter` - `v1.1.3-dev.2`

---

#### `cherrypick` - `v3.0.0-dev.2`

 - **FEAT**(binding): add deprecated proxy async methods for backward compatibility and highlight transition to modern API.
 - **DOCS**: add quick guide for circular dependency detection to README.
 - **DOCS**: add quick guide for circular dependency detection to README.
 - **BREAKING** **FEAT**: implement comprehensive circular dependency detection system.
 - **BREAKING** **FEAT**: implement comprehensive circular dependency detection system.


## 2025-07-30

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`cherrypick` - `v3.0.0-dev.1`](#cherrypick---v300-dev1)
 - [`cherrypick_flutter` - `v1.1.3-dev.1`](#cherrypick_flutter---v113-dev1)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `cherrypick_flutter` - `v1.1.3-dev.1`

---

#### `cherrypick` - `v3.0.0-dev.1`

 - **DOCS**: add quick guide for circular dependency detection to README.


## 2025-07-30

### Changes

---

Packages with breaking changes:

 - [`cherrypick` - `v3.0.0-dev.0`](#cherrypick---v300-dev0)

Packages with other changes:

 - [`cherrypick_flutter` - `v1.1.3-dev.0`](#cherrypick_flutter---v113-dev0)

---

#### `cherrypick` - `v3.0.0-dev.0`

 - **BREAKING** **FEAT**: implement comprehensive circular dependency detection system.

#### `cherrypick_flutter` - `v1.1.3-dev.0`

 - **FIX**: update deps.


## 2025-07-28

### Changes

---

Packages with breaking changes:

 - [`cherrypick_flutter` - `v1.1.2`](#cherrypick_flutter---v112)

Packages with other changes:

 - [`cherrypick` - `v2.2.0`](#cherrypick---v220)
 - [`cherrypick_annotations` - `v1.1.0`](#cherrypick_annotations---v110)
 - [`cherrypick_generator` - `v1.1.0`](#cherrypick_generator---v110)

Packages graduated to a stable release (see pre-releases prior to the stable version for changelog entries):

 - `cherrypick` - `v2.2.0`
 - `cherrypick_annotations` - `v1.1.0`
 - `cherrypick_flutter` - `v1.1.2`
 - `cherrypick_generator` - `v1.1.0`

---

#### `cherrypick_flutter` - `v1.1.2`

#### `cherrypick` - `v2.2.0`

#### `cherrypick_annotations` - `v1.1.0`

#### `cherrypick_generator` - `v1.1.0`


## 2025-06-04

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`cherrypick_generator` - `v1.1.0-dev.5`](#cherrypick_generator---v110-dev5)

---

#### `cherrypick_generator` - `v1.1.0-dev.5`

 - **FEAT**: implement tryResolve via generate code.


## 2025-05-28

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`cherrypick_generator` - `v1.1.0-dev.4`](#cherrypick_generator---v110-dev4)

---

#### `cherrypick_generator` - `v1.1.0-dev.4`

 - **FIX**: fixed warnings.


## 2025-05-23

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`cherrypick_annotations` - `v1.1.0-dev.1`](#cherrypick_annotations---v110-dev1)
 - [`cherrypick_generator` - `v1.1.0-dev.3`](#cherrypick_generator---v110-dev3)

---

#### `cherrypick_annotations` - `v1.1.0-dev.1`

 - **FEAT**: implement InjectGenerator.

#### `cherrypick_generator` - `v1.1.0-dev.3`

 - **FEAT**: implement InjectGenerator.


## 2025-05-23

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`cherrypick_generator` - `v1.1.0-dev.2`](#cherrypick_generator---v110-dev2)

---

#### `cherrypick_generator` - `v1.1.0-dev.2`

 - **FIX**: update instance generator code.


## 2025-05-22

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`cherrypick` - `v2.2.0-dev.1`](#cherrypick---v220-dev1)
 - [`cherrypick_generator` - `v1.1.0-dev.1`](#cherrypick_generator---v110-dev1)
 - [`cherrypick_flutter` - `v1.1.2-dev.1`](#cherrypick_flutter---v112-dev1)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `cherrypick_flutter` - `v1.1.2-dev.1`

---

#### `cherrypick` - `v2.2.0-dev.1`

 - **FIX**: fix warnings.

#### `cherrypick_generator` - `v1.1.0-dev.1`

 - **FIX**: optimize code.


## 2025-05-22

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`cherrypick` - `v2.2.0-dev.0`](#cherrypick---v220-dev0)
 - [`cherrypick_annotations` - `v1.1.0-dev.0`](#cherrypick_annotations---v110-dev0)
 - [`cherrypick_flutter` - `v1.1.2-dev.0`](#cherrypick_flutter---v112-dev0)
 - [`cherrypick_generator` - `v1.1.0-dev.0`](#cherrypick_generator---v110-dev0)

---

#### `cherrypick` - `v2.2.0-dev.0`

 - **FEAT**: Add async dependency resolution and enhance example.
 - **FEAT**: implement toInstanceAync binding.

#### `cherrypick_annotations` - `v1.1.0-dev.0`

 - **FEAT**: implement generator for dynamic params.
 - **FEAT**: implement instance/provide annotations.
 - **FEAT**: implement generator for named annotation.
 - **FEAT**: implement generator di module.
 - **FEAT**: implement annotations.

#### `cherrypick_flutter` - `v1.1.2-dev.0`

 - **FIX**: fix warning.
 - **FIX**: fix warnings.

#### `cherrypick_generator` - `v1.1.0-dev.0`

 - **FIX**: fix warning conflict with names.
 - **FIX**: fix warnings.
 - **FIX**: fix module generator.
 - **FIX**: fix generator for  singletone annotation.
 - **FEAT**: implement generator for dynamic params.
 - **FEAT**: implement async mode for instance/provide annotations.
 - **FEAT**: generate instance async code.
 - **FEAT**: implement instance/provide annotations.
 - **FEAT**: implement named dependency.
 - **FEAT**: implement generator for named annotation.
 - **FEAT**: implement generator di module.
 - **FEAT**: implement annotations.


## 2025-05-19

### Changes

---

Packages with breaking changes:

 - [`cherrypick_flutter` - `v1.1.1`](#cherrypick_flutter---v111)

Packages with other changes:

 - [`cherrypick` - `v2.1.0`](#cherrypick---v210)

Packages graduated to a stable release (see pre-releases prior to the stable version for changelog entries):

 - `cherrypick` - `v2.1.0`
 - `cherrypick_flutter` - `v1.1.1`

---

#### `cherrypick_flutter` - `v1.1.1`

#### `cherrypick` - `v2.1.0`


## 2025-05-16

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`cherrypick` - `v2.1.0-dev.1`](#cherrypick---v210-dev1)
 - [`cherrypick_flutter` - `v1.1.1-dev.1`](#cherrypick_flutter---v111-dev1)

---

#### `cherrypick` - `v2.1.0-dev.1`

 - **FIX**: fix warnings.
 - **FIX**: fix warnings.
 - **FIX**: support passing params when resolving dependency recursively in parent scope.
 - **FEAT**: Add async dependency resolution and enhance example.
 - **FEAT**: Add async dependency resolution and enhance example.

#### `cherrypick_flutter` - `v1.1.1-dev.1`

 - **FIX**: fix warnings.


## 2025-05-16

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`cherrypick` - `v2.0.2`](#cherrypick---v202)
 - [`cherrypick_flutter` - `v1.1.1`](#cherrypick_flutter---v111)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `cherrypick_flutter` - `v1.1.1`

---

#### `cherrypick` - `v2.0.2`

 - **FIX**: support passing params when resolving dependency recursively in parent scope.


## 2025-05-03

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`cherrypick_flutter` - `v1.1.0`](#cherrypick_flutter---v110)

---

#### `cherrypick_flutter` - `v1.1.0`

 - **FIX**: update description.
 - **FIX**: update gitignore.
 - **FEAT**: modify api in CherryPickProvider.


## 2025-05-02

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`cherrypick` - `v2.0.1`](#cherrypick---v201)
 - [`cherrypick_flutter` - `v1.0.1`](#cherrypick_flutter---v101)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `cherrypick_flutter` - `v1.0.1`

---

#### `cherrypick` - `v2.0.1`

 - **FIX**: fix warning.

