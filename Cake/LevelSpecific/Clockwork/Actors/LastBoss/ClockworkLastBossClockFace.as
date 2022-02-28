class AClockworkLastBossClockFace : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent ClockFaceMesh;

	UPROPERTY(DefaultComponent, Attach = ClockFaceMesh)
	UStaticMeshComponent MinuteHandMesh;

	UPROPERTY(DefaultComponent, Attach = ClockFaceMesh)
	UStaticMeshComponent HourHandMesh;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ClockFaceRedEvent;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY()
	UForceFeedbackEffect ClockFaceFeedback;

	FVector StartingColor = FVector(1.2f, 0.3f, 0.167f);
	FVector RedColor = FVector(1500.f, 0.f, 0.f);

	bool bClockIsAngered = false;
	bool bShouldBeGoingBack = false;
	bool bIsPlayingForceFeedback = false;

	float ColorLerpAlpha = 0.f;
	float ColorLerpTime = 0.f;
	float ColorLerpTimeMax = 1.f;
	float TimeBeforeGoingBack = 2.f;
	float GoingBackTimer = 0.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bClockIsAngered)
			return;
		
		if (!bShouldBeGoingBack)
			ColorLerpAlpha += DeltaTime / ColorLerpTimeMax;

		if (ColorLerpAlpha >= 1.f && !bShouldBeGoingBack)
		{
			ColorLerpAlpha = 1.f;
			GoingBackTimer = TimeBeforeGoingBack;
			if (GoingBackTimer > -1.f)
				StopClockFace();
		}

		if (bShouldBeGoingBack)
		{
			GoingBackTimer -= DeltaTime;
			
			if (GoingBackTimer <= 0.f)
			{
				ColorLerpAlpha -= DeltaTime / ColorLerpTimeMax;

				if (ColorLerpAlpha <= 0.f)
				{
					ColorLerpAlpha = 0.f;
					bClockIsAngered = false;
					bShouldBeGoingBack = false;
					StopForceFeedback();
				}
			}
		}

		ClockFaceMesh.SetVectorParameterValueOnMaterialIndex(0, n"Emissive Tint", FMath::Lerp(StartingColor, RedColor, ColorLerpAlpha));

		MinuteHandMesh.AddLocalRotation(FRotator(0.f, 0.f, -1200.f * DeltaTime));
		HourHandMesh.AddLocalRotation(FRotator(0.f, 0.f, -750.f * DeltaTime));
		
	}

	// -1 duration for unlimited duration
	UFUNCTION()
	void TurnClockFaceRed(bool bShouldApplyPoi, float Duration, bool bApplyCamShake, bool bApplyForceFeedback)
	{
		if (!bClockIsAngered)
		{
			TimeBeforeGoingBack = Duration;
			UHazeAkComponent::HazePostEventFireForget(ClockFaceRedEvent, GetActorTransform());

			if (bApplyCamShake)
			{
				PlayCameraShake(Game::GetCody());
				PlayCameraShake(Game::GetMay());
			}

			if (bApplyForceFeedback)
			{
				bIsPlayingForceFeedback = bApplyForceFeedback;
				
				TArray<AHazePlayerCharacter> Players = Game::GetPlayers();
				for (auto Player : Players)
					Player.PlayForceFeedback(ClockFaceFeedback, true, false, n"ClockFaceFeedback");
			}
			
			bClockIsAngered = true;

			if (bShouldApplyPoi)
			{
				ApplyPointOfInterest(Game::GetCody());
				ApplyPointOfInterest(Game::GetMay());
			}
		}
	}

	UFUNCTION()
	void StopClockFace()
	{
		if (!bShouldBeGoingBack)
		{
			if (GoingBackTimer == -1.f)
				GoingBackTimer = 0.f;
			
			bShouldBeGoingBack = true;
		}
	}

	UFUNCTION()
	void StopForceFeedback()
	{
		if (bIsPlayingForceFeedback)
		{
			bIsPlayingForceFeedback = false;
			TArray<AHazePlayerCharacter> Players = Game::GetPlayers();
			for (auto Player : Players)
				Player.StopForceFeedback(ClockFaceFeedback, n"ClockFaceFeedback");
		}
	}

	UFUNCTION()
	void PlayCameraShake(AHazePlayerCharacter Player)
	{
		Player.PlayCameraShake(CameraShake);
	}

	UFUNCTION()
	void ApplyPointOfInterest(AHazePlayerCharacter Player)
	{
		FHazePointOfInterest Poi;
		Poi.FocusTarget.Actor = this;
		Poi.Duration = 3.f;
		Player.ApplyPointOfInterest(Poi, this);
	}
}