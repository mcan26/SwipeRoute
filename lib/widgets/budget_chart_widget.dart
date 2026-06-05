import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class BudgetChartWidget extends StatelessWidget {
  final Map<String, double> budgetData;

  const BudgetChartWidget({super.key, required this.budgetData});

  @override
  Widget build(BuildContext context) {
    if (budgetData.isEmpty) {
      return const SizedBox.shrink();
    }

    final double total = budgetData.values.fold(0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();

    final List<Color> colors = [
      const Color(0xFFFE3C72),
      Colors.blueAccent,
      Colors.amber,
      Colors.purpleAccent,
      Colors.greenAccent,
    ];

    int colorIndex = 0;
    final List<PieChartSectionData> sections = budgetData.entries.map((entry) {
      final value = entry.value;
      final percentage = (value / total) * 100;
      final color = colors[colorIndex % colors.length];
      colorIndex++;

      return PieChartSectionData(
        color: color,
        value: value,
        title: '${percentage.toStringAsFixed(0)}%',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        children: [
          const Text(
            'Tahmini Bütçe Analizi',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Toplam: ₺${total.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Color(0xFFFE3C72),
              fontWeight: FontWeight.w900,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 160,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: sections,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: budgetData.entries.map((entry) {
              final idx = budgetData.keys.toList().indexOf(entry.key);
              final color = colors[idx % colors.length];
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${entry.key} (₺${entry.value.toStringAsFixed(0)})',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
