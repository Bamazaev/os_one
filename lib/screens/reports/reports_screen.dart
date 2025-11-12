import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/theme/theme_bloc.dart';
import '../../bloc/theme/theme_state.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});
  static const String route = '/reports';

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        return Scaffold(
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: themeState.backgroundGradient,
            ),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth > 800;
                  final isMobile = constraints.maxWidth < 600;

                  return SingleChildScrollView(
                    padding: EdgeInsets.all(isDesktop ? 40 : 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Заголовок
                        Text(
                          'Отчеты',
                          style: TextStyle(
                            color: themeState.textColor,
                            fontSize: isDesktop ? 42 : 32,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Статистика и аналитика',
                          style: TextStyle(
                            color: themeState.secondaryTextColor,
                            fontSize: isDesktop ? 20 : 16,
                          ),
                        ),
                        SizedBox(height: isDesktop ? 40 : 30),

                        // Карточки статистики
                        _buildStatsCards(isDesktop, isMobile),
                        SizedBox(height: isDesktop ? 30 : 20),

                        // Типы отчетов
                        _buildReportTypes(context, isDesktop, isMobile),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }


  Widget _buildStatsCards(bool isDesktop, bool isMobile) {
    final stats = [
      {
        'title': 'Продажи',
        'value': '1,234,567',
        'unit': 'с.',
        'icon': Icons.trending_up,
        'color': const Color(0xFF10b981),
      },
      {
        'title': 'Заказы',
        'value': '856',
        'unit': 'шт.',
        'icon': Icons.shopping_cart,
        'color': const Color(0xFF3b82f6),
      },
      {
        'title': 'Клиенты',
        'value': '342',
        'unit': 'чел.',
        'icon': Icons.people,
        'color': const Color(0xFFf59e0b),
      },
      {
        'title': 'Средний чек',
        'value': '1,442',
        'unit': 'с.',
        'icon': Icons.attach_money,
        'color': const Color(0xFFec4899),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop ? 4 : isMobile ? 2 : 2,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: isDesktop ? 1.3 : 1.1,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return _buildStatCard(
          title: stat['title'] as String,
          value: stat['value'] as String,
          unit: stat['unit'] as String,
          icon: stat['icon'] as IconData,
          color: stat['color'] as Color,
          isDesktop: isDesktop,
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
    required bool isDesktop,
  }) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        return Container(
          padding: EdgeInsets.all(isDesktop ? 20 : 15),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.2),
            ),
            child: Icon(icon, color: color, size: isDesktop ? 28 : 24),
          ),
          const Spacer(),
          Text(
            title,
            style: TextStyle(
              color: themeState.secondaryTextColor,
              fontSize: isDesktop ? 14 : 12,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: themeState.textColor,
                  fontSize: isDesktop ? 24 : 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 5),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  unit,
                  style: TextStyle(
                    color: themeState.secondaryTextColor,
                    fontSize: isDesktop ? 14 : 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
        );
      },
    );
  }

  Widget _buildReportTypes(BuildContext context, bool isDesktop, bool isMobile) {
    final reportTypes = [
      {
        'icon': Icons.calendar_today,
        'title': 'Отчет за день',
        'subtitle': 'Статистика текущего дня',
        'color': const Color(0xFF10b981),
      },
      {
        'icon': Icons.date_range,
        'title': 'Отчет за неделю',
        'subtitle': 'Статистика за 7 дней',
        'color': const Color(0xFF3b82f6),
      },
      {
        'icon': Icons.calendar_month,
        'title': 'Отчет за месяц',
        'subtitle': 'Месячная статистика',
        'color': const Color(0xFFf59e0b),
      },
      {
        'icon': Icons.pie_chart,
        'title': 'Аналитика продаж',
        'subtitle': 'Детальный анализ',
        'color': const Color(0xFF8b5cf6),
      },
      {
        'icon': Icons.inventory,
        'title': 'Отчет по товарам',
        'subtitle': 'Статистика товаров',
        'color': const Color(0xFFec4899),
      },
      {
        'icon': Icons.people,
        'title': 'Отчет по клиентам',
        'subtitle': 'База клиентов',
        'color': const Color(0xFF14b8a6),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop ? 3 : isMobile ? 1 : 2,
        crossAxisSpacing: isDesktop ? 25 : 15,
        mainAxisSpacing: isDesktop ? 25 : 15,
        childAspectRatio: isDesktop ? 1.5 : isMobile ? 2.5 : 1.8,
      ),
      itemCount: reportTypes.length,
      itemBuilder: (context, index) {
        final report = reportTypes[index];
        return _buildReportCard(
          context: context,
          icon: report['icon'] as IconData,
          title: report['title'] as String,
          subtitle: report['subtitle'] as String,
          color: report['color'] as Color,
          isDesktop: isDesktop,
        );
      },
    );
  }

  Widget _buildReportCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isDesktop,
  }) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        return GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$title: В разработке'),
                backgroundColor: color,
              ),
            );
          },
          child: Container(
            padding: EdgeInsets.all(isDesktop ? 20 : 15),
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
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isDesktop ? 15 : 12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.2),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: isDesktop ? 30 : 25,
                color: Colors.white,
              ),
            ),
            SizedBox(width: isDesktop ? 20 : 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
              Text(
                title,
                style: TextStyle(
                  color: themeState.textColor,
                  fontSize: isDesktop ? 18 : 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: TextStyle(
                  color: themeState.secondaryTextColor,
                  fontSize: isDesktop ? 14 : 12,
                ),
              ),
            ],
          ),
        ),
        Icon(
          Icons.arrow_forward_ios,
          color: themeState.secondaryTextColor,
          size: 16,
        ),
      ],
    ),
          ),
        );
      },
    );
  }
}

