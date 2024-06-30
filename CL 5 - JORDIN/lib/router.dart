import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animations/animations.dart';

import 'home.dart';
import 'search_page.dart';

import 'model/router_provider.dart';

const String _homePageLocation = '/reply/home';
const String _searchPageLocation = '/reply/search';

class ReplyRouterDelegate extends RouterDelegate<ReplyRoutePath>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<ReplyRoutePath> {
  ReplyRouterDelegate({required this.replyState})
      : navigatorKey = GlobalKey<NavigatorState>(),
        super() {
    replyState.addListener(notifyListeners);
  }

  @override
  final GlobalKey<NavigatorState> navigatorKey;

  final RouterProvider replyState;

  @override
  void dispose() {
    replyState.removeListener(notifyListeners);
    super.dispose();
  }

  @override
  ReplyRoutePath get currentConfiguration => replyState.routePath;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<RouterProvider>.value(value: replyState),
      ],
      child: Selector<RouterProvider, ReplyRoutePath?>(
        selector: (context, routerProvider) => routerProvider.routePath,
        builder: (context, routePath, child) {
          return Navigator(
            key: navigatorKey,
            onPopPage: _handlePopPage,
            pages: [
              // Home page with SharedAxisTransition
              const SharedAxisTransitionPageWrapper(
                transitionKey: ValueKey('home'),
                screen: HomePage(),
              ),
              // Search page with SharedAxisTransition
              if (routePath is ReplySearchPath)
                SharedAxisTransitionPageWrapper(
                  transitionKey: ValueKey('search'),
                  screen: SearchPage(),
                ),
            ],
          );
        },
      ),
    );
  }

  bool _handlePopPage(Route<dynamic> route, dynamic result) {
    assert(route.willHandlePopInternally ||
        replyState.routePath is ReplySearchPath);

    final bool didPop = route.didPop(result);
    if (didPop) replyState.routePath = ReplyHomePath();
    return didPop;
  }

  @override
  Future<void> setNewRoutePath(ReplyRoutePath configuration) async {
    replyState.routePath = configuration;
  }
}

@immutable
abstract class ReplyRoutePath {}

class ReplyHomePath extends ReplyRoutePath {
  ReplyHomePath(); // Constructor sin constante para ReplyHomePath
}

class ReplySearchPath extends ReplyRoutePath {
  ReplySearchPath(); // Constructor sin constante para ReplySearchPath
}

class ReplyRouteInformationParser
    extends RouteInformationParser<ReplyRoutePath> {
  @override
  Future<ReplyRoutePath> parseRouteInformation(
      RouteInformation routeInformation) async {
    final uri = Uri.parse(routeInformation.location!);

    if (uri.path == _searchPageLocation) {
      return ReplySearchPath();
    } else {
      return ReplyHomePath();
    }
  }

  @override
  RouteInformation? restoreRouteInformation(ReplyRoutePath configuration) {
    if (configuration is ReplyHomePath) {
      return RouteInformation(location: _homePageLocation);
    } else if (configuration is ReplySearchPath) {
      return RouteInformation(location: _searchPageLocation);
    } else {
      return null;
    }
  }
}

class SharedAxisTransitionPageWrapper extends Page {
  final Widget screen;
  final ValueKey transitionKey;
  final SharedAxisTransitionType transitionType;

  const SharedAxisTransitionPageWrapper({
    required this.screen,
    required this.transitionKey,
    this.transitionType = SharedAxisTransitionType.scaled,
  }) : super(key: transitionKey);

  @override
  Route createRoute(BuildContext context) {
    return PageRouteBuilder(
      settings: this,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SharedAxisTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          transitionType: transitionType,
          fillColor: Theme.of(context).cardColor,
          child: child!,
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) => screen,
    );
  }
}
