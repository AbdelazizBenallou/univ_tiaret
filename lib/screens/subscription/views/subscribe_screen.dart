import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:univ_tiaret/components/bottom_sheet_selector.dart';
import 'package:univ_tiaret/constants.dart';
import 'package:univ_tiaret/l10n/app_localizations.dart';
import 'package:univ_tiaret/logic/auth_provider.dart';
import 'package:univ_tiaret/logic/subscription_provider.dart';
import 'package:univ_tiaret/models/semester.dart';
import 'package:univ_tiaret/logic/semesters_provider.dart';

class SubscribeScreen extends ConsumerStatefulWidget {
  const SubscribeScreen({super.key});

  @override
  ConsumerState<SubscribeScreen> createState() => _SubscribeScreenState();
}

class _SubscribeScreenState extends ConsumerState<SubscribeScreen> {
  Semester? _selectedSemester;
  bool _initialLoadDone = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await ref.read(subscriptionProvider.notifier).loadAll();
    final user = ref.read(authProvider).user;
    if (user?.levelId != null) {
      ref.read(semestersProvider.notifier).fetchSemesters(levelId: user!.levelId!);
    }
    if (mounted) setState(() => _initialLoadDone = true);
  }

  Future<void> _pickSemester() async {
    final t = AppLocalizations.of(context);
    final semesters = ref.read(semestersProvider).semesters;
    if (semesters.isEmpty) return;

    final result = await showBottomSheetSelector<Semester>(
      context: context,
      items: semesters,
      title: t.translate('select_semester'),
      leadingIcon: Icons.date_range_rounded,
      selectedName: _selectedSemester?.name,
      itemLabelBuilder: (s) => s.name,
    );
    if (result != null) setState(() => _selectedSemester = result);
  }

  Future<void> _submitDemand() async {
    final t = AppLocalizations.of(context);
    final user = ref.read(authProvider).user;

    if (_selectedSemester == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.translate('select_semester'))),
      );
      return;
    }

    final specialityId = user?.specialityId;
    if (specialityId == null) return;

    final msg = await ref.read(subscriptionProvider.notifier).createDemand(
      semesterId: _selectedSemester!.id,
      specialityId: specialityId,
    );

    if (mounted) {
      if (msg == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.translate('demand_created'))),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final state = ref.watch(subscriptionProvider);
    final semestersState = ref.watch(semestersProvider);
    final user = ref.watch(authProvider).user;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(t.translate('manage_subscription'))),
      body: state.loading || !_initialLoadDone
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              children: [
                if (state.current != null)
                  _buildActiveCard(state.current!, t, isDark, colors)
                else
                  _buildNoSubscriptionCard(t, isDark, colors),

                if (state.current == null) ...[
                  const SizedBox(height: 12),
                  _buildDemandCard(state, t, isDark, colors),
                ],

                if (state.current == null && state.demands.every((d) => d.status != 'pending')) ...[
                  const SizedBox(height: 24),
                  _buildForm(state, semestersState, user, t, isDark, colors),
                ],
              ],
            ),
    );
  }

  Widget _buildActiveCard(dynamic sub, AppLocalizations t, bool isDark, ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(t.translate('current_subscription'), colors),
        Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.transparent : Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _infoTile(Icons.date_range_rounded, t.translate('semester'), sub.semesterName),
              _divider(isDark),
              _infoTile(Icons.star_rounded, t.translate('subscription_type'), sub.type.toString().toUpperCase()),
              _divider(isDark),
              if (sub.specialityName != null)
                _infoTile(Icons.book_rounded, t.translate('speciality_name'), sub.specialityName),
              if (sub.specialityName != null) _divider(isDark),
              _infoTile(Icons.calendar_today_rounded, t.translate('start_date'), _fmtDate(sub.startDate)),
              _divider(isDark),
              _infoTile(Icons.event_rounded, t.translate('end_date'), _fmtDate(sub.endDate)),
              if (sub.remainingDays != null) ...[
                _divider(isDark),
                _infoTile(Icons.timer_rounded, t.translate('remaining_days'), '${sub.remainingDays} ${t.translate('days')}'),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                t.translate('active').toUpperCase(),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.success, letterSpacing: 1),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNoSubscriptionCard(AppLocalizations t, bool isDark, ColorScheme colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.transparent : Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.card_membership_rounded, size: 32, color: AppColors.warning),
          ),
          const SizedBox(height: 16),
          Text(
            t.translate('no_subscription_title'),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colors.onSurface),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            t.translate('no_subscription_message'),
            style: TextStyle(fontSize: 13, color: colors.onSurface.withValues(alpha: 0.5)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDemandCard(dynamic state, AppLocalizations t, bool isDark, ColorScheme colors) {
    final pendingDemands = state.demands.where((d) => d.status == 'pending').toList();
    if (pendingDemands.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(t.translate('my_demands'), colors),
        ...pendingDemands.map((demand) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.transparent : Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _infoTile(Icons.date_range_rounded, t.translate('semester'), demand.semesterName),
              _divider(isDark),
              _infoTile(Icons.star_rounded, t.translate('subscription_type'), demand.type.toUpperCase()),
              _divider(isDark),
              if (demand.specialityName != null)
                _infoTile(Icons.book_rounded, t.translate('speciality_name'), demand.specialityName!),
              if (demand.specialityName != null) _divider(isDark),
              _infoTile(Icons.schedule_rounded, t.translate('requested_at'), _fmtDateTime(demand.requestedAt)),
              _divider(isDark),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        t.translate('pending').toUpperCase(),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.warning, letterSpacing: 0.5),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _fmtDateTime(demand.requestedAt),
                      style: TextStyle(fontSize: 11, color: colors.onSurface.withValues(alpha: 0.4)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildForm(dynamic state, dynamic semestersState, dynamic user, AppLocalizations t, bool isDark, ColorScheme colors) {
    final loadingSemesters = semestersState.loading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(t.translate('request_subscription'), colors),
        Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.transparent : Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              GestureDetector(
                onTap: loadingSemesters ? null : _pickSemester,
                child: InputDecorator(
                  decoration: InputDecoration(
                    prefixIcon: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Icon(Icons.date_range_rounded, size: 22,
                        color: colors.onSurface.withValues(alpha: 0.3)),
                    ),
                    suffixIcon: Padding(
                      padding: const EdgeInsetsDirectional.only(end: 12),
                      child: Icon(Icons.keyboard_arrow_down_rounded,
                        color: colors.onSurface.withValues(alpha: 0.4), size: 22),
                    ),
                    suffixIconConstraints: const BoxConstraints(maxHeight: 24, maxWidth: 36),
                    labelText: t.translate('select_semester'),
                  ),
                  child: Text(
                    _selectedSemester?.name ?? (loadingSemesters ? t.translate('loading') : ''),
                    style: TextStyle(
                      fontSize: 15,
                      color: _selectedSemester != null ? colors.onSurface : colors.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
              _divider(isDark),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.greenLight, AppColors.greenAccent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.greenAccent.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.star_rounded, size: 20, color: Colors.white),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.translate('subscription_type'), style: TextStyle(fontSize: 12, color: colors.onSurface.withValues(alpha: 0.5))),
                          const SizedBox(height: 2),
                          Text('PREMIUM', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colors.onSurface)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _divider(isDark),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.greenLight, AppColors.greenAccent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.greenAccent.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.book_rounded, size: 20, color: Colors.white),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.translate('speciality_name'), style: TextStyle(fontSize: 12, color: colors.onSurface.withValues(alpha: 0.5))),
                          const SizedBox(height: 2),
                          Text(
                            user?.specialityName ?? '-',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colors.onSurface),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: state.saving ? null : _submitDemand,
            child: state.saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(t.translate('request_subscription')),
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(String title, ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: colors.onSurface.withValues(alpha: 0.5),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _divider(bool isDark) {
    return Divider(
      height: 1,
      indent: 72,
      endIndent: 16,
      color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.greenLight, AppColors.greenAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.greenAccent.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, size: 20, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: colors.onSurface.withValues(alpha: 0.5)),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colors.onSurface),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime? dt) {
    if (dt == null) return '-';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  String _fmtDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
