import Vino.Pickups.PickupActor;
class ABackstageCarryableCoin : APickupActor
{
	UPROPERTY(DefaultComponent, Attach = PickupRoot)
	UHazeAkComponent HazeAkComp;

	default CarryCapabilitySheet = Asset("/Game/Blueprints/Pickups/CapabilitySheets/PickupBig_Carry_BlockingSheet_Music.PickupBig_Carry_BlockingSheet_Music");

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent CoinFlipAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent CoinPickUpAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent CoinPutDownAudioEvent;
	
	UPROPERTY(Meta = (MakeEditWidget))
    FTransform FlipLocation01;

	UPROPERTY(Meta = (MakeEditWidget))
    FTransform FlipLocation02;

	UPROPERTY(Meta = (MakeEditWidget))
    FTransform FlipLocation03;

	UPROPERTY()
	UCurveFloat FlipCurve;

	UPROPERTY()
	UCurveFloat SpinCurve;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;

	UPROPERTY(DefaultComponent)
	UForceFeedbackComponent ForceFeedbackComp;

	default DisableComp.bDisabledAtStart = true;
	default DisableComp.bActorIsVisualOnly = true;

	FVector StartFlipLocation;
	FVector DesiredLocation;
	FTransform InitialTransform;

	bool bIsFlipping = false;
	bool bPickedUp = false;
	bool bBlockMove = false;

	float StartZ = 0;
	float PreviousAlpha;
	float Alpha;

	int FlipIndex;

	UFUNCTION()
	void Initialize()
	{
		OnPutDownEvent.AddUFunction(this, n"PutDown");
		StartZ = ActorLocation.Z;
		InteractionComponent.OnActivated.AddUFunction(this, n"PickedUp");

		InitialTransform = ActorTransform;
		StartFlipLocation = ActorLocation;

		EnableActor(nullptr);
		
		ActivateCoinDance();
	}

	void ActivateCoinDance()
	{
		if(Network::HasWorldControl())
		{
			NetSetDesiredLocation(InitialTransform.TransformPosition(FlipLocation01.Location));
			NetSetHasLanded(false);
			bIsFlipping = true;
		}
	}

	UFUNCTION()
	void PickedUp(UInteractionComponent Component, AHazePlayerCharacter Player)
	{
		bIsFlipping = false;
		bPickedUp = true;
		HazeAkComp.HazePostEvent(CoinPickUpAudioEvent);
	}

	UFUNCTION()
	void PutDown(AHazePlayerCharacter PlayerCharacter, APickupActor PickupActor)
	{
		if (Network::HasWorldControl())
		{
			ActivateCoinDance();
		}

		HazeAkComp.HazePostEvent(CoinPutDownAudioEvent);
		bPickedUp = false;
	}

	UFUNCTION()
	void DisableCoin()
	{
		bBlockMove = true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bPickedUp || bBlockMove)
			return;

		if(bIsFlipping)
		{
			Alpha += DeltaSeconds * 0.5f;

			if (Alpha >= 1.f)
			{
				FlipFinished();
			}

			FVector CoinLocation = FVector::ZeroVector;
			CoinLocation.X = FMath::Lerp(StartFlipLocation.X, DesiredLocation.X, Alpha);
			CoinLocation.Y = FMath::Lerp(StartFlipLocation.Y, DesiredLocation.Y, Alpha);
			CoinLocation.Z = FlipCurve.GetFloatValue(Alpha) + StartZ;
			
			FRotator Rotation = ActorRotation;
			Rotation.Roll = SpinCurve.GetFloatValue(Alpha);
			ActorRotation = Rotation;
			ActorLocation = CoinLocation;
			PreviousAlpha = Alpha;
		}
	}

	UFUNCTION()
	void FlipFinished()
	{
		bIsFlipping = false;

		if (Network::HasWorldControl())
		{
			NetSetHasLanded(true);
			System::SetTimer(this, n"StartFlip", 1.5f + Network::GetPingRoundtripSeconds(), false);
		}
	}

	UFUNCTION(NetFunction)
	void NetSetHasLanded(bool bEnable)
	{
		if (bEnable)
		{
			InteractionComponent.Enable(n"IsFlipping");
			if (!Network::HasWorldControl())
				System::SetTimer(this, n"StartFlip", 1.5f, false);
		}
		else
		{
			InteractionComponent.Disable(n"IsFlipping");
			bIsFlipping = true;
			Alpha = 0;
			StartFlipLocation = ActorLocation;
			ForceFeedbackComp.Play();
		}
	}

	UFUNCTION()
	void StartFlip()
	{
		HazeAkComp.HazePostEvent(CoinFlipAudioEvent);
		
		if (bPickedUp)
			return;

		for(auto player : Game::Players)
		{
			if (player.ActorLocation.Distance(ActorLocation) < 200)
			{
				player.MovementComponent.AddImpulse(FVector::UpVector * 1500);
			}
		}

		if(Network::HasWorldControl())
		{
			FlipIndex = (FlipIndex + 1) % 3;

			if (FlipIndex == 0)
			{
				NetSetDesiredLocation(InitialTransform.TransformPosition(FlipLocation02.Location));
			}
			else if (FlipIndex == 1)
			{
				NetSetDesiredLocation(InitialTransform.TransformPosition(FlipLocation03.Location));
			}
			else if (FlipIndex == 2)
			{
				NetSetDesiredLocation(InitialTransform.TransformPosition(FlipLocation01.Location));
			}
			
			NetSetHasLanded(false);
		}
	}

	UFUNCTION(NetFunction)
	void NetSetDesiredLocation(FVector Location)
	{
		DesiredLocation = Location;
	}
}