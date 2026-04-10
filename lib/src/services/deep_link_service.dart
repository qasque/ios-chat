import 'dart:async';

import 'package:app_links/app_links.dart';

class DeepLinkService {
  final _appLinks = AppLinks();

  StreamSubscription<Uri>? subscribe(void Function(Uri uri) onLink) {
    return _appLinks.uriLinkStream.listen(onLink);
  }
}
