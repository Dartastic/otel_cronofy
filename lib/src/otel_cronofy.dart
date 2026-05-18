// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_cronofy_suppression.dart';

const _tracerName = 'dartastic_otel_libs_cronofy';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

class CronofyResult {
  const CronofyResult({
    this.itemCount,
    this.provider,
    this.subCount,
    this.slotsReturned,
    this.queryPeriodsCount,
    this.smartInviteId,
    this.realTimeSchedulingUrl,
    this.usedPageToken,
    this.requestId,
    this.statusCode,
  });

  /// Items returned for list endpoints.
  final int? itemCount;

  /// `account.providerName` — `google` / `office365` / `outlook` /
  /// `exchange` / `apple`. Slice availability latency by provider.
  final String? provider;

  /// Number of `sub`s (calendar identifiers) in an availability or
  /// freebusy call — Cronofy's per-call cost dim.
  final int? subCount;

  /// Available slots returned by an availability query.
  final int? slotsReturned;

  /// `query_periods.length` — span of time covered by the query.
  final int? queryPeriodsCount;

  /// `smart_invite_id` for the Smart Invite product.
  final String? smartInviteId;

  /// Whether a Real-Time Scheduling URL was returned.
  final String? realTimeSchedulingUrl;

  /// Whether `next_page` was used.
  final bool? usedPageToken;

  /// `Cronofy-Request-ID`.
  final String? requestId;

  final int? statusCode;
}

class CronofyCallResult<T> {
  const CronofyCallResult({required this.value, this.result});
  final T value;
  final CronofyResult? result;
}

/// Wraps a Cronofy API call in a CLIENT span. [operation] is one of
/// `events.list`, `events.create`, `events.delete`, `events.batch`,
/// `availability`, `availability.subsequent`, `free_busy`,
/// `real_time_scheduling`, `real_time_sequencing`, `smart_invites`,
/// `userinfo`, `profiles`, `channels.create`, `bookings.list`,
/// `conferencing_service_authorizations`.
Future<T> tracedCronofy<T>({
  required String operation,
  required Future<CronofyCallResult<T>> Function() invoke,
  String? accountId,
}) async {
  if (cronofyInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'cronofy',
    'rpc.method': operation,
    'cronofy.operation': operation,
  };
  if (accountId != null) m['cronofy.account.id'] = accountId;

  final span = _tracer().startSpan(
    'cronofy $operation',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final extras = <Attribute<Object>>[];
      if (r.result!.itemCount != null) {
        extras.add(OTel.attributeInt(
          'cronofy.item_count',
          r.result!.itemCount!,
        ));
      }
      if (r.result!.provider != null) {
        extras.add(OTel.attributeString(
          'cronofy.provider',
          r.result!.provider!,
        ));
      }
      if (r.result!.subCount != null) {
        extras.add(OTel.attributeInt(
          'cronofy.sub_count',
          r.result!.subCount!,
        ));
      }
      if (r.result!.slotsReturned != null) {
        extras.add(OTel.attributeInt(
          'cronofy.availability.slots',
          r.result!.slotsReturned!,
        ));
      }
      if (r.result!.queryPeriodsCount != null) {
        extras.add(OTel.attributeInt(
          'cronofy.query_periods_count',
          r.result!.queryPeriodsCount!,
        ));
      }
      if (r.result!.smartInviteId != null) {
        extras.add(OTel.attributeString(
          'cronofy.smart_invite.id',
          r.result!.smartInviteId!,
        ));
      }
      if (r.result!.realTimeSchedulingUrl != null) {
        extras.add(OTel.attributeBool(
          'cronofy.real_time_scheduling.url.present',
          true,
        ));
      }
      if (r.result!.usedPageToken != null) {
        extras.add(OTel.attributeBool(
          'cronofy.page_token.used',
          r.result!.usedPageToken!,
        ));
      }
      if (r.result!.requestId != null) {
        extras.add(OTel.attributeString(
          'cronofy.request.id',
          r.result!.requestId!,
        ));
      }
      if (r.result!.statusCode != null) {
        extras.add(OTel.attributeInt(
          'http.response.status_code',
          r.result!.statusCode!,
        ));
        if (r.result!.statusCode! >= 400) {
          span.setStatus(
            SpanStatusCode.Error,
            'Cronofy HTTP ${r.result!.statusCode}',
          );
        }
      }
      if (extras.isNotEmpty) span.addAttributes(OTel.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
