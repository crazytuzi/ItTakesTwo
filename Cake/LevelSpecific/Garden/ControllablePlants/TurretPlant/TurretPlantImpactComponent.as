import Cake.Weapons.RangedWeapon.RangedWeaponImpactComponent;

struct FTurretPlantHitInfo
{
	UPROPERTY()
	FVector HitLocation;
	UPROPERTY()
	FVector Direction;
	UPROPERTY()
	UPrimitiveComponent HitComponent;
	UPROPERTY()
	AActor HitActor;
	UPROPERTY()
	float DamageAmount = 0;
}

event void FOnTurretPlantImpact(FTurretPlantHitInfo HitInfo);

class UTurretPlantImpactComponent : URangedWeaponImpactComponent
{
	UPROPERTY()
	float DamageAmount = 30;

	UPROPERTY()
	FOnTurretPlantImpact OnTurretPlantImpact;

	void HandleImpact(AHazeActor DamageCauser, FHitResult Hit)
	{
		Super::HandleImpact(DamageCauser, Hit);

		FTurretPlantHitInfo HitInfo;
		HitInfo.HitLocation = Hit.ImpactPoint;
		HitInfo.HitComponent = Hit.Component;
		HitInfo.Direction = (Hit.ImpactPoint - Hit.TraceStart).GetSafeNormal();
		HitInfo.HitActor = Owner;
		HitInfo.DamageAmount = DamageAmount;
		HandleTurretPlantImpact(HitInfo);
	}

	void HandleTurretPlantImpact(FTurretPlantHitInfo HitInfo)
	{
		OnTurretPlantImpact.Broadcast(HitInfo);
	}
}
