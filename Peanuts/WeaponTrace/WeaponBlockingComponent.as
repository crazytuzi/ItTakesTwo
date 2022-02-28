
// This component can block weapon effects when hit.
class UWeaponBlockingComponent : UStaticMeshComponent
{
	// If true, this blocks projectile traces when hit.
	UPROPERTY()
	bool bBlockProjectile = true;

	// If true, this negates auto aim when hit.
	UPROPERTY()
	bool bBlockAutoAim = false;

	default SetCollisionProfileName(n"WeaponTraceBlocker");
	default RemoveTag(n"SapStickable");
	default RemoveTag(n"MatchStickable");
	default RemoveTag(n"Piercable");
}
