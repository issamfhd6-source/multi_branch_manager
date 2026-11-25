import 'package:flutter/material.dart';

import '../../../core/utils/dual_syp_formatter.dart';
import '../../../core/utils/safe_number_parser.dart';

class InsightsAndCalcScreen extends StatefulWidget {
  const InsightsAndCalcScreen({super.key});

  @override
  State<InsightsAndCalcScreen> createState() => _InsightsAndCalcScreenState();
}

class _InsightsAndCalcScreenState extends State<InsightsAndCalcScreen> {
  final _newSypCtrl = TextEditingController(text: '100');
  final _oldSypCtrl = TextEditingController();
  final _costNewCtrl = TextEditingController(text: '0');
  final _sellNewCtrl = TextEditingController(text: '0');

  @override
  void dispose() {
    _newSypCtrl.dispose();
    _oldSypCtrl.dispose();
    _costNewCtrl.dispose();
    _sellNewCtrl.dispose();
    super.dispose();
  }

  void _onNewSypChanged(String val) {
    final parsed = SafeNumberParser.parseDouble(val, fallback: 0);
    final oldVal = DualSypFormatter.newToOld(parsed);
    _oldSypCtrl.text = oldVal == 0 ? '' : oldVal.toStringAsFixed(0);
    setState(() {});
  }

  void _onOldSypChanged(String val) {
    final parsed = SafeNumberParser.parseDouble(val, fallback: 0);
    final newVal = DualSypFormatter.oldToNew(parsed);
    _newSypCtrl.text = newVal == 0 ? '' : newVal.toStringAsFixed(2);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final currentNew = SafeNumberParser.parseDouble(_newSypCtrl.text, fallback: 0);
    final costNew = SafeNumberParser.parseDouble(_costNewCtrl.text, fallback: 0);
    final sellNew = SafeNumberParser.parseDouble(_sellNewCtrl.text, fallback: 0);
    final marginNew = sellNew - costNew;

    return Scaffold(
      appBar: AppBar(
        title: const Text('التحليلات وحاسبة الليرة المزدوجة'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'محوّل الليرة السورية (الجديدة ↔ القديمة بنسبة 1:100)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _newSypCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'القيمة بالليرة الجديدة',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: _onNewSypChanged,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _oldSypCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'القيمة بالليرة القديمة (×100)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: _onOldSypChanged,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'النتيجة المزدوجة: ${DualSypFormatter.formatDualFromNew(currentNew)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'حاسبة هامش الربح للوحدة',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _costNewCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'التكلفة (ل.س جديدة)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _sellNewCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'سعر البيع (ل.س جديدة)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'صافي الهامش: ${DualSypFormatter.formatDualFromNew(marginNew)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
