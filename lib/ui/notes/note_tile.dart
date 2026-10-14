import 'package:flutter/cupertino.dart';

import '../../core/app_colors.dart';
import '../../core/date_format.dart';
import '../../models/note.dart';

/// Purely visual note card. Gestures live in NoteRow, so the same widget can be
/// reused (unchanged) inside the skeleton loader.
class NoteTile extends StatelessWidget {
  const NoteTile({super.key, required this.note});

  final Note note;

  @override
  Widget build(BuildContext context) {
    final preview = note.preview;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBackground(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  note.displayTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: primaryLabel(context),
                  ),
                ),
              ),
              if (note.isPinned)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(CupertinoIcons.pin_fill, size: 14, color: kAccent),
                ),
            ],
          ),
          if (preview.isNotEmpty) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              preview,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 15, color: secondaryLabel(context)),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            formatNoteDate(note.updatedAt),
            style: TextStyle(fontSize: 12, color: tertiaryLabel(context)),
          ),
        ],
      ),
    );
  }
}