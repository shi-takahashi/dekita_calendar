import 'package:flutter/material.dart';

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
}
