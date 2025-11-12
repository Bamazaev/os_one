import 'package:equatable/equatable.dart';
import '../../models/user_model.dart';

/// State-ҳо барои Storage
class StorageState extends Equatable {
  final bool initialized;
  final UserModel? currentUser;
  final List<UserModel> allUsers;
  final String? currentUserId;
  final bool loading;
  final String? error;

  const StorageState({
    this.initialized = false,
    this.currentUser,
    this.allUsers = const [],
    this.currentUserId,
    this.loading = false,
    this.error,
  });

  /// Ҳолати ибтидоӣ
  factory StorageState.initial() {
    return const StorageState();
  }

  /// Ҳолати loading
  StorageState copyWithLoading() {
    return StorageState(
      initialized: initialized,
      currentUser: currentUser,
      allUsers: allUsers,
      currentUserId: currentUserId,
      loading: true,
      error: null,
    );
  }

  /// Ҳолати initialized
  StorageState copyWithInitialized() {
    return StorageState(
      initialized: true,
      currentUser: currentUser,
      allUsers: allUsers,
      currentUserId: currentUserId,
      loading: false,
      error: null,
    );
  }

  /// Ҳолати бо корбар
  StorageState copyWithCurrentUser(UserModel? user, String? userId) {
    return StorageState(
      initialized: initialized,
      currentUser: user,
      allUsers: allUsers,
      currentUserId: userId,
      loading: false,
      error: null,
    );
  }

  /// Ҳолати бо ҳамаи корбарҳо
  StorageState copyWithAllUsers(List<UserModel> users) {
    return StorageState(
      initialized: initialized,
      currentUser: currentUser,
      allUsers: users,
      currentUserId: currentUserId,
      loading: false,
      error: null,
    );
  }

  /// Ҳолати хатогӣ
  StorageState copyWithError(String error) {
    return StorageState(
      initialized: initialized,
      currentUser: currentUser,
      allUsers: allUsers,
      currentUserId: currentUserId,
      loading: false,
      error: error,
    );
  }

  /// Ҳолати cleared
  StorageState copyWithCleared() {
    return StorageState(
      initialized: initialized,
      currentUser: null,
      allUsers: const [],
      currentUserId: null,
      loading: false,
      error: null,
    );
  }

  @override
  List<Object?> get props => [
        initialized,
        currentUser,
        allUsers,
        currentUserId,
        loading,
        error,
      ];
}

