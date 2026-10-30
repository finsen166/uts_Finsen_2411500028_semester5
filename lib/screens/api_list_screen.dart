// lib/screens/api_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/api_provider.dart';
import '../providers/view_state.dart';
import '../models/product_model.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';
import '../widgets/empty_widget.dart';
import 'api_detail_screen.dart';

class ApiListScreen extends StatefulWidget {
  const ApiListScreen({super.key});

  @override
  State<ApiListScreen> createState() => _ApiListScreenState();
}

class _ApiListScreenState extends State<ApiListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ApiProvider>().fetchProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ApiProvider>(
      builder: (context, provider, _) {
        if (provider.state == ViewState.loading) {
          return const LoadingWidget(message: 'Memuat produk...');
        }

        if (provider.state == ViewState.error) {
          return AppErrorWidget(
            message: provider.errorMessage ?? 'Gagal memuat produk',
            onRetry: provider.retry,
          );
        }

        if (provider.state == ViewState.empty) {
          return EmptyWidget(
            title: 'Tidak ada produk',
            subtitle: 'Tidak ada produk yang ditemukan.',
            icon: Icons.shopping_bag_rounded,
            action: FilledButton.icon(
              onPressed: provider.retry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Muat Ulang'),
            ),
          );
        }

        if (provider.state == ViewState.initial) {
          return const LoadingWidget(message: 'Menginisialisasi...');
        }

        return _buildProductGrid(context, provider.products, provider);
      },
    );
  }

  Widget _buildProductGrid(
      BuildContext context, List<ProductModel> products, ApiProvider provider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900
            ? 4
            : constraints.maxWidth > 600
                ? 3
                : 2;

        return RefreshIndicator(
          onRefresh: () => provider.fetchProducts(force: true),
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.72,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final product = products[index];
                      return _buildProductCard(context, product);
                    },
                    childCount: products.length,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductCard(BuildContext context, ProductModel product) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ApiDetailScreen(productId: product.id),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: product.thumbnail.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: product.thumbnail,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: colorScheme.surfaceContainerHighest,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.image_not_supported_rounded,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : Container(
                      color: colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.image_rounded,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.category,
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Text(
                      '\$${product.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.star_rounded,
                            size: 14, color: Colors.amber[700]),
                        Text(
                          ' ${product.rating.toStringAsFixed(1)}',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
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
