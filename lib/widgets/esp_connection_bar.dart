import 'package:flutter/material.dart';
import '../models/buddy_expression.dart';
import '../models/esp32_config.dart';

class EspConnectionBar extends StatefulWidget {
  final Esp32Config config;
  final bool isOnline;
  final int? latencyMs;
  final bool isChecking;
  final BuddyMode currentMode;
  final VoidCallback onConnectTap;
  final VoidCallback onSettingsTap;
  final VoidCallback onModeToggle;

  const EspConnectionBar({
    super.key,
    required this.config,
    required this.isOnline,
    this.latencyMs,
    required this.isChecking,
    required this.currentMode,
    required this.onConnectTap,
    required this.onSettingsTap,
    required this.onModeToggle,
  });

  @override
  State<EspConnectionBar> createState() => _EspConnectionBarState();
}

class _EspConnectionBarState extends State<EspConnectionBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final modeColor = widget.currentMode == BuddyMode.study
        ? (isDark ? const Color(0xFF00E5FF) : const Color(0xFF2563EB))
        : (isDark ? const Color(0xFFFF4081) : const Color(0xFFE11D48));

    final cardBg = isDark ? const Color(0xFF131A29) : Colors.white;
    final borderColor = isDark
        ? modeColor.withOpacity(0.25)
        : const Color(0xFFE2E8F0);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Mode Pill (Friend vs Study)
          InkWell(
            onTap: widget.onModeToggle,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: modeColor.withOpacity(isDark ? 0.15 : 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: modeColor.withOpacity(0.4), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.currentMode == BuddyMode.study
                        ? Icons.school_rounded
                        : Icons.favorite_rounded,
                    size: 13,
                    color: modeColor,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    widget.currentMode == BuddyMode.study ? "STUDY" : "FRIEND",
                    style: TextStyle(
                      color: modeColor,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Device status indicator (ESP8266 online/offline)
          Expanded(
            child: InkWell(
              onTap: widget.onSettingsTap,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                child: Row(
                  children: [
                    // Status Beacon
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final color = widget.isChecking
                            ? Colors.amber
                            : (widget.isOnline
                                ? const Color(0xFF10B981)
                                : (isDark ? Colors.grey : const Color(0xFF94A3B8)));

                        return Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color,
                            boxShadow: widget.isOnline
                                ? [
                                    BoxShadow(
                                      color: color.withOpacity(0.4 * _pulseController.value + 0.2),
                                      blurRadius: 6,
                                      spreadRadius: 2 * _pulseController.value,
                                    ),
                                  ]
                                : null,
                          ),
                        );
                      },
                    ),

                    const SizedBox(width: 7),

                    // Device Name & Status
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.config.deviceName,
                                style: TextStyle(
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.isChecking
                                    ? "Checking..."
                                    : (widget.isOnline
                                        ? "ONLINE"
                                        : "OFFLINE"),
                                style: TextStyle(
                                  color: widget.isChecking
                                      ? Colors.amber
                                      : (widget.isOnline
                                          ? const Color(0xFF10B981)
                                          : (isDark ? Colors.grey : const Color(0xFF64748B))),
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            widget.isOnline
                                ? "${widget.config.host}${widget.latencyMs != null ? ' • ${widget.latencyMs}ms' : ''}"
                                : "Tap to connect to ${widget.config.host}",
                            style: TextStyle(
                              color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                              fontSize: 9.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Connect / Refresh Button
          if (!widget.isOnline)
            ElevatedButton.icon(
              onPressed: widget.onConnectTap,
              icon: widget.isChecking
                  ? const SizedBox(
                      width: 11,
                      height: 11,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.bolt_rounded, size: 14),
              label: Text(
                widget.isChecking ? "Pinging..." : "Connect",
                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            )
          else
            IconButton(
              tooltip: "Device Settings",
              icon: Icon(
                Icons.tune_rounded,
                size: 18,
                color: isDark ? Colors.grey[300] : const Color(0xFF475569),
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: widget.onSettingsTap,
            ),
        ],
      ),
    );
  }
}
