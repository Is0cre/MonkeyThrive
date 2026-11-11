import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:monkeythrive/core/theme/app_appearance.dart';

void main() {
  test('appearance settings persist accent and contrast', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = AppAppearanceController.instance;

    await controller.load();
    await controller.setAccent(AppAccent.blue);
    await controller.setContrast(AppContrast.high);
    await controller.load();

    expect(controller.notifier.value.accent, AppAccent.blue);
    expect(controller.notifier.value.contrast, AppContrast.high);
  });
}
