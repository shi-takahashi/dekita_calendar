import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static const bool _isDebug = kDebugMode;

  /// スクリーンショット撮影時など、広告を非表示にするためのフラグ
  ///
  /// 使用方法:
  /// - スクリーンショット撮影時: false に設定してビルド
  /// - 本番リリース時: 必ず true に設定してビルド
  /// - ユーザーが自由に変更できないよう、設定画面には表示しない
  ///
  /// true: 広告を表示、false: 広告を非表示
  static const bool showBannerAds = true;

  // バナー広告のキャッシュ
  static final List<BannerAd> _bannerAdCache = [];
  static const int _maxCacheSize = 3;
  static bool _isPreloadingBanners = false;

  // テスト用広告ID（デバッグビルド時）
  static const String _testBannerAdUnitIdAndroid = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testBannerAdUnitIdIOS = 'ca-app-pub-3940256099942544/2934735716';

  // 本番用広告ID（リリースビルド時）- 現在はテスト用IDを使用
  static const String _productionBannerAdUnitIdAndroid = 'ca-app-pub-3940256099942544/6300978111';
  static const String _productionBannerAdUnitIdIOS = 'ca-app-pub-3940256099942544/2934735716';

  /// 現在の環境に応じたバナー広告IDを取得
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return _isDebug ? _testBannerAdUnitIdAndroid : _productionBannerAdUnitIdAndroid;
    } else {
      return _isDebug ? _testBannerAdUnitIdIOS : _productionBannerAdUnitIdIOS;
    }
  }

  /// AdMobを初期化
  static Future<void> initialize() async {
    await MobileAds.instance.initialize();

    // デバッグ時のテストデバイス設定
    if (_isDebug) {
      final requestConfiguration = RequestConfiguration(
        testDeviceIds: ['C774D381A6F78EB27EBA6CB37B4551E3'], // 必要に応じて実際のテストデバイスIDに変更
      );
      await MobileAds.instance.updateRequestConfiguration(requestConfiguration);
    }

    // バナー広告を事前にいくつか読み込んでおく
    if (showBannerAds) {
      _preloadBannerAds();
    }
  }

  /// バナー広告を作成
  static BannerAd createBannerAd({
    required Function() onAdLoaded,
    required Function() onAdFailedToLoad,
    AdSize adSize = AdSize.banner,
  }) {
    final adUnitId = bannerAdUnitId;
    print('バナー広告作成開始: $adUnitId (${_isDebug ? "テスト広告" : "本番広告"}, サイズ: $adSize)');

    return BannerAd(
      adUnitId: adUnitId,
      size: adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          print('バナー広告読み込み完了: $adUnitId');
          onAdLoaded();
        },
        onAdFailedToLoad: (ad, error) {
          print('バナー広告読み込み失敗:');
          print('  - エラーコード: ${error.code}');
          print('  - エラーメッセージ: ${error.message}');
          print('  - ドメイン: ${error.domain}');
          print('  - 広告ID: $adUnitId');
          ad.dispose();
          onAdFailedToLoad();
        },
        onAdOpened: (_) {
          print('バナー広告がタップされました');
        },
        onAdClosed: (_) {
          print('バナー広告が閉じられました');
        },
        onAdImpression: (_) {
          print('バナー広告が表示されました（インプレッション）');
        },
      ),
    )..load();
  }

  /// バナー広告を事前に複数読み込み
  static void _preloadBannerAds() async {
    if (_isPreloadingBanners || !showBannerAds) return;

    _isPreloadingBanners = true;
    print('バナー広告の事前読み込み開始');

    // 異なるサイズの広告を事前に読み込む
    final adSizes = [AdSize.banner, AdSize.largeBanner];

    for (final size in adSizes) {
      if (_bannerAdCache.length >= _maxCacheSize) break;

      // 少し間隔を空けて読み込み
      await Future.delayed(const Duration(milliseconds: 500));

      final ad = BannerAd(
        adUnitId: bannerAdUnitId,
        size: size,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            print('バナー広告事前読み込み成功: $size');
            if (_bannerAdCache.length < _maxCacheSize) {
              _bannerAdCache.add(ad as BannerAd);
            } else {
              ad.dispose();
            }
          },
          onAdFailedToLoad: (ad, error) {
            print('バナー広告事前読み込み失敗: $size');
            ad.dispose();
          },
        ),
      )..load();
    }

    _isPreloadingBanners = false;
  }

  /// キャッシュからバナー広告を取得
  static BannerAd? getCachedBannerAd() {
    if (_bannerAdCache.isEmpty) return null;

    final ad = _bannerAdCache.removeAt(0);
    print('キャッシュからバナー広告を取得 (残り${_bannerAdCache.length}個)');

    // キャッシュが減ったら補充
    if (_bannerAdCache.length < 2 && !_isPreloadingBanners) {
      Future.delayed(const Duration(seconds: 1), _preloadBannerAds);
    }

    return ad;
  }

  /// キャッシュをクリア（メモリ解放用）
  static void clearCache() {
    for (final ad in _bannerAdCache) {
      ad.dispose();
    }
    _bannerAdCache.clear();
    print('バナー広告キャッシュをクリアしました');
  }
}
