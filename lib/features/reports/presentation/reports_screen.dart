import 'package:flutter/material.dart';

import '../../../core/utils/dual_syp_formatter.dart';
import '../../users/domain/auth_models.dart';
import '../data/reports_service.dart';

class ReportsScreen extends StatefulWidget {
  final ReportsService reportsService;
  final AuthSession session;
  final String branchId;

  const ReportsScreen({
    super.key,
    required this.reportsService,
    required this.session,
    required this.branchId,
  });

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _loading = true;
  List<BranchRaceEntry> _race = [];
  String? _exportedCsv;

  @override
  void initState() {
    super.initState();
    _loadRace();
  }

  Future<void> _loadRace() async {
    setState(() => _loading = true);
    try {
      final data = await widget.reportsService.getBranchRace(
        session: widget.session,
      );
      if (!mounted) return;
      setState(() {
        _race = data;
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _exportCsv() {
    final csv = widget.reportsService.exportBranchRaceCsv(_race);
    setState(() => _exportedCsv = csv);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم تجهيز نص التصدير CSV بنجاح.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('التقارير وسباق الفروع'),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            onPressed: _loadRace,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'تصدير CSV',
            onPressed: _exportCsv,
            icon: const Icon(Icons.download),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(14),
              children: [
                if (_race.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('لا توجد بيانات فروع مسجلة بعد.'),
                    ),
                  )
                else
                  ..._race.map(
                    (entry) => Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: CircleAvatar(child: Text('#${entry.rank}')),
                        title: Text('الفرع: ${entry.branchId}'),
                        subtitle: Text(
                          'الفواتير: ${entry.invoiceCount}\n'
                          'المبيعات: ${DualSypFormatter.formatDualFromNew(entry.salesNewSyp)}\n'
                          'الربح: ${DualSypFormatter.formatDualFromNew(entry.profitNewSyp)}',
                        ),
                      ),
                    ),
                  ),
                if (_exportedCsv != null) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'معاينة تصدير CSV:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  SelectableText(
                    _exportedCsv!,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ],
            ),
    );
  }
}
