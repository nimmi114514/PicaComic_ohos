import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pica_comic/foundation/sqlite_connection.dart';

void main() {
  test('exclusive database work waits for outstanding reads', () async {
    final gateway = DatabaseGateway.instance;
    final release = Completer<void>();
    final events = <String>[];
    final read = gateway.guardedRead(() async {
      events.add('read');
      await release.future;
      events.add('read complete');
    });
    final write = gateway.runExclusive(() async => events.add('write'));
    await Future<void>.delayed(Duration.zero);
    expect(events, ['read']);
    release.complete();
    await Future.wait([read, write]);
    expect(events, ['read', 'read complete', 'write']);
  });

  test('failed database work does not block subsequent operations', () async {
    final gateway = DatabaseGateway.instance;
    await expectLater(
      gateway.guardedRead<void>(() async => throw StateError('test failure')),
      throwsStateError,
    );
    expect(await gateway.guardedRead(() async => 42), 42);
    await expectLater(
      gateway.runExclusive<void>(() async => throw StateError('test failure')),
      throwsStateError,
    );
    expect(await gateway.runExclusive(() async => 43), 43);
  });
}
