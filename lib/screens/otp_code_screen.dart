import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';

class OtpCodeScreen extends StatefulWidget {
  final String phoneNumber;
  final String verificationId;
  final Future<void> Function(String otp) onVerify;
  final Future<void> Function() onResend;
  final String? title;
  final String? subtitle;
  final String? initialOtp;
  final VoidCallback? onSuccess;
  final String? successMessage;
  final bool allowPaste; 

  const OtpCodeScreen({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
    required this.onVerify,
    required this.onResend,
    this.title,
    this.subtitle,
    this.initialOtp,
    this.onSuccess,
    this.successMessage,
    this.allowPaste = true, 
  });

  @override
  State<OtpCodeScreen> createState() => _OtpCodeScreenState();
}

class _OtpCodeScreenState extends State<OtpCodeScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isVerifyingOtp = false;
  String? _errorMessage;

  int _secondsRemaining = 30;
  Timer? _timer;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    // ถ้ามี initialOtp ให้เติมในช่อง OTP อัตโนมัติ
    if (widget.initialOtp != null && widget.initialOtp!.length == 6) {
      for (int i = 0; i < 6; i++) {
        _controllers[i].text = widget.initialOtp![i];
      }
    }
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _secondsRemaining = 30;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 1) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
        setState(() {
          _canResend = true;
        });
      }
    });
  }

  Future<void> _verifyOtp() async {
    final otp = _controllers.map((controller) => controller.text).join();
    if (otp.length != 6) {
      setState(() {
        _errorMessage = 'Please enter the 6-digit OTP code';
      });
      return;
    }

    setState(() {
      _isVerifyingOtp = true;
      _errorMessage = null;
    });

    try {
      await widget.onVerify(otp);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.successMessage ?? 'OTP verification successful!',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.green,
        ),
      );
      if (widget.onSuccess != null) {
        widget.onSuccess!();
      } else {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isVerifyingOtp = false;
        _errorMessage = 'An error occurred: ${e.toString()}';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: ${e.toString()}', style: GoogleFonts.poppins())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isVerifyingOtp = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xfff7f6fb),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(
                    Icons.arrow_back,
                    size: 32,
                    color: Colors.black54,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.verified_user,
                  size: 100,
                  color: Colors.deepPurple.shade300,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                widget.title ?? 'Verification',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.subtitle ?? "Enter your OTP code number",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black38,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        6,
                        (index) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: _textFieldOTP(
                              controller: _controllers[index],
                              focusNode: _focusNodes[index],
                              first: index == 0,
                              last: index == 5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isVerifyingOtp ? null : _verifyOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.lightBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(14.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24.0),
                          ),
                        ),
                        child: _isVerifyingOtp
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Verify',
                                style: GoogleFonts.poppins(fontSize: 16),
                              ),
                      ),
                    ),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.poppins(color: Colors.red, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                "Didn't receive any code?",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black38,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              GestureDetector(
                onTap: _canResend
                    ? () {
                        widget.onResend();
                        _startTimer();
                      }
                    : null,
                child: Text(
                  _canResend ? "Resend New Code" : "Resend New Code (${_secondsRemaining}s)",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _canResend ? Colors.lightBlueAccent : Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _textFieldOTP({
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool first,
    required bool last,
  }) {
    return SizedBox(
      height: 48,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        autofocus: first,
        onChanged: (value) async {
          // รองรับ paste เฉพาะช่องแรกเท่านั้น
          if (first && value.length == 6 && RegExp(r'^\d{6}$').hasMatch(value)) {
            for (int i = 0; i < 6; i++) {
              _controllers[i].text = value[i];
            }
            FocusScope.of(context).unfocus();
            await _verifyOtp();
            return;
          }
          // ช่องอื่นๆ รับทีละหลัก
          if (value.length == 1 && !last) {
            focusNode.nextFocus();
          }
          if (value.isEmpty && !first) {
            focusNode.previousFocus();
          }
        },
        onSubmitted: (_) {
          if (_controllers.every((c) => c.text.isNotEmpty)) {
            _verifyOtp();
          }
        },
        showCursor: true,
        readOnly: false,
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
          fontSize: 20,
          color: Colors.blue,
          fontWeight: FontWeight.bold,
        ),
        keyboardType: TextInputType.number,
        maxLength: 1, // ให้แต่ละช่องรับทีละหลัก
        decoration: InputDecoration(
          counter: const Offstage(),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(width: 2, color: Colors.black12),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(width: 2, color: Colors.purple),
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        enableInteractiveSelection: widget.allowPaste,
      ),
    );
  }
}