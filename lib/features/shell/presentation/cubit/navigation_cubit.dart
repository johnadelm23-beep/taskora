import 'package:flutter_bloc/flutter_bloc.dart';

class NavigationCubit extends Cubit<int> {
  NavigationCubit() : super(0);

  void selectTab(int index) {
    if (state != index && index >= 0 && index <= 3) {
      emit(index);
    }
  }
}
