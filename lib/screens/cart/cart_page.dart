import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/theme/theme_bloc.dart';
import '../../bloc/theme/theme_state.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 800;

            return SingleChildScrollView(
              padding: EdgeInsets.all(isDesktop ? 40 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Корзина',
                    style: TextStyle(
                      color: themeState.textColor,
                      fontSize: isDesktop ? 42 : 32,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Ваши товары',
                    style: TextStyle(
                      color: themeState.secondaryTextColor,
                      fontSize: isDesktop ? 20 : 16,
                    ),
                  ),
                  SizedBox(height: isDesktop ? 40 : 30),

                  // Пустая корзина
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: isDesktop ? 120 : 100,
                          color: themeState.secondaryTextColor.withOpacity(0.5),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Корзина пуста',
                          style: TextStyle(
                            color: themeState.textColor,
                            fontSize: isDesktop ? 24 : 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Добавьте товары из каталога',
                          style: TextStyle(
                            color: themeState.secondaryTextColor,
                            fontSize: isDesktop ? 16 : 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
