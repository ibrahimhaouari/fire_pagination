// Dart Packages
import 'dart:async';

// Flutter Packages
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

// Firebase Packages
import 'package:cloud_firestore/cloud_firestore.dart';


// Data Models
import 'models/page_options.dart';
import 'models/view_type.dart';
import 'models/wrap_options.dart';

// Widgets
import 'widgets/defaults/bottom_loader.dart';
import 'widgets/defaults/empty_screen.dart';
import 'widgets/defaults/error_screen.dart';
import 'widgets/defaults/initial_loader.dart';
import 'widgets/views/build_pagination.dart';

// Functions
import 'functions/separator_builder.dart';

/// A [StreamBuilder] that automatically loads more data when the user scrolls
/// to the bottom.
///
/// Optimized for [FirebaseFirestore] with fields like `createdAt` and
/// `timestamp` to sort the data.
///
/// Supports live add and realtime updates to loaded data.
///
/// Data can be represented in a [ListView], [GridView] or scollable [Wrap].
class FirePagination extends StatefulWidget {
  /// Creates a [StreamBuilder] widget that automatically loads more data when
  /// the user scrolls to the bottom.
  ///
  /// Optimized for [FirebaseFirestore] with fields like `createdAt` and
  /// `timestamp` to sort the data.
  ///
  /// Supports live add and realtime updates to loaded data.
  ///
  /// Data can be represented in a [ListView], [GridView] or scollable [Wrap].
  const FirePagination({
    required this.query,
    required this.itemBuilder,
    super.key,
    this.separatorBuilder,
    this.limit = 10,
    this.initialLimit = null,
    this.viewType = ViewType.list,
    this.listenForAdd = false,
    this.listenForUpdates = false,
    this.gridDelegate = const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
    ),
    this.wrapOptions = const WrapOptions(),
    this.pageOptions = const PageOptions(),
    this.onError = null,
    this.onEmpty = const EmptyScreen(),
    this.bottomLoader = const BottomLoader(),
    this.initialLoader = const InitialLoader(),
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.shrinkWrap = false,
    this.physics,
    this.padding,
    this.controller,
    this.pageController,
  });

  /// The query to use to fetch data from Firestore.
  ///
  /// ### Note:
  /// - The query must **NOT** contain a `limit` itself.
  /// - The `limit` must be set using the [limit] property of this widget.
  final Query query;

  /// The builder to use to build the items in the list.
  ///
  /// The builder is passed the build context, snapshot of the document and
  /// index of the item in the list.
  final Widget Function(BuildContext, List<DocumentSnapshot>, int) itemBuilder;

  /// The builder to use to render the separator.
  ///
  /// Only used if [viewType] is [ViewType.list].
  ///
  /// Default [Widget] is [SizedBox.shrink].
  final Widget Function(BuildContext, int)? separatorBuilder;

  /// The number of items to fetch from Firestore at once.
  ///
  /// Defaults to `10`.
  final int limit;

  /// The initial number of items to fetch from Firestore the first time.
  /// 
  /// Defaults to `null` which fetches [limit] items.
  final int? initialLimit;

  /// The type of view to use for the list.
  ///
  /// Defaults to [ViewType.list].
  final ViewType viewType;

  /// Whether to fetch newly added items as they are added to Firestore.
  ///
  /// Defaults to `false`.
  final bool listenForAdd;

  /// whether to listen for updates to the loaded data.
  ///
  /// Defaults to `false`.
  final bool listenForUpdates;

  /// The delegate to use for the [GridView].
  ///
  /// Defaults to [SliverGridDelegateWithFixedCrossAxisCount].
  final SliverGridDelegate gridDelegate;

  /// The [Wrap] widget properties to use.
  ///
  /// Defaults to [WrapOptions].
  final WrapOptions wrapOptions;

  /// The [PageView] properties to use.
  ///
  /// Defaults to [PageOptions].
  final PageOptions pageOptions;

  /// The widget to use when an error occurs.
  ///
  /// Defaults to [ErrorScreen].
  final Widget Function(VoidCallback)? onError;

  /// The widget to use when data is empty.
  ///
  /// Defaults to [EmptyScreen].
  final Widget onEmpty;

  /// The widget to use when more data is loading.
  ///
  /// Defaults to [BottomLoader].
  final Widget bottomLoader;

  /// The widget to use when data is loading initially.
  ///
  /// Defaults to [InitialLoader].
  final Widget initialLoader;

  /// The scrolling direction of the [ScrollView].
  final Axis scrollDirection;

  /// Whether the [ScrollView] scrolls in the reading direction.
  final bool reverse;

  /// Should the [ScrollView] be shrink-wrapped.
  final bool shrinkWrap;

  /// The scroll behavior to use for the [ScrollView].
  final ScrollPhysics? physics;

  /// The padding to use for the [ScrollView].
  final EdgeInsetsGeometry? padding;

  /// The scroll controller to use for the [ScrollView].
  ///
  /// Defaults to [ScrollController].
  final ScrollController? controller;

  /// The page controller to use for the [PageView].
  ///
  /// Defaults to [PageController].
  final PageController? pageController;

  @override
  State<FirePagination> createState() => _FirePaginationState();
}

/// The state of the [FirePagination] widget.
class _FirePaginationState extends State<FirePagination> {
  /// All the data that has been loaded from Firestore.
  final List<DocumentSnapshot> _docs = [];

  /// The last document that was loaded from Firestore.
  DocumentSnapshot? _lastDoc;

  /// Snapshot subscription for the query.
  ///
  /// Also handles updates to loaded data.
  StreamSubscription<QuerySnapshot>? _streamSub;

  /// Snapshot subscription for the query to handle newly added data.
  StreamSubscription<QuerySnapshot>? _addStreamSub;

  /// [ScrollController] to listen to scroll end and load more data.
  late final ScrollController _controller =
      widget.controller ?? ScrollController();

  /// [PageController] to listen to page changes and load more data.
  late final PageController _pageController =
      widget.pageController ?? PageController();

  /// Whether initial data is loading.
  bool _isInitialLoading = true;

  /// Whether an error has occurred.
  bool _isError = false;

  /// Whether more data is loading.
  bool _isFetching = false;

  /// Whether the end for given query has been reached.
  ///
  /// This is used to determine if more data should be loaded when the user
  /// scrolls to the bottom.
  bool _isEnded = false;

  /// Loads more data from Firestore and handles updates to loaded data.
  ///
  /// Setting [getMore] to `false` will only set listener for the currently
  /// loaded data.
  Future<void> _loadDocuments({bool getMore = true}) async {
      try{
        _isError = false;

        if(widget.listenForUpdates){
          await _loadDocumentsWithListener(getMore: getMore);
        }
        else{
          await _loadDocumentsWithoutListener(getMore: getMore);
        }
      }
      catch(e){
        _isError = true;
        if(mounted) setState(() {});
        throw e;
      }
  }

  Future<void> _loadDocumentsWithListener({bool getMore = true}) async {
    // To cancel previous updates listener when new one is set.
    final tempSub = _streamSub;

    if (getMore) setState(() => _isFetching = true);

    final docsLimit = _docs.length + (getMore ? (_isInitialLoading ? widget.initialLimit ?? widget.limit : widget.limit) : 0);
    var docsQuery = widget.query.limit(docsLimit);
    if (_docs.isNotEmpty) {
      docsQuery = docsQuery.startAtDocument(_docs.first);
    }

    _streamSub = docsQuery.snapshots().listen((QuerySnapshot snapshot) async {
      await tempSub?.cancel();

      // Log each document's cache status
      // snapshot.docs.forEach((doc) {
      //   print('Document ID: ${doc.id}, isFromCache: ${doc.metadata.isFromCache}');
      // });
      // final cachedCount = snapshot.docs.where((doc) => doc.metadata.isFromCache).length;
      // print('Documents from cache: $cachedCount / ${snapshot.docs.length}');

      _docs
        ..clear()
        ..addAll(snapshot.docs);

      // To set new updates listener for the existing data
      // or to set new add listener if the first document is removed.
      final isDocRemoved = snapshot.docChanges.any(
        (DocumentChange change) => change.type == DocumentChangeType.removed,
      );

      _isFetching = false;
      if (!isDocRemoved) {
        _isEnded = snapshot.docs.length < docsLimit;
      }

      if (isDocRemoved || _isInitialLoading) {
        _isInitialLoading = false;
        if (snapshot.docs.isNotEmpty) {
          // Set updates listener for the existing data starting from the first
          // document only.
          await _loadDocuments(getMore: false);
        } else {
          _streamSub?.cancel();
        }
        if (widget.listenForAdd) _setAddListener();
      }

      if (mounted) setState(() {});

      // Add data till the view is scrollable. This ensures that the user can
      // scroll to the bottom and load more data.
      if (_isInitialLoading || _isFetching || _isEnded) return;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (_controller.hasClients &&
            _controller.position.maxScrollExtent <= 0) {
          _loadDocuments();
        }
      });
    });
  }

  Future<void> _loadDocumentsWithoutListener({bool getMore = true}) async {


    if (getMore) setState(() => _isFetching = true);

    final docsLimit = _isInitialLoading ? widget.initialLimit ?? widget.limit : widget.limit;

    var docsQuery = widget.query.limit(docsLimit);
    if (_lastDoc != null) {
      docsQuery = docsQuery.startAfterDocument(_lastDoc!);
    }

    // Perform one-time fetch without live add
    final snapshot = await docsQuery.get();
    if (snapshot.docs.isNotEmpty) {
      if (getMore) {
        _docs.addAll(snapshot.docs);
      } else {
        _docs.clear();
        _docs.addAll(snapshot.docs);
      }
      _lastDoc = _docs.last;
    }

    _isFetching = false;
    _isEnded = snapshot.docs.length < widget.limit;
    if (_isInitialLoading) {
      _isInitialLoading = false;
      if (widget.listenForAdd) _setAddListener();
    }

    if (mounted) setState(() {});

    // Load more data if needed
    if (_isFetching || _isEnded) return;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (_controller.hasClients &&
            _controller.position.maxScrollExtent <= 0) {
          _loadDocuments();
        }
    });

    }



  /// Sets the add listener for the query.
  ///
  /// Fires when new data is added to the query.
  Future<void> _setAddListener() async {
    // To cancel previous add listener when new one is set.
    final tempSub = _addStreamSub;

    var latestDocQuery = widget.query.limit(1);
    if (_docs.isNotEmpty) {
      latestDocQuery = latestDocQuery.endBeforeDocument(_docs.first);
    }

    _addStreamSub =
        latestDocQuery.snapshots(includeMetadataChanges: true).listen(
      (QuerySnapshot snapshot) async {
        await tempSub?.cancel();
        if (snapshot.docs.isEmpty ||
            snapshot.docs.first.metadata.hasPendingWrites
            ) return;

        final docExists = _docs.any((doc) => doc.id == snapshot.docs.first.id);
        if (docExists) return;

        _docs.insert(0, snapshot.docs.first);

        // To handle newly added data after this currently loaded data.
        await _setAddListener();

        // Set updates listener for the newly added data.
        if(widget.listenForUpdates){
          _loadDocuments(getMore: false);
        }else{
          if(mounted) setState(() {});
        }
      },
    );
  }

  /// To handle scroll end event and load more data.
  void _scrollListener() {
    if (_isInitialLoading || _isFetching || _isEnded) return;
    if (!_controller.hasClients) return;

    final position = _controller.position;
    if (position.pixels >= (position.maxScrollExtent - 50)) {
      _loadDocuments();
    }
  }

    // Previous query to detect changes
  late Query _previousQuery;

  @override
  void initState() {
    super.initState();
    _previousQuery = widget.query;
    _loadDocuments();
    _controller.addListener(_scrollListener);
  }

  @override
  void didUpdateWidget(FirePagination oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if the query has changed
    if (widget.query != _previousQuery) {
      // Update the previous query
      _previousQuery = widget.query;

      // Cancel existing listeners and reset state
      _streamSub?.cancel();
      _addStreamSub?.cancel();
      _lastDoc = null;
      _isInitialLoading = true;
      _isEnded = false;
      _docs.clear();

      // Load documents with the new query
      _loadDocuments();
    }
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    _addStreamSub?.cancel();
    _controller
      ..removeListener(_scrollListener)
      ..dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _isError ? (widget.onError?.call(_loadDocuments) ?? ErrorScreen(onRetry: _loadDocuments))
        : _isInitialLoading
        ? widget.initialLoader
        : _docs.isEmpty
            ? widget.onEmpty
            : BuildPagination(
                items: _docs,
                itemBuilder: widget.itemBuilder,
                separatorBuilder: widget.separatorBuilder ?? separatorBuilder,
                isLoading: _isFetching,
                viewType: widget.viewType,
                bottomLoader: widget.bottomLoader,
                gridDelegate: widget.gridDelegate,
                wrapOptions: widget.wrapOptions,
                pageOptions: widget.pageOptions,
                scrollDirection: widget.scrollDirection,
                reverse: widget.reverse,
                controller: _controller,
                pageController: _pageController,
                shrinkWrap: widget.shrinkWrap,
                physics: widget.physics,
                padding: widget.padding,
                onPageChanged: (index) {
                  if (index >= _docs.length - 1) _loadDocuments();
                },
              );
  }
}