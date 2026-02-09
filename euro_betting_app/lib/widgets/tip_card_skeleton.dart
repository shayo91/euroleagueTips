import 'package:flutter/cupertino.dart';
import 'package:shimmer/shimmer.dart';

class TipCardSkeleton extends StatelessWidget {
  const TipCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF2C2C2E),
      highlightColor: const Color(0xFF48484A),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF2C2C2E),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 20,
                    color: const Color(0xFF2C2C2E),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 80,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C2E),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              height: 16,
              color: const Color(0xFF2C2C2E),
            ),
          ],
        ),
      ),
    );
  }
}
