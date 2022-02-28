import Cake.LevelSpecific.Garden.Vine.VineImpactComponent;

UCLASS(Abstract)
class AVineablePlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent PlatformRoot;

	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	UStaticMeshComponent BulbMesh;

	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	UStaticMeshComponent PlatformMesh;

	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	UVineImpactComponent VineImpactComp;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike MovePlatformTimeLike;

	UPROPERTY()
	float EndOffset = 600.f;

	UPROPERTY()
	bool bPreviewEndLocation = false;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (bPreviewEndLocation)
			PlatformRoot.SetRelativeLocation(FVector(EndOffset, 0.f, 0.f));
		else
			PlatformRoot.SetRelativeLocation(FVector::ZeroVector);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MovePlatformTimeLike.BindUpdate(this, n"UpdateMovePlatform");
		MovePlatformTimeLike.SetPlayRate(3.f);

		VineImpactComp.OnVineConnected.AddUFunction(this, n"VineConnected");
		VineImpactComp.OnVineDisconnected.AddUFunction(this, n"VineDisconnected");
	}

	UFUNCTION(NotBlueprintCallable)
	void VineConnected()
	{
		MovePlatformTimeLike.Play();
	}

	UFUNCTION(NotBlueprintCallable)
	void VineDisconnected()
	{
		MovePlatformTimeLike.Reverse();
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateMovePlatform(float CurValue)
	{
		float CurOffset = FMath::Lerp(0.f, EndOffset, CurValue);
		PlatformRoot.SetRelativeLocation(FVector(CurOffset, 0.f, 0.f));
	}
}