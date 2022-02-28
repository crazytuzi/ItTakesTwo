import Cake.LevelSpecific.Hopscotch.Hazeboy.HazeboySettings;

import void HazeboyRegisterVisibleActor(AActor Actor, int ExclusivePlayer) from 'Cake.LevelSpecific.Hopscotch.Hazeboy.HazeboyManager';
import void HazeboyUnregisterVisibleActor(AActor Actor) from 'Cake.LevelSpecific.Hopscotch.Hazeboy.HazeboyManager';
import void HazeboyRegisterResetCallback(UObject Object, FName Function) from 'Cake.LevelSpecific.Hopscotch.Hazeboy.HazeboyManager';

class AHazeboyExplosion : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent ScaleRoot;

	UPROPERTY(DefaultComponent, Attach = ScaleRoot)
	USphereComponent SphereCollision;
	default SphereCollision.SphereRadius = 1.f;

	UPROPERTY(DefaultComponent, Attach = ScaleRoot)
	UStaticMeshComponent Mesh;

	UPROPERTY(EditDefaultsOnly, Category = "Visuals")
	TArray<UMaterialInterface> PlayerMaterials;
	UMaterialInstanceDynamic Material;

	UPROPERTY(BlueprintReadOnly)
	AHazePlayerCharacter OwnerPlayer;

	float Lifetime = 0.f;
	bool bIsSuperCharged = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HazeboyRegisterVisibleActor(this, -1);
		HazeboyRegisterResetCallback(this, n"Reset");

		int PlayerIndex = int(OwnerPlayer.Player);
		Material = Mesh.CreateDynamicMaterialInstance(0, PlayerMaterials[PlayerIndex]);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		HazeboyUnregisterVisibleActor(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		ScaleRoot.RelativeScale3D = FVector(CurrentRadius);
		if (Lifetime > Hazeboy::ExplosionDuration - Hazeboy::ExplosionFadeDuration)
		{
			float Fade = (Lifetime - (Hazeboy::ExplosionDuration - Hazeboy::ExplosionFadeDuration)) / Hazeboy::ExplosionFadeDuration;
			Material.SetScalarParameterValue(n"Alpha", 1.f - Fade);
		}

		Lifetime += DeltaTime;
		if (Lifetime > Hazeboy::ExplosionDuration)
			DestroyActor();
	}

	float GetCurrentRadius() property
	{
		float Multiplier = 1.f;
		if (bIsSuperCharged)
			Multiplier = Hazeboy::SuperChargeExplosionMultiplier;

		float SizeAlpha = FMath::Pow(Lifetime / Hazeboy::ExplosionDuration, 1.f / Hazeboy::ExplosionExponent);
		return FMath::Lerp(Hazeboy::ExplosionSizeMin, Hazeboy::ExplosionSizeMax, SizeAlpha) * Multiplier;
	}

	UFUNCTION()
	void Reset()
	{
		DestroyActor();
	}
}