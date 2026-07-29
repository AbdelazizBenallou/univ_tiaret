import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:univ_tiaret/constants.dart';
import 'package:univ_tiaret/l10n/app_localizations.dart';
import 'package:univ_tiaret/logic/auth_provider.dart';
import 'package:univ_tiaret/logic/subscription_provider.dart';
import 'package:univ_tiaret/logic/semesters_provider.dart';

class SubscribeScreen extends ConsumerStatefulWidget {
  const SubscribeScreen({super.key});

  @override
  ConsumerState<SubscribeScreen> createState() => _SubscribeScreenState();
}

class _SubscribeScreenState extends ConsumerState<SubscribeScreen> {
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

  String? get _currentSemesterName {
    final semesters = ref.read(semestersProvider).semesters;
    final current = semesters.where((s) => s.isCurrent).firstOrNull;
    return current?.name;
  }

  Future<void> _requestPremium() async {
    final t = AppLocalizations.of(context);
    final user = ref.read(authProvider).user;
    final semesters = ref.read(semestersProvider).semesters;
    final current = semesters.where((s) => s.isCurrent).firstOrNull;

    if (current == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.translate('no_current_semester'))),
      );
      return;
    }
    if (user?.specialityId == null) return;

    final msg = await ref.read(subscriptionProvider.notifier).createDemand(
      semesterId: current.id,
      specialityId: user!.specialityId!,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg ?? t.translate('demand_created'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final state = ref.watch(subscriptionProvider);
    final user = ref.watch(authProvider).user;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(t.translate('subscription'))),
      body: state.loading || !_initialLoadDone
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              children: [
                _SemesterCard(
                  semesterName: _currentSemesterName,
                  levelName: user?.levelName,
                  specialityName: user?.specialityName,
                  isDark: isDark,
                  colors: colors,
                ),
                const SizedBox(height: 20),
                _SubscriptionStatus(
                  current: state.current,
                  demands: state.demands,
                  loading: state.saving,
                  isDark: isDark,
                  colors: colors,
                  t: t,
                  onRequestPremium: _requestPremium,
                ),
                if (state.demands.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _DemandsList(
                    demands: state.demands,
                    isDark: isDark,
                    colors: colors,
                    t: t,
                  ),
                ],
              ],
            ),
    );
  }
}

class _SemesterCard extends StatelessWidget {
  final String? semesterName;
  final String? levelName;
  final String? specialityName;
  final bool isDark;
  final ColorScheme colors;

  const _SemesterCard({
    required this.semesterName,
    required this.levelName,
    required this.specialityName,
    required this.isDark,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.greenLight, AppColors.greenAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.greenAccent.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.school_rounded, size: 24, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        semesterName ?? '-',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        levelName ?? '',
                        style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.8)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'PREMIUM',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.8),
                  ),
                ),
              ],
            ),
            if (specialityName != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.book_rounded, size: 14, color: Colors.white.withValues(alpha: 0.8)),
                    const SizedBox(width: 6),
                    Text(
                      specialityName!,
                      style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.9)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SubscriptionStatus extends StatelessWidget {
  final dynamic current;
  final List<dynamic> demands;
  final bool loading;
  final bool isDark;
  final ColorScheme colors;
  final AppLocalizations t;
  final VoidCallback onRequestPremium;

  const _SubscriptionStatus({
    required this.current,
    required this.demands,
    required this.loading,
    required this.isDark,
    required this.colors,
    required this.t,
    required this.onRequestPremium,
  });

  @override
  Widget build(BuildContext context) {
    if (current != null) {
      return _buildActive();
    }

    final pending = demands.where((d) => d.status == 'pending').toList();
    if (pending.isNotEmpty) {
      return _buildPending(pending.first);
    }

    final rejected = demands.where((d) => d.status == 'rejected').toList();
    if (rejected.isNotEmpty) {
      return _buildRejected(rejected.last);
    }

    return _buildNoSubscription();
  }

  Widget _buildActive() {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.verified_rounded, size: 26, color: AppColors.success),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.translate('active_subscription'),
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: colors.onSurface),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${current.type?.toUpperCase() ?? ''} ${t.translate('subscription')}',
                        style: TextStyle(fontSize: 12, color: colors.onSurface.withValues(alpha: 0.5)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    t.translate('active').toUpperCase(),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.success, letterSpacing: 0.5),
                  ),
                ),
              ],
            ),
            if (current.remainingDays != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Text(
                      '${current.remainingDays}',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.greenAccent),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      t.translate('remaining_days').toLowerCase(),
                      style: TextStyle(fontSize: 13, color: colors.onSurface.withValues(alpha: 0.5)),
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(t.translate('end_date'), style: TextStyle(fontSize: 10, color: colors.onSurface.withValues(alpha: 0.4))),
                        const SizedBox(height: 2),
                        Text(
                          current.endDate != null ? _fmtDate(current.endDate) : '-',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.onSurface),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPending(dynamic demand) {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.hourglass_empty_rounded, size: 26, color: AppColors.warning),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.translate('pending_request'),
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: colors.onSurface),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${t.translate('requested_at')} ${_fmtDateTime(demand.requestedAt)}',
                        style: TextStyle(fontSize: 12, color: colors.onSurface.withValues(alpha: 0.5)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    t.translate('pending').toUpperCase(),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.warning, letterSpacing: 0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_rounded, size: 16, color: AppColors.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      t.translate('pending_message'),
                      style: TextStyle(fontSize: 12, color: AppColors.warning.withValues(alpha: 0.8)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRejected(dynamic demand) {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: errorColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.cancel_rounded, size: 26, color: errorColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.translate('request_rejected'),
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: colors.onSurface),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        t.translate('requested_at'),
                        style: TextStyle(fontSize: 12, color: colors.onSurface.withValues(alpha: 0.5)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: errorColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    t.translate('rejected').toUpperCase(),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: errorColor, letterSpacing: 0.5),
                  ),
                ),
              ],
            ),
            if (demand.adminNote != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: errorColor.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  demand.adminNote,
                  style: TextStyle(fontSize: 12, color: errorColor.withValues(alpha: 0.8)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNoSubscription() {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.card_membership_rounded, size: 28, color: AppColors.warning),
            ),
            const SizedBox(height: 14),
            Text(
              t.translate('no_subscription_title'),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: colors.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              t.translate('no_subscription_action'),
              style: TextStyle(fontSize: 13, color: colors.onSurface.withValues(alpha: 0.5)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: loading ? null : onRequestPremium,
                icon: loading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.star_rounded, size: 20),
                label: Text(t.translate('request_premium')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtDate(DateTime? dt) {
    if (dt == null) return '-';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  String _fmtDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _DemandsList extends StatelessWidget {
  final List<dynamic> demands;
  final bool isDark;
  final ColorScheme colors;
  final AppLocalizations t;

  const _DemandsList({
    required this.demands,
    required this.isDark,
    required this.colors,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            t.translate('history'),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: colors.onSurface.withValues(alpha: 0.5),
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...demands.map((demand) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _DemandTile(
            demand: demand,
            isDark: isDark,
            colors: colors,
            t: t,
          ),
        )),
      ],
    );
  }
}

class _DemandTile extends StatelessWidget {
  final dynamic demand;
  final bool isDark;
  final ColorScheme colors;
  final AppLocalizations t;

  const _DemandTile({
    required this.demand,
    required this.isDark,
    required this.colors,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (demand.status) {
      'pending' => AppColors.warning,
      'approved' => AppColors.success,
      'rejected' => errorColor,
      _ => colors.onSurface,
    };

    final statusBg = statusColor.withValues(alpha: 0.1);
    final statusText = t.translate(demand.status);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.transparent : Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                demand.status == 'pending'
                    ? Icons.hourglass_empty_rounded
                    : demand.status == 'approved'
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded,
                size: 20,
                color: statusColor,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${t.translate('semester')} ${demand.semesterName ?? ''}',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.onSurface),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _fmtDateTime(demand.requestedAt),
                    style: TextStyle(fontSize: 11, color: colors.onSurface.withValues(alpha: 0.4)),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                statusText.toUpperCase(),
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor, letterSpacing: 0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
