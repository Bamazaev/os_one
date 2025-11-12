import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/auth_repository.dart';
import '../../services/hive_service.dart';
import 'sync_event.dart';
import 'sync_state.dart';

/// BLoC барои синхронизатсия бо Google Sheets
class SyncBloc extends Bloc<SyncEvent, SyncState> {
  final AuthRepository authRepository;

  SyncBloc({required this.authRepository}) : super(SyncState.initial()) {
    on<SyncRequested>(_onSyncRequested);
    on<SyncUserRequested>(_onSyncUserRequested);
    on<SyncDownloadRequested>(_onSyncDownloadRequested);
    on<SyncUploadRequested>(_onSyncUploadRequested);
  }

  /// Синхронизатсияи умумӣ
  Future<void> _onSyncRequested(
    SyncRequested event,
    Emitter<SyncState> emit,
  ) async {
    emit(state.copyWithSyncing(0.1));
    
    try {
      // 1. Боргирӣ аз Google Sheets
      emit(state.copyWithSyncing(0.3));
      // Дар ояндa метавон корбарҳоро аз Google Sheets барои offline кор гирифт
      
      // 2. Боргузорӣ ба Google Sheets
      emit(state.copyWithSyncing(0.6));
      // Дар ояндa метавон тағйиротҳои локалиро ба Google Sheets фиристод
      
      // 3. Тамом
      emit(state.copyWithSyncing(1.0));
      await Future.delayed(const Duration(milliseconds: 500));
      emit(state.copyWithSuccess());
      
    } catch (e) {
      emit(state.copyWithError('Хатогӣ дар синхронизатсия: ${e.toString()}'));
    }
  }

  /// Синхронизатсияи корбари муайян
  Future<void> _onSyncUserRequested(
    SyncUserRequested event,
    Emitter<SyncState> emit,
  ) async {
    emit(state.copyWithSyncing(0.2));
    
    try {
      // Гирифтани корбар аз Google Sheets
      final user = await authRepository.getCurrentUser();
      
      if (user != null) {
        // Захира дар Hive
        await HiveService.saveUser(user);
        emit(state.copyWithSuccess());
      } else {
        emit(state.copyWithError('Корбар ёфт нашуд'));
      }
    } catch (e) {
      emit(state.copyWithError('Хатогӣ: ${e.toString()}'));
    }
  }

  /// Боргирӣ аз Google Sheets
  Future<void> _onSyncDownloadRequested(
    SyncDownloadRequested event,
    Emitter<SyncState> emit,
  ) async {
    emit(state.copyWithSyncing(0.2));
    
    try {
      // Дар ояндa: Боргирии ҳамаи маълумот аз Google Sheets
      emit(state.copyWithSyncing(0.8));
      await Future.delayed(const Duration(milliseconds: 500));
      emit(state.copyWithSuccess());
    } catch (e) {
      emit(state.copyWithError('Хатогӣ дар боргирӣ: ${e.toString()}'));
    }
  }

  /// Боргузорӣ ба Google Sheets
  Future<void> _onSyncUploadRequested(
    SyncUploadRequested event,
    Emitter<SyncState> emit,
  ) async {
    emit(state.copyWithSyncing(0.2));
    
    try {
      // Дар ояндa: Боргузории тағйироти локалӣ ба Google Sheets
      emit(state.copyWithSyncing(0.8));
      await Future.delayed(const Duration(milliseconds: 500));
      emit(state.copyWithSuccess());
    } catch (e) {
      emit(state.copyWithError('Хатогӣ дар боргузорӣ: ${e.toString()}'));
    }
  }
}

