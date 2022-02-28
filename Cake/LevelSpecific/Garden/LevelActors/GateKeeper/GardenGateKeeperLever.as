UCLASS(Abstract)
class AGardenGateKeeperLever : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent LeverRoot;

	UPROPERTY(DefaultComponent, Attach = LeverRoot)
	UStaticMeshComponent LeverMesh;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike MoveLeverTimeLike;
	default MoveLeverTimeLike.Duration = 0.25f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveLeverTimeLike.BindUpdate(this, n"UpdateMoveLever");
		MoveLeverTimeLike.BindFinished(this, n"FinishMoveLever");
	}

	UFUNCTION()
	void UpdateMoveLever(float CurValue)
	{
		float CurRot = FMath::Lerp(90.f, 0.f, CurValue);
		LeverRoot.SetRelativeRotation(FRotator(CurRot, 0.f, 0.f));
	}

	UFUNCTION()
	void FinishMoveLever()
	{

	}

	UFUNCTION()
	void ActivateLever()
	{
		MoveLeverTimeLike.Play();
	}

	UFUNCTION()
	void DeactivateLever()
	{
		MoveLeverTimeLike.Reverse();
	}
}