import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../../bloc/theme/theme_bloc.dart';
import '../../bloc/theme/theme_state.dart';
import '../auth/login_screen.dart';
import 'home_page.dart';
import '../reports/reports_screen.dart';
import '../cart/cart_page.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  static const String route = '/home';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const ReportsScreen(),
    const CartPage(),
    const ProfileScreen(),
  ];

  Widget _buildNavItem({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required int index,
    required ThemeState themeState,
  }) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: isSelected 
                    ? themeState.primaryColor.withOpacity(0.15) 
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected ? themeState.primaryColor : themeState.borderColor,
                  width: 2,
                ),
              ),
              child: Icon(
                isSelected ? selectedIcon : icon,
                size: 48,
                color: isSelected ? themeState.primaryColor : themeState.secondaryTextColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? themeState.primaryColor : themeState.secondaryTextColor,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (!state.isAuthenticated && state.user == null && !state.loading) {
          Navigator.pushReplacementNamed(context, LoginScreen.route);
        }
      },
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 800;

              if (isDesktop) {
                // Desktop layout with side navigation
                return Scaffold(
                  body: Row(
                    children: [
                      // Side Navigation Rail
                      Container(
                        width: 120,
                        decoration: BoxDecoration(
                          color: themeState.cardColor,
                          border: Border(
                            right: BorderSide(
                              color: themeState.borderColor,
                              width: 1,
                            ),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(themeState.isDarkMode ? 0.3 : 0.1),
                              blurRadius: 20,
                              offset: const Offset(5, 0),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const SizedBox(height: 30),
                            _buildNavItem(
                              icon: Icons.home_outlined,
                              selectedIcon: Icons.home,
                              label: 'Главная',
                              index: 0,
                              themeState: themeState,
                            ),
                            _buildNavItem(
                              icon: Icons.analytics_outlined,
                              selectedIcon: Icons.analytics,
                              label: 'Отчеты',
                              index: 1,
                              themeState: themeState,
                            ),
                            _buildNavItem(
                              icon: Icons.shopping_cart_outlined,
                              selectedIcon: Icons.shopping_cart,
                              label: 'Корзина',
                              index: 2,
                              themeState: themeState,
                            ),
                            _buildNavItem(
                              icon: Icons.person_outline,
                              selectedIcon: Icons.person,
                              label: 'Профиль',
                              index: 3,
                              themeState: themeState,
                            ),
                          ],
                        ),
                      ),
                      // Main content
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: themeState.backgroundGradient,
                          ),
                          child: SafeArea(
                            child: _pages[_currentIndex],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                // Mobile layout with bottom navigation
                return Scaffold(
                  body: Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      gradient: themeState.backgroundGradient,
                    ),
                    child: SafeArea(
                      child: _pages[_currentIndex],
                    ),
                  ),
                  bottomNavigationBar: Container(
                    decoration: BoxDecoration(
                      color: themeState.cardColor,
                      border: Border(
                        top: BorderSide(
                          color: themeState.borderColor,
                          width: 1,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(themeState.isDarkMode ? 0.3 : 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                        child: SalomonBottomBar(
                          currentIndex: _currentIndex,
                          onTap: (index) => setState(() => _currentIndex = index),
                          selectedItemColor: themeState.primaryColor,
                          unselectedItemColor: themeState.secondaryTextColor,
                          items: [
                            SalomonBottomBarItem(
                              icon: const Icon(Icons.home),
                              title: Text(
                                'Главная',
                                style: TextStyle(
                                  fontFamily: 'Montserrat Alternates',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              selectedColor: themeState.primaryColor,
                            ),
                            SalomonBottomBarItem(
                              icon: const Icon(Icons.analytics),
                              title: Text(
                                'Отчеты',
                                style: TextStyle(
                                  fontFamily: 'Montserrat Alternates',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              selectedColor: themeState.primaryColor,
                            ),
                            SalomonBottomBarItem(
                              icon: const Icon(Icons.shopping_cart),
                              title: Text(
                                'Корзина',
                                style: TextStyle(
                                  fontFamily: 'Montserrat Alternates',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              selectedColor: themeState.primaryColor,
                            ),
                            SalomonBottomBarItem(
                              icon: const Icon(Icons.person),
                              title: Text(
                                'Профиль',
                                style: TextStyle(
                                  fontFamily: 'Montserrat Alternates',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              selectedColor: themeState.primaryColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }
}
