const bool _isProd = bool.fromEnvironment('dart.vm.product');

final String kBaseUrl    = _isProd ? 'https://julius-clinic.bnr.la/api'         : 'http://localhost:8080/api';
final String kWsUrl      = _isProd ? 'wss://julius-clinic.bnr.la/ws'            : 'ws://localhost:8080/ws';
final String kUploadsUrl = _isProd ? 'https://julius-clinic.bnr.la/api/uploads' : 'http://localhost:8080/api/uploads';
