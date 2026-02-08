import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:web/web.dart' as web;
import 'package:flutter/foundation.dart';
import 'supabase_client.dart';

const vapidPublicKey = String.fromEnvironment('VAPID_PUBLIC_KEY');

@JS('eval')
external JSFunction _eval(JSString code);

class PushNotificationService {
  static bool get isSupported {
    if (!kIsWeb) return false;
    try {
      return web.window.navigator.serviceWorker.isDefinedAndNotNull;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> requestPermission() async {
    if (!isSupported) return false;
    final result = await web.Notification.requestPermission().toDart;
    return result.toDart == 'granted';
  }

  static Future<bool> subscribe() async {
    if (!isSupported) return false;

    final granted = await requestPermission();
    if (!granted) return false;

    try {
      final registration = await web.window.navigator.serviceWorker
          .getRegistration('push-sw.js')
          .toDart;

      if (registration == null) return false;

      final applicationServerKey = _urlBase64ToUint8Array(vapidPublicKey);

      final subscription = await registration.pushManager
          .subscribe(
            web.PushSubscriptionOptionsInit(
              userVisibleOnly: true,
              applicationServerKey: applicationServerKey,
            ),
          )
          .toDart;

      await _saveSubscription(subscription);
      return true;
    } catch (e) {
      debugPrint('Push subscribe error: $e');
      return false;
    }
  }

  static Future<bool> isSubscribed() async {
    if (!isSupported) return false;
    try {
      final registration = await web.window.navigator.serviceWorker
          .getRegistration('push-sw.js')
          .toDart;
      if (registration == null) return false;
      final subscription =
          await registration.pushManager.getSubscription().toDart;
      return subscription != null;
    } catch (e) {
      return false;
    }
  }

  static Future<void> _saveSubscription(
      web.PushSubscription subscription) async {
    final client = SupabaseClientManager.client;
    final user = client.auth.currentUser;
    if (user == null) return;

    final userProfile = await client
        .from('users')
        .select('id')
        .eq('auth_id', user.id)
        .maybeSingle();

    if (userProfile == null) return;

    final endpoint = subscription.endpoint;

    // Get keys via toJSON() and JS interop
    final subJson = subscription.toJSON();
    final keysObj = (subJson as JSObject).getProperty('keys'.toJS) as JSObject;
    final p256dh =
        (keysObj.getProperty('p256dh'.toJS) as JSString).toDart;
    final auth =
        (keysObj.getProperty('auth'.toJS) as JSString).toDart;

    await client.from('push_subscriptions').upsert(
      {
        'user_id': userProfile['id'],
        'endpoint': endpoint,
        'p256dh_key': p256dh,
        'auth_key': auth,
      },
      onConflict: 'endpoint',
    );
  }

  static JSObject _urlBase64ToUint8Array(String base64String) {
    final padding = '=' * ((4 - base64String.length % 4) % 4);
    final base64 = (base64String + padding)
        .replaceAll('-', '+')
        .replaceAll('_', '/');

    final fn = _eval('''
      (function(b64) {
        var raw = atob(b64);
        var arr = new Uint8Array(raw.length);
        for (var i = 0; i < raw.length; ++i) arr[i] = raw.charCodeAt(i);
        return arr;
      })
    '''
        .toJS);
    return fn.callAsFunction(null, base64.toJS) as JSObject;
  }
}
