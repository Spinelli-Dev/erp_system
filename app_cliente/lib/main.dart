import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'core/app_colors.dart';
import 'navigation/app_router.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/navigation_provider.dart';
import 'providers/order_history_provider.dart';
import 'providers/product_provider.dart';
import 'services/api_client.dart';
import 'services/cep_service.dart';
import 'services/delivery_fee_service.dart';
import 'services/order_service.dart';
import 'services/product_service.dart';
import 'services/user_profile_service.dart';
import 'widgets/mobile_frame.dart';

/// Endereço da API, passado na hora de rodar:
///   flutter run --dart-define=API_BASE_URL=https://localhost:5001/api
/// Sem ele, o app usa os serviços mockados (dados fixos, sem rede).
const _apiBaseUrl = String.fromEnvironment('API_BASE_URL');

void main() {
  runApp(MaxiMassasApp(api: _apiBaseUrl.isEmpty ? null : ApiClient(baseUrl: _apiBaseUrl)));
}

class MaxiMassasApp extends StatelessWidget {
  const MaxiMassasApp({super.key, this.api});

  /// `null` = modo offline com mocks.
  final ApiClient? api;

  @override
  Widget build(BuildContext context) {
    final api = this.api;
    // Um só serviço de pedidos para enviar (checkout) e listar (histórico).
    final pedidos = api == null ? null : ApiOrderService(api);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(service: api == null ? null : ApiUserProfileService(api)),
        ),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(
          create: (_) => CartProvider(deliveryFeeService: api == null ? null : ApiDeliveryFeeService(api)),
        ),
        // ChangeNotifierProvider "lazy": só cria o ProductProvider (e
        // dispara a carga inicial do cardápio) quando a aba de produtos
        // for de fato aberta pela primeira vez.
        ChangeNotifierProvider(
          create: (_) => ProductProvider(service: api == null ? null : ApiProductService(api)),
        ),
        ChangeNotifierProvider(create: (_) => OrderHistoryProvider(service: pedidos)),
        // Lido pela tela de finalização; null faz ela cair no mock.
        Provider<OrderService?>.value(value: pedidos),
        // Lido pelos campos de endereço (preenchimento pelo CEP); null = sem consulta.
        Provider<CepService?>.value(value: api == null ? null : ApiCepService(api)),
      ],
      // Builder para o AppRouter enxergar o AuthProvider criado acima.
      child: Builder(
        builder: (context) {
          final router = AppRouter(context.read<AuthProvider>());

          return MaterialApp(
            title: 'Maxi Massas',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              scaffoldBackgroundColor: AppColors.background,
              fontFamily: GoogleFonts.inter().fontFamily,
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.primary,
                primary: AppColors.primary,
              ),
              appBarTheme: const AppBarTheme(iconTheme: IconThemeData(color: Colors.white)),
            ),
            // Sem sessão, qualquer rota (inclusive o deep link de uma aba,
            // ex.: /pedidos) abre o login — ver AppRouter.
            initialRoute: AppTab.produtos.rota,
            onGenerateInitialRoutes: router.gerarRotasIniciais,
            onGenerateRoute: router.gerarRota,
            // Aplica a moldura de celular a TODAS as telas de uma vez só,
            // envolvendo o Navigator inteiro (e, com ele, SnackBars e
            // diálogos também). Ver widgets/mobile_frame.dart.
            builder: (context, child) => MobileFrame(child: child!),
          );
        },
      ),
    );
  }
}
