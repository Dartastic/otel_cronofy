// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_cronofy/otel_cronofy.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_cronofy-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('availability records sub_count + slots + provider', () async {
    await tracedCronofy<String>(
      operation: 'availability',
      accountId: 'acc-1',
      invoke: () async => const CronofyCallResult(
        value: 'ok',
        result: CronofyResult(
          provider: 'office365',
          subCount: 4,
          slotsReturned: 22,
          queryPeriodsCount: 3,
          statusCode: 200,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('cronofy availability')!);
    expect(a['cronofy.provider'], 'office365');
    expect(a['cronofy.sub_count'], 4);
    expect(a['cronofy.availability.slots'], 22);
    expect(a['cronofy.query_periods_count'], 3);
  });

  test('real_time_scheduling records url.present', () async {
    await tracedCronofy<String>(
      operation: 'real_time_scheduling',
      invoke: () async => const CronofyCallResult(
        value: 'ok',
        result: CronofyResult(
          realTimeSchedulingUrl: 'https://app.cronofy.com/scheduling/...',
          statusCode: 200,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('cronofy real_time_scheduling')!);
    expect(a['cronofy.real_time_scheduling.url.present'], true);
  });

  test('suppression skips spans', () async {
    await runWithoutCronofyInstrumentationAsync(() async {
      await tracedCronofy<String>(
        operation: 'events.list',
        invoke: () async => const CronofyCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('cronofy '), isEmpty);
  });
}
