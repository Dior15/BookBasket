import 'package:flutter/material.dart';

/// ------------------------------
/// REPORT MODEL
/// ------------------------------
class Report {
  String userName;
  String issue;
  String? bookTitle;
  String status; // "Pending" or "Resolved"

  Report({
    required this.userName,
    required this.issue,
    this.bookTitle,
    required this.status,
  });
}

/// ------------------------------
/// SHARED REPORT STORE (UI ONLY)
/// ------------------------------
class ReportStore {
  static List<Report> reports = [
    Report(
      userName: "John Doe",
      issue: "EPUB file not loading",
      bookTitle: "Flutter Basics",
      status: "Pending",
    ),
    Report(
      userName: "Sarah Smith",
      issue: "Cannot login to account",
      status: "Resolved",
    ),
    Report(
      userName: "Alex Brown",
      issue: "Book not appearing in basket",
      bookTitle: "Advanced Dart",
      status: "Pending",
    ),
  ];
}

/// ------------------------------
/// REPORTS PAGE
/// ------------------------------
class Reports extends StatefulWidget {
  const Reports({super.key});

  @override
  State<Reports> createState() => _ReportsState();
}

class _ReportsState extends State<Reports> {
  String selectedFilter = "All";

  List<Report> get filteredReports {
    if (selectedFilter == "All") {
      return ReportStore.reports;
    }
    return ReportStore.reports
        .where((r) => r.status == selectedFilter)
        .toList();
  }

  void _toggleStatus(int index) {
    setState(() {
      final report = filteredReports[index];
      report.status =
      report.status == "Pending" ? "Resolved" : "Pending";
    });
  }

  Color _statusColor(String status) {
    return status == "Pending" ? Colors.orange : Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reports & Issues"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Text(
                'Reports & Issues',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),

          /// ------------------------------
          /// FILTER BUTTONS
          /// ------------------------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ["All", "Pending", "Resolved"].map((filter) {
                return ChoiceChip(
                  label: Text(filter),
                  selected: selectedFilter == filter,
                  onSelected: (_) {
                    setState(() {
                      selectedFilter = filter;
                    });
                  },
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          /// ------------------------------
          /// REPORT LIST
          /// ------------------------------
          Expanded(
            child: ListView.builder(
              itemCount: filteredReports.length,
              itemBuilder: (context, index) {
                final report = filteredReports[index];

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  child: ListTile(
                    isThreeLine: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3949AB).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.report_problem_rounded, color: Color(0xFF3949AB)),
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            report.issue,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _statusColor(report.status),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            report.status,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text("User: ${report.userName}"),
                        if (report.bookTitle != null)
                          Text("Book: ${report.bookTitle}"),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.check_circle_outline_rounded),
                      onPressed: () => _toggleStatus(index),
                      tooltip: 'Mark as Resolved/Pending',
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
