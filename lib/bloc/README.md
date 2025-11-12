# BLoC Architecture - Касса OS

## 📋 Структураи BLoC-ҳо

```
lib/
├── bloc/
│   ├── storage/          # Storage BLoC (Hive)
│   │   ├── storage_event.dart
│   │   ├── storage_state.dart
│   │   └── storage_bloc.dart
│   │
│   └── sync/             # Sync BLoC (Google Sheets)
│       ├── sync_event.dart
│       ├── sync_state.dart
│       └── sync_bloc.dart
│
├── auth/bloc/            # Auth BLoC (Аутентификатсия)
│   ├── auth_event.dart
│   ├── auth_state.dart
│   └── auth_bloc.dart
│
└── splash/bloc/          # Splash BLoC
    ├── splash_event.dart
    ├── splash_state.dart
    └── splash_bloc.dart
```

## 🎯 BLoC-ҳои асосӣ

### 1️⃣ **StorageBloc** - Идораи Hive (захираи локалӣ)

#### Events:
- `StorageInitRequested` - Инициализатсия
- `StorageSaveUser(user)` - Захираи корбар
- `StorageGetCurrentUser` - Гирифтани корбари ҷорӣ
- `StorageSetCurrentUserId(userId)` - Танзими ID
- `StorageClearCurrentUser` - Logout
- `StorageGetAllUsers` - Ҳамаи корбарҳо
- `StorageDeleteUser(userId)` - Нест кардан
- `StorageClearAll` - Пок кардани ҳама

#### States:
- `initialized` - Инициализатсия шуд
- `currentUser` - Корбари ҷорӣ
- `allUsers` - Рӯйхати ҳама
- `loading` - Дар ҳоли кор
- `error` - Хатогӣ

#### Истифода:
```dart
// Захираи корбар
context.read<StorageBloc>().add(StorageSaveUser(user));

// Гирифтани корбари ҷорӣ
context.read<StorageBloc>().add(const StorageGetCurrentUser());

// Listening
BlocBuilder<StorageBloc, StorageState>(
  builder: (context, state) {
    if (state.currentUser != null) {
      return Text('Салом, ${state.currentUser!.name}');
    }
    return Text('Корбар надорад');
  },
)
```

### 2️⃣ **SyncBloc** - Синхронизатсия бо Google Sheets

#### Events:
- `SyncRequested` - Синхронизатсияи умумӣ
- `SyncUserRequested(userId)` - Синхронизатсияи корбар
- `SyncDownloadRequested` - Боргирӣ аз Google Sheets
- `SyncUploadRequested` - Боргузорӣ ба Google Sheets

#### States:
- `syncing` - Дар ҳоли синхронизатсия
- `lastSyncSuccess` - Охирин муваффақ буд
- `lastSyncTime` - Вақти охирин
- `progress` - Прогресс (0.0-1.0)
- `error` - Хатогӣ

#### Истифода:
```dart
// Синхронизатсия
context.read<SyncBloc>().add(const SyncRequested());

// Progress indicator
BlocBuilder<SyncBloc, SyncState>(
  builder: (context, state) {
    if (state.syncing) {
      return LinearProgressIndicator(value: state.progress);
    }
    return SizedBox.shrink();
  },
)
```

### 3️⃣ **AuthBloc** - Аутентификатсия

#### Events:
- `AuthCheckRequested` - Санҷиши корбар
- `RegisterSubmitted(...)` - Қайд шудан
- `LoginSubmitted(phone, password)` - Ворид шудан
- `LogoutRequested` - Баромадан

#### States:
- `user` - Корбари ҷорӣ
- `loading` - Loading
- `error` - Хатогӣ
- `isAuthenticated` - Аутентификатсия шуд

#### Истифода:
```dart
// Login
context.read<AuthBloc>().add(
  LoginSubmitted(phone, password),
);

// Check auth status
BlocBuilder<AuthBloc, AuthState>(
  builder: (context, state) {
    if (state.isAuthenticated) {
      return HomeScreen();
    }
    return LoginScreen();
  },
)
```

## 🔄 Равиши кор

### Register/Login Flow:
```
1. User тугмаи "Login" мезанад
2. LoginScreen → AuthBloc.add(LoginSubmitted(...))
3. AuthBloc → AuthRepository.login(...)
4. AuthRepository:
   ├─ Google Sheets → Санҷиши phone/password
   └─ StorageBloc.add(StorageSaveUser(user)) ← Захира дар Hive
5. AuthBloc.emit(state.copyWithUser(user))
6. UI автоматӣ навсозӣ мешавад
```

### Get Current User Flow:
```
1. App оғоз мешавад
2. AuthBloc.add(AuthCheckRequested())
3. AuthRepository.getCurrentUser():
   ├─ Hive → user доред? ✅ Return
   └─ Hive → user надоред? ❌
       └─ Google Sheets → Гирифтан
           └─ Hive → Захира кардан
4. AuthBloc.emit(state.copyWithUser(user))
```

### Sync Flow:
```
1. User тугмаи "Sync" мезанад
2. SyncBloc.add(SyncRequested())
3. SyncBloc:
   ├─ emit(progress: 0.3) - Боргирӣ...
   ├─ Google Sheets → Гирифтани маълумот
   ├─ Hive → Захира кардан
   ├─ emit(progress: 0.6) - Боргузорӣ...
   ├─ Hive → Гирифтани тағйирот
   ├─ Google Sheets → Фиристодан
   └─ emit(success)
4. UI → Progress indicator
```

## 💡 Best Practices

### 1. MultiBlocProvider дар main.dart:
```dart
MultiBlocProvider(
  providers: [
    BlocProvider(create: (context) => StorageBloc()..add(const StorageInitRequested())),
    BlocProvider(create: (context) => SyncBloc(authRepository: AuthRepository())),
    BlocProvider(create: (context) => AuthBloc(authRepository: AuthRepository())),
  ],
  child: MaterialApp(...),
)
```

### 2. BlocBuilder барои UI:
```dart
BlocBuilder<AuthBloc, AuthState>(
  builder: (context, state) {
    if (state.loading) return LoadingWidget();
    if (state.error != null) return ErrorWidget(state.error);
    return ContentWidget();
  },
)
```

### 3. BlocListener барои navigation:
```dart
BlocListener<AuthBloc, AuthState>(
  listener: (context, state) {
    if (state.isAuthenticated) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  },
  child: LoginForm(),
)
```

### 4. BlocConsumer = Builder + Listener:
```dart
BlocConsumer<AuthBloc, AuthState>(
  listener: (context, state) {
    if (state.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.error!)),
      );
    }
  },
  builder: (context, state) {
    return LoginForm();
  },
)
```

## 📊 State Management

Ҳамаи state-ҳо дар BLoC-ҳо нигоҳ дошта мешаванд:
- ✅ UI-ҳо фақат rendering мекунанд
- ✅ Business logic дар BLoC-ҳо аст
- ✅ Data layer дар Repository-ҳо аст
- ✅ Local storage дар HiveService аст

## 🎯 Натиҷа

BLoC Architecture:
- ✅ Clean Architecture
- ✅ Testable
- ✅ Scalable
- ✅ Maintainable
- ✅ Separation of Concerns

