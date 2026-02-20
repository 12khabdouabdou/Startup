import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../jobs/models/job_model.dart';

/// Generates a professional digital manifest PDF for a completed job.
/// Also uploads the generated PDF to Supabase Storage for audit trails.
class ManifestService {
  final SupabaseClient _supabase;
  ManifestService(this._supabase);
  
  static const String _bucket = 'manifests';

  /// Generate manifest PDF bytes for a completed job.
  Future<Uint8List> generateManifest({
    required Job job,
    required String hostName,
    required String haulerName,
    String? hostCompany,
    String? haulerCompany,
  }) async {
    final pdf = pw.Document(
      title: 'FillExchange Manifest — Job ${job.id.substring(0, 8)}',
      author: 'FillExchange',
    );

    final dateFormat = DateFormat('MMM dd, yyyy — hh:mm a');
    final now = DateTime.now();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ─── Header ──────────────────────────────
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('FILLEXCHANGE', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
                      pw.SizedBox(height: 4),
                      pw.Text('Digital Manifest', style: pw.TextStyle(fontSize: 14, color: PdfColors.grey600)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Manifest #${job.id.substring(0, 8).toUpperCase()}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 4),
                      pw.Text('Generated: ${dateFormat.format(now)}', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ],
              ),
              pw.Divider(thickness: 2, color: PdfColors.green800),
              pw.SizedBox(height: 20),

              // ─── Job Details ─────────────────────────
              _sectionTitle('Job Details'),
              _infoRow('Job ID', job.id),
              _infoRow('Status', job.status.name.toUpperCase()),
              _infoRow('Material', job.material ?? 'N/A'),
              _infoRow('Quantity', '${job.quantity?.toStringAsFixed(1) ?? "N/A"} units'),
              _infoRow('Created', dateFormat.format(job.createdAt)),
              if (job.updatedAt != null)
                _infoRow('Completed', dateFormat.format(job.updatedAt!)),
              pw.SizedBox(height: 20),

              // ─── Parties ─────────────────────────────
              _sectionTitle('Parties'),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Supplier / Host', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                        pw.Text(hostName, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                        if (hostCompany != null) pw.Text(hostCompany, style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Hauler', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                        pw.Text(haulerName, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                        if (haulerCompany != null) pw.Text(haulerCompany, style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // ─── Locations ───────────────────────────
              _sectionTitle('Locations'),
              _infoRow('Pickup', job.pickupAddress ?? 'N/A'),
              _infoRow('Dropoff', job.dropoffAddress ?? 'N/A'),
              pw.SizedBox(height: 20),

              // ─── Photo Verification ──────────────────
              _sectionTitle('Photo Verification'),
              _infoRow('Pickup Photo', job.pickupPhotoUrl != null ? '✅ Captured' : '❌ Missing'),
              _infoRow('Dropoff Photo', job.dropoffPhotoUrl != null ? '✅ Captured' : '❌ Missing'),
              if (job.notes != null && job.notes!.isNotEmpty) ...[
                pw.SizedBox(height: 10),
                _infoRow('Notes', job.notes!),
              ],

              pw.Spacer(),

              // ─── Footer ──────────────────────────────
              pw.Divider(color: PdfColors.grey400),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'This is an electronically generated document.\nNo signature is required.',
                    style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
                  ),
                  pw.Text(
                    'FillExchange © ${now.year}',
                    style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    final bytes = await pdf.save();

    // Upload to Supabase Storage for audit trail (Story 6.1)
    await _uploadToStorage(jobId: job.id, bytes: bytes);

    return bytes;
  }

  /// Uploads the PDF to the 'manifests' bucket and returns a signed URL.
  /// Returns null silently on failure (PDF is still usable locally).
  Future<String?> _uploadToStorage({required String jobId, required Uint8List bytes}) async {
    try {
      final path = 'manifests/$jobId.pdf';
      await _supabase.storage.from(_bucket).uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(contentType: 'application/pdf', upsert: true),
      );
      // Generate a signed URL valid for 1 year (for sharing/archival)
      final signedUrl = await _supabase.storage.from(_bucket).createSignedUrl(path, 60 * 60 * 24 * 365);
      return signedUrl;
    } catch (e) {
      // Non-fatal: local PDF still works even if upload fails
      return null;
    }
  }

  // ─── Helper Widgets ──────────────────────────────────

  static pw.Widget _sectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Text(
        title,
        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.green800),
      ),
    );
  }

  static pw.Widget _infoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text(label, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
          ),
          pw.Expanded(
            child: pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
          ),
        ],
      ),
    );
  }
}

// ─── Provider ──────────────────────────────────────────

final manifestServiceProvider = Provider<ManifestService>((ref) {
  return ManifestService(Supabase.instance.client);
});
