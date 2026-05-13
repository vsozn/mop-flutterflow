import 'package:supabase_flutter/supabase_flutter.dart';

class NGOAuditService {
  final SupabaseClient supabase = Supabase.instance.client;

  /// Claims the next available un-audited action from the queue.
  /// Uses the 'claim_audit_task' PostgreSQL function to avoid race conditions (SKIP LOCKED).
  Future<String?> claimNextTask(String ngoId) async {
    try {
      final response = await supabase.rpc('claim_audit_task', params: {'v_ngo_id': ngoId});
      return response?.toString();
    } catch (e) {
      print('Error claiming task: $e');
      return null;
    }
  }

  /// Approves an action and triggers the Edge Function to mint the Trinsic Yoma Credential.
  Future<bool> approveAction(String actionId) async {
    try {
      // 1. Mark as verified and record audit completion time.
      await supabase.from('actions')
          .update({
            'status': 'verified',
            'audit_completed_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', actionId);

      // 2. Fetch action data + user city for credential issuance.
      final actionData = await supabase.from('actions')
          .select('*, profiles(city_id)')
          .eq('id', actionId)
          .single();

      // 3. Trigger the Trinsic Edge Function to issue the Yoma credential.
      //    Logged on failure but does not roll back the approval — issuance can be retried.
      try {
        await supabase.functions.invoke(
          'issue-yoma-credential',
          body: {
            'student_id': actionData['user_id'],
            'action_data': actionData,
            'city_id': actionData['profiles']?['city_id'],
          },
        );
      } catch (e) {
        print('Credential issuance failed for $actionId — will need retry: $e');
      }

      return true;
    } catch (e) {
      print('Error approving action: $e');
      return false;
    }
  }

  /// Rejects an action, preserving the audit trail.
  Future<bool> rejectAction(String actionId) async {
    try {
      await supabase.from('actions')
          .update({
            'status': 'rejected',
            'audit_completed_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', actionId);
      return true;
    } catch (e) {
      print('Error rejecting action: $e');
      return false;
    }
  }
}
