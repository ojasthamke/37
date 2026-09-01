import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminPushService {
  static final AdminPushService instance = AdminPushService._();
  AdminPushService._();

  static const String _clientEmail = 'firebase-adminsdk-fbsvc@alibhaji-customers.iam.gserviceaccount.com';
  static const String _projectId = 'alibhaji-customers';
  static const String _privateKey = """-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDFhBm3/XNbpA9M
yHviRcGZyN3QzLi22tmui+ukIfsLWM9r7WUGvzo346HXixg8VS2VYlF3IPIUghGd
KsacEw4Tv9e9B2aXQbfp09fBY/7bLaPynEGCOpUlYDbJPHKMZ8jwtU9+RldtEfRB
EM6G2BW3EndHPceDThWuoc11aVHEaeFsPwA2jY6Q+3FbMfO7RIBEoFPEuhpKT4ay
qWmqfqlVkL4yjnK5d1DxM0hf9alw6ivJlF2KMAOki9GnP8snu5hNuXna75NsxGbl
cfoEpsY2hjiILXyNQRhoS4L1OaDdTef4Wg1C/WImzVx+9XNvlxvYLkaZXafAoLn4
YIJWgCzJAgMBAAECggEAF+EAclKFcPWqKzMXwG4vhDtDueZuNHPL78LBwnj14/7L
gOBVSkCx4KeNXZosMWsY1N/Aj+xJ6A8mOFU/aAdpDcaFO2Na1Kbg0wzwn371L6QF
F06AdaabI8bN3iayheVW5pGnonwNk3BMEoEI1EY+hdYJLpyPnivBX6NMdsk8q0ft
Ag927r6DH3btA2QBLy7douzioor8ro8n/kW4aDLia3+/OVk/CHpYtE/rINxIqm3q
PqSJlAEL1X81m7pBojfUxI1hqGg2cx7blzifoZnYLzOri9oYKVIv+7Wj+PB6cQNx
B+ce1nCoVPbUXfIy5XGIGYP4pvOxGT0ID2145VyIAwKBgQD7AW1sPqZz64pSjy1M
KEMtC/sJSfkHtNvf0hzJgYJp95YXrW8HmHEgaeR1OtDUH87qeWa3yCSNlFEQB7y8
nljKfmBkHMsExX2y/kvVYT4aAPAdzOoPS1p4PaT0Wk0riGGU0aqKJCnAs7m5KJuk
hpqvR5BcMBg211QczMl8q9nYywKBgQDJcjU1AyuJRwu0Tt52HKJ9R6cx/vmN9ZBj
46/yHimpRfeXBi0s+8/dWe3zGgxR1XlMqFrU6z9GqEqNfK+QNwXQuL36VZMckjMu
NKeOWxVBIEWJOKZYKVmU0BdxgzWg/nbrILFJcG0xWxCfWq8EAIrmgKR64kXlrBrP
CCOayLjiOwKBgFZ6KGvZrdlUNiS5hV6upG45qXSK0sxv6CzVo+tcvkSp80EXFKCm
SZtkQDyPVfEvQEeSKex5fPZ2OfNu5vyJBYhGQAldzihHrkXjzNaoGRA2cIOj3KQG
TxYMDu/MyLeN1ijCj6HmUag9g2gicHUflt16p2bLfxwt1aHSgDx+rKA/AoGBAJk0
BIcmvAuRPrOIb+O/70v8HIoHcl+mbIOre/pVOjYEgkIXbnARqoqbhD4oh0oNYk0M
lNfteZgREXH9a7/wOLn+Zm1me5V1EvuHDA9V8hovovKzZL8T448rm0i3Eyg3ntU/
bdV+bWzl5wRqgUQ37WtUVsMmJyZ+93yQohNrqEBVAoGARlFbA+8GRiAcFNPbS8VC
wHc8VnWwJt1T3zeR8iJDrWIJ+iaGzjmenY84szJeiP6sJGUg91uC2cygIl4jsOiT
FaZSz1Ba1MgfgtF3Km9fV2fAJWdKtlD4R3oHfE9mdkUNWiPkssaxMaVIkFD8389J
MLv59suZ2ePGGJizLeScuGI=
-----END PRIVATE KEY-----""";

  String? _cachedAccessToken;
  DateTime? _tokenExpiry;

  Future<String> _getAccessToken() async {
    if (_cachedAccessToken != null && _tokenExpiry != null && DateTime.now().isBefore(_tokenExpiry!)) {
      return _cachedAccessToken!;
    }

    final jwt = JWT(
      {
        'iss': _clientEmail,
        'scope': 'https://www.googleapis.com/auth/firebase.messaging',
        'aud': 'https://oauth2.googleapis.com/token',
      },
    );

    final pemKey = RSAPrivateKey(_privateKey);
    final token = jwt.sign(pemKey, algorithm: JWTAlgorithm.RS256, expiresIn: const Duration(hours: 1));

    final res = await http.post(
      Uri.parse('https://oauth2.googleapis.com/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        'assertion': token,
      },
    );

    if (res.statusCode != 200) {
      throw Exception('OAuth2 token error: ${res.statusCode} ${res.body}');
    }

    final data = jsonDecode(res.body);
    _cachedAccessToken = data['access_token'] as String;
    _tokenExpiry = DateTime.now().add(const Duration(minutes: 50));
    return _cachedAccessToken!;
  }

  Future<bool> sendDirectPush({
    String? targetToken,
    String? topic,
    required String title,
    required String body,
    String? payload,
    String? channelId,
  }) async {
    try {
      final accessToken = await _getAccessToken();
      final fcmUrl = Uri.parse('https://fcm.googleapis.com/v1/projects/$_projectId/messages:send');

      final targetKey = (targetToken != null && targetToken.isNotEmpty) ? 'token' : 'topic';
      final targetValue = (targetToken != null && targetToken.isNotEmpty) ? targetToken : (topic ?? 'all_customers');

      final messagePayload = {
        'message': {
          targetKey: targetValue,
          'notification': {
            'title': title,
            'body': body,
          },
          'data': {
            'title': title,
            'body': body,
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'payload': payload ?? '',
            'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
          },
          'android': {
            'priority': 'high',
            'ttl': '86400s',
            'notification': {
              'channel_id': channelId ?? 'aplibhaji_customer_channel',
              'sound': 'default',
              'default_sound': true,
              'default_vibrate_timings': true,
              'notification_priority': 'PRIORITY_MAX',
              'visibility': 'PUBLIC',
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            },
          },
          'apns': {
            'headers': {
              'apns-priority': '10',
            },
            'payload': {
              'aps': {
                'alert': {
                  'title': title,
                  'body': body,
                },
                'sound': 'default',
                'badge': 1,
                'content-available': 1,
              },
            },
          },
        },
      };

      final response = await http.post(
        fcmUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(messagePayload),
      );

      debugPrint('AdminPushService: FCM push to $targetValue -> Status ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('AdminPushService: sendDirectPush error: $e');
      return false;
    }
  }

  /// Broadcasts to topic 'all_customers' cleanly without duplication
  Future<void> broadcastToAllCustomers({
    required String title,
    required String body,
    String? payload,
  }) async {
    // Send single high-priority push to FCM topic 'all_customers'
    await sendDirectPush(
      topic: 'all_customers',
      title: title,
      body: body,
      payload: payload,
    );
  }

  /// Sends targeted push notification for a specific customer
  Future<void> sendToCustomer({
    required String customerId,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      final client = Supabase.instance.client;
      var cust = await client
          .from('customers')
          .select('fcm_token')
          .eq('id', customerId)
          .maybeSingle();

      if (cust == null || cust['fcm_token'] == null) {
        cust = await client
            .from('customers')
            .select('fcm_token')
            .eq('auth_user_id', customerId)
            .maybeSingle();
      }

      final token = cust?['fcm_token']?.toString();
      if (token != null && token.isNotEmpty) {
        await sendDirectPush(
          targetToken: token,
          title: title,
          body: body,
          payload: payload,
        );
      } else {
        // Fallback to topic broadcast if no specific token found
        await sendDirectPush(
          topic: 'all_customers',
          title: title,
          body: body,
          payload: payload,
        );
      }
    } catch (e) {
      debugPrint('AdminPushService: sendToCustomer error: $e');
    }
  }

  /// Sends push when order status is updated
  Future<void> sendOrderStatusPush({
    required String customerId,
    required String orderNo,
    required String status,
  }) async {
    String title;
    String body;

    switch (status.toLowerCase()) {
      case 'confirmed':
        title = 'Order Confirmed! 🛍️';
        body = 'Your order #$orderNo has been confirmed and is being prepared.';
        break;
      case 'out for delivery':
        title = 'Order Out for Delivery! 🚚';
        body = 'Your fresh order #$orderNo is on its way to your delivery address!';
        break;
      case 'delivered':
        title = 'Order Delivered! 🎉';
        body = 'Your order #$orderNo has been delivered. Enjoy your fresh harvest!';
        break;
      case 'cancelled':
        title = 'Order Cancelled';
        body = 'Your order #$orderNo has been cancelled.';
        break;
      default:
        title = 'Order Status Updated';
        body = 'Your order #$orderNo is now: $status';
    }

    await sendToCustomer(
      customerId: customerId,
      title: title,
      body: body,
      payload: 'order_$orderNo',
    );
  }
}
