import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:universal_html/html.dart' as html;

import '../models/salon.dart';
import '../models/transaction.dart';

abstract class PrinterService {
  Future<void> printBill({
    required Transaction transaction,
    required Salon? salon,
    String? customerName,
    String? staffName,
  });

  Future<void> shareBill({
    required Transaction transaction,
    required Salon? salon,
    String? customerName,
    String? staffName,
  });
}

class PdfPrinterService implements PrinterService {
  @override
  Future<void> printBill({
    required Transaction transaction,
    required Salon? salon,
    String? customerName,
    String? staffName,
  }) async {
    final bytes = await _buildBillPdf(
      transaction: transaction,
      salon: salon,
      customerName: customerName,
      staffName: staffName,
    );
    await Printing.layoutPdf(onLayout: (format) async => bytes);
  }

  @override
  Future<void> shareBill({
    required Transaction transaction,
    required Salon? salon,
    String? customerName,
    String? staffName,
  }) async {
    final bytes = await _buildBillPdf(
      transaction: transaction,
      salon: salon,
      customerName: customerName,
      staffName: staffName,
    );
    final fileName = 'bill_${transaction.id.toString().padLeft(6, '0')}.pdf';

    if (kIsWeb) {
      _downloadPdfOnWeb(bytes, fileName);
      return;
    }

    try {
      await Printing.sharePdf(bytes: bytes, filename: fileName);
    } catch (_) {
      await Printing.layoutPdf(onLayout: (format) async => bytes);
    }
  }

  void _downloadPdfOnWeb(Uint8List bytes, String fileName) {
    final blob = html.Blob(<dynamic>[bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..style.display = 'none';

    html.document.body?.children.add(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
  }

  Future<Uint8List> _buildBillPdf({
    required Transaction transaction,
    required Salon? salon,
    String? customerName,
    String? staffName,
  }) async {
    final baseFont = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();

    final doc = pw.Document();
    final vnd = NumberFormat('#,###');
    final paidAt = DateFormat('dd/MM/yyyy HH:mm').format(
      transaction.paidAt ?? DateTime.now(),
    );

    doc.addPage(
      pw.Page(
        theme: pw.ThemeData.withFont(base: baseFont, bold: boldFont),
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(20),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  salon?.name ?? 'Nail Studio',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              if ((salon?.address ?? '').isNotEmpty)
                pw.Center(child: pw.Text(salon?.address ?? '')),
              if ((salon?.phone ?? '').isNotEmpty)
                pw.Center(child: pw.Text('ĐT: ${salon?.phone ?? ''}')),
              pw.SizedBox(height: 10),
              pw.Divider(),
              pw.SizedBox(height: 6),
              _metaRow('Hóa đơn', '#${transaction.id.toString().padLeft(6, '0')}'),
              _metaRow('Thời gian', paidAt),
              if ((customerName ?? '').isNotEmpty)
                _metaRow('Khách hàng', customerName ?? ''),
              if ((staffName ?? '').isNotEmpty)
                _metaRow('Nhân viên', staffName ?? ''),
              pw.SizedBox(height: 10),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  children: [
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: pw.Text(
                            'Dịch vụ',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Text(
                          'Giá',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 6),
                    ...transaction.items.map(
                      (item) => pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 3),
                        child: pw.Row(
                          children: [
                            pw.Expanded(child: pw.Text(item.serviceName)),
                            pw.Text('${vnd.format(item.price)}đ'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
              _summaryRow('Tạm tính', '${vnd.format(transaction.subtotal)}đ'),
              if (transaction.tipAmount > 0)
                _summaryRow('Tip', '+ ${vnd.format(transaction.tipAmount)}đ'),
              if (transaction.taxAmount > 0)
                _summaryRow('Thuế', '+ ${vnd.format(transaction.taxAmount)}đ'),
              if (transaction.discountAmount > 0)
                _summaryRow(
                  'Giảm giá',
                  '- ${vnd.format(transaction.discountAmount)}đ',
                ),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Tổng cộng',
                    style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    '${vnd.format(transaction.totalAmount)}đ',
                    style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Text('Thanh toán: ${_paymentMethodLabel(transaction.paymentMethod)}'),
              pw.Spacer(),
              pw.Center(
                child: pw.Text(
                  'Cảm ơn quý khách đã sử dụng dịch vụ!',
                  style: const pw.TextStyle(fontSize: 11),
                ),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  pw.Widget _metaRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(color: PdfColors.grey700)),
          pw.Text(value),
        ],
      ),
    );
  }

  pw.Widget _summaryRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [pw.Text(label), pw.Text(value)],
      ),
    );
  }

  String _paymentMethodLabel(String method) {
    return switch (method) {
      'cash' => 'Tiền mặt',
      'card' => 'Thẻ',
      'transfer' => 'Chuyển khoản',
      _ => method,
    };
  }
}

final printerServiceProvider = Provider<PrinterService>((ref) {
  return PdfPrinterService();
});
