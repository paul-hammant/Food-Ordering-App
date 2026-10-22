import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:selenium/selenium.dart';

void main() {
  group('Selaenium Component & Core Engine Tests', () {
    test('W3C route mapping via Aether core engine FFI', () {
      expect(route('get'), equals('POST /session/:sessionId/url'));
      expect(route('findElement'), equals('POST /session/:sessionId/element'));
      expect(route('nonExistentCommand'), isEmpty);
    });

    test('W3C error code mapping via Aether core engine FFI', () {
      expect(errorCode('no such element'), equals(17));
      expect(errorCode('stale element reference'), equals(23));
      expect(errorCode('invalid argument'), equals(7));
      expect(errorCode('no such shadow root'), equals(19));
      expect(errorCode('unknown error'), equals(1));
    });

    test('By strategy constructors and locator JSON encoding', () {
      final byCss = By.cssSelector('.food-card');
      expect(byCss.strategy, equals('css selector'));
      expect(byCss.value, equals('.food-card'));

      final jsonCss = jsonDecode(locator(byCss.strategy, byCss.value));
      expect(jsonCss, equals({'using': 'css selector', 'value': '.food-card'}));

      final byXpath = By.xpath('//button[@id="checkout"]');
      expect(byXpath.strategy, equals('xpath'));
      expect(byXpath.value, equals('//button[@id="checkout"]'));

      final jsonXpath = jsonDecode(locator(byXpath.strategy, byXpath.value));
      expect(jsonXpath, equals({'using': 'xpath', 'value': '//button[@id="checkout"]'}));
    });

    test('By.id rewrite normalization handled by Aether core engine', () {
      final byId = By.id('login-btn');
      expect(byId.strategy, equals('id'));
      expect(byId.value, equals('login-btn'));

      // Selaenium engine normalizes id strategy into standard W3C CSS selector
      final jsonId = jsonDecode(locator(byId.strategy, byId.value));
      expect(jsonId, equals({'using': 'css selector', 'value': '*[id="login-btn"]'}));
    });

    test('W3C Exception mapping to typed Dart exceptions', () {
      expect(errorCode('no such element'), equals(17));
      expect(errorCode('detached shadow root'), equals(2));

      // Unreachable endpoint correctly raises WebDriverException with code -1
      expect(
        () => WebDriver.chrome('http://127.0.0.1:1'),
        throwsA(isA<WebDriverException>().having((e) => e.code, 'code', equals(-1))),
      );
    });

    test('WebDriver Browser Session Request construction', () {
      expect(
        () => WebDriver.firefox('http://127.0.0.1:1'),
        throwsA(isA<WebDriverException>().having((e) => e.code, 'code', equals(-1))),
      );

      expect(
        () => WebDriver.edge('http://127.0.0.1:1'),
        throwsA(isA<WebDriverException>().having((e) => e.code, 'code', equals(-1))),
      );
    });
  });
}
