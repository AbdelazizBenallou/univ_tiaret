import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:univ_tiaret/constants.dart';
import 'package:univ_tiaret/l10n/app_localizations.dart';
import 'package:univ_tiaret/logic/connectivity_provider.dart';
import 'package:univ_tiaret/logic/subscription_provider.dart';
import 'package:univ_tiaret/route/route_constants.dart';

class SubscriptionGuard extends ConsumerStatefulWidget {
  final Widget child;

  const SubscriptionGuard({super.key, required this.child});

  @override
  ConsumerState<SubscriptionGuard> createState() => _SubscriptionGuardState();
}

class _SubscriptionGuardState extends ConsumerState<SubscriptionGuard> {
  NetworkStatus _prevNetworkStatus = NetworkStatus.checking;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(subscriptionProvider);
    final networkStatus = ref.watch(connectivityProvider);

    if (!state.loadedOnce && !state.loading) {
      Future.microtask(() => ref.read(subscriptionProvider.notifier).loadAll());
    }

    if (_prevNetworkStatus == NetworkStatus.offline &&
        networkStatus == NetworkStatus.online &&
        state.loadError) {
      Future.microtask(() => ref.read(subscriptionProvider.notifier).loadAll());
    }
    _prevNetworkStatus = networkStatus;

    if (state.loading || !state.loadedOnce) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.current != null) return widget.child;

    if (state.loadError) {
      return _OfflineView(
        onRetry: () => ref.read(subscriptionProvider.notifier).loadAll(),
      );
    }

    return const NoSubscriptionView();
  }
}

class _OfflineView extends StatelessWidget {
  final VoidCallback onRetry;

  const _OfflineView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final t = AppLocalizations.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                size: 40,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              t.translate('offline_title'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              t.translate('offline_message'),
              style: TextStyle(
                fontSize: 14,
                color: colors.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  t.translate('retry'),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NoSubscriptionView extends StatelessWidget {
  const NoSubscriptionView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final t = AppLocalizations.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_rounded,
                size: 40,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              t.translate('no_subscription_title'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              t.translate('no_subscription_message'),
              style: TextStyle(
                fontSize: 14,
                color: colors.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, subscribeScreenRoute),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  t.translate('subscribe_now'),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
