import 'package:flutter_riverpod/flutter_riverpod.dart';

class ShellIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int index) {
    state = index;
  }
}

final shellIndexProvider = NotifierProvider<ShellIndexNotifier, int>(ShellIndexNotifier.new);
