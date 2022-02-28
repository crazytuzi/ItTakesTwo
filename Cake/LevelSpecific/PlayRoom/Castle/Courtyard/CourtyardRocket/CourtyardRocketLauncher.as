import Vino.Buttons.GroundPoundButton;
import Peanuts.Spline.SplineActor;
import Vino.Checkpoints.Volumes.DeathVolume;
import Vino.Movement.Components.MovementComponent;

event void FOnRocketFinishedSpline(ASplineActor SplineActor);

class ACourtyardRocketLauncher : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent)
	USceneComponent HatchRoot;

	UPROPERTY(DefaultComponent, Attach = HatchRoot)
	UStaticMeshComponent LeftHatch;

	UPROPERTY(DefaultComponent, Attach = HatchRoot)
	UStaticMeshComponent RightHatch;

	UPROPERTY(DefaultComponent)
	USceneComponent RocketRoot;

	UPROPERTY(DefaultComponent, Attach = RocketRoot)
	UStaticMeshComponent Rocket;

	UPROPERTY(DefaultComponent, Attach = Rocket)
	UNiagaraComponent RocketThruster;

	UPROPERTY(DefaultComponent)
	UBoxComponent PlayerKnockVolume;
	default PlayerKnockVolume.SetCollisionProfileName(n"OverlapOnlyPawn");

	UPROPERTY(DefaultComponent, Attach = RocketRoot)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ActivateAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ExplodeAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent CloseHatchAudioEvent;

	UPROPERTY()
	ADeathVolume DeathTrigger;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike OpenHatchTimeLike;

	UPROPERTY()
	UNiagaraSystem Explosion;

	UPROPERTY()
	AGroundPoundButton Button;

	UPROPERTY()
	TArray<ASplineActor> Splines;

	UPROPERTY()
	float MaxRocketSpeed = 500.0f;

	UPROPERTY()
	float MinRocketSpeed = 50.0f;

	UPROPERTY()
	float DeltaSpeed = 9.0f;

	float CurrentRockedSpeed = 50.0f;

	UPROPERTY()
	FOnRocketFinishedSpline OnRocketFinishedSpline;

	UHazeSplineComponent CurrentSpline;

	bool bRocketActivated = false;
	float RocketDistance = 0.0f;
	int CurrentSplineIndex = 0;
	bool bOpeningHatch = false;

	FVector OriginalRocketLocation = FVector(.0f, .0f, 100.0f);
	FRotator OriginalRocketRotation = FRotator(90.0f, .0f, .0f);

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Button.OnButtonGroundPoundCompleted.AddUFunction(this, n"ButtonPressed");

		OpenHatchTimeLike.BindUpdate(this, n"UpdateOpenHatch");
		OpenHatchTimeLike.BindFinished(this, n"CloseHatch");

		Rocket.SetHiddenInGame(true);
		RocketThruster.Deactivate();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(bRocketActivated)
		{
			CurrentRockedSpeed += DeltaTime * DeltaSpeed;

            CurrentRockedSpeed = FMath::Clamp(CurrentRockedSpeed, MinRocketSpeed, MaxRocketSpeed);
			
			if(CurrentRockedSpeed >= MaxRocketSpeed)
				PrintToScreen("woo");

			RocketDistance += DeltaTime * CurrentRockedSpeed;

			FTransform SplineTransform = CurrentSpline.GetTransformAtDistanceAlongSpline(RocketDistance, ESplineCoordinateSpace::World, false);

			RocketRoot.SetWorldTransform(SplineTransform);

			if (RocketDistance >= CurrentSpline.SplineLength)
			{
				FinishRocket();
			}
		}
	}

	UFUNCTION()
	void ButtonPressed(AHazePlayerCharacter Player)
	{
		bRocketActivated = true;

		Rocket.SetHiddenInGame(false);
		RocketThruster.Activate(true);

		HazeAkComp.HazePostEvent(ActivateAudioEvent);

		CurrentSplineIndex++;

		if(CurrentSplineIndex > Splines.Num() - 1)
			CurrentSplineIndex = 0;

		if(Splines[CurrentSplineIndex] != nullptr)
			CurrentSpline = Splines[CurrentSplineIndex].Spline;

		KnockPlayersAwayFromHatch();

		DeathTrigger.DisableDeathVolume();

		OpenHatchTimeLike.PlayFromStart();
		bOpeningHatch = true;

		FHazePointOfInterest PointOfInterestSettings;
		PointOfInterestSettings.FocusTarget.Component = RocketRoot;
		PointOfInterestSettings.Blend.BlendTime = 0.35f;
		PointOfInterestSettings.Duration = PointOfInterestSettings.Blend.BlendTime;

		Player.ApplyPointOfInterest(PointOfInterestSettings, this);
	}

	void KnockPlayersAwayFromHatch()
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (!PlayerKnockVolume.IsOverlappingActor(Player))
				continue;

			FVector ToPlayer = Player.ActorLocation - ActorLocation;
			ToPlayer = ToPlayer.ConstrainToDirection(ActorRightVector);
			ToPlayer.Normalize();


			FVector Impulse = FVector::UpVector * 1800.f;
			Impulse += ToPlayer * 900.f;

			UHazeMovementComponent::Get(Player).AddImpulse(Impulse);
		}
	}

	UFUNCTION()
	void FinishRocket()
	{
		bRocketActivated = false;

		HazeAkComp.HazePostEvent(StopAudioEvent);
		HazeAkComp.HazePostEvent(ExplodeAudioEvent);

		if (Explosion != nullptr)
			Niagara::SpawnSystemAtLocation(Explosion, Rocket.WorldLocation);

		if(Splines[CurrentSplineIndex] != nullptr)
			OnRocketFinishedSpline.Broadcast(Splines[CurrentSplineIndex]);

		Rocket.SetHiddenInGame(true);
		RocketThruster.Deactivate();

		RocketRoot.SetRelativeLocation(OriginalRocketLocation);
		RocketRoot.SetRelativeRotation(OriginalRocketRotation);

		RocketDistance = 0.0f;
		CurrentRockedSpeed = 0.0f;

		Button.ResetButton();
	}

	UFUNCTION()
	void CloseHatch()
	{
		if(bOpeningHatch)
		{
			bOpeningHatch = false;
			OpenHatchTimeLike.ReverseFromEnd();
			UHazeAkComponent::HazePostEventFireForget(CloseHatchAudioEvent, GetActorTransform());
		}
		else
		{
			DeathTrigger.EnableDeathVolume();
			
		}
		
	}

	UFUNCTION()
	void UpdateOpenHatch(float CurValue)
	{
		float Roll = FMath::Lerp(0.f, -90.f, CurValue);
		LeftHatch.SetRelativeRotation(FRotator(0.f, 0.f, Roll));
		RightHatch.SetRelativeRotation(FRotator(0.f, 180.f, Roll));
	}

}