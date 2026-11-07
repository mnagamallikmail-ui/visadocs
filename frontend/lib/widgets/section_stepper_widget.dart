import 'package:flutter/material.dart';

class SectionItem {
  final String id;
  final String title;
  final IconData icon;
  final bool isCompleted;

  const SectionItem({
    required this.id,
    required this.title,
    required this.icon,
    this.isCompleted = false,
  });
}

class SectionStepperWidget extends StatelessWidget {
  final List<SectionItem> sections;
  final int activeIndex;
  final ValueChanged<int> onSectionSelected;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const SectionStepperWidget({
    super.key,
    required this.sections,
    required this.activeIndex,
    required this.onSectionSelected,
    this.onPrevious,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    if (sections.isEmpty) return const SizedBox.shrink();

    final current = sections[activeIndex.clamp(0, sections.length - 1)];
    final percent = ((activeIndex + 1) / sections.length * 100).toInt();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Section info & direct jump button
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(current.icon, size: 18, color: const Color(0xFF1E3A8A)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SECTION ${activeIndex + 1} OF ${sections.length} ($percent%)',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2563EB),
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      current.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Jump Button
              OutlinedButton.icon(
                onPressed: () => _showSectionJumpModal(context),
                icon: const Icon(Icons.list_alt_rounded, size: 16),
                label: const Text('Jump', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Horizontal Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (activeIndex + 1) / sections.length,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 10),

          // Horizontal Stepper Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(sections.length, (idx) {
                final item = sections[idx];
                final bool isActive = idx == activeIndex;
                final bool isPast = idx < activeIndex || item.isCompleted;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => onSectionSelected(idx),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFF1E3A8A)
                            : isPast
                                ? const Color(0xFFF0FDF4)
                                : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isActive
                              ? const Color(0xFF1E3A8A)
                              : isPast
                                  ? const Color(0xFF86EFAC)
                                  : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isPast && !isActive)
                            const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF16A34A))
                          else
                            Text(
                              '${idx + 1}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isActive ? Colors.white : const Color(0xFF64748B),
                              ),
                            ),
                          const SizedBox(width: 6),
                          Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                              color: isActive
                                  ? Colors.white
                                  : isPast
                                      ? const Color(0xFF166534)
                                      : const Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  void _showSectionJumpModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Jump to Section',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: sections.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, idx) {
                      final item = sections[idx];
                      final bool isSelected = idx == activeIndex;
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 14,
                          backgroundColor: isSelected
                              ? const Color(0xFF1E3A8A)
                              : item.isCompleted
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFFE2E8F0),
                          child: Text(
                            '${idx + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: (isSelected || item.isCompleted) ? Colors.white : const Color(0xFF475569),
                            ),
                          ),
                        ),
                        title: Text(
                          item.title,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFF1E293B),
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.arrow_right_alt_rounded, color: Color(0xFF1E3A8A))
                            : null,
                        onTap: () {
                          Navigator.pop(ctx);
                          onSectionSelected(idx);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

