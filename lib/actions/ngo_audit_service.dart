import 'package:supabase_flutter/supabase_flutter.dart';

class NGOAuditService {
  final SupabaseClient supabase = Supabase.instance.client;

  /// Claims the next available un-audited action from the queue.
  /// Uses the 'claim_audit_task' PostgreSQL function to avoid race conditions (SKIP LOCKED).
  Future<String?> claimNextTask(String ngoId) async {
    try {
      final response = await supabase.rpc('claim_audit_task', params: {'v_ngo_id': ngoId});
      
      // Response contains the claimed task UUID, or null if queue is empty.
      return response as String?;
    } catch (e) {
      print('Error claiming task: $e');
      return null;
    }
  }

  /// Approves an action and optionally triggers the Edge Function to mint the Trinsic Yoma Credential.
  Future<bool> approveAction(String actionId) async {
    try {
      // 1. Mark as verified in the DB
      await supabase.from('actions')
          .update({'status': 'verified'})
          .eq('id', actionId);
          
      // 2. Fetch action data + user city to trigger credential issuance
      final actionData = await supabase.from('actions')
          .select('*, profiles(city_id)')
          .eq('id', actionId)
          .single();
      
      // 3. Trigger the Trinsic Edge Function to issue the Yoma credential
      await supabase.functions.invoke(
        'issue-yoma-credential',
        body: {
          'student_id': actionData['user_id'],
          'action_data': actionData,
          'city_id': actionData['profiles']?['city_id'] ?? 'India',
        },
      );
      
      return true;
    } catch (e) {
      print('Error approving action: $e');
      return false;
    }
  }

  /// Rejects an action.
  Future<bool> rejectAction(String actionId) async {
    try {
      // Typically we either delete the action or mark it 'rejected'.
      // For this spec, we will delete it or flag it. Let's delete to trigger the 'Right to Erasure' cascade webhook if applicable.
      await supabase.from('actions').delete().eq('id', actionId);
      return true;
    } catch (e) {
      print('Error rejecting action: $e');
      return false;
    }
  }
}
