/// A dependency that is intentionally never bound anywhere.
///
/// Used by the Inspector to contrast the two lookup styles on the same type:
/// `resolve<AuditTrail>()` throws, `tryResolve<AuditTrail>()` returns `null`.
/// Optional integrations — analytics, audit logs, debug overlays — are exactly
/// the case `tryResolve` exists for.
class AuditTrail {
  void record(String action) {}
}
