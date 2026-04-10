import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_strings.dart';
import '../models/game_models.dart';
import '../services/fx_service.dart';
import '../services/notification_service.dart';
import '../state/game_store.dart';
import '../widgets/app_scope.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _startAmountCtrl;
  late TextEditingController _maxAmountCtrl;
  late TextEditingController _fxRateCtrl;

  bool _fxSavedCheckmark = false;
  bool _fxLoading = false;
  TimeOfDay? _reminderTime;

  late GameStore _store;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _store = AppScope.of(context);
    final s = _store.settings;
    final lang = s.languageCode;
    final start = s.startAmountMinorByLanguage[lang] ?? 500;
    final max = s.maxAmountMinorByLanguage[lang] ?? 100000000;
    _startAmountCtrl =
        TextEditingController(text: (start / 100).toStringAsFixed(2));
    _maxAmountCtrl =
        TextEditingController(text: (max / 100).toStringAsFixed(2));
    _fxRateCtrl = TextEditingController();
    _reminderTime =
        TimeOfDay(hour: s.reminderHour, minute: s.reminderMinute);
  }

  @override
  void dispose() {
    _startAmountCtrl.dispose();
    _maxAmountCtrl.dispose();
    _fxRateCtrl.dispose();
    super.dispose();
  }

  String get _currency =>
      _store.settings.currencyByLanguage[_store.settings.languageCode] ?? 'USD';

  void _saveLimits() {
    final start = _parseAmount(_startAmountCtrl.text);
    final max = _parseAmount(_maxAmountCtrl.text);
    if (start == null || max == null) return;
    final lang = _store.settings.languageCode;
    final newStart = Map<String, int>.from(
        _store.settings.startAmountMinorByLanguage)
      ..[lang] = start;
    final newMax =
        Map<String, int>.from(_store.settings.maxAmountMinorByLanguage)
          ..[lang] = max;
    _store.updateSettings(_store.settings.copyWith(
      startAmountMinorByLanguage: newStart,
      maxAmountMinorByLanguage: newMax,
    ));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Limits saved'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  int? _parseAmount(String text) {
    final val = double.tryParse(text.replaceAll(',', '.'));
    if (val == null || val <= 0) return null;
    return (val * 100).round();
  }

  void _updateFxManually() {
    final rate = double.tryParse(_fxRateCtrl.text.replaceAll(',', '.'));
    if (rate == null || rate <= 0) return;
    // Update the from→to pair for current currency
    final currency = _currency;
    final newTable =
        Map<String, double>.from(_store.settings.approxFxTable);
    // Update all pairs involving this currency (simplified: update one direction)
    newTable['USD_$currency'] = rate;
    if (rate != 0) newTable['${currency}_USD'] = 1 / rate;
    _store.updateSettings(_store.settings.copyWith(approxFxTable: newTable));
    setState(() {
      _fxSavedCheckmark = true;
      _fxRateCtrl.clear();
    });
    Future.delayed(const Duration(seconds: 2),
        () => mounted ? setState(() => _fxSavedCheckmark = false) : null);
  }

  Future<void> _fetchLiveFx() async {
    final currency = _currency;
    if (currency == 'USD') return;
    setState(() => _fxLoading = true);
    final rate = await LiveFxService.fetchRate('USD', currency);
    if (!mounted) return;
    setState(() => _fxLoading = false);
    if (rate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch rate')),
      );
      return;
    }
    final newTable =
        Map<String, double>.from(_store.settings.approxFxTable);
    newTable['USD_$currency'] = rate;
    newTable['${currency}_USD'] = 1 / rate;
    _store.updateSettings(_store.settings.copyWith(approxFxTable: newTable));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Rate updated: 1 USD = ${rate.toStringAsFixed(4)} $currency'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _toggleNotifications(bool value) async {
    if (value) {
      final granted = await NotificationService.instance.requestPermission();
      if (!mounted) return;
      if (!granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification permission denied')),
        );
        return;
      }
      await _scheduleReminder();
    } else {
      await NotificationService.instance.cancelReminder();
    }
    if (!mounted) return;
    _store.updateSettings(_store.settings.copyWith(notificationsEnabled: value));
  }

  Future<void> _scheduleReminder() async {
    final t = _reminderTime!;
    final s = _store.settings;
    await NotificationService.instance.scheduleDailyReminder(
      hour: t.hour,
      minute: t.minute,
      title: 'DreamSpend',
      body: "Don't forget to track your spending today!",
    );
    _store.updateSettings(
        s.copyWith(reminderHour: t.hour, reminderMinute: t.minute));
  }

  Future<void> _pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime!,
    );
    if (picked != null) {
      setState(() => _reminderTime = picked);
      if (_store.settings.notificationsEnabled) {
        await _scheduleReminder();
      }
    }
  }

  Future<void> _confirmReset(BuildContext context, AppStrings s) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.t('resetTitle')),
        content: Text(s.t('resetConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.t('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.t('reset')),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _store.restartGame();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final store = AppScope.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text(s.t('settings'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle(context, s.t('language')),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'en', label: Text('EN')),
              ButtonSegment(value: 'ru', label: Text('RU')),
              ButtonSegment(value: 'de', label: Text('DE')),
            ],
            selected: {store.settings.languageCode},
            onSelectionChanged: (value) {
              store.switchLanguage(value.first);
              final lang = value.first;
              final start =
                  store.settings.startAmountMinorByLanguage[lang] ?? 500;
              final max =
                  store.settings.maxAmountMinorByLanguage[lang] ?? 100000000;
              setState(() {
                _startAmountCtrl.text = (start / 100).toStringAsFixed(2);
                _maxAmountCtrl.text = (max / 100).toStringAsFixed(2);
              });
            },
          ),

          const SizedBox(height: 24),
          _sectionTitle(context, s.t('limits')),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _startAmountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  decoration: InputDecoration(
                    labelText: s.t('startAmount'),
                    suffixText: _currency,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _maxAmountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  decoration: InputDecoration(
                    labelText: s.t('maxAmount'),
                    suffixText: _currency,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: _saveLimits,
              child: Text(s.t('save')),
            ),
          ),

          const SizedBox(height: 24),
          _sectionTitle(context, s.t('maxBehavior')),
          const SizedBox(height: 4),
          RadioListTile<MaxBehavior>(
            value: MaxBehavior.reset,
            groupValue: store.settings.maxBehavior,
            onChanged: (v) => store.updateMaxBehavior(v!),
            title: Text(s.t('reset')),
            contentPadding: EdgeInsets.zero,
          ),
          RadioListTile<MaxBehavior>(
            value: MaxBehavior.cap,
            groupValue: store.settings.maxBehavior,
            onChanged: (v) => store.updateMaxBehavior(v!),
            title: Text(s.t('cap')),
            contentPadding: EdgeInsets.zero,
          ),
          Text(
            store.settings.maxBehavior == MaxBehavior.reset
                ? s.t('maxBehaviorResetHint')
                : s.t('maxBehaviorCapHint'),
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.black45),
          ),

          const SizedBox(height: 24),
          _sectionTitle(context, s.t('fxRate')),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _fxRateCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  decoration: InputDecoration(
                    labelText: 'USD → $_currency',
                    hintText: s.t('manualRate'),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _fxSavedCheckmark
                    ? Container(
                        key: const ValueKey('check'),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, color: Colors.green),
                      )
                    : FilledButton(
                        key: const ValueKey('update'),
                        onPressed: _updateFxManually,
                        child: Text(s.t('update')),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _fxLoading ? null : _fetchLiveFx,
            icon: _fxLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cloud_download_outlined, size: 18),
            label: Text(s.t('fetchLiveRate')),
          ),

          const SizedBox(height: 24),
          _sectionTitle(context, s.t('notifications')),
          const SizedBox(height: 4),
          SwitchListTile(
            value: store.settings.notificationsEnabled,
            onChanged: _toggleNotifications,
            title: Text(s.t('enableNotifications')),
            contentPadding: EdgeInsets.zero,
          ),
          if (store.settings.notificationsEnabled)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(s.t('reminderTime')),
              trailing: TextButton(
                onPressed: () => _pickTime(context),
                child: Text(
                  _reminderTime!.format(context),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),

          const SizedBox(height: 24),
          _sectionTitle(context, s.t('onboarding')),
          const SizedBox(height: 4),
          Center(
            child: TextButton.icon(
              onPressed: () {
                store.updateOnboardingShown(false);
                context.go('/onboarding');
              },
              icon: const Icon(Icons.replay_rounded, size: 18),
              label: Text(s.t('replayOnboarding')),
            ),
          ),

          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.t('dangerZone'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red.shade300),
                    ),
                    onPressed: () => _confirmReset(context, s),
                    child: Text(s.t('resetAll')),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) => Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.bold),
      );
}
