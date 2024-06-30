import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animations/animations.dart';

import 'inbox.dart';
import 'model/email_store.dart';

class MailViewRouterDelegate extends RouterDelegate<void>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<void> {
  final AnimationController drawerController;

  MailViewRouterDelegate({required this.drawerController});

  @override
  Widget build(BuildContext context) {
    bool handlePopPage(Route<dynamic> route, dynamic result) {
      return false;
    }

    return Selector<EmailStore, String>(
      selector: (context, emailStore) => emailStore.currentlySelectedInbox,
      builder: (context, currentlySelectedInbox, child) {
        return Navigator(
          key: navigatorKey,
          onPopPage: handlePopPage,
          pages: [
            // TODO: Add Fade through transition between mailbox pages (Motion)
            FadeThroughTransitionPageWrapper(
              mailbox: InboxPage(
                destination: currentlySelectedInbox,
              ),
              transitionKey: ValueKey(currentlySelectedInbox),
            ),
          ],
        );
      },
    );
  }

  @override
  GlobalKey<NavigatorState> get navigatorKey => GlobalKey<NavigatorState>();

  @override
  Future<bool> popRoute() async {
    var emailStore =
    Provider.of<EmailStore>(navigatorKey.currentContext!, listen: false);
    bool onCompose = emailStore.onCompose;
    bool onMailView = emailStore.onMailView;

    if (!(onMailView || onCompose)) {
      if (emailStore.bottomDrawerVisible) {
        drawerController.reverse();
        return true; // Return true directly as a Future<bool>
      }

      if (emailStore.currentlySelectedInbox != 'Inbox') {
        emailStore.currentlySelectedInbox = 'Inbox';
        return true; // Return true directly as a Future<bool>
      }
      return false; // Return false directly as a Future<bool>
    }

    if (onCompose) {
      emailStore.onCompose = false;
      return false; // Return false directly as a Future<bool>
    }

    if (emailStore.bottomDrawerVisible && onMailView) {
      drawerController.reverse();
      return true; // Return true directly as a Future<bool>
    }

    if (navigatorKey.currentState!.canPop()) {
      navigatorKey.currentState!.pop();
      Provider.of<EmailStore>(navigatorKey.currentContext!, listen: false)
          .currentlySelectedEmailId = -1;
      return true; // Return true directly as a Future<bool>
    }

    return false; // Return false directly as a Future<bool>
  }

  @override
  Future<void> setNewRoutePath(void configuration) {
    // This function will never be called.
    throw UnimplementedError();
  }
}

// TODO: Add Fade through transition between mailbox pages (Motion)
class FadeThroughTransitionPageWrapper extends Page {
  final Widget mailbox;
  final ValueKey transitionKey;

  const FadeThroughTransitionPageWrapper({
    required this.mailbox,
    required this.transitionKey,
  }) : super(key: transitionKey);

  @override
  Route createRoute(BuildContext context) {
    return PageRouteBuilder(
      settings: this,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeThroughTransition(
          fillColor: Theme.of(context).scaffoldBackgroundColor,
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          child: child,
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        return mailbox;
      },
    );
  }
}
