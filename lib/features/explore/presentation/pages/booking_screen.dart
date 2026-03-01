import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:local_auth/local_auth.dart';
import 'package:nivaas/core/api/api_client.dart';
import 'package:nivaas/core/api/api_endpoints.dart';
import 'package:nivaas/core/services/hive/hive_service.dart';
import 'package:nivaas/features/explore/presentation/pages/esewa_payment_screen.dart';

class BookingScreen extends ConsumerStatefulWidget {
  final String itemId;
  final String itemType; // 'accommodation' or 'experience'
  final String itemTitle;
  final double pricePerUnit;
  final String unitLabel; // 'night' or 'person'

  const BookingScreen({
    super.key,
    required this.itemId,
    required this.itemType,
    required this.itemTitle,
    required this.pricePerUnit,
    required this.unitLabel,
  });

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  static const Color primaryOrange = Color(0xFFFF6518);
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isAuthenticatingBiometric = false;
  DateTime? _startDate;
  DateTime? _endDate;
  int _guests = 1;
  bool _isLoading = false;

  // Availability state
  bool _isCheckingAvailability = false;
  bool? _isAvailable; // null = not checked, true = available, false = not available
  String _availabilityMessage = '';

  int get _units {
    if (widget.unitLabel == 'night' && _startDate != null && _endDate != null) {
      return _endDate!.difference(_startDate!).inDays;
    }
    return _guests;
  }

  double get _totalPrice => widget.pricePerUnit * _units;

  Future<bool> _authenticateForPayment() async {
    if (_isAuthenticatingBiometric) return false;
    _isAuthenticatingBiometric = true;

    try {
      // Always attempt authentication — biometricOnly:false means the OS will
      // show fingerprint, face, PIN, pattern, or password depending on what
      // the device supports and what is currently available.
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Verify identity to continue to eSewa payment',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
      debugPrint('🔐 authenticate() returned: $authenticated');

      if (!authenticated) {
        _showSnackBar('Verification cancelled. Tap Pay with eSewa to try again.', Colors.orange);
      }
      return authenticated;
    } on PlatformException catch (e) {
      debugPrint('🔐 PlatformException: code=${e.code} message=${e.message}');
      // Show confirmation dialog so user explicitly chooses to proceed.
      return await _showAuthFailedDialog(e.message ?? 'Biometric unavailable');
    } catch (e) {
      debugPrint('\ud83d\udd10 Unexpected error: $e');
      return await _showAuthFailedDialog('Authentication unavailable');
    } finally {
      _isAuthenticatingBiometric = false;
    }
  }

  /// Shows a dialog when biometric/PIN auth can't be completed, letting the
  /// user explicitly choose to proceed or cancel.
  Future<bool> _showAuthFailedDialog(String reason) async {
    if (!mounted) return false;
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Verification Unavailable'),
        content: Text('$reason\n\nDo you want to proceed to payment without verification?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Proceed'),
          ),
        ],
      ),
    );
    return proceed == true;
  }

  Future<void> _selectDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: (isDark ? const ColorScheme.dark() : const ColorScheme.light()).copyWith(
              primary: primaryOrange,
              onPrimary: Colors.white,
              surface: Theme.of(context).colorScheme.surface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (range != null) {
      setState(() {
        _startDate = range.start;
        _endDate = range.end;
        _isAvailable = null;
        _availabilityMessage = '';
      });
      _checkAvailability();
    }
  }

  Future<void> _checkAvailability() async {
    if (_startDate == null || _endDate == null) return;

    setState(() {
      _isCheckingAvailability = true;
      _isAvailable = null;
      _availabilityMessage = '';
    });

    try {
      final api = ApiClient();
      final itemParam = widget.itemType == 'accommodation'
          ? 'accommodationId=${widget.itemId}'
          : 'experienceId=${widget.itemId}';
      final response = await api.get(
        '${ApiEndpoints.checkAvailability}?$itemParam&startDate=${_startDate!.toIso8601String()}&endDate=${_endDate!.toIso8601String()}',
      );

      final available = response.data['available'] == true;

      if (mounted) {
        setState(() {
          _isAvailable = available;
          _availabilityMessage = available
              ? 'Dates are available!'
              : 'These dates are not available. Please choose different dates.';
        });
      }
    } catch (_) {
      // If we can't check, allow booking and let backend validate
      if (mounted) {
        setState(() {
          _isAvailable = true;
          _availabilityMessage = 'Dates selected';
        });
      }
    } finally {
      if (mounted) setState(() => _isCheckingAvailability = false);
    }
  }

  Future<void> _handleConfirmBooking() async {
    final hiveService = HiveService();
    if (!hiveService.isLoggedIn()) {
      _showSnackBar('Please login to book', Colors.red);
      return;
    }

    if (_startDate == null || _endDate == null) {
      _showSnackBar('Please select dates', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final api = ApiClient();
      final body = <String, dynamic>{
        'startDate': _startDate!.toIso8601String(),
        'endDate': _endDate!.toIso8601String(),
      };
      if (widget.itemType == 'accommodation') {
        body['accommodationId'] = widget.itemId;
      } else {
        body['experienceId'] = widget.itemId;
      }

      // Backend creates booking (pending) + payment record + returns eSewa form
      final response = await api.post(ApiEndpoints.esewaInitiate, data: body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data'] as Map<String, dynamic>? ?? {};
        final paymentUrl = data['paymentUrl']?.toString() ?? '';
        final formFields = Map<String, dynamic>.from(data['formFields'] as Map? ?? {});
        final bookingId = data['bookingId']?.toString() ?? '';

        if (paymentUrl.isEmpty || formFields.isEmpty) {
          // Cancel the pending booking since we can't proceed with payment
          if (bookingId.isNotEmpty) {
            try {
              await api.post(ApiEndpoints.cancelBooking, data: {'bookingId': bookingId});
              debugPrint('🗑️ Cancelled pending booking $bookingId (invalid payment response)');
            } catch (e) {
              debugPrint('⚠️ Failed to cancel pending booking $bookingId: $e');
            }
          }
          _showSnackBar('Invalid payment response from server', Colors.red);
          return;
        }

        final fingerprintPassed = await _authenticateForPayment();
        if (!fingerprintPassed) {
          if (bookingId.isNotEmpty) {
            try {
              await api.post(ApiEndpoints.cancelBooking, data: {'bookingId': bookingId});
              debugPrint('🗑️ Cancelled pending booking $bookingId (fingerprint failed)');
            } catch (e) {
              debugPrint('⚠️ Failed to cancel pending booking $bookingId: $e');
            }
          }
          return;
        }

        if (mounted) {
          final result = await Navigator.push<Map<String, dynamic>>(
            context,
            MaterialPageRoute(
              builder: (_) => EsewaPaymentScreen(
                paymentUrl: paymentUrl,
                formFields: formFields,
                itemTitle: widget.itemTitle,
                totalPrice: _totalPrice,
              ),
            ),
          );

          final status = result?['status'];
          if (status == 'success') {
            final paidAmount = result?['paidAmount']?.toString() ?? _totalPrice.toStringAsFixed(0);
            if (mounted) {
              Navigator.pop(context); // back to detail
              _showSuccessDialog(paidAmount, widget.itemTitle);
            }
          } else {
            // Payment failed or was cancelled — cancel the pending booking
            if (bookingId.isNotEmpty) {
              try {
                await api.post(ApiEndpoints.cancelBooking, data: {'bookingId': bookingId});
                debugPrint('🗑️ Cancelled pending booking $bookingId (payment $status)');
              } catch (e) {
                debugPrint('⚠️ Failed to cancel pending booking $bookingId: $e');
              }
            }
            if (status == 'failed') {
              _showSnackBar('Payment failed. Please try again.', Colors.red);
            } else {
              _showSnackBar('Payment cancelled.', Colors.orange);
            }
          }
        }
      }
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 409) {
        setState(() {
          _isAvailable = false;
          _availabilityMessage = 'Selected dates are not available. Please choose different dates.';
        });
        _showSnackBar('Selected dates are not available', Colors.red);
      } else {
        _showSnackBar('Payment failed: ${e.toString().replaceAll('Exception: ', '')}', Colors.red);
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: color),
      );
    }
  }

  void _showSuccessDialog(String paidAmount, String itemTitle) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            Text(
              'NPR $paidAmount paid successfully for $itemTitle',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colorScheme.outline.withOpacity(0.35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.itemTitle,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text('NPR ${widget.pricePerUnit.toStringAsFixed(0)} / ${widget.unitLabel}',
                      style: const TextStyle(color: primaryOrange, fontWeight: FontWeight.w600, fontSize: 15)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Date selection
            const Text('Select dates', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _selectDateRange,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: primaryOrange.withOpacity(0.4)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: primaryOrange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _startDate != null && _endDate != null
                          ? Text(
                              '${dateFormat.format(_startDate!)} – ${dateFormat.format(_endDate!)}',
                              style: const TextStyle(fontSize: 15),
                            )
                          : Text(
                              'Tap to select dates',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Availability status
            if (_isCheckingAvailability)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue)),
                    const SizedBox(width: 10),
                    const Text('Checking availability...', style: TextStyle(color: Colors.blue, fontSize: 14)),
                  ],
                ),
              )
            else if (_isAvailable != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isAvailable! ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _isAvailable! ? Colors.green.shade200 : Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isAvailable! ? Icons.check_circle : Icons.cancel,
                      color: _isAvailable! ? Colors.green : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _availabilityMessage,
                        style: TextStyle(
                          color: _isAvailable! ? Colors.green.shade700 : Colors.red.shade700,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Guest count
            const Text('Number of guests', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton(
                  onPressed: _guests > 1 ? () => setState(() => _guests--) : null,
                  icon: const Icon(Icons.remove_circle_outline),
                  color: primaryOrange,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: colorScheme.outline.withOpacity(0.45)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('$_guests', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                ),
                IconButton(
                  onPressed: () => setState(() => _guests++),
                  icon: const Icon(Icons.add_circle_outline),
                  color: primaryOrange,
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Price breakdown
            if (_startDate != null && _endDate != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryOrange.withOpacity(isDark ? 0.18 : 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('NPR ${widget.pricePerUnit.toStringAsFixed(0)} × $_units ${widget.unitLabel}${_units > 1 ? 's' : ''}',
                            style: const TextStyle(fontSize: 15)),
                        Text('NPR ${_totalPrice.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 15)),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                        Text('NPR ${_totalPrice.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: primaryOrange)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Book button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: (_isLoading || _isAvailable == false || _isCheckingAvailability) ? null : _handleConfirmBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  disabledBackgroundColor: primaryOrange.withOpacity(0.3),
                ),
                child: _isLoading
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(
                        _isAvailable == false ? 'Dates Not Available' : 'Pay with eSewa',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
