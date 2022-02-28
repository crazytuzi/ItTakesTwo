//import Vino.Movement.Components.MovementComponent;
//import Vino.Movement.Components.LedgeGrab.LedgeGrabComponent;

//class UCharacterAirJumpValidationCapability : UHazeCapability
//{
	//default CapabilityTags.Add(n"AirJump");
	//default CapabilityTags.Add(CapabilityTags::Movement);
	//default CapabilityTags.Add(n"AirJumpValidation");

	
	//default TickGroup = ECapabilityTickGroups::ActionMovement;
	//default TickGroupOrder = 98;

	//default CapabilityDebugCategory = CapabilityTags::Movement;

	//AHazePlayerCharacter Player;
	//UHazeMovementComponent MoveComp;
	//ULedgeGrabComponent LedgeGrabComp;

	//UFUNCTION(BlueprintOverride)
	//void Setup(FCapabilitySetupParams SetupParams)
	//{
		//Player = Cast<AHazePlayerCharacter>(Owner);
		//MoveComp = UHazeMovementComponent::GetOrCreate(Owner);
		//LedgeGrabComp = ULedgeGrabComponent::GetOrCreate(Owner);
	//}

	//UFUNCTION(BlueprintOverride)
	//EHazeNetworkActivation ShouldActivate() const
	//{
		//if (!WasActionStarted(ActionNames::MovementJump))
        	//return EHazeNetworkActivation::DontActivate;

		//if (MoveComp.IsGrounded())
        	//return EHazeNetworkActivation::DontActivate;

		//if (LedgeGrabComp.CurrentState == ELedgeGrabStates::JumpOff)
        	//return EHazeNetworkActivation::ActivateLocal;

        //return EHazeNetworkActivation::DontActivate;
	//}

	//UFUNCTION(BlueprintOverride)
	//EHazeNetworkDeactivation ShouldDeactivate() const
	//{
		//return EHazeNetworkDeactivation::DeactivateFromControl;
	//}

	//UFUNCTION(BlueprintOverride)
	//void OnActivated(FCapabilityActivationParams ActivationParams)
	//{
		//Owner.BlockCapabilities(n"AirJump", this);
	//}

	//UFUNCTION(BlueprintOverride)
	//void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	//{
		//Owner.UnblockCapabilities(n"AirJump", this);	
	//}

	//UFUNCTION(BlueprintOverride)
	//void OnRemoved()
	//{

    //}



	//UFUNCTION(BlueprintOverride)
	//void TickActive(float DeltaTime)
	//{	
	
	//}
//} 
