import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.WheelBoat.WheelBoatActor;
class UWheelBoatHitReactionCapability : UHazeCapability
{
	default CapabilityTags.Add(n"WheelBoatHitReactionCapability");
    default CapabilityTags.Add(n"WheelBoat");
	default CapabilityTags.Add(n"WheelBoatMovement");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AWheelBoatActor WheelBoat;

	float StartingPitch;
	float PitchTarget1;
	float PitchTarget2;
	float CurrentPitch;

	float InterpSpeed;
	float CurrentZ;
	float ZTarget1;
	float ZTarget2;
	float ZTargetStart;

	int RandSelector;

	int Stage;

	bool bCanDeactivate;

	float Timer;

    UFUNCTION(BlueprintOverride)
    void Setup(FCapabilitySetupParams Params)
    {
		WheelBoat = Cast<AWheelBoatActor>(Owner);
    }

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (WheelBoat.bTakingDamageReaction)
        	return EHazeNetworkActivation::ActivateLocal;

        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (bCanDeactivate)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Timer = 1.25f;

		Stage = 0;

		StartingPitch = WheelBoat.ActorRotation.Pitch;
		PitchTarget1 = WheelBoat.ActorRotation.Pitch + 2.3f;
		PitchTarget2 = WheelBoat.ActorRotation.Pitch - 2.9f;

		ZTargetStart = 0.f;	
		ZTarget1 = -150.f;	
		ZTarget2 = 0.f;
		CurrentZ = 0.f;	
		
		CurrentPitch = StartingPitch;

		bCanDeactivate = false;
		
		InterpSpeed = 12.2f;

		WheelBoat.bTakingDamageReaction = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{

    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (WheelBoat.bTakingDamageReaction)
		{
			InterpSpeed = 13.5f;
			Stage = 0;
			Timer = 1.5f;
			RandSelector = FMath::RandRange(0, 1);
			WheelBoat.bTakingDamageReaction = false;
		}

		Timer -= DeltaTime;

		if (RandSelector == 0)
		{
			switch(Stage)
			{
				case 0: RotatingTo(DeltaTime, PitchTarget1); break;
				case 1: RotatingTo(DeltaTime, PitchTarget2); break;
				case 2: RotatingTo(DeltaTime, StartingPitch); break;
				case 3: bCanDeactivate = true; break;
			}
		}
		else
		{
			switch(Stage)
			{
				case 0: RotatingTo(DeltaTime, PitchTarget2); break;
				case 1: RotatingTo(DeltaTime, PitchTarget1); break;
				case 2: RotatingTo(DeltaTime, StartingPitch); break;
				case 3: bCanDeactivate = true; break;
			}			
		}

		if (Timer >= 1.f)
			DownUpAction(DeltaTime, ZTarget1); 
		else
			DownUpAction(DeltaTime, ZTargetStart); 

		WheelBoat.SetActorRotation(FRotator(CurrentPitch, WheelBoat.ActorRotation.Yaw, WheelBoat.ActorRotation.Roll));
		WheelBoat.SetActorLocation(WheelBoat.ActorLocation + FVector(0.f, 0.f, CurrentZ));
	}

	UFUNCTION()
	void RotatingTo(float DeltaTime, float PitchTarget)
	{
		InterpSpeed *= 0.993f;

		CurrentPitch = FMath::FInterpConstantTo(CurrentPitch, PitchTarget, DeltaTime, InterpSpeed);

		float PitchRange = PitchTarget - CurrentPitch;
		PitchRange = FMath::Abs(PitchRange);

		if (PitchRange <= 0.3f && Stage < 2)
			Stage++;
		else if (PitchRange <= 0.2f && Stage == 2)
			Stage++;
	}

	UFUNCTION()
	void DownUpAction(float DeltaTime, float ZTarget)
	{
		CurrentZ = FMath::FInterpTo(CurrentZ, ZTarget, DeltaTime, 3.2f);
	}
}