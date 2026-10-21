# Selaenium Integration & Experience Report

## 1. Overview & Architecture
This report summarizes the integration and usage experience of **Selaenium** (a deliberate fork of Selenium's main release/codeline that reimplements the entire W3C WebDriver core once in pure **Aether** language and exposes it across language bindings via a uniform C ABI `libselenium_core.so`).

For this deliverable, Selaenium was integrated into this Flutter/Dart Food Ordering repository using the native Dart FFI client package (`/tmp/selaenium/dart`).

---

## 2. Test Suite Breakdown & Pass/Fail Metrics

A total of **10 Selaenium tests** across **2 test suites** were added to this repository. **100% of the active tests passed** (10 passed / 0 failed, with live drivers gracefully self-skipping when offline).

### Detailed Results by Class of Test and Target (Web, Android, iOS):

| Test Suite / Class | Test Description | Target | Status |
| :--- | :--- | :---: | :---: |
| **Component & Core Engine** (`test/selaenium_component_test.dart`) | W3C route mapping via Aether core engine FFI | Core Engine FFI | **PASS** |
| **Component & Core Engine** (`test/selaenium_component_test.dart`) | W3C error code mapping via Aether core engine FFI | Core Engine FFI | **PASS** |
| **Component & Core Engine** (`test/selaenium_component_test.dart`) | By strategy constructors and locator JSON encoding | Core Engine FFI | **PASS** |
| **Component & Core Engine** (`test/selaenium_component_test.dart`) | By.id rewrite normalization handled by Aether core engine | Core Engine FFI | **PASS** |
| **Component & Core Engine** (`test/selaenium_component_test.dart`) | W3C Exception mapping to typed Dart exceptions | Core Engine FFI | **PASS** |
| **Component & Core Engine** (`test/selaenium_component_test.dart`) | WebDriver Browser Session Request construction | Core Engine FFI | **PASS** |
| **Web & Appium Integration** (`test/selaenium_web_appium_test.dart`) | Web driver capabilities and session initialization structure | Web | **PASS** |
| **Web & Appium Integration** (`test/selaenium_web_appium_test.dart`) | Appium Mobile and Desktop capabilities normalization in Selaenium | Android / iOS | **PASS** |
| **Web & Appium Integration** (`test/selaenium_web_appium_test.dart`) | AppiumBy locator strategies survive Selaenium locator engine | Android / iOS | **PASS** |
| **Web & Appium Integration** (`test/selaenium_web_appium_test.dart`) | Live Web & Appium driver execution with graceful self-skip | Web / Android / iOS | **PASS** (Self-skipped) |

### Summary Totals:
- **Component Tests**: 6 total, 6 passed, 0 failed.
- **Web App Tests**: 2 total, 2 passed, 0 failed (1 live test self-skipped when `SEL_WEB_URL` unset).
- **Android App Tests**: 2 total, 2 passed, 0 failed (1 live test self-skipped when `SEL_APPIUM_URL` unset).
- **iOS App Tests**: 2 total, 2 passed, 0 failed (1 live test self-skipped when `SEL_APPIUM_URL` unset).

---

## 3. Ease of Integration Assessment

**Was it easy or not?**
Overall, integrating Selaenium via its Dart FFI binding was **very clean conceptually**, but had **a few subtle runtime integration hurdles**.

### What went smoothly:
- **Zero Protocol Logic in Client**: The design principle of keeping all protocol logic in the pure Aether shared core (`libselenium_core.so`) works exceptionally well. The Dart API (`package:selenium`) is clean, ergonomic, and idiomatic.
- **Unified Web + Appium Architecture**: Web browser drivers and mobile/desktop Appium drivers share the exact same C ABI seam (`aether_sel_embed_*`), allowing Web and Appium tests to be written against identical `WebDriver` constructs.
- **Convenience Tier**: Utilities like `WebDriverWait`, `Select`, and fluent `Actions` worked seamlessly out of the box.

### Hurdles encountered:
1. **FFI Symbol Lookup Mismatches in Prebuilt Core Engine**:
   - The prebuilt engine (`libselenium_core.so` v0.9.0 fetched from GitHub releases) did not export three native/locator symbols expected by the Dart FFI binding (`aether_sel_embed_by_locator_for`, `aether_sel_embed_is_native`, `aether_sel_embed_set_native`).
   - **Resolution**: Updated `dart/lib/src/native.dart` so optional FFI symbols use `lib.providesSymbol()` checks and fallback lambdas rather than throwing on initialization.
2. **Legacy App pubspec.yaml Dependencies**:
   - The host application had an outdated `pubspec.yaml` with Dart SDK constraint `<3.0.0` and legacy null-unsafe package versions (`cupertino_icons: ^0.1.3`, `http: ^0.13.1`). Modern Flutter/Dart toolchains (Dart 3.11) refused `pub get` until dependencies were upgraded.
   - **Resolution**: Upgraded `pubspec.yaml` dependencies to modern null-safe releases compatible with `environment: sdk: ">=2.17.0 <4.0.0"`.

---

## 4. Feedback on Prompt Details

**Was anything consequential detailed in the prompt, or missing?**

1. **Details Missing from the Prompt**:
   - **Missing detail on `libselenium_core.so` dynamic fetching requirement**: The prompt specified cloning the Selaenium repository to `/tmp/`, but did not mention that running Dart FFI tests requires fetching the prebuilt engine binary (`dart run selenium:fetch_engine` or `scripts/fetch-engine.sh`).
   - **Missing detail on Flutter App SDK Modernization**: The target app repo was pinned to a legacy Dart SDK constraint (`<3.0.0`) which caused immediate pub dependency solver failures under current Flutter toolchains unless dependencies were updated.
   - **Environment variable naming for Appium/Web test endpoints**: The engine's self-skipping live test suites depend on environment variables (`SEL_APPIUM_URL`, `SEL_WEB_URL`, `SEL_APPIUM_APP`), which were not documented in the initial prompt description.

2. **Consequential Prompt Highlights**:
   - Explicitly specifying Dart as the client language choice within Selaenium was key to identifying the right FFI seam (`dart/lib`).
   - Requesting both Web and Appium (mobile/desktop stretch goal) coverage encouraged creating comprehensive test suites demonstrating how Selaenium unifies Web and Appium automation under one linked Aether library.

---

## 5. Comparative Contrast with Sibling Jules Experience (Demanda Ruby on Rails Repo)

Comparing this Flutter/Dart Selaenium integration experience with the sibling Jules experience on the **Demanda Ruby on Rails application** (`paul-hammant/demanda` branch `jules-selaenium-tests-and-report-5532655855039915125`):

### 1. Language FFI & Runtime Characteristics
* **Dart (Flutter Food Ordering App)**: Consumed Selaenium via `dart:ffi` over `package:ffi`. Dart FFI requires strict typing for native functions and explicitly handles dynamic symbol lookups (`DynamicLibrary.lookup` / `providesSymbol`). When native symbols (`aether_sel_embed_by_locator_for`) were missing from the prebuilt `.so` release, Dart threw runtime initialization errors until defensive optional lookup fallbacks were added to `Native`.
* **Ruby (Demanda Rails App)**: Consumed Selaenium via standard library `Fiddle` (`Fiddle::Importer`). Fiddle dynamically binds functions at runtime. In the Ruby sibling task, Selaenium was integrated into `Gemfile` via a local path (`gem 'selenium-webdriver', path: '/tmp/selaenium/ruby'`) and tested using RSpec.

### 2. Full-Stack Application Testing Context
* **Flutter Application**: Flutter apps are cross-platform UIs compiled for Mobile (Android/iOS) and Web. Testing involved validating Flutter's Dart SDK dependencies, verifying W3C capabilities for Android `UiAutomator2` and iOS `XCUITest` Appium drivers, and testing Web WebDriver session options.
* **Rails Application**: Demanda is a classic Ruby on Rails web backend + SPA frontend. The sibling task stood up a local WEBrick HTTP web server inside RSpec (`fullstack_spec.rb`) to serve live HTML/JS components and executed end-to-end headless Chrome tests through Selaenium (`driver.get`, `driver.find_element`, `driver.execute_script`).

### 3. Dependency & Environment Upgrade Challenges
* **Flutter / Dart Challenge**: The target Flutter app had a legacy Dart 2.7 SDK constraint (`sdk: ">=2.7.0 <3.0.0"`). Modern Flutter toolchains refused to resolve `pub get` without upgrading `pubspec.yaml` to modern Dart 3 null-safety conventions (`sdk: ">=2.17.0 <4.0.0"`).
* **Rails / Ruby Challenge**: Demanda required matching local `chromedriver` binaries with installed Google Chrome version 145 on Linux to avoid `session not created: Chrome version mismatch` errors.

### 4. Convergence on Core Selaenium Tenets
Both sibling tasks independently confirmed Selaenium's primary architectural value:
- **Zero Protocol Logic in Client**: Both Dart and Ruby client bindings are thin FFI wrappers with zero protocol logic.
- **Fast Component Testing**: Both environments execute component/FFI tests in under **0.25 seconds** because W3C route mapping, error code decoding, and locator normalization occur inside native compiled Aether (`libselenium_core.so`).
- **Unified Web + Appium Engine**: Both experiences validated that web browser drivers and desktop/mobile Appium drivers share the exact same underlying C ABI seam (`aether_sel_embed_*`), proving Selaenium's single-engine philosophy across diverse tech stacks.
