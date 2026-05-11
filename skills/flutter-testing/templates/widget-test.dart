// Widget test template — WidgetTester, ProviderScope overrides, semantics
// Replace [FeatureName] with actual feature name

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ===========================================================================
// TEST APP WRAPPER
// ===========================================================================

Widget buildTestApp({
  required Widget child,
  List<Override> overrides = const [],
  Locale locale = const Locale('en'),
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

// ===========================================================================
// WIDGET TESTS
// ===========================================================================

void main() {
  group('FeatureNameScreen', () {
    late FakeFeatureNameRepository fakeRepo;

    setUp(() {
      fakeRepo = FakeFeatureNameRepository()
        ..items = [
          const FeatureNameModel(id: '1', title: 'First item'),
          const FeatureNameModel(id: '2', title: 'Second item'),
        ];
    });

    // ---------------------------------------------------------------------------
    testWidgets('shows loading indicator while data loads', (tester) async {
      // Arrange: repository that never completes
      final hangingRepo = FakeFeatureNameRepository()..shouldHang = true;

      await tester.pumpWidget(buildTestApp(
        overrides: [
          featureNameRepositoryProvider.overrideWithValue(hangingRepo),
        ],
        child: const FeatureNameScreen(),
      ));

      // Only pump once — don't settle (data still loading)
      await tester.pump();

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byKey(const ValueKey('feature_name_list')), findsNothing);
    });

    // ---------------------------------------------------------------------------
    testWidgets('displays items when loaded successfully', (tester) async {
      await tester.pumpWidget(buildTestApp(
        overrides: [
          featureNameRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: const FeatureNameScreen(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('First item'), findsOneWidget);
      expect(find.text('Second item'), findsOneWidget);
    });

    // ---------------------------------------------------------------------------
    testWidgets('shows empty state when list is empty', (tester) async {
      fakeRepo.items = [];

      await tester.pumpWidget(buildTestApp(
        overrides: [
          featureNameRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: const FeatureNameScreen(),
      ));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('feature_name_empty')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('feature_name_list')), findsNothing);
    });

    // ---------------------------------------------------------------------------
    testWidgets('shows error state when repository throws', (tester) async {
      fakeRepo.shouldThrow = true;

      await tester.pumpWidget(buildTestApp(
        overrides: [
          featureNameRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: const FeatureNameScreen(),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('feature_name_error')), findsOneWidget);
    });

    // ---------------------------------------------------------------------------
    testWidgets('retry button reloads items on error', (tester) async {
      fakeRepo.shouldThrow = true;

      await tester.pumpWidget(buildTestApp(
        overrides: [
          featureNameRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: const FeatureNameScreen(),
      ));
      await tester.pumpAndSettle();

      // Fix the repo before tapping retry
      fakeRepo.shouldThrow = false;
      await tester.tap(find.byKey(const ValueKey('retry_button')));
      await tester.pumpAndSettle();

      expect(find.text('First item'), findsOneWidget);
    });

    // ---------------------------------------------------------------------------
    testWidgets('screen has correct semantics', (tester) async {
      await tester.pumpWidget(buildTestApp(
        overrides: [
          featureNameRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: const FeatureNameScreen(),
      ));
      await tester.pumpAndSettle();

      // Verify screen reader can find all interactive elements
      expect(
        tester.getSemantics(find.byKey(const ValueKey('feature_name_list'))),
        isNotNull,
      );
    });

    // ---------------------------------------------------------------------------
    testWidgets('layout handles large text scale without overflow', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaleFactor: 2.0),
          child: buildTestApp(
            overrides: [
              featureNameRepositoryProvider.overrideWithValue(fakeRepo),
            ],
            child: const FeatureNameScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // No RenderFlex overflow exceptions
      expect(tester.takeException(), isNull);
    });
  });
}
