import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindurun/app/bootstrap/providers.dart';
import 'package:mindurun/core/models/models.dart';
import 'package:mindurun/core/services/demo_seed_service.dart';
import 'package:mindurun/features/session/session_providers.dart';

void main() {
  late ProviderContainer container;
  late SessionController controller;
  late User almir;
  late User ana;
  setUp(() {
    container = ProviderContainer();
    container.read(demoSeedServiceProvider).reset(DateTime(2026, 10, 22));
    controller = container.read(sessionControllerProvider.notifier);
    final users = container.read(userRepositoryProvider);
    almir = users.getUser(DemoIds.almir)!;
    ana = users.getUser(DemoIds.ana)!;
  });
  tearDown(() => container.dispose());
  test('starts without a selected user', () {
    expect(container.read(sessionControllerProvider).currentUser, isNull);
    expect(container.read(sessionControllerProvider).isAuthenticated, isFalse);
  });
  test('selects Almir', () {
    controller.selectUser(almir);
    expect(container.read(sessionControllerProvider).currentUser, same(almir));
    expect(container.read(sessionControllerProvider).isAuthenticated, isTrue);
    expect(container.read(currentUserProvider), same(almir));
  });
  test('replaces Almir with Ana and notifies dependents', () {
    controller.selectUser(almir);

    final changes = <User?>[];

    final subscription = container.listen<User?>(
      currentUserProvider,
      (_, next) => changes.add(next),
    );

    controller.selectUser(ana);

    expect(container.read(sessionControllerProvider).currentUser, same(ana));

    expect(container.read(currentUserProvider), same(ana));

    expect(changes, [ana]);

    subscription.close();
  });
  test('logout clears the session', () {
    controller.selectUser(almir);
    controller.logout();
    expect(container.read(sessionControllerProvider).currentUser, isNull);
    expect(container.read(sessionControllerProvider).isAuthenticated, isFalse);
    expect(container.read(currentUserProvider), isNull);
  });
  test('new containers do not retain a previous session', () {
    controller.selectUser(ana);
    final fresh = ProviderContainer();
    addTearDown(fresh.dispose);
    expect(fresh.read(currentUserProvider), isNull);
  });
}
