// lib/features/pos/widgets/payment_checkout_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/pos_provider.dart';

final _vnd = NumberFormat('#,###', 'vi_VN');

class PaymentCheckoutDialog extends ConsumerStatefulWidget {
  const PaymentCheckoutDialog({super.key});

  @override
  ConsumerState<PaymentCheckoutDialog> createState() => _PaymentCheckoutDialogState();
}

class _PaymentCheckoutDialogState extends ConsumerState<PaymentCheckoutDialog> {
  final _tipCtrl = TextEditingController();
  final _discountValueCtrl = TextEditingController();
  final _discountReasonCtrl = TextEditingController();
  final _splitAmountCtrl = TextEditingController();

  String _discountType = 'fixed';
  String _selectedPaymentMethod = 'cash';

  @override
  void initState() {
    super.initState();
    final pos = ref.read(posProvider);
    if (pos.tipAmount > 0) _tipCtrl.text = pos.tipAmount.toStringAsFixed(0);
    if (pos.discountValue > 0) _discountValueCtrl.text = pos.discountValue.toStringAsFixed(0);
    if (pos.discountReason != null) _discountReasonCtrl.text = pos.discountReason!;
    _discountType = pos.discountType;
    _selectedPaymentMethod = pos.paymentMethod;
  }

  void _applyAdjustments() {
    final tip = double.tryParse(_tipCtrl.text.replaceAll(',', '')) ?? 0;
    ref.read(posProvider.notifier).setTip(tip);

    final discountVal = double.tryParse(_discountValueCtrl.text.replaceAll(',', '')) ?? 0;
    ref.read(posProvider.notifier).setDiscount(
      type: _discountType, 
      value: discountVal, 
      reason: _discountReasonCtrl.text.isNotEmpty ? _discountReasonCtrl.text : null,
    );
  }

  double _getRemainingAmount(PosState pos) {
    final paid = pos.splitPayments.fold(0.0, (sum, p) => sum + (p['amount'] as double));
    return pos.grandTotal - paid;
  }

  @override
  Widget build(BuildContext context) {
    final pos = ref.watch(posProvider);
    final remaining = _getRemainingAmount(pos);

    return Dialog(
      backgroundColor: const Color(0xFF151520),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('THANH TOÁN', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left side: Adjustments (Tip & Discount)
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ĐIỀU CHỈNH', style: TextStyle(color: Color(0xFF888899), fontSize: 12)),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _tipCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(labelText: 'Tiền Tip (VND)', labelStyle: TextStyle(color: Color(0xFF555566))),
                          onChanged: (_) => _applyAdjustments(),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _discountValueCtrl,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: _discountType == 'percentage' ? 'Giảm giá (%)' : 'Giảm giá (VND)',
                                  labelStyle: const TextStyle(color: Color(0xFF555566)),
                                ),
                                onChanged: (_) => _applyAdjustments(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            DropdownButton<String>(
                              value: _discountType,
                              dropdownColor: const Color(0xFF252535),
                              style: const TextStyle(color: Colors.white),
                              items: const [
                                DropdownMenuItem(value: 'fixed', child: Text('VND')),
                                DropdownMenuItem(value: 'percentage', child: Text('%')),
                              ],
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() => _discountType = v);
                                  _applyAdjustments();
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _discountReasonCtrl,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(labelText: 'Lý do giảm giá', labelStyle: TextStyle(color: Color(0xFF555566))),
                          onChanged: (_) => _applyAdjustments(),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: const Color(0xFF1D1D2B), borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Tạm tính: ${_vnd.format(pos.subtotal)} đ', style: const TextStyle(color: Color(0xFF888899))),
                              if (pos.tipAmount > 0) Text('+ Tip: ${_vnd.format(pos.tipAmount)} đ', style: const TextStyle(color: Color(0xFF888899))),
                              if (pos.discountAmount > 0) Text('- Giảm giá: ${_vnd.format(pos.discountAmount)} đ', style: const TextStyle(color: Colors.green)),
                              if (pos.taxAmount > 0) Text('+ Thuế: ${_vnd.format(pos.taxAmount)} đ', style: const TextStyle(color: Colors.orange)),
                              const Divider(color: Color(0xFF333344)),
                              Text('TỔNG CỘNG: ${_vnd.format(pos.grandTotal)} đ', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const VerticalDivider(color: Color(0xFF252535), width: 32),
                  
                  // Right side: Payment Methods
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('PHƯƠNG THỨC THANH TOÁN', style: TextStyle(color: Color(0xFF888899), fontSize: 12)),
                        const SizedBox(height: 12),
                        
                        // List of added split payments
                        if (pos.splitPayments.isNotEmpty) ...[
                          ...pos.splitPayments.map((p) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(_getIconForMethod(p['method'] as String), color: const Color(0xFF888899)),
                            title: Text(_getNameForMethod(p['method'] as String), style: const TextStyle(color: Colors.white)),
                            trailing: Text('${_vnd.format(p['amount'])} đ', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                          )),
                          TextButton(
                            onPressed: () => ref.read(posProvider.notifier).clearSplitPayments(),
                            child: const Text('Xóa tất cả', style: TextStyle(color: Colors.red)),
                          ),
                          const Divider(color: Color(0xFF252535)),
                        ],

                        if (remaining > 0) ...[
                          Text('Cần thu thêm: ${_vnd.format(remaining)} đ', style: const TextStyle(color: Colors.orange, fontSize: 16)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButton<String>(
                                  value: _selectedPaymentMethod,
                                  isExpanded: true,
                                  dropdownColor: const Color(0xFF252535),
                                  style: const TextStyle(color: Colors.white),
                                  items: const [
                                    DropdownMenuItem(value: 'cash', child: Text('Tiền mặt')),
                                    DropdownMenuItem(value: 'card', child: Text('Thẻ')),
                                    DropdownMenuItem(value: 'transfer', child: Text('Chuyển khoản')),
                                  ],
                                  onChanged: (v) {
                                    if (v != null) setState(() => _selectedPaymentMethod = v);
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _splitAmountCtrl..text = remaining.toStringAsFixed(0),
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(labelText: 'Số tiền'),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle, color: Color(0xFFFF6B9D)),
                                onPressed: () {
                                  final amount = double.tryParse(_splitAmountCtrl.text.replaceAll(',', '')) ?? 0;
                                  if (amount > 0 && amount <= remaining) {
                                    ref.read(posProvider.notifier).addSplitPayment(_selectedPaymentMethod, amount);
                                    _splitAmountCtrl.clear();
                                  }
                                },
                              ),
                            ],
                          ),
                        ] else ...[
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('Đã đủ tiền!', style: TextStyle(color: Colors.green, fontSize: 18, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy', style: TextStyle(color: Color(0xFF888899))),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: remaining == 0 ? () async {
                    // Call checkout logic
                    await ref.read(posProvider.notifier).checkout();
                    if (context.mounted) Navigator.pop(context);
                  } : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B9D),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: pos.isCheckingOut
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('HOÀN TẤT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  IconData _getIconForMethod(String method) {
    switch (method) {
      case 'cash': return Icons.money;
      case 'card': return Icons.credit_card;
      case 'transfer': return Icons.qr_code;
      default: return Icons.payment;
    }
  }

  String _getNameForMethod(String method) {
    switch (method) {
      case 'cash': return 'Tiền mặt';
      case 'card': return 'Thẻ';
      case 'transfer': return 'Chuyển khoản';
      default: return 'Khác';
    }
  }
}
