import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import '../providers/photo_sorter_provider.dart';
import '../services/gallery_service.dart';
import 'permission_gate_screen.dart';
import 'swipe_screen.dart';
import 'stats_screen.dart';
import 'settings_screen.dart';
import 'pro_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final GalleryService _galleryService = GalleryService();
  List<AlbumInfo>? _albums;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _init();
  }

  Future<void> _init() async {
    final provider = context.read<PhotoSorterProvider>();
    await provider.checkPermissionOnly();
    if (!provider.hasPermission) {
      setState(() => _loading = false);
      return;
    }
    final albums = await _galleryService.getAlbums();
    setState(() {
      _albums = albums;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PhotoSorterProvider>();

    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!provider.hasPermission) {
      return PermissionGateScreen(
        isPermanentlyDenied:
        provider.permissionStatus == PermissionStatus.permanentlyDenied,
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Picder',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart, color: Colors.white70),
            tooltip: 'Statistiques',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const StatsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white70),
            tooltip: 'Réglages',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: _albums == null || _albums!.isEmpty
          ? const Center(
        child: Text('Aucun album trouvé',
            style: TextStyle(color: Colors.white54)),
      )
          : GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: _albums!.length + 1, // +1 pour la carte Pro
        itemBuilder: (context, index) {
          if (index == _albums!.length) {
            return _ProCard(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProScreen()),
              ),
            );
          }
          final album = _albums![index];
          return _AlbumCard(
            album: album,
            onTap: () {
              provider.setAlbum(album.path);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SwipeScreen()),
              );
            },
          );
        },
      ),
    );
  }
}

class _AlbumCard extends StatelessWidget {
  final AlbumInfo album;
  final VoidCallback onTap;

  const _AlbumCard({required this.album, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (album.cover != null)
              AssetEntityImage(
                album.cover!,
                isOriginal: false,
                thumbnailSize: const ThumbnailSize(300, 300),
                fit: BoxFit.cover,
              )
            else
              Container(color: Colors.grey[900]),
            // Dégradé pour la lisibilité du texte
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black87],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      album.path.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                    Text(
                      '${album.count} photos',
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProCard extends StatelessWidget {
  final VoidCallback onTap;

  const _ProCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFe94560), Color(0xFF0f3460)],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.workspace_premium, color: Colors.white, size: 36),
              SizedBox(height: 8),
              Text('Picder Pro',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              Text('Vidéos · Sync cloud',
                  style: TextStyle(color: Colors.white70, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}