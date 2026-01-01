import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/drm_service.dart';
import '../models/drm_submission.dart';
import '../../../core/theme/app_theme.dart';

/// Screen showing all DRM form submissions with their sync status
class DrmSubmissionsScreen extends StatelessWidget {
  const DrmSubmissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Submissions'),
        actions: [
          Consumer<DrmService>(
            builder: (context, drmService, _) {
              if (drmService.pendingCount > 0 &&
                  drmService.isOnline &&
                  !drmService.isSyncing) {
                return IconButton(
                  icon: const Icon(Icons.sync),
                  tooltip: 'Sync now',
                  onPressed: () => drmService.syncNow(),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<DrmService>(
        builder: (context, drmService, child) {
          final submissions = drmService.submissions;

          if (submissions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_rounded,
                    size: 64,
                    color: Theme.of(context).disabledColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No submissions yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).disabledColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Submit a DRM form to see it here',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => drmService.syncNow(),
            child: ListView.separated(
              itemCount: submissions.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                indent: 72,
                color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
              ),
              itemBuilder: (context, index) {
                final sub = submissions[index];
                final date = DateTime.tryParse(sub.timestamp) ?? DateTime.now();
                final formattedDate = DateFormat('MMM d, h:mm a').format(date);

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: _buildLeadingThumbnail(sub.imagePath),
                  title: Text(
                    "${sub.district} - ${sub.pollingStation}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        '${sub.county} › ${sub.subCounty} › ${sub.parish}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formattedDate,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).disabledColor,
                        ),
                      ),
                    ],
                  ),
                  trailing: _buildStatusWidget(context, sub.status),
                  onTap: () => _showSubmissionDetails(context, sub),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildLeadingThumbnail(String path) {
    final file = File(path);
    if (!file.existsSync()) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.broken_image, color: Colors.grey),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.file(
        file,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 56,
          height: 56,
          color: Colors.grey[300],
          child: const Icon(Icons.broken_image, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildStatusWidget(BuildContext context, SubmissionStatus status) {
    switch (status) {
      case SubmissionStatus.pending:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.schedule, size: 14, color: AppColors.warning),
              const SizedBox(width: 4),
              Text(
                'Cached',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.warning,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      case SubmissionStatus.uploading:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.navyBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(AppColors.navyBlue),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Sending',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.navyBlue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      case SubmissionStatus.sent:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, size: 14, color: AppColors.success),
              const SizedBox(width: 4),
              Text(
                'Sent',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.success,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      case SubmissionStatus.failed:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 14, color: AppColors.error),
              const SizedBox(width: 4),
              Text(
                'Failed',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
    }
  }

  void _showSubmissionDetails(BuildContext context, DrmSubmission submission) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) => Column(
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image
                      if (File(submission.imagePath).existsSync())
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(submission.imagePath),
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Status
                      _buildStatusWidget(context, submission.status),
                      const SizedBox(height: 16),

                      // Location details
                      _buildDetailRow(context, 'District', submission.district),
                      _buildDetailRow(context, 'County', submission.county),
                      _buildDetailRow(
                        context,
                        'Sub-County',
                        submission.subCounty,
                      ),
                      _buildDetailRow(context, 'Parish', submission.parish),
                      _buildDetailRow(
                        context,
                        'Polling Station',
                        submission.pollingStation,
                      ),

                      const SizedBox(height: 16),

                      // Timestamp
                      _buildDetailRow(
                        context,
                        'Submitted',
                        DateFormat('MMMM d, yyyy h:mm a').format(
                          DateTime.tryParse(submission.timestamp) ??
                              DateTime.now(),
                        ),
                      ),

                      // Error message if failed
                      if (submission.status == SubmissionStatus.failed &&
                          submission.errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: AppColors.error,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  submission.errorMessage!,
                                  style: TextStyle(
                                    color: AppColors.error,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
