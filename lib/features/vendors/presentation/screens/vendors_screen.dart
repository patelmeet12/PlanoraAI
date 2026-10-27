import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/accessible_card.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../events/presentation/providers/event_providers.dart';
import '../../domain/models/vendor_category.dart';
import '../../domain/models/vendor_model.dart';
import '../../domain/services/vendor_service.dart';

class VendorsScreen extends ConsumerStatefulWidget {
  const VendorsScreen({super.key});

  @override
  ConsumerState<VendorsScreen> createState() => _VendorsScreenState();
}

class _VendorsScreenState extends ConsumerState<VendorsScreen> {
  VendorCategory? _selectedCategory;
  bool _isComparing = false;

  @override
  Widget build(BuildContext context) {
    final activeEventAsync = ref.watch(activeEventProvider);
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;

    return activeEventAsync.when(
      data: (aggregate) {
        if (aggregate == null) {
          return const EmptyStateView(
            icon: Icons.storefront_outlined,
            title: 'No Event Active',
            message: 'Create an event to organize suppliers and vendors.',
          );
        }

        final vendors = aggregate.vendors;
        final cur = aggregate.event.currency;

        final filtered = _selectedCategory == null
            ? vendors
            : vendors.where((v) => v.category == _selectedCategory).toList();

        final comparisonItems = _selectedCategory != null
            ? VendorService.compareVendors(filtered)
            : <VendorComparisonItem>[];

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: width > 900 ? 36 : 16,
            vertical: 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Action Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Vendor Organizer', style: theme.textTheme.headlineMedium),
                      Text(
                        'Track quotes, evaluate side-by-side benchmarks, and manage bookings',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (filtered.length >= 2)
                        OutlinedButton.icon(
                          onPressed: () => setState(() => _isComparing = !_isComparing),
                          icon: Icon(_isComparing ? Icons.view_agenda : Icons.compare),
                          label: Text(_isComparing ? 'Standard View' : 'Compare Category'),
                        ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: () => _showAddVendorDialog(context, aggregate.event.id),
                        icon: const Icon(Icons.add_business, size: 18),
                        label: const Text('Add Vendor'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Transparent Booking Disclaimer
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withAlpha(100),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: theme.colorScheme.outline),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_user_outlined, size: 18, color: AppColors.info),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Planora AI provides planning records and cost estimates. Final contracts, bookings, and payments must be confirmed directly with independent service providers.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Category Filter Chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterChip(
                    label: const Text('All Vendors'),
                    selected: _selectedCategory == null,
                    onSelected: (_) => setState(() {
                      _selectedCategory = null;
                      _isComparing = false;
                    }),
                  ),
                  ...VendorCategory.values.map((cat) {
                    final isSel = _selectedCategory == cat;
                    return FilterChip(
                      label: Text(cat.displayName),
                      selected: isSel,
                      onSelected: (val) {
                        setState(() {
                          _selectedCategory = val ? cat : null;
                        });
                      },
                    );
                  }),
                ],
              ),
              const SizedBox(height: 20),

              // Comparison View (if activated)
              if (_isComparing && comparisonItems.isNotEmpty) ...[
                _buildComparisonTable(context, comparisonItems, cur),
                const SizedBox(height: 24),
              ],

              // Vendor Cards List
              if (filtered.isEmpty)
                const EmptyStateView(
                  icon: Icons.store_outlined,
                  title: 'No Vendors in Category',
                  message: 'Add a vendor record to track quotes and contact details.',
                )
              else
                ...filtered.map((v) => _buildVendorCard(context, v, cur)),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading vendors: $e')),
    );
  }

  Widget _buildComparisonTable(
    BuildContext context,
    List<VendorComparisonItem> items,
    String cur,
  ) {
    final theme = Theme.of(context);

    return AccessibleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.compare_arrows, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Side-by-Side Category Comparison (${_selectedCategory?.displayName})',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Vendor Name')),
                DataColumn(label: Text('Quoted / Est.')),
                DataColumn(label: Text('Price Delta vs Avg')),
                DataColumn(label: Text('Rating')),
                DataColumn(label: Text('Booking Status')),
                DataColumn(label: Text('Payment')),
              ],
              rows: items.map((c) {
                final v = c.vendor;
                final price = v.quotedPrice > 0 ? v.quotedPrice : v.estimatedPrice;

                return DataRow(
                  cells: [
                    DataCell(
                      Row(
                        children: [
                          Text(v.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          if (c.isLowestPrice) ...[
                            const SizedBox(width: 6),
                            const StatusBadge(label: 'Lowest Price', type: BadgeType.success, compact: true),
                          ],
                          if (c.isHighestRated) ...[
                            const SizedBox(width: 6),
                            const StatusBadge(label: 'Top Rated', type: BadgeType.info, compact: true),
                          ],
                        ],
                      ),
                    ),
                    DataCell(Text(CurrencyFormatter.format(price, currency: cur))),
                    DataCell(
                      Text(
                        c.priceDifference > 0
                            ? '+${CurrencyFormatter.format(c.priceDifference, currency: cur)}'
                            : (c.priceDifference < 0
                                ? '-${CurrencyFormatter.format(c.priceDifference.abs(), currency: cur)}'
                                : 'Average'),
                        style: TextStyle(
                          color: c.priceDifference > 0 ? AppColors.warning : AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    DataCell(
                      Row(
                        children: [
                          const Icon(Icons.star, size: 14, color: AppColors.secondary),
                          const SizedBox(width: 4),
                          Text('${v.userRating} / 5.0'),
                        ],
                      ),
                    ),
                    DataCell(Text(v.bookingStatus.displayName)),
                    DataCell(Text(v.paymentStatus.displayName)),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVendorCard(BuildContext context, VendorModel vendor, String cur) {
    final theme = Theme.of(context);
    final price = vendor.quotedPrice > 0 ? vendor.quotedPrice : vendor.estimatedPrice;

    BadgeType statusType;
    switch (vendor.bookingStatus) {
      case BookingStatus.booked:
        statusType = BadgeType.success;
        break;
      case BookingStatus.quoted:
      case BookingStatus.shortlisted:
        statusType = BadgeType.info;
        break;
      case BookingStatus.declined:
        statusType = BadgeType.error;
        break;
      default:
        statusType = BadgeType.neutral;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: AccessibleCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            vendor.name,
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          if (vendor.isDemoData) ...[
                            const SizedBox(width: 8),
                            const StatusBadge(
                              label: 'Illustrative Benchmark',
                              icon: Icons.science_outlined,
                              type: BadgeType.neutral,
                              compact: true,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Category: ${vendor.category.displayName}',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.format(price, currency: cur),
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      vendor.quotedPrice > 0 ? 'Formal Quote' : 'Estimated Benchmark',
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (vendor.notes != null && vendor.notes!.isNotEmpty) ...[
              Text(vendor.notes!, style: theme.textTheme.bodySmall),
              const SizedBox(height: 12),
            ],

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Wrap(
                  spacing: 8,
                  children: [
                    StatusBadge(label: vendor.bookingStatus.displayName, type: statusType, compact: true),
                    StatusBadge(label: vendor.paymentStatus.displayName, type: BadgeType.neutral, compact: true),
                    if (vendor.userRating > 0)
                      StatusBadge(
                        label: '★ ${vendor.userRating.toStringAsFixed(1)}',
                        type: BadgeType.neutral,
                        compact: true,
                      ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      tooltip: 'Edit Status / Notes',
                      onPressed: () => _showEditVendorDialog(context, vendor),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      tooltip: 'Delete Vendor',
                      onPressed: () async {
                        final confirm = await ConfirmDialog.show(
                          context,
                          title: 'Delete Vendor?',
                          content: 'Are you sure you want to remove "${vendor.name}"?',
                          confirmLabel: 'Delete',
                          isDestructive: true,
                        );
                        if (confirm == true) {
                          await ref.read(activeEventProvider.notifier).deleteVendor(vendor.id);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddVendorDialog(BuildContext context, String eventId) {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    VendorCategory category = VendorCategory.caterer;
    BookingStatus bookingStatus = BookingStatus.inquiry;
    PaymentStatus paymentStatus = PaymentStatus.unpaid;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDlgState) {
            return AlertDialog(
              title: const Text('Add Vendor Record'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Vendor / Company Name *'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<VendorCategory>(
                      initialValue: category,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: VendorCategory.values.map((c) {
                        return DropdownMenuItem(value: c, child: Text(c.displayName));
                      }).toList(),
                      onChanged: (v) => setDlgState(() => category = v!),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: priceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Price / Quote *', prefixText: '\$ '),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<BookingStatus>(
                      initialValue: bookingStatus,
                      decoration: const InputDecoration(labelText: 'Booking Status'),
                      items: BookingStatus.values.map((b) {
                        return DropdownMenuItem(value: b, child: Text(b.displayName));
                      }).toList(),
                      onChanged: (v) => setDlgState(() => bookingStatus = v!),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Deliverables & Notes'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    final price = double.tryParse(priceCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
                    if (name.isEmpty) return;

                    const uuid = Uuid();
                    final newVendor = VendorModel(
                      id: uuid.v4(),
                      eventId: eventId,
                      name: name,
                      category: category,
                      quotedPrice: price,
                      bookingStatus: bookingStatus,
                      paymentStatus: paymentStatus,
                      notes: notesCtrl.text.trim(),
                      isDemoData: false,
                    );

                    await ref.read(activeEventProvider.notifier).saveVendor(newVendor);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Save Vendor'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditVendorDialog(BuildContext context, VendorModel vendor) {
    final notesCtrl = TextEditingController(text: vendor.notes);
    final quoteCtrl = TextEditingController(text: vendor.quotedPrice.toStringAsFixed(0));
    BookingStatus bookingStatus = vendor.bookingStatus;
    PaymentStatus paymentStatus = vendor.paymentStatus;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDlgState) {
            return AlertDialog(
              title: Text('Update ${vendor.name}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: quoteCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Quoted Price', prefixText: '\$ '),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<BookingStatus>(
                      initialValue: bookingStatus,
                      decoration: const InputDecoration(labelText: 'Booking Status'),
                      items: BookingStatus.values.map((b) {
                        return DropdownMenuItem(value: b, child: Text(b.displayName));
                      }).toList(),
                      onChanged: (v) => setDlgState(() => bookingStatus = v!),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<PaymentStatus>(
                      initialValue: paymentStatus,
                      decoration: const InputDecoration(labelText: 'Payment Status'),
                      items: PaymentStatus.values.map((p) {
                        return DropdownMenuItem(value: p, child: Text(p.displayName));
                      }).toList(),
                      onChanged: (v) => setDlgState(() => paymentStatus = v!),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Notes & Deliverables'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    final quote = double.tryParse(quoteCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? vendor.quotedPrice;
                    final updated = vendor.copyWith(
                      quotedPrice: quote,
                      bookingStatus: bookingStatus,
                      paymentStatus: paymentStatus,
                      notes: notesCtrl.text.trim(),
                    );

                    await ref.read(activeEventProvider.notifier).saveVendor(updated);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
