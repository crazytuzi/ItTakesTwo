import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackGlobalBindFunctions;

class ASilentRoomFallingFloor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent)
	UActorImpactedCallbackComponent Impacts;

	UPROPERTY()
	UCurveFloat DownCurve;

	bool bShouldMove = false;
	bool bShouldMoveDown = false;

	float MovePlatformAlpha = 0.f;
	float MovePaltformDuration = 4.5f;

	TArray<AHazePlayerCharacter> PlayersOnPlatform;

	FVector StartLoc = FVector::ZeroVector;
	FVector TargetLoc = FVector(0.f, 0.f, -4000.f);

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Impacts.OnActorDownImpactedByPlayer.AddUFunction(this, n"PlayerLandedOnPlatform");
		Impacts.OnDownImpactEndingPlayer.AddUFunction(this, n"PlayerLeftPlatform");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bShouldMove)
			return;

		MeshRoot.SetRelativeLocation(FMath::Lerp(StartLoc, TargetLoc, DownCurve.GetFloatValue(MovePlatformAlpha)));
		MovePlatformAlpha += DeltaTime / MovePaltformDuration;

		if (MovePlatformAlpha >= 1.f)
		{
			MeshRoot.SetRelativeLocation(StartLoc);
			bShouldMove = false;
			CheckPlayerArray();
		}
	}

	UFUNCTION()
	void PlayerLandedOnPlatform(AHazePlayerCharacter Player, const FHitResult& Hit)
	{
		PlayersOnPlatform.AddUnique(Player);
		CheckPlayerArray();
	}

	UFUNCTION()
	void PlayerLeftPlatform(AHazePlayerCharacter Player)
	{
		PlayersOnPlatform.Remove(Player);
		CheckPlayerArray();
	}

	void CheckPlayerArray()
	{
		if (PlayersOnPlatform.Num() > 0)
		{
			if (bShouldMove)
				return;

			bShouldMove = true;
			MovePlatformAlpha = 0.f;
		} 
	}
}