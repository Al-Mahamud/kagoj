import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final loginCookiesProvider = Provider((ref) => LoginCookies());

/// Keeps the user signed in to the ePaper sites across app restarts.
///
/// The papers keep the login in session cookies (such as ASP.NET_SessionId)
/// that have no expiry date, and the WebView throws those away whenever the
/// app process ends. This rewrites each session cookie with an expiry date so
/// it is stored on disk like any other cookie. A cookie the site deletes or
/// replaces is still deleted or replaced, because it keeps the same name,
/// domain and path.
class LoginCookies {
  LoginCookies({CookieManager? cookieManager})
      : _cookies = cookieManager ?? CookieManager.instance();

  final CookieManager _cookies;

  /// How long a kept cookie lives. It is pushed forward every time the
  /// paper is opened, so only a paper left unopened this long signs out.
  static const keepFor = Duration(days: 30);

  /// Makes the session cookies sent to each of [urls] persistent.
  Future<void> keep(Iterable<WebUri> urls) async {
    final expires = DateTime.now().add(keepFor).millisecondsSinceEpoch;
    for (final url in urls) {
      try {
        for (final cookie in await _cookies.getCookies(url: url)) {
          // Without cookie details (older Android WebViews) a session cookie
          // can't be told apart from a persistent one, so leave them alone.
          if (cookie.isSecure == null || cookie.expiresDate != null) continue;
          final domain = cookie.domain;
          await _cookies.setCookie(
            url: url,
            name: cookie.name,
            value: '${cookie.value}',
            path: cookie.path ?? '/',
            // Only domain cookies carry a leading dot; leaving the domain out
            // keeps a host-only cookie host-only instead of adding a copy.
            domain: domain != null && domain.startsWith('.') ? domain : null,
            expiresDate: expires,
            isSecure: cookie.isSecure,
            isHttpOnly: cookie.isHttpOnly,
            sameSite: cookie.sameSite,
          );
        }
      } catch (e) {
        debugPrint('Could not keep login cookies for $url: $e');
      }
    }
  }
}
