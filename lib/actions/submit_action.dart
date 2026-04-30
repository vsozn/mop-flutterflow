import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:supabase_flutter/supabase_flutter.dart';

Future<String?> submitActionWithStrippedPhoto(
  File photoFile,
  String userId,
  String actionType,
  double co2SavedKg,
  double waterSavedLiters,
) async {
  try {
    // 1. Read original image
    final bytes = await photoFile.readAsBytes();
    
    // 2. Decode image (this reads the pixels but standard decode doesn't retain EXIF when re-encoding)
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception("Failed to decode image");

    // 3. Re-encode the image. The default encodeJpg strips EXIF metadata!
    // This enforces the DPDP location privacy requirement perfectly.
    final strippedBytes = img.encodeJpg(image, quality: 85);

    // 4. Upload stripped image to Supabase Storage
    final supabase = Supabase.instance.client;
    final fileName = 'actions/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
    
    await supabase.storage.from('proof_photos').uploadBinary(
          fileName,
          strippedBytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
        );

    // 5. Get the public URL
    final proofUrl = supabase.storage.from('proof_photos').getPublicUrl(fileName);

    // 6. Insert Action Record into Database
    await supabase.from('actions').insert({
      'user_id': userId,
      'action_type': actionType,
      'co2_saved_kg': co2SavedKg,
      'water_saved_liters': waterSavedLiters,
      'status': 'tier_1_auto', // default trust tier
      'proof_url': proofUrl,
      'created_at': DateTime.now().toIso8601String(),
    });

    return proofUrl;
  } catch (e) {
    print('Error submitting action: $e');
    return null;
  }
}
