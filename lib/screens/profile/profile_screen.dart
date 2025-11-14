import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../../auth/bloc/auth_state.dart';
import '../../bloc/theme/theme_bloc.dart';
import '../../bloc/theme/theme_event.dart';
import '../../bloc/theme/theme_state.dart';
import '../../utils/base64_helper.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState.user == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final isAdmin = authState.user!.role.toLowerCase() == 'admin';

        return BlocBuilder<ThemeBloc, ThemeState>(
          builder: (context, themeState) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth > 800;
                final isMobile = constraints.maxWidth < 600;

                return SingleChildScrollView(
                  padding: EdgeInsets.all(isDesktop ? 40 : 20),
                  child: Column(
                    children: [
                      // Header с аватаром
                      _buildHeader(context, authState, themeState, isDesktop, isMobile),
                      SizedBox(height: isDesktop ? 40 : 30),

                      // Функции на основе роли
                      if (isAdmin)
                        _buildAdminFeatures(context, themeState, isDesktop, isMobile)
                      else
                        _buildUserFeatures(context, themeState, isDesktop, isMobile),

                      SizedBox(height: isDesktop ? 30 : 20),

                      // Кнопка выхода
                      _buildLogoutButton(context, themeState, isDesktop),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, AuthState authState, ThemeState themeState, bool isDesktop, bool isMobile) {
    final avatarSize = isDesktop ? 80.0 : isMobile ? 60.0 : 70.0;

    return Container(
      padding: EdgeInsets.all(isDesktop ? 30 : 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        color: themeState.cardColor,
        border: Border.all(color: themeState.borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(themeState.isDarkMode ? 0.3 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Кнопка переключения темы
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: themeState.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: themeState.primaryColor.withOpacity(0.3), width: 1),
                ),
                child: IconButton(
                  icon: Icon(
                    themeState.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                    color: themeState.primaryColor,
                  ),
                  onPressed: () {
                    context.read<ThemeBloc>().add(const ThemeToggled());
                  },
                  tooltip: themeState.isDarkMode ? 'Светлая тема' : 'Темная тема',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          
          // Аватар
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: themeState.primaryColor,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: themeState.primaryColor.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: CircleAvatar(
              radius: avatarSize,
              backgroundColor: themeState.surfaceColor,
              backgroundImage: authState.user!.photoUrl != null &&
                      authState.user!.photoUrl!.isNotEmpty
                  ? (() {
                      final bytes = safeBase64Decode(authState.user!.photoUrl!);
                      return bytes != null ? MemoryImage(bytes) : null;
                    })()
                  : null,
              child: authState.user!.photoUrl == null || authState.user!.photoUrl!.isEmpty
                  ? Icon(Icons.person, size: avatarSize, color: themeState.secondaryTextColor)
                  : null,
            ),
          ),
          const SizedBox(height: 20),

          // Имя
          Text(
            '${authState.user!.name} ${authState.user!.lastName}',
            style: TextStyle(
              color: themeState.textColor,
              fontSize: isDesktop ? 28 : isMobile ? 20 : 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),

          // Роль
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  themeState.primaryColor,
                  themeState.primaryColor.withOpacity(0.7),
                ],
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_user, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  authState.user!.role.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),

          // Email и телефон
          if (!isMobile) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.email, color: themeState.secondaryTextColor, size: 16),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    authState.user!.email,
                    style: TextStyle(
                      color: themeState.secondaryTextColor,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.phone, color: themeState.secondaryTextColor, size: 16),
                const SizedBox(width: 8),
                Text(
                  authState.user!.phone,
                  style: TextStyle(
                    color: themeState.secondaryTextColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAdminFeatures(BuildContext context, ThemeState themeState, bool isDesktop, bool isMobile) {
    final features = [
      {
        'icon': Icons.people,
        'title': 'Сотрудники',
        'subtitle': 'Управление персоналом',
        'color': const Color(0xFF10b981),
      },
      {
        'icon': Icons.analytics,
        'title': 'Отчеты',
        'subtitle': 'Статистика и аналитика',
        'color': const Color(0xFF3b82f6),
      },
      {
        'icon': Icons.inventory,
        'title': 'Товары',
        'subtitle': 'Управление товарами',
        'color': const Color(0xFFf59e0b),
      },
      {
        'icon': Icons.settings,
        'title': 'Настройки',
        'subtitle': 'Системные настройки',
        'color': const Color(0xFF8b5cf6),
      },
      {
        'icon': Icons.history,
        'title': 'История',
        'subtitle': 'История операций',
        'color': const Color(0xFFec4899),
      },
      {
        'icon': Icons.attach_money,
        'title': 'Касса',
        'subtitle': 'Финансовые операции',
        'color': const Color(0xFF14b8a6),
      },
    ];

    return _buildFeatureGrid(features, context, themeState, isDesktop, isMobile);
  }

  Widget _buildUserFeatures(BuildContext context, ThemeState themeState, bool isDesktop, bool isMobile) {
    final features = [
      {
        'icon': Icons.shopping_bag,
        'title': 'Покупки',
        'subtitle': 'История покупок',
        'color': const Color(0xFF3b82f6),
      },
      {
        'icon': Icons.favorite,
        'title': 'Избранное',
        'subtitle': 'Любимые товары',
        'color': const Color(0xFFec4899),
      },
      {
        'icon': Icons.notifications,
        'title': 'Уведомления',
        'subtitle': 'Мои уведомления',
        'color': const Color(0xFFf59e0b),
      },
      {
        'icon': Icons.card_giftcard,
        'title': 'Бонусы',
        'subtitle': 'Бонусная программа',
        'color': const Color(0xFF8b5cf6),
      },
    ];

    return _buildFeatureGrid(features, context, themeState, isDesktop, isMobile);
  }

  Widget _buildFeatureGrid(
      List<Map<String, dynamic>> features, BuildContext context, ThemeState themeState, bool isDesktop, bool isMobile) {
    final crossAxisCount = isDesktop ? 3 : 2;
    final childAspectRatio = isDesktop ? 1.3 : isMobile ? 1.1 : 1.2;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: isDesktop ? 25 : 15,
        mainAxisSpacing: isDesktop ? 25 : 15,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final feature = features[index];
        return _buildFeatureCard(
          icon: feature['icon'] as IconData,
          title: feature['title'] as String,
          subtitle: feature['subtitle'] as String,
          color: feature['color'] as Color,
          themeState: themeState,
          isDesktop: isDesktop,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${feature['title']}: В разработке'),
                backgroundColor: feature['color'] as Color,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required ThemeState themeState,
    required bool isDesktop,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: themeState.cardColor,
          border: Border.all(color: themeState.borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(themeState.isDarkMode ? 0.3 : 0.05),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(isDesktop ? 20 : 15),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.1),
                border: Border.all(color: color.withOpacity(0.3), width: 1),
              ),
              child: Icon(
                icon,
                size: isDesktop ? 40 : 35,
                color: color,
              ),
            ),
            SizedBox(height: isDesktop ? 15 : 12),
            Text(
              title,
              style: TextStyle(
                color: themeState.textColor,
                fontSize: isDesktop ? 18 : 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                subtitle,
                style: TextStyle(
                  color: themeState.secondaryTextColor,
                  fontSize: isDesktop ? 13 : 11,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, ThemeState themeState, bool isDesktop) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: isDesktop ? 400 : double.infinity,
      ),
      child: ElevatedButton.icon(
        onPressed: () {
          context.read<AuthBloc>().add(const LogoutRequested());
        },
        icon: const Icon(Icons.logout, size: 24),
        label: Text(
          'ВЫХОД',
          style: TextStyle(
            fontSize: isDesktop ? 18 : 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade600,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            vertical: isDesktop ? 18 : 15,
            horizontal: isDesktop ? 40 : 30,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 10,
          shadowColor: Colors.red.withOpacity(0.3),
        ),
      ),
    );
  }
}
