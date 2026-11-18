import 'package:flutter_test/flutter_test.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/foundation/image_translation/ordered_group_committer.dart';
import 'package:pica_comic/foundation/image_translation/translation_performance_config.dart';
import 'package:pica_comic/foundation/image_translation/worker_pool_selection.dart';

class _MemoryAppdata extends Appdata {
  @override
  Future<void> saveData([bool syncData = true]) async {}
}

void main() {
  test('translation settings fall back without leaking between comics', () {
    final data = _MemoryAppdata();
    data.setTranslationReaderSetting(
        null, null, 'imageTranslationEnabled', false);
    data.setTranslationReaderSetting(
        'a', 'source', 'imageTranslationEnabled', true);
    expect(
        data.getTranslationReaderSetting(
            'a', 'source', 'imageTranslationEnabled'),
        isTrue);
    expect(
        data.getTranslationReaderSetting(
            'b', 'source', 'imageTranslationEnabled'),
        isFalse);
    expect(
        data.getTranslationReaderSetting(
            'a', 'other', 'imageTranslationEnabled'),
        isFalse);
    expect(data.getDeviceTranslationReaderSetting('imageTranslationEnabled'),
        isFalse);
  });

  test('removing a comic translation override restores the global value', () {
    final data = _MemoryAppdata();
    data.setTranslationReaderSetting(null, null, 'target', 'zh-CN');
    data.setTranslationReaderSetting('a', 'source', 'target', 'en');
    data.setTranslationReaderSetting('a', 'source', 'target', null);
    expect(data.getTranslationReaderSetting('a', 'source', 'target'), 'zh-CN');
    expect(data.translationSettings['readerSettings'], isEmpty);
  });

  test('pretranslation commits only a contiguous completed prefix', () {
    final committer = OrderedGroupCommitter(0);
    final first = GroupResult(2, 0, {});
    final second = GroupResult(1, 1, {3});
    expect(committer.record(1, second), isEmpty);
    expect(committer.nextCommitIndex, 0);
    expect(committer.hasPending, isTrue);
    expect(committer.record(0, first), [first, second]);
    expect(committer.nextCommitIndex, 2);
    expect(committer.hasPending, isFalse);
  });

  test('pretranslation resumes at its saved group index', () {
    final committer = OrderedGroupCommitter(4);
    final fifth = GroupResult(1, 0, {});
    final sixth = GroupResult(0, 1, {11});
    expect(committer.record(5, sixth), isEmpty);
    expect(committer.record(4, fifth), [fifth, sixth]);
    expect(committer.nextCommitIndex, 6);
  });

  test('OCR dispatch uses the least-busy worker with stable ties', () {
    expect(pickLeastBusyIndex([3, 1, 2]), 1);
    expect(pickLeastBusyIndex([0, 0, 1]), 0);
    expect(pickLeastBusyIndex([5]), 0);
  });

  test('mobile translation presets limit concurrency', () {
    final saver = TranslationPerformanceConfig.valuesFor(
      TranslationPerformancePreset.saver,
      isDesktop: false,
    );
    expect(saver.ocrWorkers, 1);
    expect(saver.batchPages, 1);
    final balanced = TranslationPerformanceConfig.valuesFor(
      TranslationPerformancePreset.balanced,
      isDesktop: false,
    );
    expect(balanced.batchPages, 2);
    expect(balanced.imageConcurrency, 2);
    expect(balanced.llmConcurrency, 2);
  });
}
