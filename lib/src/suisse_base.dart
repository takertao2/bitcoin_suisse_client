import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

const List<String> supportedCountries = ['CH'];

class Payment {
  String merchantNumber;
  String terminalNumber;
  int amount; // in cents, 100 = 1 EUR/CHF/...
  String description;
  String reference;
  String email;
  String fromCurrency;
  String toCurrency;
  Uri declineUrl;
  Uri acceptUrl;
  Uri callbackUrl;

  String hash;

  String toJson() {
    return json.encode({
      'Amount': amount,
      'TerminalNumber': terminalNumber,
      'MerchantNumber': merchantNumber,
      'Description': description,
      'Reference': reference,
      'Email': email,
      'FromCurrency': fromCurrency,
      'ToCurrency': toCurrency,
      'DeclineUrl': declineUrl,
      'AcceptUrl': acceptUrl,
      'CallbackUrl': callbackUrl,
      'Hash': hash,
    });
  }
}

class Client {
  Client(String url, this._secret)
      : _url = Uri.parse(url),
        _client = http.Client();

  final Uri _url;
  final String _secret;
  final http.Client _client;
  static const Map<String, String> _headers = {
    HttpHeaders.userAgentHeader: 'Bitcoin Suisse - Dart',
    HttpHeaders.contentTypeHeader: 'application/json',
  };

  Future<http.Response> getMerchant(String terminalNumber) async {
    var hash = _hash('$terminalNumber$_secret');
    return _client.post(
      _url.replace(path: '/api/GetMerchant'),
      body: json.encode({'Key': terminalNumber, 'Hash': hash}),
      headers: _headers,
    );
  }

  Future<http.Response> getPaymentRequest(String paymentNumber) async {
    var hash = _hash('$paymentNumber$_secret');
    return _client.post(
      _url.replace(path: '/api/GetPaymentRequest'),
      body: json.encode({'Key': paymentNumber, 'Hash': hash}),
      headers: _headers,
    );
  }

  Future<http.Response> createPayementRequest(Payment payment) async {
    var hash = _hash(
        '${payment.merchantNumber}${payment.terminalNumber}${payment.amount}${payment.fromCurrency}${payment.toCurrency}$_secret');
    payment.hash = hash;
    return _client.post(
      _url.replace(path: '/api/CreatePaymentRequest'),
      body: payment.toJson(),
      headers: _headers,
    );
  }

  Future<http.Response> isChanged(String key) async {
    return _client.get(
      _url.replace(path: '/api/isChanged', queryParameters: {'Key': key}),
      headers: _headers,
    );
  }

  String _hash(String input) {
    var bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }
}
