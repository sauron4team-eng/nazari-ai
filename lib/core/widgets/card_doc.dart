import 'package:flutter/material.dart';

/// Widget simple et réutilisable : Carte blanche vide
Widget customCard({
  Widget? child,
  double elevation = 2,
  double borderRadius = 12,
  EdgeInsets padding = const EdgeInsets.all(16),
  EdgeInsets margin = const EdgeInsets.all(0),
  Function()? onTap,
}) {
  return Container(
    margin: margin,
    child: GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: elevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Padding(padding: padding, child: child),
      ),
    ),
  );
}

/// Widget pour une carte document
Widget cardDocWidget({
  String? title,
  String? subtitle,
  Color? color,
  IconData? icon,
  Function()? onMorePressed,
  Function()? onViewPressed,
}) {
  return customCard(
    padding: const EdgeInsets.all(16),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header avec icône, titre et menu
        Row(
          children: [
            Icon(
              icon ?? Icons.insert_drive_file,
              size: 40,
              color: color ?? Colors.blue,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title ?? 'Document Title',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle ?? 'Document Subtitle',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onMorePressed ?? () {},
              icon: Icon(Icons.more_vert, color: Colors.grey[600]),
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Status offline
        Row(
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 18,
              color: Colors.green[600],
            ),
            const SizedBox(width: 8),
            Text(
              'Available offline',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Actions
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[900],
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Summarize',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: onViewPressed ?? () {},
              icon: Icon(Icons.visibility, color: Colors.grey[600]),
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      ],
    ),
  );
}
