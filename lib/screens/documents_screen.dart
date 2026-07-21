import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// NazariAI - Documents Screen
// StatefulWidget prêt à être importé et appelé dans un main.dart existant :
//
//   import 'documents_screen.dart';
//   ...
//   home: const DocumentsScreen(),
//
// Changements de cette version :
//  - Les cartes "Recent Documents" sont empilées verticalement (une par ligne)
//    au lieu d'une grille 2 colonnes.
//  - Mise en page responsive : paddings, tailles de police et disposition de
//    la barre de recherche/filtres s'adaptent à la largeur de l'écran
//    (petits mobiles, mobiles standards, tablettes).
// ---------------------------------------------------------------------------

// -------------------- Palette de couleurs (thème NazariAI) -----------------
const Color colorPrimary = Color(0xFF0B5D3B);
const Color colorOnPrimary = Color(0xFFFFFFFF);
const Color colorPrimaryContainer = Color(0xFFDCEFE5);
const Color colorOnPrimaryContainer = Color(0xFF0B5D3B);
const Color colorSecondary = Color(0xFF795900);
const Color colorSurface = Color(0xFFF9F7F2);
const Color colorSurfaceContainerLow = Color(0xFFF1F4EF);
const Color colorSurfaceContainerHigh = Color(0xFFE6E9E4);
const Color colorSurfaceContainerLowest = Color(0xFFFFFFFF);
const Color colorOnSurface = Color(0xFF181D19);
const Color colorOnSurfaceVariant = Color(0xFF404942);
const Color colorOutlineVariant = Color(0xFFE5E7EB);
const Color colorSuccess = Color(0xFF22C55E);

// -------------------- Seuils responsive -------------------------------------
const double _breakpointSmallPhone = 360; // très petits écrans
const double _breakpointWide = 700; // bascule bento grid en 2 colonnes

// -------------------- Modèle de données simple (Map, pas de classe métier) -
final List<Map<String, String>> _allDocuments = [
  {
    'title': 'Macroeconomics_Ch4.pdf',
    'meta': 'Added 2h ago • 4.2 MB',
    'icon': 'picture_as_pdf',
    'type': 'pdf',
  },
  {
    'title': 'History_Thesis_Draft.docx',
    'meta': 'Added Yesterday • 1.1 MB',
    'icon': 'description',
    'type': 'doc',
  },
  {
    'title': 'Lab_Results_Bio.xlsx',
    'meta': 'Added 3 days ago • 850 KB',
    'icon': 'lab_profile',
    'type': 'doc',
  },
  {
    'title': 'Neural_Networks_Intro.pdf',
    'meta': 'Added 5 days ago • 12.4 MB',
    'icon': 'picture_as_pdf',
    'type': 'pdf',
  },
];

// -------------------- Widget public à appeler depuis main.dart -------------
class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String _selectedFilter = 'All'; // 'All' | 'PDFs' | 'Documents'

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _query = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, String>> get _filteredDocuments {
    return _allDocuments.where((doc) {
      final matchesQuery = doc['title']!.toLowerCase().contains(_query);
      final matchesFilter =
          _selectedFilter == 'All' ||
          (_selectedFilter == 'PDFs' && doc['type'] == 'pdf') ||
          (_selectedFilter == 'Documents' && doc['type'] == 'doc');
      return matchesQuery && matchesFilter;
    }).toList();
  }

  void _selectFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
  }

  // Padding horizontal responsive : plus serré sur très petit écran,
  // plus large sur tablette/desktop.
  double _horizontalPadding(double width) {
    if (width < _breakpointSmallPhone) return 12;
    if (width < _breakpointWide) return 16;
    return 48;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorSurface,

      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double width = constraints.maxWidth;
            final double hPad = _horizontalPadding(width);
            return _buildBody(width, hPad);
          },
        ),
      ),
      floatingActionButton: _buildUploadFab(),
    );
  }

  // -------------------- Corps scrollable -------------------------------------
  Widget _buildBody(double width, double hPad) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildWelcomeHero(width),
          const SizedBox(height: 24),
          _buildSearchAndFilterBar(width),
          const SizedBox(height: 24),
          _buildBentoGrid(width),
          const SizedBox(height: 24),
          _buildOfflineTipBanner(width),
          const SizedBox(height: 90),
        ],
      ),
    );
  }

  // -------------------- Hero + stats ------------------------------------------
  Widget _buildWelcomeHero(double width) {
    final bool isSmall = width < _breakpointSmallPhone;
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.end,
      runSpacing: 12,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Library',
              style: TextStyle(
                fontSize: isSmall ? 26 : 32,
                fontWeight: FontWeight.bold,
                color: colorPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Manage and summarize your study materials offline.',
              style: TextStyle(color: colorOnSurfaceVariant, fontSize: 14),
            ),
          ],
        ),
        _buildStatsBox(),
      ],
    );
  }

  Widget _buildStatsBox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: colorSurfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatItem('${_allDocuments.length}', 'Files'),
          Container(
            width: 1,
            height: 32,
            color: colorOutlineVariant,
            margin: const EdgeInsets.symmetric(vertical: 8),
          ),
          _buildStatItem('1.2GB', 'Used'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: colorPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: colorOnSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // -------------------- Recherche + filtres (interactifs, responsive) ----------
  Widget _buildSearchAndFilterBar(double width) {
    final filters = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildFilterChip('All'),
        _buildFilterChip('PDFs'),
        _buildFilterChip('Documents'),
      ],
    );

    // Sur mobile étroit : champ de recherche pleine largeur, filtres en dessous.
    // Sur écran plus large : recherche + filtres sur la même ligne.
    if (width < _breakpointWide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterTextField(),
          const SizedBox(height: 12),
          filters,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: _buildFilterTextField()),
        const SizedBox(width: 12),
        filters,
      ],
    );
  }

  Widget _buildFilterTextField() {
    return SizedBox(
      width: double.infinity,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Filter by name or topic...',
          prefixIcon: const Icon(
            Icons.filter_list,
            color: colorOnSurfaceVariant,
          ),
          filled: true,
          fillColor: colorSurfaceContainerLowest,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: colorOutlineVariant),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: colorOutlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: colorPrimary),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final bool selected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => _selectFilter(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? colorPrimaryContainer : colorSurfaceContainerHigh,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? colorOnPrimaryContainer : colorOnSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // -------------------- Bento grid --------------------------------------------
  Widget _buildBentoGrid(double width) {
    final bool isWide = width >= _breakpointWide;
    final Widget left = _buildQuickInsightsColumn();
    final Widget right = _buildRecentDocumentsColumn();

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 4, child: left),
          const SizedBox(width: 24),
          Expanded(flex: 8, child: right),
        ],
      );
    }
    // Sur mobile : colonne unique, Quick Insights au-dessus, Recent Documents en dessous.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [left, const SizedBox(height: 24), right],
    );
  }

  Widget _buildQuickInsightsColumn() {
    return Column(
      children: [
        _buildAiReadinessCard(),
        const SizedBox(height: 24),
        _buildWeeklyProgressCard(),
      ],
    );
  }

  Widget _buildAiReadinessCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorPrimary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.psychology, color: colorOnPrimary),
          const SizedBox(height: 8),
          const Text(
            'AI Readiness',
            style: TextStyle(
              color: colorOnPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'All ${_allDocuments.length} documents are indexed and ready for offline querying.',
            style: TextStyle(
              color: colorOnPrimary.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: colorSurface,
                foregroundColor: colorPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Optimize Cache',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyProgressCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorSurfaceContainerLowest,
        border: Border.all(color: colorOutlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt, color: colorSecondary),
          const SizedBox(height: 8),
          const Text(
            'Weekly Progress',
            style: TextStyle(
              color: colorOnSurface,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "You've summarized 5 chapters this week. Keep it up!",
            style: TextStyle(color: colorOnSurfaceVariant, fontSize: 14),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: const LinearProgressIndicator(
              value: 0.65,
              minHeight: 8,
              backgroundColor: colorSurfaceContainerLow,
              valueColor: AlwaysStoppedAnimation<Color>(colorPrimary),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------- Liste des documents : une carte par ligne --------------
  Widget _buildRecentDocumentsColumn() {
    final docs = _filteredDocuments;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Documents',
                style: TextStyle(
                  color: colorOnSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: colorPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (docs.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'No documents match your search.',
              style: TextStyle(color: colorOnSurfaceVariant, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          )
        else
          // Colonne verticale : chaque carte occupe toute la largeur disponible,
          // empilées les unes en dessous des autres (une par ligne).
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: docs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final doc = docs[index];
              return _buildDocumentCard(
                title: doc['title']!,
                meta: doc['meta']!,
                iconName: doc['icon']!,
                type: doc['type']!,
              );
            },
          ),
      ],
    );
  }

  IconData _iconFromName(String name) {
    switch (name) {
      case 'picture_as_pdf':
        return Icons.picture_as_pdf;
      case 'description':
        return Icons.description;
      case 'lab_profile':
        return Icons.biotech;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _iconBgFromType(String type) {
    switch (type) {
      case 'pdf':
        return const Color(0xFFFEE2E2);
      default:
        return const Color(0xFFDBEAFE);
    }
  }

  Color _iconColorFromType(String type) {
    switch (type) {
      case 'pdf':
        return const Color(0xFFB91C1C);
      default:
        return const Color(0xFF1D4ED8);
    }
  }

  // Carte document : layout en Row qui s'adapte via Expanded pour ne jamais
  // déborder, quelle que soit la largeur de l'écran.
  Widget _buildDocumentCard({
    required String title,
    required String meta,
    required String iconName,
    required String type,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorSurfaceContainerLowest,
        border: Border.all(color: colorOutlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _iconBgFromType(type),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Icon(
                  _iconFromName(iconName),
                  color: _iconColorFromType(type),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: colorOnSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: colorOnSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.more_vert,
                color: colorOnSurfaceVariant,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Icon(Icons.offline_pin, color: colorSuccess, size: 18),
              SizedBox(width: 6),
              Text(
                'Available Offline',
                style: TextStyle(
                  color: colorSuccess,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorPrimary,
                    foregroundColor: colorOnPrimary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Summarize',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: colorOutlineVariant),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                child: const Icon(
                  Icons.visibility,
                  color: colorOnSurfaceVariant,
                  size: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------- Bandeau Pro Tip ------------------------------------------
  Widget _buildOfflineTipBanner(double width) {
    final bool isSmall = width < _breakpointSmallPhone;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorPrimaryContainer,
        border: Border.all(color: colorOutlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Flex(
        direction: isSmall ? Axis.vertical : Axis.horizontal,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: colorSurfaceContainerLowest,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.lightbulb, color: colorPrimary),
          ),
          SizedBox(width: isSmall ? 0 : 16, height: isSmall ? 12 : 0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Pro Tip',
                  style: TextStyle(
                    color: colorPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "NazariAI processes everything locally. You can upload and summarize documents "
                  "even when you're completely offline. Your data never leaves this device.",
                  style: TextStyle(color: colorOnSurfaceVariant, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------- FAB (icône seule sur petit écran, label sur le reste) ----
  Widget _buildUploadFab() {
    return Builder(
      builder: (context) {
        final double screenWidth = MediaQuery.of(context).size.width;
        if (screenWidth < _breakpointSmallPhone) {
          return FloatingActionButton(
            onPressed: () {},
            backgroundColor: colorPrimary,
            foregroundColor: colorOnPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.add),
          );
        }
        return FloatingActionButton.extended(
          onPressed: () {},
          backgroundColor: colorPrimary,
          foregroundColor: colorOnPrimary,
          icon: const Icon(Icons.add),
          label: const Text(
            'Upload New Document',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        );
      },
    );
  }
}
