class AMicrophoneChaseDoorCamera : AHazeCameraActor
{
	UPROPERTY(DefaultComponent, ShowOnActor)
	UHazeCameraComponent Camera;

	float InitialFov = 70.f;

	float DistanceToPlayers = 0.f;

	float TargetY = 1000.f;
	float CameraLocationLerp = 0.f;
	bool bStartTickingLerp = false;

	FVector ActorStartingLoc;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ActorStartingLoc = ActorLocation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bStartTickingLerp)
			return;

		CameraLocationLerp += DeltaTime/10.f;
		float Fov = FMath::RadiansToDegrees(2.f * FMath::Atan(DistanceToPlayers * FMath::Tan(FMath::DegreesToRadians(70.f * 0.5f) / (DistanceToPlayers + FMath::Lerp(0.f, TargetY, CameraLocationLerp)))));	
		FHazeCameraBlendSettings Blend;
		Blend.BlendTime = 0.f;
		Game::GetCody().ApplyFieldOfView(Fov, Blend, this);
		SetActorLocation(FMath::Lerp(ActorStartingLoc, ActorStartingLoc + FVector(0.f, TargetY, 0.f), CameraLocationLerp));
	}

	UFUNCTION()
	void ActivateDoorCamera(AHazePlayerCharacter Player, UObject CamInstigator)
	{
		FHazeCameraBlendSettings Blend;
		ActivateCamera(Player, Blend, CamInstigator);		
	}

	UFUNCTION()
	void StartLerpingFov()
	{
		bStartTickingLerp = true;
		FVector MiddleLocationToPlayers = FVector((Game::GetCody().ActorLocation + Game::GetMay().ActorLocation) / 2.f);
		DistanceToPlayers = (MiddleLocationToPlayers - ActorLocation).Size();
	}

	UFUNCTION()
	void DeactivateDoorCamera()
	{
		Game::GetCody().ClearFieldOfViewByInstigator(this);
		bStartTickingLerp = false;
	}
}