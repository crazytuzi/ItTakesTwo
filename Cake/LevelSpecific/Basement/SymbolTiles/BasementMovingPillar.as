UCLASS(Abstract)
class ABasementMovingPillar : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent PillarRoot;

	UPROPERTY(DefaultComponent, Attach = PillarRoot)
	UStaticMeshComponent PillarMesh;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike ShakePillarTimeLike;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike MovePillarTimeLike;

	UPROPERTY()
	float EndLocation = -3000.f;

	UPROPERTY()
	bool bPreviewEnd = false;

	UPROPERTY()
	float MoveTime = 1.f;

	float MaxRotation = 3.f;

	UPROPERTY()
	float StartLocation = 0.f;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		float EndLoc = bPreviewEnd ? EndLocation : 0.f;
		PillarRoot.SetRelativeLocation(FVector(0.f, 0.f, EndLoc));
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ShakePillarTimeLike.SetPlayRate(4.f);

		ShakePillarTimeLike.BindUpdate(this, n"UpdateShakePillar");
		ShakePillarTimeLike.BindFinished(this, n"FinishShakePillar");

		MovePillarTimeLike.BindUpdate(this, n"UpdateMovePillar");
		MovePillarTimeLike.BindFinished(this, n"FinishMovePillar");

		MovePillarTimeLike.SetPlayRate(1.f/MoveTime);
	}

	void SetNewEndLocation(float NewEndLoc)
	{
		EndLocation = NewEndLoc;
	}

	UFUNCTION()
	void StartMovingPillar(float Delay, bool bReverse = false)
	{
		if (bReverse)
			System::SetTimer(this, n"ReversePillar", Delay, false);
		else
			System::SetTimer(this, n"ShakePillar", Delay, false);
	}

	UFUNCTION(NotBlueprintCallable)
	void ShakePillar()
	{
		ShakePillarTimeLike.PlayFromStart();
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateShakePillar(float CurValue)
	{
		float Roll = FMath::RandRange(-MaxRotation, MaxRotation) * CurValue;
		float Pitch = FMath::RandRange(-MaxRotation, MaxRotation) * CurValue;
		float Yaw = FMath::RandRange(-MaxRotation, MaxRotation) * CurValue;

		PillarRoot.SetRelativeRotation(FRotator(Pitch, Yaw, Roll));
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishShakePillar()
	{
		StartLocation = PillarRoot.RelativeLocation.Z;
		MovePillarTimeLike.PlayFromStart();
	}

	UFUNCTION()
	void MovePillar()
	{
		MovePillarTimeLike.PlayFromStart();
	}

	UFUNCTION()
	void ReversePillar()
	{
		MovePillarTimeLike.ReverseFromEnd();
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateMovePillar(float CurValue)
	{
		float CurLoc = FMath::Lerp(StartLocation, EndLocation, CurValue);
		PillarRoot.SetRelativeLocation(FVector(0.f, 0.f, CurLoc));
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishMovePillar()
	{

	}
}