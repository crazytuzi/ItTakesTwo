import Cake.LevelSpecific.Garden.Vine.VineImpactComponent;

UCLASS(Abstract)
class AVineableHatch : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent HatchRoot;

	UPROPERTY(DefaultComponent, Attach = HatchRoot)
	UStaticMeshComponent HatchMesh;

	UPROPERTY(DefaultComponent, Attach = HatchRoot)
	UStaticMeshComponent BulbMesh;

	UPROPERTY(DefaultComponent, Attach = HatchRoot)
	UVineImpactComponent VineImpactComp;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike MoveHatchTimeLike;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		VineImpactComp.OnVineConnected.AddUFunction(this, n"VineConnected");
		VineImpactComp.OnVineDisconnected.AddUFunction(this, n"VineDisconnected");

		MoveHatchTimeLike.BindUpdate(this, n"UpdateMoveHatch");
		MoveHatchTimeLike.SetPlayRate(3.f);
	}

	UFUNCTION(NotBlueprintCallable)
	void VineConnected()
	{
		MoveHatchTimeLike.Play();
	}

	UFUNCTION(NotBlueprintCallable)
	void VineDisconnected()
	{
		MoveHatchTimeLike.Reverse();
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateMoveHatch(float CurValue)
	{
		float CurRot = FMath::Lerp(0.f, 90.f, CurValue);
		HatchRoot.SetRelativeRotation(FRotator(0.f, 0.f, CurRot));
		VineImpactComp.CurrentWidgetRadialProgress = CurValue;
	}
}