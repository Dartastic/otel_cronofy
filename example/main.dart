// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_cronofy/otel_cronofy.dart';

/// Traces Cronofy calls with OpenTelemetry.
///
/// `otel_cronofy` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Cronofy call in
/// [tracedCronofy]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'cronofy-example');

  // Wraps a Cronofy API call in a CLIENT span.
  final cronofyId = await tracedCronofy<String>(
    operation: 'events.create',
    accountId: 'account_8f3a2c',
    invoke: () async {
      // Make the Cronofy call here, then report what it returned.
      const id = 'cronofy_8f3a2c';
      return const CronofyCallResult(
          value: id,
          result: CronofyResult(
              itemCount: 3,
              provider: 'account.providerName',
              subCount: 3,
              slotsReturned: 1,
              queryPeriodsCount: 3,
              smartInviteId: 'smart_invite_id',
              realTimeSchedulingUrl: 'https://api.example.com/v1/resource',
              usedPageToken: true,
              requestId: 'Cronofy-Request-ID',
              statusCode: 201));
    },
  );
  OTelLog.info('tracedCronofy events.create returned $cronofyId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutCronofyInstrumentationAsync.
  await runWithoutCronofyInstrumentationAsync(
    () => tracedCronofy<String>(
      operation: 'events.create',
      accountId: 'account_8f3a2c',
      invoke: () async {
        const id = 'cronofy_8f3a2c';
        return const CronofyCallResult(
            value: id,
            result: CronofyResult(
                itemCount: 3,
                provider: 'account.providerName',
                subCount: 3,
                slotsReturned: 1,
                queryPeriodsCount: 3,
                smartInviteId: 'smart_invite_id',
                realTimeSchedulingUrl: 'https://api.example.com/v1/resource',
                usedPageToken: true,
                requestId: 'Cronofy-Request-ID',
                statusCode: 201));
      },
    ),
  );

  await OTel.shutdown();
}
