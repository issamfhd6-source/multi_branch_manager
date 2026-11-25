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
  bool _loading = false;
  String? _exportedCsv;
  List<dynamic> _race = [];

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _loading = true);
    try {
      await widget.reportsService.buildSalesSummary(
        session: widget.session,
        branchId: widget.branchId,
      );
      if (!mounted) return;
      setState(() {
        _race = [];
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تحميل التقارير: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _exportCsv() async {
    final buffer = StringBuffer()
      ..writeln('branch_id,invoices_count,sales_new_syp,profit_new_syp');
    for (final entry in _race) {
      final dynamic item = entry;
      buffer.writeln(
        '${item?.branchId ?? ''},'
        '${item?.invoiceCount ?? 0},'
        '${item?.salesNewSyp ?? 0},'
        '${item?.profitNewSyp ?? 0}',
      );
    }
    setState(() => _exportedCsv = buffer.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('التقارير'),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            onPressed: _loading ? null : _loadReports,
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
                    (entry) {
                      final dynamic item = entry;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: CircleAvatar(child: Text('#${item?.rank ?? ''}')),
                          title: Text('الفرع: ${item?.branchId ?? ''}'),
                          subtitle: Text(
                            'الفواتير: ${item?.invoiceCount ?? 0}\n'
                            'المبيعات: ${DualSypFormatter.formatDualFromNew(item?.salesNewSyp ?? 0)}\n'
                            'الربح: ${DualSypFormatter.formatDualFromNew(item?.profitNewSyp ?? 0)}',
                          ),
                        ),
                      );
                    },
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
