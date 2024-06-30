import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

final GlobalKey<ProductListWidgetState> productList = GlobalKey<ProductListWidgetState>();

void main() {
  runApp(
    AppStateWidget(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Store',
        home: MyStorePage(),
      ),
    ),
  );
}

class AppState {
  AppState({
    required this.productList,
    this.ItemsInCart = const <String>{},
  });

  final List<String> productList;
  final Set<String> ItemsInCart;

  AppState copyWith({
    List<String>? productList,
    Set<String>? ItemsInCart,
  }) {
    return AppState(
      productList: productList ?? this.productList,
      ItemsInCart: ItemsInCart ?? this.ItemsInCart,
    );
  }
}

class AppStateScope extends InheritedWidget {
  AppStateScope(
    this.data, {
    Key? key,
    required Widget child,
  }) : super(key: key, child: child);

  final AppState data;

  static AppState of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppStateScope>()!.data;
  }

  @override
  bool updateShouldNotify(AppStateScope oldWidget) {
    return data != oldWidget.data;
  }
}

class AppStateWidget extends StatefulWidget {
  AppStateWidget({required this.child});

  final Widget child;

  static AppStateWidgetState of(BuildContext context) {
    return context.findAncestorStateOfType<AppStateWidgetState>()!;
  }

  @override
  AppStateWidgetState createState() => AppStateWidgetState();
}

class AppStateWidgetState extends State<AppStateWidget> {
  AppState data = AppState(
    productList: Server.getProductList(),
  );

  void setProductList(List<String> newProductList) {
    if (data.productList != newProductList) {
      setState(() {
        data = data.copyWith(productList: newProductList);
      });
    }
  }

  void addToCart(String id) {
    if (!data.ItemsInCart.contains(id)) {
      setState(() {
        final Set<String> newItemsInCart = Set<String>.from(data.ItemsInCart);
        newItemsInCart.add(id);
        data = data.copyWith(ItemsInCart: newItemsInCart);
      });
    }
  }

  void removeFromCart(String id) {
    if (data.ItemsInCart.contains(id)) {
      setState(() {
        final Set<String> newItemsInCart = Set<String>.from(data.ItemsInCart);
        newItemsInCart.remove(id);
        data = data.copyWith(ItemsInCart: newItemsInCart);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppStateScope(data, child: widget.child);
  }
}

class MyStorePage extends StatefulWidget {
  MyStorePage({Key? key}) : super(key: key);

  @override
  MyStorePageState createState() => MyStorePageState();
}

class MyStorePageState extends State<MyStorePage> {
  bool inSearch = false;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  void _toggleSearch() {
    setState(() {
      inSearch = !inSearch;
    });

    _controller.clear();
    productList.currentState!.setProductList(Server.getProductList());
  }

  void _handleSearch() {
    _focusNode.unfocus();
    final String filter = _controller.text;
    productList.currentState!.setProductList(Server.getProductList(filter: filter));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            leading: Padding(
              padding: EdgeInsets.all(16.0),
              child: Image.network('${Server.baseAssetURL}/google-logo.png')),
            title: inSearch
                ? TextField(
                    autofocus: true,
                    focusNode: _focusNode,
                    controller: _controller,
                    onSubmitted: (_) => _handleSearch(),
                    decoration: InputDecoration(
                      hintText: 'Search Google Store',
                      prefixIcon: IconButton(icon: Icon(Icons.search), onPressed: _handleSearch),
                      suffixIcon: IconButton(icon: Icon(Icons.close), onPressed: _toggleSearch),
                    ),
                  )
                : null,
            actions: [
              if (!inSearch) IconButton(onPressed: _toggleSearch, icon: Icon(Icons.search, color: Colors.black)),
              ShoppingCartIcon(key: Key('ShoppingCart')),
            ],
            backgroundColor: Colors.white,
            pinned: true,
          ),
          SliverToBoxAdapter(
            child: ProductListWidget(key: productList),
          ),
        ],
      ),
    );
  }
}

class ShoppingCartIcon extends StatelessWidget {
  ShoppingCartIcon({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Set<String> ItemsInCart = AppStateScope.of(context).ItemsInCart;
    final bool hasPurchase = ItemsInCart.length > 0;
    return Stack(
      alignment: Alignment.center,
      children: [
        Padding(
          padding: EdgeInsets.only(right: hasPurchase ? 17.0 : 10.0),
          child: Icon(
            Icons.shopping_cart,
            color: Colors.black,
          ),
        ),
        if (hasPurchase)
          Padding(
            padding: const EdgeInsets.only(left: 17.0),
            child: CircleAvatar(
              radius: 8.0,
              backgroundColor: Colors.lightBlue,
              foregroundColor: Colors.white,
              child: Text(
                ItemsInCart.length.toString(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12.0,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// TODO: CONVERT PRODUCTLISTWIDGET INTO STATELESSWIDGET
class ProductListWidget extends StatefulWidget {
  ProductListWidget({Key? key}) : super(key: key);

  @override
  ProductListWidgetState createState() => ProductListWidgetState();
}

class ProductListWidgetState extends State<ProductListWidget> {
  List<String> productList = [];

  @override
  void initState() {
    super.initState();
    productList = Server.getProductList();
  }

  void setProductList(List<String> newProductList) {
    setState(() {
      productList = newProductList;
    });
  }

  void _handleAddToCart(String id, BuildContext context) {
    AppStateWidget.of(context).addToCart(id);
  }

  void _handleRemoveFromCart(String id, BuildContext context) {
    AppStateWidget.of(context).removeFromCart(id);
  }

  Widget _buildProductTile(String id, BuildContext context) {
    final bool purchased = AppStateScope.of(context).ItemsInCart.contains(id);
    return ProductTile(
      product: Server.getProductById(id),
      purchased: purchased,
      onAddToCart: () => _handleAddToCart(id, context),
      onRemoveFromCart: () => _handleRemoveFromCart(id, context),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: productList.map((id) => _buildProductTile(id, context)).toList(),
    );
  }
}

class ProductTile extends StatelessWidget {
  ProductTile({
    Key? key,
    required this.product,
    required this.purchased,
    required this.onAddToCart,
    required this.onRemoveFromCart,
  }) : super(key: key);

  final Product product;
  final bool purchased;
  final VoidCallback onAddToCart;
  final VoidCallback onRemoveFromCart;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(product.name),
      subtitle: Text(product.description),
      trailing: purchased
          ? IconButton(icon: Icon(Icons.remove_shopping_cart), onPressed: onRemoveFromCart)
          : IconButton(icon: Icon(Icons.add_shopping_cart), onPressed: onAddToCart),
    );
  }
}

class Server {
  static const String baseAssetURL = 'https://example.com/assets';

  static List<String> getProductList({String filter = ''}) {
    // Este es solo un simulacro. Reemplázalo con tu lógica real de recuperación de lista de productos.
    return ['product1', 'product2', 'product3'].where((product) => product.contains(filter)).toList();
  }

  static Product getProductById(String id) {
    // Este es solo un simulacro. Reemplázalo con tu lógica real de recuperación de productos.
    return Product(id: id, name: 'Product $id', description: 'Description of product $id');
  }
}

class Product {
  final String id;
  final String name;
  final String description;

  Product({required this.id, required this.name, required this.description});
}
