import Cake.LevelSpecific.Clockwork.TimeControlMechanic.TimeControlActorComponent;

UCLASS(Abstract, HideCategories = "Cooking Replication Input Actor Capability LOD")
class AClockworkRotatingCogTimeDilate : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh;

	bool bShouldSpin = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetSpinEnabled(true);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bShouldSpin)
			return;
		
		FRotator RotationToAdd = FRotator(0.f, 40.f * DeltaTime, 0.f);
		Root.AddLocalRotation(RotationToAdd);
	}

	UFUNCTION()
	void SetSpinEnabled(bool bEnabled)
	{
		bShouldSpin = bEnabled;
	}
}