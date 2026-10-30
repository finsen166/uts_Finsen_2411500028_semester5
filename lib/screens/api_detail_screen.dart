// lib/screens/api_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/api_provider.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';

class ApiDetailScreen extends StatefulWidget {
  final int productId;

  const ApiDetailScreen({super.key, required this.productId});

  @override
  State<ApiDetailScreen> createState() => _ApiDetailScreenState();
}

class _ApiDetailScreenState extends State<ApiDetailScreen> {
  int _selectedImageIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ApiProvider>().fetchProductById(widget.productId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Produk'),
        centerTitle: true,
      ),
      body: Consumer<ApiProvider>(
        builder: (context, provider, _) {
          if (provider.isLoadingDetail) {
            return const LoadingWidget(message: 'Memuat detail produk...');
          }

          if (provider.detailError != null) {
            return AppErrorWidget(
              message: provider.detailError!,
              onRetry: () => provider.fetchProductById(widget.productId),
            );
          }

          final product = provider.selectedProduct;
          if (product == null) {
            return const LoadingWidget(message: 'Memuat...');
          }

          return Center(
            child: SingleChildScrollView(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 800),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image Gallery
                    if (product.images.isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: CachedNetworkImage(
                            imageUrl: product.images[_selectedImageIndex],
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: colorScheme.surfaceContainerHighest,
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: colorScheme.surfaceContainerHighest,
                              child: const Icon(
                                Icons.image_not_supported_rounded,
                                size: 64,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (product.images.length > 1) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 72,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: product.images.length,
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () {
                                  setState(() => _selectedImageIndex = index);
                                },
                                child: Container(
                                  width: 72,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _selectedImageIndex == index
                                          ? colorScheme.primary
                                          : colorScheme.outline
                                              .withValues(alpha: 0.3),
                                      width:
                                          _selectedImageIndex == index ? 2 : 1,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(7),
                                    child: CachedNetworkImage(
                                      imageUrl: product.images[index],
                                      fit: BoxFit.cover,
                                      errorWidget: (ctx, url, err) =>
                                          const Icon(Icons.image_rounded),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                    const SizedBox(height: 16),
                    // Product Info
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: colorScheme.outline.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title and price row
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    product.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '\$${product.price.toStringAsFixed(2)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(
                                            color: colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    if (product.discountPercentage > 0)
                                      Text(
                                        '-${product.discountPercentage.toStringAsFixed(0)}%',
                                        style: const TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Chips
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                _buildChip(
                                    context,
                                    product.category,
                                    Icons.category_rounded,
                                    colorScheme.primaryContainer),
                                if (product.brand.isNotEmpty)
                                  _buildChip(
                                      context,
                                      product.brand,
                                      Icons.business_rounded,
                                      colorScheme.secondaryContainer),
                                _buildChip(
                                    context,
                                    'Stok: ${product.stock}',
                                    Icons.inventory_rounded,
                                    product.stock > 0
                                        ? Colors.green.shade100
                                        : Colors.red.shade100),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Rating
                            Row(
                              children: [
                                ...List.generate(5, (i) {
                                  return Icon(
                                    i < product.rating.floor()
                                        ? Icons.star_rounded
                                        : (i < product.rating
                                            ? Icons.star_half_rounded
                                            : Icons.star_border_rounded),
                                    color: Colors.amber[700],
                                    size: 20,
                                  );
                                }),
                                const SizedBox(width: 8),
                                Text(
                                  '${product.rating.toStringAsFixed(1)} / 5.0',
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            // Description
                            Text(
                              'Deskripsi',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              product.description,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    height: 1.6,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChip(BuildContext context, String label, IconData icon,
      Color backgroundColor) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      visualDensity: VisualDensity.compact,
    );
  }
}
