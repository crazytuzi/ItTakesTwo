
UCLASS(abstract)
class ARangedWeaponProjectile : AHazeActor
{
	// Typically the ranged weapon that spawned this projectile.
	AHazeActor DamageCauser;
	
	// The actor that owns the weapon.
	AHazeActor ActorInstigator;

	// The location that the projectile started at
	FVector OriginLocation;

	UPROPERTY(EditDefaultsOnly, Category = Damage, BlueprintReadOnly)
	float Damage = 1.0f;
}
