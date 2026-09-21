// PATCH(vidra): pins the assumption Player.dispose() now rests on -- that a
// blocking mdk call handed to Isolate.run() can be abandoned on a deadline
// while the caller (the Dart UI thread) carries on. If this ever stops holding,
// dispose() is back to freezing the whole app on a stuck teardown.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fvp/src/player.dart';

void main() {
  test('awaitMdk returns true when the call finishes', () async {
    expect(await Player.awaitMdk(() {}), isTrue);
  });

  test('awaitMdk gives up on a call that never returns', () async {
    final clock = Stopwatch()..start();
    // sleep() blocks the isolate's thread the same way a stuck native call
    // does. The isolate stays parked after we give up -- that leak is the
    // deliberate trade, and it dies with the test process.
    final ok = await Player.awaitMdk(
      () => sleep(const Duration(seconds: 30)),
      deadline: const Duration(milliseconds: 300),
    );
    clock.stop();
    expect(ok, isFalse, reason: 'must report the miss so _pp is not freed');
    expect(clock.elapsed, lessThan(const Duration(seconds: 5)),
        reason: 'caller must not be dragged down with the blocked isolate');
  });
}
