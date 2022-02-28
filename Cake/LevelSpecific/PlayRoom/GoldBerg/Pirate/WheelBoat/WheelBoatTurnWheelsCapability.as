import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.WheelBoat.WheelBoatActor;

class UWheelBoatTurnWheelsCapability : UHazeCapability
{
    default CapabilityTags.Add(n"WheelBoat");
	default CapabilityTags.Add(n"WheelBoatTurnWheels");
	
    default TickGroup = ECapabilityTickGroups::BeforeMovement;

	AWheelBoatActorWheelActor SubActor;
	AWheelBoatActor WheelBoat;
	UOnWheelBoatComponent WheelComp;



	//float AnimationSpeed = 0;
	//float MovementSpeed = 0;
	
    UFUNCTION(BlueprintOverride)
    void Setup(FCapabilitySetupParams Params)
    {
		SubActor = Cast<AWheelBoatActorWheelActor>(Owner);
		WheelBoat = SubActor.ParentBoat;
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkActivation ShouldActivate() const
    {
		if(WheelBoat.PlayerInLeftWheel == nullptr && WheelBoat.PlayerInRightWheel == nullptr)
            return EHazeNetworkActivation::DontActivate;
		
		if(SubActor.Player == nullptr)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkDeactivation ShouldDeactivate() const
    {
		if(WheelBoat.PlayerInLeftWheel == nullptr || WheelBoat.PlayerInRightWheel == nullptr)
            return EHazeNetworkDeactivation::DeactivateLocal;
       
	   	if(SubActor.Player == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

        return EHazeNetworkDeactivation::DontDeactivate;
    }

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		WheelComp = UOnWheelBoatComponent::Get(SubActor.Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		WheelComp = nullptr;
		FWheelBoatMovementData& MovementData = SubActor.MovementData;
		MovementData.PendingSteering = FVector::ZeroVector;
	}

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
		FWheelBoatMovementData& MovementData = SubActor.MovementData;
		MovementData.PendingSteering = WheelComp.PlayerSteeringInput;

		float MovementInput = 0;
		float AnimationInput = 0;
		WheelBoat.GetInputValue(SubActor.Player, MovementInput, AnimationInput);	
		MovementData.UpdateMovement(DeltaTime, MovementInput, AnimationInput);
		SetAnimationForPlayerDependingOnWheelSpeed(MovementData.WheelBoatWheelAnimationRange * DeltaTime);

		// Need to check if we are any of the sides...
		const float SplashAmount = FMath::Abs(MovementData.WheelBoatWheelAnimationRange);
		if(SubActor.IsLeftSide())
		{		
			WheelBoat.LeftWheelSplashEffect.SetNiagaraVariableFloat("User.SpawnRate", SplashAmount * WheelBoat.WheelSplashMaxSpawnRate);	
		}
		else if(SubActor.IsRightSide())
		{
			WheelBoat.RightWheelSplashEffect.SetNiagaraVariableFloat("User.SpawnRate", SplashAmount * WheelBoat.WheelSplashMaxSpawnRate);
		}	
    }

	void SetAnimationForPlayerDependingOnWheelSpeed(float WheelSpeed)
	{
		if(!FMath::IsNearlyZero(WheelSpeed, 0.05f))
		{
			if(WheelSpeed > 0)
			{
				SubActor.Player.SetCapabilityActionState(n"SprintingFwd", EHazeActionState::Active);
			}
			else if (WheelSpeed < 0)
			{   
				SubActor.Player.SetCapabilityActionState(n"SprintingBwd", EHazeActionState::Active);
			}
		}
		else
		{
			SubActor.Player.SetCapabilityActionState(n"SprintingFwd", EHazeActionState::Inactive);
			SubActor.Player.SetCapabilityActionState(n"SprintingBwd", EHazeActionState::Inactive);
		}
	}
}