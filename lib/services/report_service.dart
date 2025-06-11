import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:bike_rental_app/models/payment.dart';
import 'package:bike_rental_app/models/rental.dart';

class ReportService {
  // Tạo báo cáo tổng quan
  Future<Uint8List> generateOverviewReport({
    required DateTime startDate,
    required DateTime endDate,
    required int totalRentals,
    required double totalRevenue,
    required double totalCompensation,
    required double totalLateFee,
    required int completedRentals,
    required Map<String, int> methodCounts,
    required Map<String, double> methodRevenues,
    required double revenueGrowth,
    required double rentalGrowth,
  }) async {
    // Tạo đối tượng PDF
    final pdf = pw.Document();

    // Tải font hỗ trợ tiếng Việt từ assets
    final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    final fontDataBold = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');

    // Tạo font từ dữ liệu
    final font = pw.Font.ttf(fontData.buffer.asByteData());
    final fontBold = pw.Font.ttf(fontDataBold.buffer.asByteData());

    // Định dạng tiền tệ
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    // Định dạng ngày tháng
    final dateFormat = DateFormat('dd/MM/yyyy');

    // Tạo trang báo cáo
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'BÁO CÁO THỐNG KÊ',
                    style: pw.TextStyle(font: fontBold, fontSize: 24),
                  ),
                  pw.Text(
                    'SmurfBike',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 20,
                      color: PdfColors.blue700,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Thời gian: ${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}',
                style: pw.TextStyle(font: font, fontSize: 14),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Ngày xuất báo cáo: ${dateFormat.format(DateTime.now())}',
                style: pw.TextStyle(font: font, fontSize: 14),
              ),
              pw.Divider(),
            ],
          );
        },
        footer: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Divider(),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'SmurfBike - Hệ thống quản lý cho thuê xe máy',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.Text(
                    'Trang ${context.pageNumber}/${context.pagesCount}',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
        build: (pw.Context context) {
          return [
            // Phần tổng quan
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'TỔNG QUAN',
                  style: pw.TextStyle(font: fontBold, fontSize: 18),
                ),
                pw.SizedBox(height: 8),
                pw.Row(
                  children: [
                    _buildInfoBox(
                      title: 'Tổng số đơn thuê',
                      value: '$totalRentals',
                      growth: rentalGrowth,
                      font: font,
                      fontBold: fontBold,
                      width: 250,
                    ),
                    pw.SizedBox(width: 20),
                    _buildInfoBox(
                      title: 'Đơn hoàn thành',
                      value: '$completedRentals',
                      growth: null,
                      font: font,
                      fontBold: fontBold,
                      width: 250,
                    ),
                  ],
                ),
                pw.SizedBox(height: 16),
                pw.Row(
                  children: [
                    _buildInfoBox(
                      title: 'Tổng doanh thu',
                      value: currencyFormat.format(totalRevenue),
                      growth: revenueGrowth,
                      font: font,
                      fontBold: fontBold,
                      width: 250,
                    ),
                    pw.SizedBox(width: 20),
                    _buildInfoBox(
                      title: 'Tỷ lệ hoàn thành',
                      value:
                          totalRentals > 0
                              ? '${(completedRentals / totalRentals * 100).toStringAsFixed(1)}%'
                              : '0%',
                      growth: null,
                      font: font,
                      fontBold: fontBold,
                      width: 250,
                    ),
                  ],
                ),
                pw.SizedBox(height: 16),
                pw.Row(
                  children: [
                    _buildInfoBox(
                      title: 'Tiền đền bù',
                      value: currencyFormat.format(totalCompensation),
                      growth: null,
                      font: font,
                      fontBold: fontBold,
                      width: 250,
                    ),
                    pw.SizedBox(width: 20),
                    _buildInfoBox(
                      title: 'Phí trễ hẹn',
                      value: currencyFormat.format(totalLateFee),
                      growth: null,
                      font: font,
                      fontBold: fontBold,
                      width: 250,
                    ),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 20),

            // Phần thống kê theo phương thức thanh toán
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'THỐNG KÊ THEO PHƯƠNG THỨC THANH TOÁN',
                  style: pw.TextStyle(font: fontBold, fontSize: 18),
                ),
                pw.SizedBox(height: 8),
                pw.Table(
                  border: pw.TableBorder.all(
                    color: PdfColors.grey400,
                    width: 0.5,
                  ),
                  children: [
                    // Header
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColors.blue50),
                      children: [
                        _buildTableCell(
                          'Phương thức thanh toán',
                          fontBold,
                          isHeader: true,
                        ),
                        _buildTableCell('Số lượng', fontBold, isHeader: true),
                        _buildTableCell('Doanh thu', fontBold, isHeader: true),
                        _buildTableCell('Tỷ lệ', fontBold, isHeader: true),
                      ],
                    ),
                    // Data rows
                    ...methodCounts.keys.map((method) {
                      final count = methodCounts[method] ?? 0;
                      final revenue = methodRevenues[method] ?? 0;
                      final percentage =
                          totalRentals > 0
                              ? (count / totalRentals * 100).toStringAsFixed(1)
                              : '0';

                      return pw.TableRow(
                        children: [
                          _buildTableCell(method, font),
                          _buildTableCell(
                            count.toString(),
                            font,
                            alignment: pw.Alignment.center,
                          ),
                          _buildTableCell(
                            currencyFormat.format(revenue),
                            font,
                            alignment: pw.Alignment.centerRight,
                          ),
                          _buildTableCell(
                            '$percentage%',
                            font,
                            alignment: pw.Alignment.center,
                          ),
                        ],
                      );
                    }),
                    // Total row
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColors.grey100),
                      children: [
                        _buildTableCell('Tổng cộng', fontBold),
                        _buildTableCell(
                          totalRentals.toString(),
                          fontBold,
                          alignment: pw.Alignment.center,
                        ),
                        _buildTableCell(
                          currencyFormat.format(totalRevenue),
                          fontBold,
                          alignment: pw.Alignment.centerRight,
                        ),
                        _buildTableCell(
                          '100%',
                          fontBold,
                          alignment: pw.Alignment.center,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 20),

            // Phần ghi chú
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'GHI CHÚ',
                  style: pw.TextStyle(font: fontBold, fontSize: 18),
                ),
                pw.SizedBox(height: 8),
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        '• Báo cáo này được tạo tự động từ hệ thống SmurfBike.',
                        style: pw.TextStyle(font: font, fontSize: 12),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        '• Doanh thu được tính dựa trên các đơn thanh toán đã hoàn thành.',
                        style: pw.TextStyle(font: font, fontSize: 12),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        '• Tăng trưởng được tính so với kỳ trước đó có cùng độ dài.',
                        style: pw.TextStyle(font: font, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );

    // Trả về PDF dưới dạng Uint8List
    return pdf.save();
  }

  // Tạo báo cáo chi tiết theo ngày
  Future<Uint8List> generateDailyReport({
    required DateTime selectedDate,
    required List<Rental> rentals,
    required List<Payment> payments,
    required double dailyRevenue,
    required double dailyCompensation,
  }) async {
    // Tạo đối tượng PDF
    final pdf = pw.Document();

    // Tải font hỗ trợ tiếng Việt từ assets
    final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    final fontDataBold = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');

    // Tạo font từ dữ liệu
    final font = pw.Font.ttf(fontData.buffer.asByteData());
    final fontBold = pw.Font.ttf(fontDataBold.buffer.asByteData());

    // Định dạng tiền tệ
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    // Định dạng ngày tháng
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');

    // Tạo trang báo cáo
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'BÁO CÁO NGÀY ${dateFormat.format(selectedDate)}',
                    style: pw.TextStyle(font: fontBold, fontSize: 24),
                  ),
                  pw.Text(
                    'SmurfBike',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 20,
                      color: PdfColors.blue700,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Ngày xuất báo cáo: ${dateFormat.format(DateTime.now())}',
                style: pw.TextStyle(font: font, fontSize: 14),
              ),
              pw.Divider(),
            ],
          );
        },
        footer: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Divider(),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'SmurfBike - Hệ thống quản lý cho thuê xe máy',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.Text(
                    'Trang ${context.pageNumber}/${context.pagesCount}',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
        build: (pw.Context context) {
          return [
            // Phần tổng quan ngày
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'TỔNG QUAN NGÀY',
                  style: pw.TextStyle(font: fontBold, fontSize: 18),
                ),
                pw.SizedBox(height: 8),
                pw.Row(
                  children: [
                    _buildInfoBox(
                      title: 'Số đơn thuê',
                      value: '${rentals.length}',
                      growth: null,
                      font: font,
                      fontBold: fontBold,
                      width: 250,
                    ),
                    pw.SizedBox(width: 20),
                    _buildInfoBox(
                      title: 'Đơn hoàn thành',
                      value:
                          '${rentals.where((r) => r.status == RentalStatusConstants.completed).length}',
                      growth: null,
                      font: font,
                      fontBold: fontBold,
                      width: 250,
                    ),
                  ],
                ),
                pw.SizedBox(height: 16),
                pw.Row(
                  children: [
                    _buildInfoBox(
                      title: 'Doanh thu',
                      value: currencyFormat.format(dailyRevenue),
                      growth: null,
                      font: font,
                      fontBold: fontBold,
                      width: 250,
                    ),
                    pw.SizedBox(width: 20),
                    _buildInfoBox(
                      title: 'Tiền đền bù',
                      value: currencyFormat.format(dailyCompensation),
                      growth: null,
                      font: font,
                      fontBold: fontBold,
                      width: 250,
                    ),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 20),

            // Phần chi tiết đơn thuê
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'CHI TIẾT ĐƠN THUÊ',
                  style: pw.TextStyle(font: fontBold, fontSize: 18),
                ),
                pw.SizedBox(height: 8),
                pw.Table(
                  border: pw.TableBorder.all(
                    color: PdfColors.grey400,
                    width: 0.5,
                  ),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(1.5),
                    1: const pw.FlexColumnWidth(1),
                    2: const pw.FlexColumnWidth(1),
                    3: const pw.FlexColumnWidth(1.5),
                    4: const pw.FlexColumnWidth(1),
                  },
                  children: [
                    // Header
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColors.blue50),
                      children: [
                        _buildTableCell('Mã đơn', fontBold, isHeader: true),
                        _buildTableCell('Thời gian', fontBold, isHeader: true),
                        _buildTableCell('Trạng thái', fontBold, isHeader: true),
                        _buildTableCell(
                          'Phương thức',
                          fontBold,
                          isHeader: true,
                        ),
                        _buildTableCell('Số tiền', fontBold, isHeader: true),
                      ],
                    ),
                    // Data rows
                    ...rentals.map((rental) {
                      final payment = payments.firstWhere(
                        (p) => p.rentalId == rental.id,
                        orElse:
                            () => Payment(
                              id: '',
                              rentalId: rental.id,
                              paymentMethod: 'Chưa thanh toán',
                              paymentDate: DateTime.now(),
                              amount: 0,
                              status: 'Pending',
                            ),
                      );

                      return pw.TableRow(
                        children: [
                          _buildTableCell(rental.id.substring(0, 8), font),
                          _buildTableCell(
                            timeFormat.format(rental.startTime),
                            font,
                            alignment: pw.Alignment.center,
                          ),
                          _buildTableCell(
                            rental.status,
                            font,
                            alignment: pw.Alignment.center,
                          ),
                          _buildTableCell(payment.paymentMethod, font),
                          _buildTableCell(
                            payment.id.isNotEmpty
                                ? currencyFormat.format(payment.amount)
                                : '-',
                            font,
                            alignment: pw.Alignment.centerRight,
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 20),

            // Phần chi tiết thanh toán
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'CHI TIẾT THANH TOÁN',
                  style: pw.TextStyle(font: fontBold, fontSize: 18),
                ),
                pw.SizedBox(height: 8),
                pw.Table(
                  border: pw.TableBorder.all(
                    color: PdfColors.grey400,
                    width: 0.5,
                  ),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(1.5),
                    1: const pw.FlexColumnWidth(1.5),
                    2: const pw.FlexColumnWidth(1),
                    3: const pw.FlexColumnWidth(1),
                    4: const pw.FlexColumnWidth(1.5),
                  },
                  children: [
                    // Header
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColors.blue50),
                      children: [
                        _buildTableCell(
                          'Mã thanh toán',
                          fontBold,
                          isHeader: true,
                        ),
                        _buildTableCell(
                          'Mã đơn thuê',
                          fontBold,
                          isHeader: true,
                        ),
                        _buildTableCell(
                          'Phương thức',
                          fontBold,
                          isHeader: true,
                        ),
                        _buildTableCell('Trạng thái', fontBold, isHeader: true),
                        _buildTableCell('Số tiền', fontBold, isHeader: true),
                      ],
                    ),
                    // Data rows
                    ...payments.map((payment) {
                      return pw.TableRow(
                        children: [
                          _buildTableCell(payment.id.substring(0, 8), font),
                          _buildTableCell(
                            payment.rentalId.substring(0, 8),
                            font,
                          ),
                          _buildTableCell(payment.paymentMethod, font),
                          _buildTableCell(
                            payment.status,
                            font,
                            alignment: pw.Alignment.center,
                          ),
                          _buildTableCell(
                            currencyFormat.format(payment.amount),
                            font,
                            alignment: pw.Alignment.centerRight,
                          ),
                        ],
                      );
                    }),
                    // Total row
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColors.grey100),
                      children: [
                        _buildTableCell('', font),
                        _buildTableCell('', font),
                        _buildTableCell('', font),
                        _buildTableCell(
                          'Tổng cộng',
                          fontBold,
                          alignment: pw.Alignment.centerRight,
                        ),
                        _buildTableCell(
                          currencyFormat.format(dailyRevenue),
                          fontBold,
                          alignment: pw.Alignment.centerRight,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    // Trả về PDF dưới dạng Uint8List
    return pdf.save();
  }

  // Widget hỗ trợ tạo ô thông tin
  pw.Widget _buildInfoBox({
    required String title,
    required String value,
    required double? growth,
    required pw.Font font,
    required pw.Font fontBold,
    required double width,
  }) {
    return pw.Container(
      width: width,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              font: font,
              fontSize: 12,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(value, style: pw.TextStyle(font: fontBold, fontSize: 16)),
          if (growth != null) ...[
            pw.SizedBox(height: 4),
            pw.Row(
              children: [
                pw.Text(
                  growth >= 0 ? '▲' : '▼',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 10,
                    color: growth >= 0 ? PdfColors.green700 : PdfColors.red700,
                  ),
                ),
                pw.SizedBox(width: 2),
                pw.Text(
                  '${growth.abs().toStringAsFixed(1)}%',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 10,
                    color: growth >= 0 ? PdfColors.green700 : PdfColors.red700,
                  ),
                ),
                pw.SizedBox(width: 2),
                pw.Text(
                  'so với kỳ trước',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // Widget hỗ trợ tạo ô trong bảng
  pw.Widget _buildTableCell(
    String text,
    pw.Font font, {
    bool isHeader = false,
    pw.Alignment alignment = pw.Alignment.centerLeft,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Align(
        alignment: alignment,
        child: pw.Text(
          text,
          style: pw.TextStyle(font: font, fontSize: isHeader ? 12 : 10),
        ),
      ),
    );
  }

  // Hiển thị báo cáo PDF
  Future<void> showReport(Uint8List pdfData, String title) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfData,
      name: title,
    );
  }

  // Lưu báo cáo PDF
  Future<void> saveReport(Uint8List pdfData, String fileName) async {
    await Printing.sharePdf(bytes: pdfData, filename: fileName);
  }
}
