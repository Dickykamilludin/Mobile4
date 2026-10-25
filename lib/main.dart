import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const InfoNesiaApp());
}

class InfoNesiaApp extends StatelessWidget {
  const InfoNesiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Berita',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1769E0),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FB),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController =
      TextEditingController();

  String _selectedCategory = 'Nasional';

  bool _isLoading = true;
  bool _showBackToTop = false;

  String? _errorMessage;

  List<Map<String, dynamic>> _news = [];

  final List<Map<String, dynamic>> _favorites = [];

  final Map<String, String> _categoryUrls = {
    'Nasional':
        'https://raw.githubusercontent.com/amnottdevv/news-json-rawcontent-opensource/main/idnews/news1.json',

    'Teknologi':
        'https://raw.githubusercontent.com/amnottdevv/news-json-rawcontent-opensource/main/indotechnews/news1.json',

    'Olahraga':
        'https://raw.githubusercontent.com/amnottdevv/news-json-rawcontent-opensource/main/sportsnewsID/news1.json',

    'Ekonomi':
        'https://raw.githubusercontent.com/amnottdevv/news-json-rawcontent-opensource/main/indofinansial/news1.json',
  };

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_scrollListener);

    _loadNews();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();

    super.dispose();
  }

  void _scrollListener() {
    final showButton = _scrollController.offset > 350;

    if (showButton != _showBackToTop) {
      setState(() {
        _showBackToTop = showButton;
      });
    }
  }

  Future<void> _loadNews({
    bool showLoading = true,
  }) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final url = _categoryUrls[_selectedCategory]!;

      final response = await http.get(
        Uri.parse(url),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Server mengembalikan ${response.statusCode}',
        );
      }

      final data = jsonDecode(response.body);

      final List<dynamic> newsData = data['news'] ?? [];

      final List<Map<String, dynamic>> loadedNews =
          newsData
              .map(
                (item) =>
                    Map<String, dynamic>.from(item),
              )
              .toList();

      if (loadedNews.isEmpty) {
        throw Exception('Data berita kosong');
      }

      setState(() {
        _news = loadedNews;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;

        _errorMessage =
            'Berita belum dapat dimuat.\n'
            'Silakan tekan tombol refresh.';
      });
    }
  }

  void _changeCategory(String category) {
    setState(() {
      _selectedCategory = category;
      _searchController.clear();
    });

    _scrollToTop();

    _loadNews();
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(
          milliseconds: 600,
        ),
        curve: Curves.easeOut,
      );
    }
  }

  String _getNewsKey(
    Map<String, dynamic> news,
  ) {
    return news['id']?.toString() ??
        news['name']?.toString() ??
        '';
  }

  bool _isFavorite(
    Map<String, dynamic> news,
  ) {
    return _favorites.any(
      (item) =>
          _getNewsKey(item) == _getNewsKey(news),
    );
  }

  void _toggleFavorite(
    Map<String, dynamic> news,
  ) {
    final key = _getNewsKey(news);

    setState(() {
      final index = _favorites.indexWhere(
        (item) => _getNewsKey(item) == key,
      );

      if (index >= 0) {
        _favorites.removeAt(index);
      } else {
        _favorites.add(news);
      }
    });
  }

  List<Map<String, dynamic>> get _filteredNews {
    final keyword =
        _searchController.text.trim().toLowerCase();

    if (keyword.isEmpty) {
      return _news;
    }

    return _news.where((news) {
      final title =
          news['name']?.toString().toLowerCase() ?? '';

      final description =
          news['descriptions']
                  ?.toString()
                  .toLowerCase() ??
              '';

      return title.contains(keyword) ||
          description.contains(keyword);
    }).toList();
  }

  String _title(Map<String, dynamic> news) {
    return news['name']?.toString() ??
        'Judul berita tidak tersedia';
  }

  String _description(
    Map<String, dynamic> news,
  ) {
    return news['descriptions']?.toString() ??
        'Deskripsi tidak tersedia.';
  }

  String _image(Map<String, dynamic> news) {
    return news['image']?.toString() ?? '';
  }

  String _source(Map<String, dynamic> news) {
    return news['sumber']?.toString() ??
        'Sumber berita';
  }

  String _date(Map<String, dynamic> news) {
    return news['posted']?.toString() ??
        'Tanggal tidak tersedia';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildHome(),

      bottomNavigationBar:
          _buildBottomNavigation(),

      floatingActionButton:
          _showBackToTop
              ? FloatingActionButton(
                  onPressed: _scrollToTop,
                  child: const Icon(
                    Icons.keyboard_arrow_up,
                  ),
                )
              : null,
    );
  }

  Widget _buildBottomNavigation() {
    return NavigationBar(
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Beranda',
        ),
        NavigationDestination(
          icon: Icon(Icons.favorite_border),
          selectedIcon: Icon(Icons.favorite),
          label: 'Favorit',
        ),
      ],
      selectedIndex: 0,
      onDestinationSelected: (index) {
        if (index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FavoritePage(
                favorites: _favorites,
                onRemove: (news) {
                  _toggleFavorite(news);
                },
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildHome() {
    final newsList = _filteredNews;

    return RefreshIndicator(
      onRefresh: () => _loadNews(
        showLoading: false,
      ),
      child: CustomScrollView(
        controller: _scrollController,
        physics:
            const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _buildHeader(),
          ),

          SliverToBoxAdapter(
            child: _buildSearch(),
          ),

          SliverToBoxAdapter(
            child: _buildCategories(),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                20,
                18,
                20,
                10,
              ),
              child: Row(
                children: [
                  const Text(
                    'Berita Terbaru',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _selectedCategory,
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_isLoading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (_errorMessage != null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildError(),
            )
          else if (newsList.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  'Berita tidak ditemukan.',
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                16,
                5,
                16,
                30,
              ),
              sliver: SliverList(
                delegate:
                    SliverChildBuilderDelegate(
                  (context, index) {
                    return _buildNewsCard(
                      newsList[index],
                    );
                  },
                  childCount: newsList.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        20,
        50,
        20,
        25,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1769E0),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.newspaper,
              color: Color(0xFF1769E0),
              size: 32,
            ),
          ),

          const SizedBox(width: 14),

          const Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Berita Cuy',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Berita Terkini',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        20,
        20,
        5,
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (_) {
          setState(() {});
        },
        decoration: InputDecoration(
          hintText: 'Cari berita...',
          prefixIcon: const Icon(
            Icons.search,
          ),
          suffixIcon:
              _searchController.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                      icon: const Icon(
                        Icons.close,
                      ),
                    )
                  : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildCategories() {
    return SizedBox(
      height: 55,
      child: ListView(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 8,
        ),
        scrollDirection: Axis.horizontal,
        children:
            _categoryUrls.keys.map((category) {
          return Padding(
            padding:
                const EdgeInsets.only(
              right: 8,
            ),
            child: ChoiceChip(
              label: Text(category),
              selected:
                  category ==
                      _selectedCategory,
              onSelected: (_) {
                _changeCategory(
                  category,
                );
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNewsCard(
    Map<String, dynamic> news,
  ) {
    final image = _image(news);
    final favorite = _isFavorite(news);

    return Card(
      margin:
          const EdgeInsets.only(bottom: 18),
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  NewsDetailPage(
                news: news,
                favorite: favorite,
                onFavorite: () {
                  _toggleFavorite(news);
                },
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              height: 200,
              child: image.isNotEmpty
                  ? Image.network(
                      image,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (
                            context,
                            error,
                            stackTrace,
                          ) {
                        return _imageError();
                      },
                    )
                  : _imageError(),
            ),

            Padding(
              padding:
                  const EdgeInsets.fromLTRB(
                16,
                12,
                12,
                16,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration:
                            BoxDecoration(
                          color:
                              const Color(
                            0xFFE8F0FF,
                          ),
                          borderRadius:
                              BorderRadius
                                  .circular(
                            20,
                          ),
                        ),
                        child: Text(
                          _selectedCategory,
                          style:
                              const TextStyle(
                            color:
                                Color(
                              0xFF1769E0,
                            ),
                            fontSize: 11,
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),
                      ),

                      const Spacer(),

                      IconButton(
                        onPressed: () {
                          _toggleFavorite(
                            news,
                          );
                        },
                        icon: Icon(
                          favorite
                              ? Icons.favorite
                              : Icons
                                  .favorite_border,
                          color: favorite
                              ? Colors.red
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),

                  Text(
                    _title(news),
                    maxLines: 3,
                    overflow:
                        TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      height: 1.3,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    _description(news),
                    maxLines: 3,
                    overflow:
                        TextOverflow.ellipsis,
                    style: TextStyle(
                      color:
                          Colors.grey.shade600,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      const Icon(
                        Icons.public,
                        size: 15,
                        color: Colors.grey,
                      ),

                      const SizedBox(width: 5),

                      Expanded(
                        child: Text(
                          _source(news),
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style: TextStyle(
                            color: Colors
                                .grey
                                .shade600,
                            fontSize: 12,
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      const Icon(
                        Icons.calendar_month,
                        size: 15,
                        color: Colors.grey,
                      ),

                      const SizedBox(width: 5),

                      Text(
                        _date(news),
                        style: TextStyle(
                          color: Colors
                              .grey
                              .shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageError() {
    return Container(
      color: const Color(0xFFE5ECF7),
      child: const Center(
        child: Icon(
          Icons.image,
          size: 55,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.cloud_off,
            size: 65,
            color: Colors.grey,
          ),

          const SizedBox(height: 15),

          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 20),

          ElevatedButton.icon(
            onPressed: () {
              _loadNews();
            },
            icon: const Icon(
              Icons.refresh,
            ),
            label: const Text(
              'Muat Berita',
            ),
          ),
        ],
      ),
    );
  }
}

// ===============================
// HALAMAN DETAIL BERITA
// ===============================

class NewsDetailPage extends StatefulWidget {
  final Map<String, dynamic> news;
  final bool favorite;
  final VoidCallback onFavorite;

  const NewsDetailPage({
    super.key,
    required this.news,
    required this.favorite,
    required this.onFavorite,
  });

  @override
  State<NewsDetailPage> createState() =>
      _NewsDetailPageState();
}

class _NewsDetailPageState
    extends State<NewsDetailPage> {
  late bool favorite;

  @override
  void initState() {
    super.initState();

    favorite = widget.favorite;
  }

  @override
  Widget build(BuildContext context) {
    final title =
        widget.news['name']?.toString() ??
            'Judul berita';

    final description =
        widget.news['descriptions']
                ?.toString() ??
            '';

    final article =
        widget.news['artikel']?.toString() ??
            '';

    final image =
        widget.news['image']?.toString() ?? '';

    final source =
        widget.news['sumber']?.toString() ??
            'Sumber berita';

    final date =
        widget.news['posted']?.toString() ??
            '';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detail Berita',
        ),
        actions: [
          IconButton(
            onPressed: () {
              widget.onFavorite();

              setState(() {
                favorite = !favorite;
              });
            },
            icon: Icon(
              favorite
                  ? Icons.favorite
                  : Icons.favorite_border,
              color:
                  favorite
                      ? Colors.red
                      : null,
            ),
          ),
        ],
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            if (image.isNotEmpty)
              Image.network(
                image,
                width: double.infinity,
                height: 260,
                fit: BoxFit.cover,
                errorBuilder:
                    (
                      context,
                      error,
                      stackTrace,
                    ) {
                  return Container(
                    height: 260,
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: Icon(
                        Icons.image,
                        size: 60,
                        color: Colors.grey,
                      ),
                    ),
                  );
                },
              ),

            Padding(
              padding:
                  const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    source,
                    style: const TextStyle(
                      color:
                          Color(0xFF1769E0),
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    date,
                    style: TextStyle(
                      color:
                          Colors.grey.shade600,
                    ),
                  ),

                  const SizedBox(height: 18),

                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 25,
                      height: 1.3,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 18),

                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color:
                          Colors.grey.shade800,
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Divider(),

                  const SizedBox(height: 15),

                  Text(
                    article,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color:
                          Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===============================
// HALAMAN FAVORIT
// ===============================

class FavoritePage extends StatelessWidget {
  final List<Map<String, dynamic>> favorites;
  final Function(Map<String, dynamic>) onRemove;

  const FavoritePage({
    super.key,
    required this.favorites,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Berita Favorit',
        ),
      ),

      body: favorites.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 70,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 15),
                  Text(
                    'Belum ada berita favorit',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding:
                  const EdgeInsets.all(16),
              itemCount:
                  favorites.length,
              itemBuilder:
                  (context, index) {
                final news =
                    favorites[index];

                return Card(
                  margin:
                      const EdgeInsets.only(
                    bottom: 15,
                  ),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius:
                          BorderRadius
                              .circular(
                        10,
                      ),
                      child: Image.network(
                        news['image']
                                ?.toString() ??
                            '',
                        width: 75,
                        height: 75,
                        fit: BoxFit.cover,
                      ),
                    ),

                    title: Text(
                      news['name']
                              ?.toString() ??
                          '',
                      maxLines: 2,
                      overflow:
                          TextOverflow
                              .ellipsis,
                    ),

                    trailing:
                        IconButton(
                      onPressed: () {
                        onRemove(news);

                        Navigator.pop(
                          context,
                        );
                      },
                      icon: const Icon(
                        Icons.delete_outline,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}