import Cake.LevelSpecific.SnowGlobe.WindWalk.DoublePull.WindWalkDoublePullActor;

class UWindWalkDoublePullPlayerCapability : UHazeCapability
{
	default CapabilityTags.Add(WindWalkTags::WindWalkDoublePull);
	default CapabilityTags.Add(WindWalkTags::WindWalkDoublePullPlayerCapability);

	default CapabilityDebugCategory = WindWalkTags::WindWalk;

	UPROPERTY(Category = "Attraction")
	UForceFeedbackEffect AttractionRumble;

	UPROPERTY(Category = "Hazard")
	UForceFeedbackEffect HazardHitRumble;

	UPROPERTY(Category = "Hazard")
	TSubclassOf<UCameraShakeBase> HazardHitCameraShakeClass;

	UPROPERTY(Category = "Walk")
	UForceFeedbackEffect StepRumble;

	UPROPERTY(Category = "Walk")
	TSubclassOf<UCameraShakeBase> WalkingCameraShakeClass;
	UCameraShakeBase WalkingCameraShake;

	UPROPERTY(Category = "Tumbling")
	TSubclassOf<UCameraShakeBase> TumbleCameraShakeClass;
	UCameraShakeBase TumbleCameraShake;

	AHazePlayerCharacter PlayerOwner;
 	AWindWalkDoublePullActor WindWalkDoublePull;

	// Force feedback stuff for tumbling
	TArray<float> FFValues;
	const float FFNumberOfMotors = 4.f;
	const float FFMaxValue = 0.2f;
	float FFElapsedTime;

	// State flags
	bool bPlayersAreWalking;
	bool bPlayersAreTumbling;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);

		// Really? No in-place initialization? :(
		FFValues.Add(FFMaxValue);
		FFValues.Add(0.f);
		FFValues.Add(0.f);
		FFValues.Add(0.f);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(GetAttributeObject(n"DoublePull") == nullptr)
			return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		UDoublePullComponent DoublePullComponent = Cast<UDoublePullComponent>(GetAttributeObject(n"DoublePull"));
		WindWalkDoublePull = Cast<AWindWalkDoublePullActor>(DoublePullComponent.Owner);

		WindWalkDoublePull.OnPlayerAttractionStartedEvent.AddUFunction(this, n"OnPlayerAttractionStarted");
		WindWalkDoublePull.OnPlayerAttractionEndedEvent.AddUFunction(this, n"OnPlayerAttractionEnded");
		WindWalkDoublePull.OnPlayersHitByHazardEvent.AddUFunction(this, n"OnPlayersHitByHazard");
		
		DoublePullComponent.OnStartedEffort.AddUFunction(this, n"OnPlayerStep");

		WindWalkDoublePull.OnTumblingStarted.AddUFunction(this, n"OnTumblingStarted");
		WindWalkDoublePull.OnTumblingEnded.AddUFunction(this, n"OnTumblingEnded");
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Check if players are romantically engaged
		HandleAttractionState();

		// Update camera info
		HandleSpawnedHazards();

		// Hold FF for as long as player is activating magnet alone
		if(WindWalkDoublePull.PlayerIsActivatingMagnet(PlayerOwner) && !WindWalkDoublePull.PlayerIsActivatingMagnet(PlayerOwner.OtherPlayer))
			PlayerOwner.SetFrameForceFeedback(0.2f, 0.2f);

		// Check if players started/finished walking
		HandleWalkingCameraShake();

		// Handle circular noise rumble if players are tumbling down
		if(bPlayersAreTumbling)
			HandleTumblingForceFeedback(DeltaTime);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!WindWalkDoublePull.DoublePull.AreBothPlayersInteracting())
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		WindWalkDoublePull = nullptr;
		bPlayersAreWalking = false;
		bPlayersAreTumbling = false;
	}

	void HandleAttractionState()
	{
		if(WindWalkDoublePull.PlayersAreAttracted())
		{
			if(!WindWalkDoublePull.BothPlayersAreActivatingMagnet())
			{
				WindWalkDoublePull.OnPlayerAttractionEndedEvent.Broadcast();
			}
		}
		else
		{
			if(WindWalkDoublePull.BothPlayersAreActivatingMagnet())
			{
				WindWalkDoublePull.OnPlayerAttractionStartedEvent.Broadcast();
			}
		}
	}

	void HandleSpawnedHazards()
	{
		int ValidCameraHazardCount = 0;
		for(AWindWalkDoublePullHazard Hazard : WindWalkDoublePull.SpawnedHazards)
		{
			if(!Hazard.ShouldLoseCameraFocus(WindWalkDoublePull.ActorLocation))
				ValidCameraHazardCount++;
		}

		// Read by WindWalkDoublePullHazardCamera capability
		PlayerOwner.SetCapabilityAttributeNumber(n"ValidCameraHazardCount", ValidCameraHazardCount);
	}

	void HandleWalkingCameraShake()
	{
		if(bPlayersAreWalking)
		{
			if(!WindWalkDoublePull.BothPlayersAreWalking())
			{
				if(WalkingCameraShake != nullptr)
					PlayerOwner.StopCameraShake(WalkingCameraShake);

				bPlayersAreWalking = false;
			}
		}
		else
		{
			if(WindWalkDoublePull.BothPlayersAreWalking())
			{
				WalkingCameraShake = PlayerOwner.PlayCameraShake(WalkingCameraShakeClass, 0.4f);
				bPlayersAreWalking = true;
			}
		}
	}

	// Questionable, temporary implementation of circular, noisy FF
	void HandleTumblingForceFeedback(float DeltaTime)
	{
		FFElapsedTime += DeltaTime * FMath::RandRange(2.f, 5.f);
		if(FFElapsedTime >= FFNumberOfMotors)
			FFElapsedTime = 0.f;

		int Index = int(FFElapsedTime);
		int NextIndex = Index == 3 ? 0 : Index + 1;

		float Alpha = FMath::Frac(FFElapsedTime);
		FFValues[Index] = FMath::Lerp(0.f, FFMaxValue, 1.f - Alpha);
		FFValues[NextIndex] = FMath::Lerp(0.f, FFMaxValue, Alpha);

		PlayerOwner.SetFrameForceFeedback(FFValues[Index], FFValues[NextIndex]);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnPlayerAttractionStarted()
	{
		PlayerOwner.PlayForceFeedback(AttractionRumble, false, false, n"WindWalkDoublePullAttraction", 0.5f);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnPlayersHitByHazard()
	{
		// Play rumble feedback and camera shake
		PlayerOwner.PlayForceFeedback(HazardHitRumble, false, false, n"WindWalkDoublePullHazardHit");
		PlayerOwner.PlayCameraShake(HazardHitCameraShakeClass, 1.f);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnPlayerAttractionEnded()
	{

	}

	UFUNCTION(NotBlueprintCallable)
	void OnPlayerStep()
	{
		System::SetTimer(this, n"OnDelayedPlayerStep", 0.4f, false, 0.f, 0.1f);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnDelayedPlayerStep()
	{
		PlayerOwner.PlayForceFeedback(StepRumble, false, false, n"WinWalkDoublePullStep");
	}

	UFUNCTION(NotBlueprintCallable)
	void OnTumblingStarted()
	{
		PlayerOwner.SetAnimBoolParam(n"DoublePullGoBack", true);
		TumbleCameraShake = PlayerOwner.PlayCameraShake(TumbleCameraShakeClass);

		bPlayersAreTumbling = true;
	}

	UFUNCTION(NotBlueprintCallable)
	void OnTumblingEnded()
	{
		PlayerOwner.SetAnimBoolParam(n"DoublePullGoBack", false);
		PlayerOwner.StopCameraShake(TumbleCameraShake);

		bPlayersAreTumbling = false;
	}
}