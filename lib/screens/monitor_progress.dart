import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:intl/intl.dart';

class MonitorProgress extends StatelessWidget {
  const MonitorProgress({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> weeklyGoals = [
      {
        "task": "Get 10 customers",
        "progress": 0.7, // 70% done
        "color": Colors.green,
      },
      {
        "task": "Create 5 new products",
        "progress": 0.4,
        "color": Colors.orange,
      },
      {
        "task": "Share new products on WhatsApp, TikTok, and Instagram",
        "progress": 0.5,
        "color": Colors.blue,
      },
      {
        "task": "Update the system",
        "progress": 0.3,
        "color": Colors.purple,
      },
      {
        "task": "Visit 10 stores to check product availability",
        "progress": 0.8,
        "color": Colors.teal,
      },
    ];

    // Calculate overall progress (average)
    double overallProgress = weeklyGoals
        .map((g) => g["progress"] as double)
        .reduce((a, b) => a + b) /
        weeklyGoals.length;

    // Calculate days left (assuming week ends on Friday)
    DateTime today = DateTime.now();
    DateTime weekEnd = today.add(Duration(days: 5 - today.weekday));
    int daysLeft = weekEnd.difference(today).inDays;

    String formattedEnd = DateFormat('EEEE, MMM d').format(weekEnd);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Weekly Progress"),
        backgroundColor: Colors.purple,
        elevation: 3,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🌟 Overall progress section
            Card(
              elevation: 4,
              color: Colors.purple.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Overall Weekly Progress",
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    LinearPercentIndicator(
                      lineHeight: 14,
                      percent: overallProgress,
                      backgroundColor: Colors.grey.shade300,
                      progressColor: Colors.purple,
                      barRadius: const Radius.circular(10),
                      animation: true,
                      animationDuration: 1000,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Total progress: ${(overallProgress * 100).toStringAsFixed(0)}%",
                      style:
                      const TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Days left: $daysLeft (until $formattedEnd)",
                      style: const TextStyle(
                          fontSize: 13, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 📋 List of goals
            Expanded(
              child: ListView.builder(
                itemCount: weeklyGoals.length,
                itemBuilder: (context, index) {
                  final goal = weeklyGoals[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            goal["task"],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 10),
                          LinearPercentIndicator(
                            lineHeight: 12.0,
                            percent: goal["progress"],
                            backgroundColor: Colors.grey.shade300,
                            progressColor: goal["color"],
                            barRadius: const Radius.circular(10),
                            animation: true,
                            animationDuration: 800,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "${(goal["progress"] * 100).toStringAsFixed(0)}% completed",
                            style: const TextStyle(
                                fontSize: 13, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
