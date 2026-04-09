import 'package:flutter/material.dart';
import '../firebase_database/firebase_db.dart';

class ManageBooks extends StatefulWidget {
  const ManageBooks({super.key});

  @override
  State<ManageBooks> createState() => _ManageBooksState();
}

class _ManageBooksState extends State<ManageBooks> {
  bool _loading = true;
  List<Map<String, dynamic>> _checkouts = [];

  @override
  void initState() {
    super.initState();
    _loadCheckouts();
  }

  Future<void> _loadCheckouts() async {
    final db = FirebaseDB.getReference();
    final checkouts = await db.getAllCheckouts();

    if (mounted) {
      setState(() {
        _checkouts = checkouts;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout Ledger'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _checkouts.isEmpty
          ? const Center(
        child: Text(
          "No books are currently checked out.",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: _checkouts.length,
        itemBuilder: (context, index) {
          final checkout = _checkouts[index];
          final title = checkout['fileName'].toString().replaceAll(".epub", "");
          final heroTag = 'checkout-${checkout['fileName']}-$index';

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: Hero(
                tag: '$heroTag-icon',
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3949AB).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.book_rounded, color: Color(0xFF3949AB)),
                ),
              ),
              title: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold)
              ),
              subtitle: Text("Due: ${checkout['checkoutExpiry']}"),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CheckoutDetailsPage(
                      checkout: checkout,
                      heroTag: heroTag,
                      title: title,
                      onReturned: _loadCheckouts, // Trigger a refresh when returned
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ── Hero Target Detail Page ────────────────────────────────────────────────

class CheckoutDetailsPage extends StatelessWidget {
  final Map<String, dynamic> checkout;
  final String heroTag;
  final String title;
  final VoidCallback onReturned;

  const CheckoutDetailsPage({
    super.key,
    required this.checkout,
    required this.heroTag,
    required this.title,
    required this.onReturned,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 30),

            Hero(
              tag: '$heroTag-icon',
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: const Color(0xFF3949AB).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.book_rounded, size: 80, color: Color(0xFF3949AB)),
              ),
            ),

            const SizedBox(height: 32),

            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    _buildInfoRow(Icons.person, "Checked out by", checkout['username']),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Divider(height: 1),
                    ),
                    _buildInfoRow(Icons.calendar_today, "Return Date", checkout['checkoutExpiry']),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            // ── NEW: Force Return Button ────────────────────────────────────
            ElevatedButton.icon(
              onPressed: () async {
                // Show a quick confirmation dialog to prevent accidental yanks
                bool? confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Force Return Book?"),
                    content: Text("This will immediately yank '$title' from ${checkout['username']}'s basket and make it available for anyone to check out."),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text("Force Return"),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  final db = FirebaseDB.getReference();
                  await db.forceReturnBook(checkout['fileName'].toString());

                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Successfully force returned $title'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );

                  onReturned(); // Triggers the Ledger list to refresh
                  Navigator.pop(context); // Dismiss the Hero page
                }
              },
              icon: const Icon(Icons.assignment_return_rounded),
              label: const Text('Force Return', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade50,
                foregroundColor: Colors.red.shade700,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 28),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  label,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13)
              ),
              const SizedBox(height: 4),
              Text(
                  value,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)
              ),
            ],
          ),
        )
      ],
    );
  }
}