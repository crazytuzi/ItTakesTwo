UCLASS(Abstract)
class ASwingingBrazier : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent BrazierRoot;

	UPROPERTY(DefaultComponent, Attach = BrazierRoot)
	UStaticMeshComponent RopeMesh;

	UPROPERTY(DefaultComponent, Attach = BrazierRoot)
	UStaticMeshComponent BrazierMesh;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike SwingTimeLike;

	UPROPERTY(meta = (ClampMin = "0.0", ClampMax = "1.0", UIMin = "0.0", UIMax = "1.0"))
	float CurrentRotFrac = 0.25f;

	UPROPERTY(meta = (ClampMin = "0.0", ClampMax = "90.0", UIMin = "0.0", UIMax = "90.0"))
	float MaxRot = 60.f;

	UPROPERTY()
	float SwingTime = 6.f;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		float CurRot = FMath::Lerp(-45.f, 45.f, SwingTimeLike.Curve.ExternalCurve.GetFloatValue(CurrentRotFrac));
		BrazierRoot.SetRelativeRotation(FRotator(CurRot, 0.f, 0.f));
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SwingTimeLike.SetPlayRate(1.f/SwingTime);
		SwingTimeLike.SetNewTime(CurrentRotFrac);
		SwingTimeLike.BindUpdate(this, n"UpdateSwing");
		SwingTimeLike.Play();
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateSwing(float CurValue)
	{
		float CurRot = FMath::Lerp(-MaxRot, MaxRot, CurValue);
		BrazierRoot.SetRelativeRotation(FRotator(CurRot, 0.f, 0.f));
	}
}