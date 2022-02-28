
struct FRangedWeaponImpactInfo
{
	UPROPERTY()
	FHitResult Hit;
	UPROPERTY()
	AHazeActor DamageCauser;
}

event void FOnRangedWeaponImpact(const FRangedWeaponImpactInfo& RangedWeaponImpactInfo);

class URangedWeaponImpactComponent : UActorComponent
{
	UPROPERTY()
	FOnRangedWeaponImpact OnRangedWeaponImpact;

	void HandleImpact(AHazeActor DamageCauser, FHitResult Hit)
	{
		FRangedWeaponImpactInfo Info;
		Info.DamageCauser = DamageCauser;
		Info.Hit = Hit;

		OnRangedWeaponImpact.Broadcast(Info);
	}
}
