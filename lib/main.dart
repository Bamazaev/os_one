import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'splash_screen.dart';
import 'auth/bloc/auth_bloc.dart';
import 'auth/bloc/auth_event.dart';
import 'repositories/auth_repository.dart';
import 'repositories/category_repository.dart';
import 'repositories/product_repository.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/reports/reports_screen.dart';
import 'services/hive_service.dart';
import 'services/gsheets_service.dart';
import 'bloc/sync/sync_bloc.dart';
import 'bloc/theme/theme_bloc.dart';
import 'bloc/theme/theme_state.dart';
import 'bloc/category/category_bloc.dart';
import 'bloc/category/category_event.dart';
import 'bloc/product/product_bloc.dart';
import 'bloc/product/product_event.dart';

void main() async {
  // Иҷозат додан барои async дар main
  WidgetsFlutterBinding.ensureInitialized();
  
  // Инициализатсияи Hive - танҳо як маротиба!
  print('🚀 Оғози барнома...');
  await HiveService.init();
  print('✅ Hive инициализатсия шуд');
  
  // Инициализатсияи Google Sheets - танҳо як маротиба!
  try {
    await GsheetsService.init();
    print('✅ Google Sheets инициализатсия шуд');
    
    // Эҷоди worksheets барои ҳар як repository
    await CategoryRepository.init();
    await ProductRepository.init();
    print('✅ Ҳамаи repositories инициализатсия шуданд');
  } catch (e) {
    print('❌ Хатои инициализатсия: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Theme BLoC - барои Dark/Light режим
        BlocProvider(
          create: (context) => ThemeBloc(),
        ),
        // Sync BLoC - барои синхронизатсия бо Google Sheets
        BlocProvider(
          create: (context) => SyncBloc(
            authRepository: AuthRepository(),
          ),
        ),
        // Auth BLoC - барои аутентификатсия
        BlocProvider(
          create: (context) => AuthBloc(
            authRepository: AuthRepository(),
          )..add(const AuthCheckRequested()), // Санҷиши корбар ҳангоми оғоз
        ),
        // Category BLoC - барои категорияҳо
        BlocProvider(
          create: (context) => CategoryBloc(
            categoryRepository: CategoryRepository(),
          )..add(const CategoriesLoadRequested()), // Загрузкаи категорияҳо
        ),
        // Product BLoC - барои продуктҳо
        BlocProvider(
          create: (context) => ProductBloc(
            productRepository: ProductRepository(),
          )..add(const ProductsLoadRequested()), // Загрузкаи продуктҳо
        ),
      ],
            child: BlocBuilder<ThemeBloc, ThemeState>(
              builder: (context, themeState) {
                return MaterialApp(
              title: 'Касса OS',
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: const Color(0xFF10b981),
                  brightness: Brightness.light,
                ),
                useMaterial3: true,
                primaryColor: const Color(0xFF10b981),
                textTheme: GoogleFonts.montserratAlternatesTextTheme(),
                fontFamily: GoogleFonts.montserratAlternates().fontFamily,
              ),
              darkTheme: ThemeData(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: const Color(0xFF10b981),
                  brightness: Brightness.dark,
                ),
                useMaterial3: true,
                primaryColor: const Color(0xFF10b981),
                scaffoldBackgroundColor: const Color(0xFF0f172a),
                textTheme: GoogleFonts.montserratAlternatesTextTheme(ThemeData.dark().textTheme),
                fontFamily: GoogleFonts.montserratAlternates().fontFamily,
              ),
              themeMode: themeState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
              initialRoute: '/',
              routes: {
                '/': (context) => const SplashScreen(),
                LoginScreen.route: (context) => const LoginScreen(),
                RegisterScreen.route: (context) => const RegisterScreen(),
                HomeScreen.route: (context) => const HomeScreen(),
                ReportsScreen.route: (context) => const ReportsScreen(),
              },
                );
              },
            ),
    );
  }
}
