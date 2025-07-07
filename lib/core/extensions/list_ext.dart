import 'dart:math';

extension ListExtension<E> on List<E> {
  // bool isSorted() {
  //   for (int i = 0; i < length - 1; i++) {
  //     if (this[i] > this[i + 1]) {
  //       return false;
  //     }
  //   }
  //   return true;
  // }

  E? firstWhereOrNull(bool Function(E element) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

extension ListRandom on List {
  dynamic random({int? seed}) {
    final random = Random(seed);
    return this[random.nextInt(length)];
  }
}
