class ServerConfigModel {
  final String ip;
  final int port;

  ServerConfigModel({required this.ip, required this.port});

  String get baseUrl => "http://$ip:$port";

  factory ServerConfigModel.fromJson(Map<String, dynamic> json) {
    return ServerConfigModel(
      ip: json['ip'] ?? '127.0.0.1',
      port: json['port'] ?? 3000,
    );
  }

  Map<String, dynamic> toJson() => {'ip': ip, 'port': port};
}
