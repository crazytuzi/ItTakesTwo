import Cake.LevelSpecific.Garden.Vine.VineImpactComponent;

class AWhippableFlowerBud : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent BudMesh;

	UPROPERTY(DefaultComponent)
	UVineImpactComponent VineImpactComp;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike OpenBudTimeLike;

	UPROPERTY()
	float OpedBudTimeValue = 3;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OpenBudTimeLike.BindUpdate(this, n"UpdateOpenBud");

		VineImpactComp.OnVineWhipped.AddUFunction(this, n"VineWhipped");
	}

	UFUNCTION(NotBlueprintCallable)
	void VineWhipped()
	{
		OpenBudTimeLike.Play();
		System::SetTimer(this, n"CloseBud", OpedBudTimeValue, false);
	}

	UFUNCTION(NotBlueprintCallable)
	void CloseBud()
	{
		OpenBudTimeLike.Reverse();
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateOpenBud(float CurValue)
	{
		FVector CurScale = FMath::Lerp(FVector(0.25f, 0.25f, 1.f), FVector(1.5f, 1.5f, 0.25f), CurValue);
		BudMesh.SetRelativeScale3D(CurScale);
	}
}