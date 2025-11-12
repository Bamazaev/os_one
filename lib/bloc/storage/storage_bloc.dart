import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/hive_service.dart';
import 'storage_event.dart';
import 'storage_state.dart';

/// BLoC барои идораи Storage (Hive)
class StorageBloc extends Bloc<StorageEvent, StorageState> {
  StorageBloc() : super(StorageState.initial()) {
    on<StorageInitRequested>(_onInitRequested);
    on<StorageSaveUser>(_onSaveUser);
    on<StorageGetCurrentUser>(_onGetCurrentUser);
    on<StorageSetCurrentUserId>(_onSetCurrentUserId);
    on<StorageClearCurrentUser>(_onClearCurrentUser);
    on<StorageGetAllUsers>(_onGetAllUsers);
    on<StorageDeleteUser>(_onDeleteUser);
    on<StorageClearAll>(_onClearAll);
  }

  /// Инициализатсия
  Future<void> _onInitRequested(
    StorageInitRequested event,
    Emitter<StorageState> emit,
  ) async {
    emit(state.copyWithLoading());
    try {
      await HiveService.init();
      emit(state.copyWithInitialized());
    } catch (e) {
      emit(state.copyWithError('Хатогӣ дар инициализатсия: ${e.toString()}'));
    }
  }

  /// Захираи корбар
  Future<void> _onSaveUser(
    StorageSaveUser event,
    Emitter<StorageState> emit,
  ) async {
    try {
      await HiveService.saveUser(event.user);
      
      // Навсозии ҳолат
      final allUsers = HiveService.getAllUsers();
      emit(state.copyWithAllUsers(allUsers));
    } catch (e) {
      emit(state.copyWithError('Хатогӣ дар захираи корбар: ${e.toString()}'));
    }
  }

  /// Гирифтани корбари ҷорӣ
  Future<void> _onGetCurrentUser(
    StorageGetCurrentUser event,
    Emitter<StorageState> emit,
  ) async {
    try {
      final user = HiveService.getCurrentUser();
      final userId = HiveService.getCurrentUserId();
      emit(state.copyWithCurrentUser(user, userId));
    } catch (e) {
      emit(state.copyWithError('Хатогӣ дар гирифтани корбар: ${e.toString()}'));
    }
  }

  /// Танзими ID-и корбари ҷорӣ
  Future<void> _onSetCurrentUserId(
    StorageSetCurrentUserId event,
    Emitter<StorageState> emit,
  ) async {
    try {
      await HiveService.setCurrentUserId(event.userId);
      final user = HiveService.getUser(event.userId);
      emit(state.copyWithCurrentUser(user, event.userId));
    } catch (e) {
      emit(state.copyWithError('Хатогӣ дар танзими ID: ${e.toString()}'));
    }
  }

  /// Пок кардани корбари ҷорӣ
  Future<void> _onClearCurrentUser(
    StorageClearCurrentUser event,
    Emitter<StorageState> emit,
  ) async {
    try {
      await HiveService.clearCurrentUser();
      emit(state.copyWithCurrentUser(null, null));
    } catch (e) {
      emit(state.copyWithError('Хатогӣ дар пок кардан: ${e.toString()}'));
    }
  }

  /// Гирифтани ҳамаи корбарҳо
  Future<void> _onGetAllUsers(
    StorageGetAllUsers event,
    Emitter<StorageState> emit,
  ) async {
    try {
      final users = HiveService.getAllUsers();
      emit(state.copyWithAllUsers(users));
    } catch (e) {
      emit(state.copyWithError('Хатогӣ дар гирифтани корбарҳо: ${e.toString()}'));
    }
  }

  /// Нест кардани корбар
  Future<void> _onDeleteUser(
    StorageDeleteUser event,
    Emitter<StorageState> emit,
  ) async {
    try {
      await HiveService.deleteUser(event.userId);
      final allUsers = HiveService.getAllUsers();
      emit(state.copyWithAllUsers(allUsers));
    } catch (e) {
      emit(state.copyWithError('Хатогӣ дар нест кардан: ${e.toString()}'));
    }
  }

  /// Пок кардани ҳама
  Future<void> _onClearAll(
    StorageClearAll event,
    Emitter<StorageState> emit,
  ) async {
    try {
      await HiveService.clearAll();
      emit(state.copyWithCleared());
    } catch (e) {
      emit(state.copyWithError('Хатогӣ дар пок кардани ҳама: ${e.toString()}'));
    }
  }
}

