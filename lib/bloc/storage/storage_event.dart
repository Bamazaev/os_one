import 'package:equatable/equatable.dart';
import '../../models/user_model.dart';

/// Event-ҳо барои Storage (Hive)
abstract class StorageEvent extends Equatable {
  const StorageEvent();

  @override
  List<Object?> get props => [];
}

/// Event барои инициализатсия
class StorageInitRequested extends StorageEvent {
  const StorageInitRequested();
}

/// Event барои захираи корбар
class StorageSaveUser extends StorageEvent {
  final UserModel user;
  
  const StorageSaveUser(this.user);
  
  @override
  List<Object?> get props => [user];
}

/// Event барои гирифтани корбари ҷорӣ
class StorageGetCurrentUser extends StorageEvent {
  const StorageGetCurrentUser();
}

/// Event барои танзими корбари ҷорӣ
class StorageSetCurrentUserId extends StorageEvent {
  final String userId;
  
  const StorageSetCurrentUserId(this.userId);
  
  @override
  List<Object?> get props => [userId];
}

/// Event барои пок кардани корбари ҷорӣ
class StorageClearCurrentUser extends StorageEvent {
  const StorageClearCurrentUser();
}

/// Event барои гирифтани ҳамаи корбарҳо
class StorageGetAllUsers extends StorageEvent {
  const StorageGetAllUsers();
}

/// Event барои нест кардани корбар
class StorageDeleteUser extends StorageEvent {
  final String userId;
  
  const StorageDeleteUser(this.userId);
  
  @override
  List<Object?> get props => [userId];
}

/// Event барои пок кардани ҳамаи маълумот
class StorageClearAll extends StorageEvent {
  const StorageClearAll();
}

