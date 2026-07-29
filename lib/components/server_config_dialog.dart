import 'package:flutter/material.dart';

import 'package:univ_tiaret/components/floating_snackbar.dart';
import 'package:univ_tiaret/constants.dart';
import 'package:univ_tiaret/l10n/app_localizations.dart';
import 'package:univ_tiaret/services/api_service.dart';
import 'package:univ_tiaret/services/server_config_service.dart';

class ServerConfigDialog extends StatefulWidget {
  final String initialIp;
  final String initialPort;

  const ServerConfigDialog({
    super.key,
    this.initialIp = '127.0.0.1',
    this.initialPort = '3000',
  });

  static Future<void> show(BuildContext context) async {
    final ip = await ServerConfigService.getIp();
    final port = await ServerConfigService.getPort();
    if (!context.mounted) return;
    return showDialog(
      context: context,
      builder: (_) => ServerConfigDialog(
        initialIp: ip,
        initialPort: port.toString(),
      ),
    );
  }

  @override
  State<ServerConfigDialog> createState() => _ServerConfigDialogState();
}

class _ServerConfigDialogState extends State<ServerConfigDialog> {
  late TextEditingController _ipController;
  late TextEditingController _portController;
  bool _checking = false;
  String? _statusMessage;
  bool? _statusSuccess;

  @override
  void initState() {
    super.initState();
    _ipController = TextEditingController(text: widget.initialIp);
    _portController = TextEditingController(text: widget.initialPort);
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  Future<void> _checkHealth() async {
    setState(() {
      _checking = true;
      _statusMessage = null;
      _statusSuccess = null;
    });

    final ip = _ipController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? 3000;
    ApiService.initialize('http://$ip:$port');

    final result = await ApiService.healthCheck();
    final t = AppLocalizations.of(context);

    if (!mounted) return;
    setState(() {
      _checking = false;
      _statusSuccess = result['success'] == true;
      _statusMessage = result['success'] == true
          ? t.translate('connected_success')
          : t.translate('err_connection_failed');
    });
  }

  Future<void> _save() async {
    final ip = _ipController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? 3000;
    await ServerConfigService.saveConfig(ip, port);
    if (!mounted) return;
    showFloatingSnackBar(
      context,
      message: AppLocalizations.of(context).translate('server_config_saved'),
      type: SnackBarType.success,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(defaultBorderRadious),
      ),
      title: Text(t.translate('server_config')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _ipController,
            decoration: InputDecoration(
              hintText: t.translate('server_ip'),
              prefixIcon: Padding(
                padding: EdgeInsets.symmetric(vertical: defaultPadding * 0.25),
                child: Icon(Icons.dns_rounded, size: 24),
              ),
            ),
          ),
          const SizedBox(height: defaultPadding),
          TextField(
            controller: _portController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: t.translate('port'),
              prefixIcon: Padding(
                padding: EdgeInsets.symmetric(vertical: defaultPadding * 0.25),
                child: Icon(Icons.tag_rounded, size: 24),
              ),
            ),
          ),
          const SizedBox(height: defaultPadding),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _checking ? null : _checkHealth,
              icon: _checking
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.wifi_rounded, size: 20),
              label: Text(_checking ? t.translate('checking') : t.translate('test_connection')),
            ),
          ),
          if (_statusMessage != null) ...[
            const SizedBox(height: defaultPadding / 2),
            Text(
              _statusMessage!,
              style: TextStyle(
                color: _statusSuccess == true ? successColor : errorColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(t.translate('cancel')),
        ),
        ElevatedButton(
          onPressed: _save,
          child: Text(t.translate('save')),
        ),
      ],
    );
  }
}
