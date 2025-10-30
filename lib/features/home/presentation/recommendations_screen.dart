import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:navistfind/core/navigation/app_routes.dart';
import 'package:navistfind/features/lost_found/item/domain/models/item.dart';
import 'package:navistfind/features/lost_found/item/presentation/item_details_screen.dart';
import 'package:navistfind/core/network/api_client.dart' as core;
import 'package:navistfind/services/auth_store.dart';
import 'package:navistfind/features/lost_found/post-item/domain/enums/item_type.dart';
import 'package:navistfind/core/theme/app_theme.dart';
import 'package:navistfind/core/utils/category_utils.dart';
import 'package:navistfind/core/utils/date_formatter.dart';

class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  bool _loading = true;
  String? _error;
  List<MatchScoreItem> _items = const [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await AuthStore.getToken();
      if (token == null || token.isEmpty) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, AppRoutes.login);
        return;
      }
      final res = await core.ApiClient.client.get('/api/items/recommended');
      if (res.statusCode == 200) {
        final data = res.data;
        final List<dynamic> list = data is List
            ? data
            : (data['data'] as List? ?? []);
        final parsed = list.map((e) => MatchScoreItem.fromJson(e)).toList();
        setState(() {
          _items = parsed..sort((a, b) => b.score.compareTo(a.score));
          _loading = false;
        });
      } else if (res.statusCode == 204) {
        setState(() {
          _items = const [];
          _loading = false;
        });
      } else if (res.statusCode == 401 || res.statusCode == 403) {
        await AuthStore.clearToken();
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      } else {
        setState(() {
          _error = 'Failed to load recommendations (code ${res.statusCode})';
          _loading = false;
        });
      }
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 401 || status == 403) {
        await AuthStore.clearToken();
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, AppRoutes.login);
        return;
      }
      setState(() {
        _error =
            e.response?.data is Map && (e.response?.data['message'] is String)
            ? e.response?.data['message'] as String
            : e.message ?? 'Network error';
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const SizedBox(height: 16), // Top margin
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryBlue,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(AppTheme.radiusXLarge),
                      bottomRight: Radius.circular(AppTheme.radiusXLarge),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingL,
                    vertical: AppTheme.spacingM,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Center(
                          child: Text(
                            'Smart Recommendations',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48), // Balance with back button
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetch,
        color: AppTheme.primaryBlue,
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return _buildLoadingState();
    }
    if (_error != null) {
      return _buildErrorState();
    }
    if (_items.isEmpty) {
      return _buildEmptyState();
    }
    return _buildRecommendationsList();
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: Column(
        children: [
          const SizedBox(height: AppTheme.spacingXXL),
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingXL),
            decoration: AppTheme.getCardDecoration(
              borderRadius: AppTheme.radiusLarge,
            ),
            child: Column(
              children: [
                const CircularProgressIndicator(color: AppTheme.primaryBlue),
                const SizedBox(height: AppTheme.spacingL),
                Text(
                  'Loading recommendations...',
                  style: AppTheme.bodyLarge.copyWith(color: AppTheme.textGray),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          ...List.generate(3, (index) => _buildSkeletonCard()),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spacingXL),
          decoration: AppTheme.getCardDecoration(
            borderRadius: AppTheme.radiusLarge,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: AppTheme.errorRed,
              ),
              const SizedBox(height: AppTheme.spacingL),
              Text(
                'Failed to load recommendations',
                style: AppTheme.heading4,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingS),
              Text(
                _error!,
                style: AppTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingXL),
              ElevatedButton(
                onPressed: _fetch,
                style: AppTheme.getPrimaryButtonStyle(),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spacingXL),
          decoration: AppTheme.getCardDecoration(
            borderRadius: AppTheme.radiusLarge,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingL),
                decoration: BoxDecoration(
                  color: AppTheme.lightPanel,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                ),
                child: const Icon(
                  Icons.auto_awesome_outlined,
                  size: 48,
                  color: AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(height: AppTheme.spacingL),
              Text(
                'No recommendations yet',
                style: AppTheme.heading4,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingS),
              Text(
                'Post a lost item to get personalized recommendations',
                style: AppTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendationsList() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingL),
                  decoration: BoxDecoration(
                    gradient: AppTheme.cardGradient,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacingM),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMedium,
                          ),
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingL),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI-Powered Matching',
                              style: AppTheme.heading4.copyWith(
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacingXS),
                            Text(
                              'Based on your recent lost items',
                              style: AppTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXL),
                Text('Recommended Items', style: AppTheme.heading3),
                const SizedBox(height: AppTheme.spacingS),
                Text('${_items.length} items found', style: AppTheme.bodySmall),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final match = _items[index];
              final item = match.item;
              if (item == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacingL),
                child: _buildRecommendationCard(item),
              );
            }, childCount: _items.length),
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationCard(Item item) {
    return Container(
      decoration: AppTheme.getCardDecoration(
        borderRadius: AppTheme.radiusLarge,
        shadows: AppTheme.elevatedShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          onTap: () {
            showDialog(
              context: context,
              barrierDismissible: true,
              builder: (_) =>
                  ItemDetailsModal(itemId: item.id, type: ItemType.found),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Row(
              children: [
                // Category Icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.lightPanel,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: Icon(
                    CategoryUtils.getIcon(item.category),
                    color: AppTheme.primaryBlue,
                    size: 28,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingL),
                // Item Details - Simplified
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: AppTheme.heading4,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppTheme.spacingXS),
                      Row(
                        children: [
                          const Icon(
                            Icons.place_outlined,
                            size: 14,
                            color: AppTheme.textGray,
                          ),
                          const SizedBox(width: AppTheme.spacingXS),
                          Expanded(
                            child: Text(
                              item.location,
                              style: AppTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time_outlined,
                            size: 14,
                            color: AppTheme.textGray,
                          ),
                          const SizedBox(width: AppTheme.spacingXS),
                          Text(
                            DateFormatter.formatRelativeDate(item.date),
                            style: AppTheme.caption,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingL),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: AppTheme.lightGray,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
      ),
    );
  }
}
