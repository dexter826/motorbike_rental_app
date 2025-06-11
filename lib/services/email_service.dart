import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import '../models/rental.dart';
import '../models/user.dart';
import '../models/payment.dart';
import 'package:intl/intl.dart';

class EmailService {
  // Singleton pattern
  static final EmailService _instance = EmailService._internal();
  factory EmailService() => _instance;
  EmailService._internal();

  // Lấy thông tin cấu hình email từ biến môi trường
  String get _username => dotenv.env['EMAIL_USERNAME'] ?? '';
  String get _password => dotenv.env['EMAIL_PASSWORD'] ?? '';
  String get _host => dotenv.env['EMAIL_HOST'] ?? 'smtp.gmail.com';
  int get _port => int.parse(dotenv.env['EMAIL_PORT'] ?? '587');
  String get _companyName => dotenv.env['COMPANY_NAME'] ?? 'Smurf Village';

  // Khởi tạo SMTP server
  SmtpServer get _smtpServer => SmtpServer(
    _host,
    port: _port,
    username: _username,
    password: _password,
    ssl: false,
    allowInsecure: true,
  );

  // Gửi email
  Future<bool> _sendEmail({
    required String recipientEmail,
    required String subject,
    required String body,
  }) async {
    if (_username.isEmpty || _password.isEmpty) {
      print('Email credentials not configured');
      return false;
    }

    try {
      final message =
          Message()
            ..from = Address(_username, _companyName)
            ..recipients.add(recipientEmail)
            ..subject = subject
            ..html = body;

      final sendReport = await send(message, _smtpServer);
      print('Email sent: ${sendReport.toString()}');
      return true;
    } catch (e) {
      print('Error sending email: $e');
      return false;
    }
  }

  // Gửi email thông báo đơn thuê sắp hết hạn
  Future<bool> sendRentalDueNotification({
    required Rental rental,
    required User user,
  }) async {
    final endDate = DateFormat('dd/MM/yyyy').format(rental.endTime);

    final subject = 'Thông báo: Đơn thuê xe của bạn sắp hết hạn';
    final body = '''
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 5px;">
      <div style="text-align: center; margin-bottom: 20px;">
        <h2 style="color: #4a86e8;">$_companyName</h2>
      </div>

      <p>Xin chào <strong>${user.name}</strong>,</p>

      <p>Chúng tôi xin thông báo rằng đơn thuê xe của bạn sẽ hết hạn vào ngày <strong>$endDate</strong>.</p>

      <div style="background-color: #f5f5f5; padding: 15px; border-radius: 5px; margin: 20px 0;">
        <h3 style="margin-top: 0; color: #4a86e8;">Thông tin đơn thuê:</h3>
        <p><strong>Mã đơn:</strong> #${rental.id.substring(0, 8)}</p>
        <p><strong>Ngày hết hạn:</strong> $endDate</p>
        <p><strong>Số lượng xe:</strong> ${rental.quantity}</p>
      </div>

      <p>Vui lòng đảm bảo rằng bạn trả xe đúng hạn để tránh phát sinh phí phạt. Nếu bạn muốn gia hạn thời gian thuê, vui lòng liên hệ với chúng tôi trước ngày hết hạn.</p>

      <p>Cảm ơn bạn đã sử dụng dịch vụ của chúng tôi!</p>

      <div style="margin-top: 30px; padding-top: 20px; border-top: 1px solid #e0e0e0; text-align: center; font-size: 12px; color: #777;">
        <p>Email này được gửi tự động, vui lòng không trả lời.</p>
        <p>© ${DateTime.now().year} $_companyName. Tất cả các quyền được bảo lưu.</p>
      </div>
    </div>
    ''';

    return await _sendEmail(
      recipientEmail: user.email,
      subject: subject,
      body: body,
    );
  }

  // Gửi email thông báo đơn thuê đã quá hạn
  Future<bool> sendRentalExpiredNotification({
    required Rental rental,
    required User user,
  }) async {
    final endDate = DateFormat('dd/MM/yyyy').format(rental.endTime);
    final currentDate = DateFormat('dd/MM/yyyy').format(DateTime.now());

    // Tính thời gian quá hạn
    final difference = DateTime.now().difference(rental.endTime);
    String overdueText;
    int daysOverdue = 0;

    if (difference.inDays < 1) {
      // Nếu chưa đủ 1 ngày, hiển thị theo giờ
      final hoursOverdue = difference.inHours;
      overdueText = '$hoursOverdue giờ';
      daysOverdue = 0; // Giữ lại biến này để tương thích với code hiện tại
    } else {
      // Nếu từ 1 ngày trở lên, hiển thị theo ngày
      daysOverdue = difference.inDays;
      overdueText = '$daysOverdue ngày';
    }

    final subject = 'CẢNH BÁO: Đơn thuê xe của bạn đã quá hạn';
    final body = '''
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 5px;">
      <div style="text-align: center; margin-bottom: 20px;">
        <h2 style="color: #e74c3c;">$_companyName</h2>
      </div>

      <p>Xin chào <strong>${user.name}</strong>,</p>

      <p style="color: #e74c3c; font-weight: bold;">Chúng tôi nhận thấy rằng đơn thuê xe của bạn đã quá hạn $overdueText.</p>

      <div style="background-color: #f5f5f5; padding: 15px; border-radius: 5px; margin: 20px 0;">
        <h3 style="margin-top: 0; color: #e74c3c;">Thông tin đơn thuê:</h3>
        <p><strong>Mã đơn:</strong> #${rental.id.substring(0, 8)}</p>
        <p><strong>Ngày hết hạn:</strong> $endDate</p>
        <p><strong>Ngày hiện tại:</strong> $currentDate</p>
        <p><strong>Thời gian quá hạn:</strong> $overdueText</p>
        <p><strong>Số lượng xe:</strong> ${rental.quantity}</p>
      </div>

      <p>Vui lòng trả xe ngay lập tức để tránh phát sinh thêm phí phạt. Phí phạt sẽ được tính theo số giờ quá hạn và có thể tăng theo thời gian.</p>

      <p>Nếu bạn cần hỗ trợ hoặc có bất kỳ câu hỏi nào, vui lòng liên hệ với chúng tôi ngay.</p>

      <div style="margin-top: 30px; padding-top: 20px; border-top: 1px solid #e0e0e0; text-align: center; font-size: 12px; color: #777;">
        <p>Email này được gửi tự động, vui lòng không trả lời.</p>
        <p>© ${DateTime.now().year} $_companyName. Tất cả các quyền được bảo lưu.</p>
      </div>
    </div>
    ''';

    return await _sendEmail(
      recipientEmail: user.email,
      subject: subject,
      body: body,
    );
  }

  // Gửi email xác nhận đơn thuê thành công
  Future<bool> sendRentalConfirmation({
    required Rental rental,
    required User user,
  }) async {
    final startDate = DateFormat('dd/MM/yyyy').format(rental.startTime);
    final endDate = DateFormat('dd/MM/yyyy').format(rental.endTime);

    final subject = 'Xác nhận đơn thuê xe thành công';
    final body = '''
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 5px;">
      <div style="text-align: center; margin-bottom: 20px;">
        <h2 style="color: #4a86e8;">$_companyName</h2>
      </div>

      <p>Xin chào <strong>${user.name}</strong>,</p>

      <p>Cảm ơn bạn đã sử dụng dịch vụ thuê xe của chúng tôi. Đơn thuê của bạn đã được xác nhận thành công!</p>

      <div style="background-color: #f5f5f5; padding: 15px; border-radius: 5px; margin: 20px 0;">
        <h3 style="margin-top: 0; color: #4a86e8;">Thông tin đơn thuê:</h3>
        <p><strong>Mã đơn:</strong> #${rental.id.substring(0, 8)}</p>
        <p><strong>Ngày bắt đầu:</strong> $startDate</p>
        <p><strong>Ngày kết thúc:</strong> $endDate</p>
        <p><strong>Số lượng xe:</strong> ${rental.quantity}</p>
        <p><strong>Tổng tiền:</strong> ${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(rental.totalAmount)}</p>
      </div>

      <p>Vui lòng giữ email này để tham khảo trong tương lai. Nếu bạn có bất kỳ câu hỏi nào, đừng ngần ngại liên hệ với chúng tôi.</p>

      <p>Chúc bạn có trải nghiệm thuê xe tuyệt vời!</p>

      <div style="margin-top: 30px; padding-top: 20px; border-top: 1px solid #e0e0e0; text-align: center; font-size: 12px; color: #777;">
        <p>Email này được gửi tự động, vui lòng không trả lời.</p>
        <p>© ${DateTime.now().year} $_companyName. Tất cả các quyền được bảo lưu.</p>
      </div>
    </div>
    ''';

    return await _sendEmail(
      recipientEmail: user.email,
      subject: subject,
      body: body,
    );
  }

  // Gửi email thông báo gia hạn đơn thuê thành công
  Future<bool> sendRentalExtensionNotification({
    required Rental rental,
    required User user,
    required DateTime newEndDate,
    required double extensionFee,
  }) async {
    final oldEndDate = DateFormat('dd/MM/yyyy').format(rental.endTime);
    final newEndDateFormatted = DateFormat('dd/MM/yyyy').format(newEndDate);
    final extensionDays = newEndDate.difference(rental.endTime).inDays;

    final subject = 'Xác nhận gia hạn đơn thuê xe thành công';
    final body = '''
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 5px;">
      <div style="text-align: center; margin-bottom: 20px;">
        <h2 style="color: #4a86e8;">$_companyName</h2>
      </div>

      <p>Xin chào <strong>${user.name}</strong>,</p>

      <p>Chúng tôi xin xác nhận rằng đơn thuê xe của bạn đã được gia hạn thành công!</p>

      <div style="background-color: #f5f5f5; padding: 15px; border-radius: 5px; margin: 20px 0;">
        <h3 style="margin-top: 0; color: #4a86e8;">Thông tin gia hạn:</h3>
        <p><strong>Mã đơn:</strong> #${rental.id.substring(0, 8)}</p>
        <p><strong>Ngày kết thúc cũ:</strong> $oldEndDate</p>
        <p><strong>Ngày kết thúc mới:</strong> $newEndDateFormatted</p>
        <p><strong>Thời gian gia hạn:</strong> $extensionDays ngày</p>
        <p><strong>Phí gia hạn:</strong> ${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(extensionFee)}</p>
        <p><strong>Tổng tiền mới:</strong> ${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(rental.totalAmount + extensionFee)}</p>
      </div>

      <p>Bạn có thể tiếp tục sử dụng xe đến ngày <strong>$newEndDateFormatted</strong>. Vui lòng đảm bảo trả xe đúng hạn để tránh phát sinh phí phạt.</p>

      <p>Phí gia hạn sẽ được thanh toán cùng với tổng tiền thuê khi bạn trả xe.</p>

      <p>Cảm ơn bạn đã tiếp tục sử dụng dịch vụ của chúng tôi!</p>

      <div style="margin-top: 30px; padding-top: 20px; border-top: 1px solid #e0e0e0; text-align: center; font-size: 12px; color: #777;">
        <p>Email này được gửi tự động, vui lòng không trả lời.</p>
        <p>© ${DateTime.now().year} $_companyName. Tất cả các quyền được bảo lưu.</p>
      </div>
    </div>
    ''';

    return await _sendEmail(
      recipientEmail: user.email,
      subject: subject,
      body: body,
    );
  }

  // Gửi email xác nhận thanh toán thành công
  Future<bool> sendPaymentConfirmation({
    required Payment payment,
    required Rental rental,
    required User user,
  }) async {
    final paymentDate = DateFormat(
      'dd/MM/yyyy HH:mm',
    ).format(payment.paymentDate);
    final receiptNumber = payment.receiptNumber ?? 'N/A';

    // Tính toán các khoản phí
    final baseAmount =
        payment.amount -
        (payment.damageCompensation ?? 0) -
        (payment.lateFee ?? 0);

    final subject = 'Biên lai thanh toán #$receiptNumber';
    final body = '''
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 0; border: 1px solid #e0e0e0; border-radius: 8px; overflow: hidden;">
      <!-- Header -->
      <div style="background-color: #4a86e8; padding: 16px; color: white;">
        <table width="100%" cellpadding="0" cellspacing="0">
          <tr>
            <td>
              <div style="display: flex; align-items: center;">
                <span style="font-size: 24px; margin-right: 10px;">&#128181;</span>
                <div>
                  <h2 style="margin: 0; font-size: 18px;">BIÊN LAI THANH TOÁN</h2>
                  <p style="margin: 0; font-size: 14px;">Số: $receiptNumber</p>
                </div>
              </div>
            </td>
            <td align="right">
              <p style="margin: 0; font-size: 12px;">Ngày tạo:</p>
              <p style="margin: 0; font-size: 14px; font-weight: bold;">${DateFormat('dd/MM/yyyy').format(payment.paymentDate)}</p>
            </td>
          </tr>
        </table>
      </div>

      <!-- Merchant Info -->
      <div style="background-color: #f5f5f5; padding: 16px;">
        <h3 style="margin: 0 0 8px 0; font-size: 16px;">${_companyName}</h3>
        <p style="margin: 0; font-size: 14px;">140 đường Lê Trọng Tấn, Tây Thạnh, Tân Phú, TP. Hồ Chí Minh</p>
        <p style="margin: 0; font-size: 14px;">Mã số thuế: 0123456789</p>
        <p style="margin: 0; font-size: 14px;">Điện thoại: +84 28 3816 2799</p>
      </div>

      <!-- Divider -->
      <div style="height: 1px; background-color: #e0e0e0;"></div>

      <!-- Customer Info -->
      <div style="padding: 16px;">
        <h3 style="margin: 0 0 8px 0; font-size: 14px; color: #666;">THÔNG TIN KHÁCH HÀNG</h3>
        <div style="margin-bottom: 16px;">
          <p style="margin: 0 0 8px 0; font-size: 14px;"><strong>Tên:</strong> ${user.name}</p>
          <p style="margin: 0 0 8px 0; font-size: 14px;"><strong>Email:</strong> ${user.email}</p>
          <p style="margin: 0 0 8px 0; font-size: 14px;"><strong>SĐT:</strong> ${user.phone}</p>
          <p style="margin: 0; font-size: 14px;"><strong>Đơn thuê:</strong> #${rental.id.substring(0, 8)}</p>
        </div>
      </div>

      <!-- Payment Details -->
      <div style="padding: 16px;">
        <h3 style="margin: 0 0 12px 0; font-size: 14px; color: #666;">CHI TIẾT THANH TOÁN</h3>
        <table width="100%" cellpadding="0" cellspacing="0" style="border: 1px solid #e0e0e0; border-radius: 4px; border-collapse: separate;">
          <tr style="border-bottom: 1px solid #e0e0e0;">
            <td style="padding: 10px 16px; border-bottom: 1px solid #e0e0e0;">Phí thuê xe</td>
            <td align="right" style="padding: 10px 16px; border-bottom: 1px solid #e0e0e0;">${NumberFormat('#,###').format(baseAmount)} VND</td>
          </tr>
          ${payment.lateFee != null && payment.lateFee! > 0 ? '<tr style="border-bottom: 1px solid #e0e0e0;"><td style="padding: 10px 16px; border-bottom: 1px solid #e0e0e0;">Phí trả muộn (${payment.lateHours} giờ)</td><td align="right" style="padding: 10px 16px; border-bottom: 1px solid #e0e0e0;">${NumberFormat('#,###').format(payment.lateFee)} VND</td></tr>' : ''}
          ${payment.damageCompensation != null && payment.damageCompensation! > 0 ? '<tr style="border-bottom: 1px solid #e0e0e0;"><td style="padding: 10px 16px; border-bottom: 1px solid #e0e0e0;">Phí đền bù hư hại</td><td align="right" style="padding: 10px 16px; border-bottom: 1px solid #e0e0e0;">${NumberFormat('#,###').format(payment.damageCompensation)} VND</td></tr>' : ''}
          <tr style="background-color: #f5f5f5;">
            <td style="padding: 12px 16px; font-weight: bold; font-size: 16px;">Tổng cộng</td>
            <td align="right" style="padding: 12px 16px; font-weight: bold; font-size: 16px; color: #4a86e8;">${NumberFormat('#,###').format(payment.amount)} VND</td>
          </tr>
        </table>
      </div>

      <!-- Transaction Info -->
      <div style="padding: 16px;">
        <h3 style="margin: 0 0 8px 0; font-size: 14px; color: #666;">THÔNG TIN GIAO DỊCH</h3>
        <table width="100%" cellpadding="4" cellspacing="0">
          <tr>
            <td width="30%" style="font-weight: bold; color: #666;">Phương thức</td>
            <td>${payment.paymentMethod}</td>
          </tr>
          <tr>
            <td width="30%" style="font-weight: bold; color: #666;">Trạng thái</td>
            <td>${payment.status}</td>
          </tr>
          ${payment.transactionId != null ? '<tr><td width="30%" style="font-weight: bold; color: #666;">Mã giao dịch</td><td>${payment.transactionId}</td></tr>' : ''}
          <tr>
            <td width="30%" style="font-weight: bold; color: #666;">Thời gian</td>
            <td>$paymentDate</td>
          </tr>
        </table>
      </div>

      <!-- Signatures -->
      <div style="padding: 16px; text-align: center;">
        <table width="100%" cellpadding="4" cellspacing="0">
          <tr>
            <td width="50%" align="center">
              <p style="font-weight: bold; margin-bottom: 10px;">Người nhận</p>
              <!-- Chữ ký công ty sử dụng URL công khai từ ImgBB -->
              <img src="https://i.ibb.co/company-signature/company-signature.png" alt="Chữ ký công ty" style="height: 80px; width: auto; max-width: 200px; margin-bottom: 10px; display: block; margin-left: auto; margin-right: auto;" />
              <p>$_companyName</p>
            </td>
            <td width="50%" align="center">
              <p style="font-weight: bold; margin-bottom: 10px;">Người thanh toán</p>
              <!-- Chữ ký khách hàng - Lưu ý: cần đảm bảo customerSignature là URL công khai -->
              ${payment.customerSignature != null ? '<img src="${payment.customerSignature}" alt="Chữ ký khách hàng" style="height: 80px; width: auto; max-width: 200px; margin-bottom: 10px; display: block; margin-left: auto; margin-right: auto;" />' : '<p style="margin-bottom: 30px;">Chưa có chữ ký</p>'}
              <p>${user.name}</p>
            </td>
          </tr>
        </table>
      </div>

      <!-- Footer -->
      <div style="background-color: #f5f5f5; padding: 16px; text-align: center;">
        <p style="margin: 0; font-weight: bold;">Cảm ơn quý khách đã sử dụng dịch vụ!</p>
        <p style="margin: 4px 0 0 0; font-size: 12px; color: #666;">Biên lai này là bằng chứng thanh toán hợp lệ.</p>
      </div>

      <!-- Disclaimer -->
      <div style="margin-top: 20px; padding-top: 20px; border-top: 1px solid #e0e0e0; text-align: center; font-size: 12px; color: #777;">
        <p>Email này được gửi tự động, vui lòng không trả lời.</p>
        <p>© ${DateTime.now().year} $_companyName. Tất cả các quyền được bảo lưu.</p>
      </div>
    </div>
    ''';

    return await _sendEmail(
      recipientEmail: user.email,
      subject: subject,
      body: body,
    );
  }
}
