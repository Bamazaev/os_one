import 'package:equatable/equatable.dart';

/// State-ҳо барои синхронизатсия
class SyncState extends Equatable {
  final bool syncing;
  final bool lastSyncSuccess;
  final DateTime? lastSyncTime;
  final String? error;
  final double progress; // 0.0 то 1.0

  const SyncState({
    this.syncing = false,
    this.lastSyncSuccess = false,
    this.lastSyncTime,
    this.error,
    this.progress = 0.0,
  });

  /// Ҳолати ибтидоӣ
  factory SyncState.initial() {
    return const SyncState();
  }

  /// Ҳолати syncing
  SyncState copyWithSyncing(double progress) {
    return SyncState(
      syncing: true,
      lastSyncSuccess: lastSyncSuccess,
      lastSyncTime: lastSyncTime,
      error: null,
      progress: progress,
    );
  }

  /// Ҳолати муваффақ
  SyncState copyWithSuccess() {
    return SyncState(
      syncing: false,
      lastSyncSuccess: true,
      lastSyncTime: DateTime.now(),
      error: null,
      progress: 1.0,
    );
  }

  /// Ҳолати хатогӣ
  SyncState copyWithError(String error) {
    return SyncState(
      syncing: false,
      lastSyncSuccess: false,
      lastSyncTime: lastSyncTime,
      error: error,
      progress: 0.0,
    );
  }

  @override
  List<Object?> get props => [
        syncing,
        lastSyncSuccess,
        lastSyncTime,
        error,
        progress,
      ];
}

