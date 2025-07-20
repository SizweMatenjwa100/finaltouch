import 'package:bloc/bloc.dart';
import '../data/repositories/auth_respository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(AuthInitial()) {
    // Handle Sign Up
    on<SignUpRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        await authRepository.SignUp(
          email: event.email,
          password: event.password,
        );
        emit(AuthSuccess());
      } catch (e) {
        emit(AuthFailure(error: e.toString()));
      }
    });

    // Handle Login
    on<LoginRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        await authRepository.SignIn(
          email: event.email,
          password: event.password,
        );
        emit(AuthSuccess());
      } catch (e) {
        emit(AuthFailure(error: e.toString()));
      }
    });
  }
}
