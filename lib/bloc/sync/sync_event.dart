import 'package:equatable/equatable.dart';

/// Event-ҳо барои синхронизатсия бо Google Sheets
abstract class SyncEvent extends Equatable {
  const SyncEvent();

  @override
  List<Object?> get props => [];
}

/// Event барои синхронизатсия
class SyncRequested extends SyncEvent {
  const SyncRequested();
}

/// Event барои синхронизатсияи корбари муайян
class SyncUserRequested extends SyncEvent {
  final String userId;
  
  const SyncUserRequested(this.userId);
  
  @override
  List<Object?> get props => [userId];
}

/// Event барои боргирии маълумот аз Google Sheets
class SyncDownloadRequested extends SyncEvent {
  const SyncDownloadRequested();
}

/// Event барои боргузории маълумот ба Google Sheets
class SyncUploadRequested extends SyncEvent {
  const SyncUploadRequested();
}

