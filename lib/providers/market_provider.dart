import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

/// Modelo simples para representar uma criptomoeda em alta (Trending)
class MarketCoin {
  final String id;
  final String name;
  final String symbol;
  final double priceBtc;
  final String thumbUrl;

  MarketCoin({
    required this.id,
    required this.name,
    required this.symbol,
    required this.priceBtc,
    required this.thumbUrl,
  });

  factory MarketCoin.fromJson(Map<String, dynamic> json) {
    return MarketCoin(
      id: json['item']['id'] ?? '',
      name: json['item']['name'] ?? '',
      symbol: json['item']['symbol'] ?? '',
      priceBtc: json['item']['price_btc']?.toDouble() ?? 0.0,
      thumbUrl: json['item']['thumb'] ?? '',
    );
  }
}

/// Estado da API de mercado
class MarketState {
  final List<MarketCoin> trendingCoins;
  final bool isLoading;
  final String? errorMessage;

  MarketState({
    this.trendingCoins = const [],
    this.isLoading = true,
    this.errorMessage,
  });

  MarketState copyWith({
    List<MarketCoin>? trendingCoins,
    bool? isLoading,
    String? errorMessage,
  }) {
    return MarketState(
      trendingCoins: trendingCoins ?? this.trendingCoins,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// Notifier que consome a API do CoinGecko
class MarketNotifier extends StateNotifier<MarketState> {
  MarketNotifier() : super(MarketState()) {
    fetchTrending();
  }

  Future<void> fetchTrending() async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await http.get(
        Uri.parse('https://api.coingecko.com/api/v3/search/trending'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List coinsData = data['coins'] ?? [];
        
        // Pega as top 5
        final coins = coinsData
            .take(5)
            .map((e) => MarketCoin.fromJson(e as Map<String, dynamic>))
            .toList();

        state = state.copyWith(trendingCoins: coins, isLoading: false);
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Erro ao carregar dados do mercado',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Falha de rede ao acessar API',
      );
    }
  }
}

final marketProvider = StateNotifierProvider<MarketNotifier, MarketState>((ref) {
  return MarketNotifier();
});
