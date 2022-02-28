import Cake.Weapons.Sap.SapResponseComponent;
import Cake.Weapons.Match.MatchHitResponseComponent;

class ATreeWaterImpactManager : AHazeActor
{
	UPROPERTY(DefaultComponent, NotEditable)
	UBillboardComponent BillboardComponent;
	default BillboardComponent.SetRelativeScale3D(4.f);

	UPROPERTY()
	ALandscape Landscape;

	UPROPERTY()
	UNiagaraSystem WaterSplashEffect;

	UPROPERTY()
	UAkAudioEvent AudioEvent_WaterSplash;

	USapResponseComponent SapResponseComponent;
	UMatchHitResponseComponent MatchHitResponseComponent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (Landscape == nullptr)
			return;

		TArray<ULandscapeHeightfieldCollisionComponent> LandscapeHeightfieldCollisionComponents;

		Landscape.GetComponentsByClass(LandscapeHeightfieldCollisionComponents);
		
		for (auto LandscapeHeightfieldCollisionComponent : LandscapeHeightfieldCollisionComponents)
		{	
			LandscapeHeightfieldCollisionComponent.AddTag(n"TreeProjectileConsume");
		}

		SapResponseComponent = USapResponseComponent::GetOrCreate(Landscape);
		MatchHitResponseComponent = UMatchHitResponseComponent::GetOrCreate(Landscape);

		SapResponseComponent.OnSapConsumed.AddUFunction(this, n"OnSapHit");
		MatchHitResponseComponent.OnConsumed.AddUFunction(this, n"OnMatchHit");
	}

	UFUNCTION()
	void OnSapHit(FSapAttachTarget Where, float Mass)
	{
		Splash(Where.WorldLocation);
	}

	UFUNCTION()
	void OnMatchHit(AActor Match, UPrimitiveComponent ComponentBeingIgnited, FHitResult HitResult)
	{
		Splash(HitResult.ImpactPoint);
	}

	UFUNCTION()
	void Splash(FVector Location)
	{
		AkGameplay::PostEventAtLocation(AudioEvent_WaterSplash, Location, FRotator::ZeroRotator, "WaterSplash");
		Niagara::SpawnSystemAtLocation(WaterSplashEffect, Location);
	}
}