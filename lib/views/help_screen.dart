import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ヘルプ'), backgroundColor: Theme.of(context).colorScheme.inversePrimary),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(context, icon: Icons.info_outline, title: 'できたカレンダーとは', content: '習慣を継続して、バッジを獲得しながら成長を記録するアプリです。'),
          const SizedBox(height: 24),
          _buildSection(context, icon: Icons.home, title: 'ホーム画面', content: '今日実施する習慣の一覧が表示されます。タップして完了マークをつけましょう。'),
          const SizedBox(height: 16),
          _buildSection(context, icon: Icons.calendar_month, title: 'カレンダー画面', content: '過去の実施記録をカレンダー形式で確認できます。連続記録や達成率も見られます。'),
          const SizedBox(height: 16),
          _buildSection(context, icon: Icons.bar_chart, title: '統計画面', content: '習慣の達成状況を統計データで確認できます。'),
          const SizedBox(height: 16),
          _buildSection(context, icon: Icons.checklist, title: '管理画面', content: '登録している習慣の一覧を確認・編集できます。習慣の追加や削除もここから行えます。'),
          const SizedBox(height: 24),
          _buildSection(context, icon: Icons.add_circle_outline, title: '習慣の追加方法', content: '画面右下の＋ボタンをタップして、習慣名や実施頻度（毎日/特定の曜日）、通知時刻などを設定できます。'),
          const SizedBox(height: 24),
          _buildSection(
            context,
            icon: Icons.workspace_premium,
            title: 'バッジシステム',
            content: '習慣を継続すると、連続週数に応じてバッジを獲得できます。\n週の定義：日曜〜土曜\nその週に予定されている全ての習慣を完了すると週クリアです。\n\n・1週連続：ブロンズバッジ\n・2週連続：シルバーバッジ\n・4週連続：ゴールドバッジ\n・12週連続：プラチナバッジ\n・52週連続：ダイヤモンドバッジ',
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            icon: Icons.tips_and_updates,
            title: 'ヒント',
            content: '・ホーム画面の習慣カードを長押しすると編集画面を開けます\n・下に引っ張ると最新の情報に更新できます\n・通知を設定すると忘れずに実施できます',
          ),
          const SizedBox(height: 24),
          _buildContactSection(context),
          const SizedBox(height: 16),
          _buildPrivacyPolicySection(context),
          const SizedBox(height: 16),
          _buildVersionSection(context),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, {required IconData icon, required String title, required String content}) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(content, style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6)),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.email, color: Theme.of(context).colorScheme.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'お問い合わせ',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '不具合の報告や改善要望がございましたら、以下のメールアドレスまでお気軽にご連絡ください。',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _launchEmail(),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.mail_outline, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'fdks487351@yahoo.co.jp',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 16,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyPolicySection(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.privacy_tip, color: Theme.of(context).colorScheme.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'プライバシーポリシー',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'アプリのプライバシーポリシーをご確認いただけます。',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _launchPrivacyPolicy(),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.open_in_new, color: Colors.green[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'プライバシーポリシーを見る',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVersionSection(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: Theme.of(context).colorScheme.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'バージョン情報',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final info = snapshot.data!;
                  return Text(
                    'バージョン: ${info.version}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  );
                } else {
                  return const Text('読み込み中...');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'fdks487351@yahoo.co.jp',
      query: 'subject=できたカレンダーについて',
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  Future<void> _launchPrivacyPolicy() async {
    final Uri url = Uri.parse('https://shi-takahashi.github.io/dekita_calendar/privacy-policy');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}
