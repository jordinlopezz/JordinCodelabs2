import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:animations/animations.dart';
import 'package:provider/provider.dart';

const _iconAssetLocation = 'reply/icons';
final mobileMailNavKey = GlobalKey<NavigatorState>();
const double _kFlingVelocity = 2.0;
const _kAnimationDuration = Duration(milliseconds: 300);

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EmailStore(),
      child: MaterialApp(
        title: 'Flutter Email App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          bottomSheetTheme: BottomSheetThemeData(
            modalBackgroundColor: Colors.transparent,
          ),
        ),
        home: HomePage(),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late final AnimationController _drawerController;
  late final AnimationController _dropArrowController;
  late final AnimationController _bottomAppBarController;
  late final Animation<double> _drawerCurve;
  late final Animation<double> _dropArrowCurve;
  late final Animation<double> _bottomAppBarCurve;

  final _bottomDrawerKey = GlobalKey(debugLabel: 'Bottom Drawer');
  final _navigationDestinations = const <_Destination>[
    _Destination(
      name: 'Inbox',
      icon: '$_iconAssetLocation/twotone_inbox.png',
      index: 0,
    ),
    _Destination(
      name: 'Starred',
      icon: '$_iconAssetLocation/twotone_star.png',
      index: 1,
    ),
    _Destination(
      name: 'Sent',
      icon: '$_iconAssetLocation/twotone_send.png',
      index: 2,
    ),
    _Destination(
      name: 'Trash',
      icon: '$_iconAssetLocation/twotone_delete.png',
      index: 3,
    ),
    _Destination(
      name: 'Spam',
      icon: '$_iconAssetLocation/twotone_error.png',
      index: 4,
    ),
    _Destination(
      name: 'Drafts',
      icon: '$_iconAssetLocation/twotone_drafts.png',
      index: 5,
    ),
  ];

  final _folders = <String, String>{
    'Receipts': '$_iconAssetLocation/twotone_folder.png',
    'Pine Elementary': '$_iconAssetLocation/twotone_folder.png',
    'Taxes': '$_iconAssetLocation/twotone_folder.png',
    'Vacation': '$_iconAssetLocation/twotone_folder.png',
    'Mortgage': '$_iconAssetLocation/twotone_folder.png',
    'Freelance': '$_iconAssetLocation/twotone_folder.png',
  };

  @override
  void initState() {
    super.initState();

    _drawerController = AnimationController(
      duration: _kAnimationDuration,
      value: 0,
      vsync: this,
    )..addListener(() {
      if (_drawerController.status == AnimationStatus.dismissed &&
          _drawerController.value == 0) {
        Provider.of<EmailStore>(
          context,
          listen: false,
        ).bottomDrawerVisible = false;
      }

      if (_drawerController.value < 0.01) {
        setState(() {
          // Reload state when drawer is at its smallest to toggle visibility
          // If state is reloaded before this, the drawer closes abruptly instead
          // of animating.
        });
      }
    });

    _dropArrowController = AnimationController(
      duration: _kAnimationDuration,
      vsync: this,
    );

    _bottomAppBarController = AnimationController(
      vsync: this,
      value: 1,
      duration: const Duration(milliseconds: 250),
    );

    _drawerCurve = CurvedAnimation(
      parent: _drawerController,
      curve: Curves.easeInOut,
      reverseCurve: Curves.easeInOut.flipped,
    );

    _dropArrowCurve = CurvedAnimation(
      parent: _dropArrowController,
      curve: Curves.easeInOut,
      reverseCurve: Curves.easeInOut.flipped,
    );

    _bottomAppBarCurve = CurvedAnimation(
      parent: _bottomAppBarController,
      curve: Curves.easeInOut,
      reverseCurve: Curves.easeInOut.flipped,
    );
  }

  @override
  void dispose() {
    _drawerController.dispose();
    _dropArrowController.dispose();
    _bottomAppBarController.dispose();
    super.dispose();
  }

  void _onDestinationSelected(String destination) {
    var emailStore = Provider.of<EmailStore>(
      context,
      listen: false,
    );

    if (emailStore.onMailView) {
      emailStore.currentlySelectedEmailId = -1;
    }

    if (emailStore.currentlySelectedInbox != destination) {
      emailStore.currentlySelectedInbox = destination;
    }

    setState(() {});
  }

  bool get _bottomDrawerVisible {
    final status = _drawerController.status;
    return status == AnimationStatus.completed ||
        status == AnimationStatus.forward;
  }

  void _toggleBottomDrawerVisibility() {
    if (_drawerController.value < 0.4) {
      Provider.of<EmailStore>(
        context,
        listen: false,
      ).bottomDrawerVisible = true;
      _drawerController.animateTo(0.4, curve: Curves.easeInOut);
      _dropArrowController.animateTo(0.35, curve: Curves.easeInOut);
      return;
    }

    _dropArrowController.forward();
    _drawerController.fling(
      velocity: _bottomDrawerVisible ? -_kFlingVelocity : _kFlingVelocity,
    );
  }

  double get _bottomDrawerHeight {
    final renderBox =
    _bottomDrawerKey.currentContext!.findRenderObject() as RenderBox;
    return renderBox.size.height;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    _drawerController.value -= details.primaryDelta! / _bottomDrawerHeight;
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_drawerController.isAnimating ||
        _drawerController.status == AnimationStatus.completed) {
      return;
    }

    final flingVelocity =
        details.velocity.pixelsPerSecond.dy / _bottomDrawerHeight;

    if (flingVelocity < 0.0) {
      _drawerController.fling(
        velocity: math.max(_kFlingVelocity, -flingVelocity),
      );
    } else if (flingVelocity > 0.0) {
      _dropArrowController.forward();
      _drawerController.fling(
        velocity: math.min(-_kFlingVelocity, -flingVelocity),
      );
    } else {
      if (_drawerController.value < 0.6) {
        _dropArrowController.forward();
      }
      _drawerController.fling(
        velocity: _drawerController.value < 0.6
            ? -_kFlingVelocity
            : _kFlingVelocity,
      );
    }
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification.depth == 0) {
      if (notification is UserScrollNotification) {
        switch (notification.direction) {
          case ScrollDirection.forward:
            _bottomAppBarController.forward();
            break;
          case ScrollDirection.reverse:
            _bottomAppBarController.reverse();
            break;
          case ScrollDirection.idle:
            break;
        }
      }
    }
    return false;
  }

  Widget _buildStack(BuildContext context, BoxConstraints constraints) {
    final drawerSize = constraints.biggest;
    final drawerTop = drawerSize.height;
    final ValueChanged<String> updateMailbox = _onDestinationSelected;

    final drawerAnimation = RelativeRectTween(
      begin: RelativeRect.fromLTRB(0.0, drawerTop, 0.0, 0.0),
      end: const RelativeRect.fromLTRB(0.0, 0.0, 0.0, 0.0),
    ).animate(_drawerCurve);

    return Stack(
      clipBehavior: Clip.none,
      key: _bottomDrawerKey,
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: _handleScrollNotification,
          child: _MailRouter(
            drawerController: _drawerController,
          ),
        ),
        GestureDetector(
          onTap: () {
            _drawerController.reverse();
            _dropArrowController.reverse();
          },
          child: Visibility(
            maintainAnimation: true,
            maintainState: true,
            visible: _bottomDrawerVisible,
            child: FadeTransition(
              opacity: _drawerCurve,
              child: Container(
                height: MediaQuery.of(context).size.height,
                width: MediaQuery.of(context).size.width,
                color: Theme.of(context).bottomSheetTheme.modalBackgroundColor,
              ),
            ),
          ),
        ),
        PositionedTransition(
          rect: drawerAnimation,
          child: Visibility(
            visible: _bottomDrawerVisible,
            child: BottomDrawer(
              onVerticalDragUpdate: _handleDragUpdate,
              onVerticalDragEnd: _handleDragEnd,
              leading: _BottomDrawerDestinations(
                destinations: _navigationDestinations,
                drawerController: _drawerController,
                dropArrowController: _dropArrowController,
                onItemTapped: updateMailbox,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: _buildStack,
      ),
      bottomNavigationBar: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(_bottomAppBarCurve),
        child: FadeTransition(
          opacity: _bottomAppBarCurve,
          child: Material(
            elevation: 0,
            color: Theme.of(context).bottomAppBarTheme.color,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 10.0,
                vertical: 5.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: const <Widget>[
                  BottomNavItem(icon: Icons.home, title: 'Home'),
                  BottomNavItem(icon: Icons.search, title: 'Search'),
                  BottomNavItem(icon: Icons.person, title: 'Profile'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Destination {
  const _Destination({
    required this.name,
    required this.icon,
    required this.index,
  });

  final String name;
  final String icon;
  final int index;
}

class EmailStore with ChangeNotifier {
  bool _bottomDrawerVisible = false;
  String _currentlySelectedInbox = 'Inbox';
  int _currentlySelectedEmailId = -1;

  bool get bottomDrawerVisible => _bottomDrawerVisible;

  set bottomDrawerVisible(bool value) {
    _bottomDrawerVisible = value;
    notifyListeners();
  }

  String get currentlySelectedInbox => _currentlySelectedInbox;

  set currentlySelectedInbox(String value) {
    _currentlySelectedInbox = value;
    notifyListeners();
  }

  int get currentlySelectedEmailId => _currentlySelectedEmailId;

  set currentlySelectedEmailId(int value) {
    _currentlySelectedEmailId = value;
    notifyListeners();
  }

  bool get onMailView => _currentlySelectedEmailId != -1;
}

class BottomDrawer extends StatelessWidget {
  const BottomDrawer({
    Key? key,
    required this.onVerticalDragUpdate,
    required this.onVerticalDragEnd,
    required this.leading,
  }) : super(key: key);

  final GestureDragUpdateCallback onVerticalDragUpdate;
  final GestureDragEndCallback onVerticalDragEnd;
  final Widget leading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: onVerticalDragUpdate,
      onVerticalDragEnd: onVerticalDragEnd,
      behavior: HitTestBehavior.translucent,
      child: Material(
        elevation: 4,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 10,
            ),
            leading,
          ],
        ),
      ),
    );
  }
}

class _BottomDrawerDestinations extends StatelessWidget {
  const _BottomDrawerDestinations({
    Key? key,
    required this.destinations,
    required AnimationController drawerController,
    required AnimationController dropArrowController,
    required this.onItemTapped,
  })  : _drawerController = drawerController,
        _dropArrowController = dropArrowController,
        super(key: key);

  final List<_Destination> destinations;
  final AnimationController _drawerController;
  final AnimationController _dropArrowController;
  final ValueChanged<String> onItemTapped;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Column(
      children: [
        const SizedBox(height: 16),
        ...destinations.map((destination) => ListTile(
          leading: Image.asset(destination.icon),
          title: Text(destination.name),
          onTap: () {
            onItemTapped(destination.name);
            _drawerController.reverse();
            _dropArrowController.reverse();
          },
        )),
      ],
    );
  }
}

class BottomNavItem extends StatelessWidget {
  const BottomNavItem({
    Key? key,
    required this.icon,
    required this.title,
  }) : super(key: key);

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(icon, color: Colors.blue),
        Text(
          title,
          style: TextStyle(color: Colors.blue),
        ),
      ],
    );
  }
}

class _MailRouter extends StatelessWidget {
  const _MailRouter({
    Key? key,
    required AnimationController drawerController,
  })  : _drawerController = drawerController,
        super(key: key);

  final AnimationController _drawerController;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Navigator(
      key: mobileMailNavKey,
      onGenerateRoute: (settings) {
        switch (settings.name) {
          default:
            return MaterialPageRoute(
              builder: (_) => Scaffold(
                appBar: AppBar(
                  elevation: 0,
                  title: Text(
                    Provider.of<EmailStore>(
                      context,
                      listen: false,
                    ).currentlySelectedInbox,
                  ),
                ),
                body: ListView.builder(
                  itemCount: 50,
                  itemBuilder: (context, index) => OpenContainer(
                    closedBuilder: (_, openContainer) => ListTile(
                      leading: CircleAvatar(),
                      title: const Text('Message Subject'),
                      subtitle: const Text('Sender Name'),
                      onTap: openContainer,
                    ),
                    openBuilder: (_, closeContainer) => Scaffold(
                      appBar: AppBar(
                        title: Text('Detailed Message'),
                      ),
                      body: const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'Detailed message content goes here.',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
        }
      },
    );
  }
}
