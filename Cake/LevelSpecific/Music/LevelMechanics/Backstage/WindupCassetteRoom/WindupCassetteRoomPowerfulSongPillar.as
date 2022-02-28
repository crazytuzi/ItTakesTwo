import Cake.LevelSpecific.Music.Singing.SongReactionComponent;

class AWindupCassetteRoomPowerfulSongPillar : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	USongReactionComponent SongReaction;

	UPROPERTY()
	UCurveFloat RotationCurve;

	bool bShouldRotate = false;

	float CurrentAlpha = 0.f;
	float RotationDuration = 4.f;

	float StartingYawRot = 0.f;
	float TargetYawRot = 180.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SongReaction.OnPowerfulSongImpact.AddUFunction(this, n"OnSongImpact");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bShouldRotate)
			return;

		CurrentAlpha += DeltaTime / RotationDuration;
		
		if (CurrentAlpha >= 1.f)
		{
			CurrentAlpha = 1.f;
			bShouldRotate = false;
		}

		MeshRoot.SetRelativeRotation(FRotator(0.f, FMath::Lerp(StartingYawRot, TargetYawRot, RotationCurve.GetFloatValue(CurrentAlpha)), 0.f));
	}

	UFUNCTION()
	void OnSongImpact(FPowerfulSongInfo Info)
	{
		if (!bShouldRotate)
		{
			bShouldRotate = true;
			CurrentAlpha = 0.f;
		}
	}
}