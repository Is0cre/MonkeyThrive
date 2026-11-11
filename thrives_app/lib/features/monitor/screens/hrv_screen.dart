import 'dart:async';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/storage/hrv_service.dart';
import '../../../core/storage/session_tracker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/emergency_button.dart';

// CLINICAL SAFETY — Camera PPG / HRV measurement
//
// What this does: Uses the rear camera + flash to detect blood volume pulse
//   at the fingertip via photoplethysmography (PPG). Calculates HR and HRV
//   metrics (RMSSD, SDNN) from detected R-R intervals.
//
// What this is NOT:
//   - Not a medical device. Not validated for clinical use.
//   - Results are for self-awareness only. Not diagnostic.
//   - RMSSD thresholds shown are population averages — individual baselines vary.
//
// Algorithm:
//   1. Stream camera frames at low resolution (~30 fps).
//   2. Extract mean brightness of the centre crop (60-second window).
//   3. Bandpass filter: high-pass (remove DC / drift), low-pass moving average.
//   4. Peak detection: local maxima above adaptive threshold, min 300 ms apart.
//   5. R-R intervals from successive peak timestamps.
//   6. HR = 60 000 / mean(RR), RMSSD = sqrt(mean(ΔRRI²)), SDNN = std(RRI).
//
// Signal quality: if the standard deviation of the last 90 frames < noise
//   floor threshold the finger is likely not placed correctly.
//
// Ref: Allen (2007) Photopletysmography and its application in clinical
//   physiological measurement. Physiol Meas 28(3).

enum _HrvPhase { idle, measuring, done, noCamera, permissionDenied, error }

// ── Sample ────────────────────────────────────────────────────────────────────

class _Sample {
  final int msEpoch;
  final double value;
  const _Sample(this.msEpoch, this.value);
}

// ── Screen ─────────────────────────────────────────────────────────────────────

class HrvScreen extends StatefulWidget {
  const HrvScreen({super.key});

  @override
  State<HrvScreen> createState() => _HrvScreenState();
}

class _HrvScreenState extends State<HrvScreen> with SessionTracking {
  _HrvPhase _phase = _HrvPhase.idle;
  CameraController? _camera;

  // Raw PPG samples (rolling 75-second buffer at ~30fps)
  final List<_Sample> _samples = [];
  static const int _measureSeconds = 60;
  static const int _minSeconds =
      30; // earliest the user can stop and get results
  int _secondsElapsed = 0;
  Timer? _ticker;

  bool _fingerDetected = false;
  HrvReading? _result;

  @override
  void dispose() {
    _ticker?.cancel();
    unawaited(_stopCamera());
    super.dispose();
  }

  // ── Camera lifecycle ────────────────────────────────────────────────────────

  Future<void> _start() async {
    if (kIsWeb) {
      setState(() => _phase = _HrvPhase.noCamera);
      return;
    }

    try {
      final cameras = await availableCameras();
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => throw CameraException('no_camera', 'No back camera'),
      );

      final controller = CameraController(
        back,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await controller.initialize();
      await controller.setFlashMode(FlashMode.torch);

      _camera = controller;
      _samples.clear();
      _secondsElapsed = 0;

      beginTracking(
        'HRV Measurement',
        'Monitor',
        onEmergencyStop: () {
          _ticker?.cancel();
          _ticker = null;
          unawaited(_stopCamera());
          if (mounted) setState(() => _phase = _HrvPhase.idle);
        },
      );

      setState(() => _phase = _HrvPhase.measuring);

      await controller.startImageStream(_onFrame);

      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {
          _secondsElapsed++;
          _fingerDetected = _signalDetected();
        });
        if (_secondsElapsed >= _measureSeconds) {
          _finishMeasurement();
        }
      });
    } on CameraException catch (e) {
      setState(() {
        _phase = e.code == 'cameraPermission' || e.code == 'permissionDenied'
            ? _HrvPhase.permissionDenied
            : _HrvPhase.noCamera;
      });
    } catch (_) {
      setState(() => _phase = _HrvPhase.error);
    }
  }

  void _onFrame(CameraImage image) {
    // Extract mean brightness from the Y (luminance) plane, centre crop.
    // The Y plane in YUV-420 correlates with blood volume pulse at the fingertip
    // because the flash-illuminated capillary bed absorbs light proportionally
    // to instantaneous blood volume (oxyhemoglobin absorption).
    final plane = image.planes[0]; // Y plane (yuv420)
    final bytes = plane.bytes;
    final width = image.width;
    final height = image.height;

    // Sample a 40x40 centre crop (avoids peripheral vignetting)
    const cropHalf = 20;
    final cx = width ~/ 2;
    final cy = height ~/ 2;
    final rowStride = plane.bytesPerRow;

    double sum = 0;
    int count = 0;
    for (int row = cy - cropHalf; row < cy + cropHalf; row++) {
      for (int col = cx - cropHalf; col < cx + cropHalf; col++) {
        if (row >= 0 && row < height && col >= 0 && col < width) {
          sum += bytes[row * rowStride + col];
          count++;
        }
      }
    }
    if (count == 0) return;

    final value = sum / count;
    final ms = DateTime.now().millisecondsSinceEpoch;

    // Keep a 75-second rolling buffer
    _samples.add(_Sample(ms, value));
    if (_samples.length > 75 * 35) {
      _samples.removeRange(0, _samples.length - 75 * 35);
    }
  }

  // ── Signal quality ──────────────────────────────────────────────────────────

  /// Returns true when a pulsatile signal is detected.
  /// Heuristic: std dev of the last 90 frames must exceed the noise floor.
  bool _signalDetected() {
    if (_samples.length < 30) return false;
    final recent = _samples.length > 90
        ? _samples.sublist(_samples.length - 90)
        : _samples;
    final vals = recent.map((s) => s.value).toList();
    final std = _std(vals);
    return std > 1.5; // empirical noise floor
  }

  // ── Processing ──────────────────────────────────────────────────────────────

  Future<void> _finishMeasurement() async {
    _ticker?.cancel();
    _ticker = null;
    await _stopCamera();
    endTracking();

    if (_samples.length < 200) {
      setState(() => _phase = _HrvPhase.error);
      return;
    }

    final result = await compute(_processSignal, List<_Sample>.from(_samples));

    if (result == null) {
      setState(() => _phase = _HrvPhase.error);
      return;
    }

    await HrvService.save(result);
    setState(() {
      _result = result;
      _phase = _HrvPhase.done;
    });
  }

  Future<void> _stopCamera() async {
    final camera = _camera;
    _camera = null;
    if (camera == null) return;

    try {
      if (camera.value.isStreamingImages) {
        await camera.stopImageStream();
      }
    } catch (_) {}
    try {
      await camera.setFlashMode(FlashMode.off);
    } catch (_) {}
    await camera.dispose();
  }

  // ── Signal processing (runs in isolate) ────────────────────────────────────

  static HrvReading? _processSignal(List<_Sample> samples) {
    if (samples.length < 200) return null;

    // 1. Extract values and timestamps
    final raw = samples.map((s) => s.value).toList();
    final ts = samples.map((s) => s.msEpoch).toList();

    // 2. High-pass: subtract long moving average (removes DC drift)
    const trendWindow = 90; // ~3 seconds
    final detrended = List<double>.filled(raw.length, 0.0);
    for (int i = 0; i < raw.length; i++) {
      final lo = math.max(0, i - trendWindow ~/ 2);
      final hi = math.min(raw.length - 1, i + trendWindow ~/ 2);
      double s = 0;
      for (int j = lo; j <= hi; j++) {
        s += raw[j];
      }
      detrended[i] = raw[i] - s / (hi - lo + 1);
    }

    // 3. Low-pass: 5-sample moving average (~167 ms at 30 fps)
    const smoothWindow = 5;
    final smoothed = List<double>.filled(raw.length, 0.0);
    for (int i = 0; i < raw.length; i++) {
      final lo = math.max(0, i - smoothWindow ~/ 2);
      final hi = math.min(raw.length - 1, i + smoothWindow ~/ 2);
      double s = 0;
      for (int j = lo; j <= hi; j++) {
        s += detrended[j];
      }
      smoothed[i] = s / (hi - lo + 1);
    }

    // 4. Adaptive peak detection
    // Minimum inter-peak distance: 300 ms (~200 bpm max)
    // Threshold: mean + 0.4 * std of smoothed signal
    final mean = _mean(smoothed);
    final std = _std(smoothed);
    final threshold = mean + 0.4 * std;

    // Estimate min samples between peaks from the frame rate
    // (duration / sample count gives us avg ms per sample)
    final totalMs = ts.last - ts.first;
    final msPerSample = totalMs / samples.length;
    final minPeakGap = (300 / msPerSample).round().clamp(5, 30);

    final peaks = <int>[];
    for (int i = 1; i < smoothed.length - 1; i++) {
      if (smoothed[i] > threshold &&
          smoothed[i] > smoothed[i - 1] &&
          smoothed[i] > smoothed[i + 1]) {
        if (peaks.isEmpty || i - peaks.last >= minPeakGap) {
          peaks.add(i);
        } else if (smoothed[i] > smoothed[peaks.last]) {
          peaks[peaks.length - 1] = i; // prefer the taller peak
        }
      }
    }

    if (peaks.length < 5) return null; // too few peaks for reliable HRV

    // 5. R-R intervals in milliseconds
    final rr = <double>[];
    for (int i = 1; i < peaks.length; i++) {
      final interval = (ts[peaks[i]] - ts[peaks[i - 1]]).toDouble();
      // Physiologically plausible range: 300–2000 ms (30–200 bpm)
      if (interval >= 300 && interval <= 2000) {
        rr.add(interval);
      }
    }

    if (rr.length < 4) return null;

    // 6. Metrics
    final hr = 60000.0 / _mean(rr);

    // RMSSD — root mean square of successive differences
    double sumSqDiff = 0;
    for (int i = 1; i < rr.length; i++) {
      sumSqDiff += math.pow(rr[i] - rr[i - 1], 2).toDouble();
    }
    final rmssd = math.sqrt(sumSqDiff / (rr.length - 1));

    // SDNN — standard deviation of all NN intervals
    final sdnn = _std(rr);

    // Sanity check on HR range
    if (hr < 30 || hr > 200) return null;

    return HrvReading(
      timestamp: DateTime.fromMillisecondsSinceEpoch(ts.first),
      hr: hr,
      rmssd: rmssd,
      sdnn: sdnn,
      rrCount: rr.length,
    );
  }

  static double _mean(List<double> v) {
    if (v.isEmpty) return 0;
    return v.fold(0.0, (a, b) => a + b) / v.length;
  }

  static double _std(List<double> v) {
    if (v.length < 2) return 0;
    final m = _mean(v);
    final variance = v.fold(0.0, (a, b) => a + math.pow(b - m, 2)) / v.length;
    return math.sqrt(variance);
  }

  // ── Waveform data for display ───────────────────────────────────────────────

  /// Last 5 seconds of normalised signal for the live waveform.
  List<double> _waveformData() {
    if (_samples.length < 10) return [];
    // ~30fps × 5s = 150 samples
    final window = _samples.length > 150
        ? _samples.sublist(_samples.length - 150)
        : _samples;
    final vals = window.map((s) => s.value).toList();
    final lo = vals.reduce(math.min);
    final hi = vals.reduce(math.max);
    final range = hi - lo;
    if (range < 0.01) return List.filled(vals.length, 0.5);
    return vals.map((v) => (v - lo) / range).toList();
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Heart rate variability',
          style: TextStyle(color: AppColors.textMuted, fontSize: 15),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            _ticker?.cancel();
            unawaited(_stopCamera());
            Navigator.pop(context);
          },
        ),
      ),
      floatingActionButton: const EmergencyButton(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: switch (_phase) {
            _HrvPhase.idle => _buildIdle(),
            _HrvPhase.measuring => _buildMeasuring(),
            _HrvPhase.done => _buildDone(),
            _HrvPhase.noCamera => _buildUnavailable(
                'No camera found',
                'Camera PPG requires a rear camera with flash.',
              ),
            _HrvPhase.permissionDenied => _buildUnavailable(
                'Camera access denied',
                'Allow camera access in your device settings to use this feature.',
              ),
            _HrvPhase.error => _buildUnavailable(
                'Measurement failed',
                'Not enough signal detected. Make sure your fingertip firmly covers the camera and flash.',
              ),
          },
        ),
      ),
    );
  }

  // ── Phase screens ───────────────────────────────────────────────────────────

  Widget _buildIdle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Measure in 60 seconds',
          style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w300),
        ),
        const SizedBox(height: 8),
        const Text(
          'Place your fingertip firmly over the rear camera and flash. '
          'Stay still. Results are stored on this device only.',
          style: TextStyle(
              color: AppColors.textSecondary, fontSize: 14, height: 1.6),
        ),
        const SizedBox(height: 32),
        _InstructionCard(
          icon: Icons.camera_rear_rounded,
          text: 'Cover both the camera lens and the flash with your fingertip.',
        ),
        const SizedBox(height: 12),
        _InstructionCard(
          icon: Icons.do_not_touch_rounded,
          text:
              'Stay as still as possible. Motion creates noise in the signal.',
        ),
        const SizedBox(height: 12),
        _InstructionCard(
          icon: Icons.info_outline_rounded,
          text: 'Not a medical device. For self-awareness only.',
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: _start,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.teal,
              foregroundColor: AppColors.background,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              textStyle:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            child: const Text('Start measurement'),
          ),
        ),
      ],
    );
  }

  Widget _buildMeasuring() {
    final waveData = _waveformData();
    final progress = _secondsElapsed / _measureSeconds;
    final canStop = _secondsElapsed >= _minSeconds;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 16),

        // Countdown ring
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 140,
              height: 140,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 6,
                backgroundColor: AppColors.surfaceVariant,
                color: _fingerDetected ? AppColors.teal : AppColors.amber,
              ),
            ),
            Column(
              children: [
                Text(
                  '${_measureSeconds - _secondsElapsed}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 44,
                    fontWeight: FontWeight.w200,
                  ),
                ),
                const Text(
                  'seconds',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Signal quality indicator
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: _fingerDetected
              ? const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.favorite_rounded,
                        color: AppColors.teal, size: 14),
                    SizedBox(width: 6),
                    Text('signal detected',
                        style: TextStyle(color: AppColors.teal, fontSize: 13)),
                  ],
                )
              : const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.touch_app_rounded,
                        color: AppColors.amber, size: 14),
                    SizedBox(width: 6),
                    Text('place finger on camera + flash',
                        style: TextStyle(color: AppColors.amber, fontSize: 13)),
                  ],
                ),
        ),

        const SizedBox(height: 24),

        // Live waveform
        Container(
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: waveData.length > 5
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: CustomPaint(
                    painter: _WaveformPainter(data: waveData),
                    size: Size.infinite,
                  ),
                )
              : const Center(
                  child: Text('waiting for signal…',
                      style:
                          TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ),
        ),

        const Spacer(),

        if (canStop)
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: _finishMeasurement,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.surfaceVariant),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Stop and calculate'),
            ),
          ),

        const SizedBox(height: 8),
        const Text(
          'Not a medical device.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 11),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDone() {
    final r = _result!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your reading',
          style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w300),
        ),
        const SizedBox(height: 4),
        Text(
          'Based on ${r.rrCount} heartbeats · not a medical device',
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
        const SizedBox(height: 28),

        // HR
        _MetricCard(
          label: 'Heart rate',
          value: '${r.hr.round()}',
          unit: 'bpm',
          color: AppColors.teal,
        ),
        const SizedBox(height: 12),

        // RMSSD
        _MetricCard(
          label: 'RMSSD',
          value: r.rmssd.round().toString(),
          unit: 'ms',
          sub: r.rmssdLabel,
          color: const Color(0xFF7B68EE),
        ),
        const SizedBox(height: 12),

        // SDNN
        _MetricCard(
          label: 'SDNN',
          value: r.sdnn.round().toString(),
          unit: 'ms',
          sub: 'overall variability',
          color: const Color(0xFF4A9EDA),
        ),

        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'HRV is most meaningful as a trend over time, not a single reading. '
            'Compare against your own baseline, not population averages.',
            style: TextStyle(
                color: AppColors.textMuted, fontSize: 12, height: 1.5),
          ),
        ),

        const Spacer(),

        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton(
            onPressed: () => setState(() {
              _phase = _HrvPhase.idle;
              _result = null;
              _samples.clear();
            }),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.textPrimary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Measure again'),
          ),
        ),
      ],
    );
  }

  Widget _buildUnavailable(String title, String body) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.camera_outlined,
              color: AppColors.textMuted, size: 40),
          const SizedBox(height: 16),
          Text(title,
              style:
                  const TextStyle(color: AppColors.textPrimary, fontSize: 16)),
          const SizedBox(height: 8),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: AppColors.textMuted, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Go back', style: TextStyle(color: AppColors.teal)),
          ),
        ],
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _InstructionCard extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InstructionCard({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textMuted, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final String? sub;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.unit,
    this.sub,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12)),
                if (sub != null)
                  Text(sub!,
                      style: TextStyle(
                          color: color.withValues(alpha: 0.8), fontSize: 11)),
              ],
            ),
          ),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(
                    color: color,
                    fontSize: 32,
                    fontWeight: FontWeight.w200,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style:
                      const TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Waveform painter ──────────────────────────────────────────────────────────

class _WaveformPainter extends CustomPainter {
  final List<double> data;
  const _WaveformPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final paint = Paint()
      ..color = AppColors.teal.withValues(alpha: 0.7)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final dx = size.width / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final x = i * dx;
      final y = size.height * (1.0 - data[i].clamp(0.0, 1.0));
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WaveformPainter old) => old.data != data;
}
