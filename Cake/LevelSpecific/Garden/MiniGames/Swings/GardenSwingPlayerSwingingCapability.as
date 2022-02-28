import Cake.LevelSpecific.Garden.MiniGames.Swings.GardenSwingPlayerComponent;

class UGardenSwingPlayerSwingingCapability : UHazeCapability
{
	default CapabilityTags.Add(n"GardenSwings");

	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 30;

	AHazePlayerCharacter Player;
	UGardenSwingPlayerComponent SwingComp;
	AGardenSwingsActor Swings;

	UGardenSingleSwingComponent PlayerSwing;

	float ImpulsePowerForwards = 1.2f;
	float ImpulsePowerBackwards = 0.15f;

	float MinForwardImpulse = 550.0f;
	float MinBackwardsImpulse = -500.0f;
	float MinUpImpulse = 300.0f;


	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		SwingComp = UGardenSwingPlayerComponent::Get(Owner);

		Swings = SwingComp.Swings;
		PlayerSwing = SwingComp.CurrentSwing;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!PlayerSwing.bPlayerIsOnSwing)
			return EHazeNetworkActivation::DontActivate;
		if(!Swings.bMiniGameIsOn)
			return EHazeNetworkActivation::DontActivate;
		else
			return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(WasActionStarted(ActionNames::MovementJump))
			return EHazeNetworkDeactivation::DeactivateFromControl;
		if(!Swings.bCountingDown && Swings.MinigameComp.GetTimerValue() <= 0.f)
			return EHazeNetworkDeactivation::DeactivateFromControl;		
		else
			return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.UnblockCapabilities(CapabilityTags::MovementInput, Swings);
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreDeactivation(FCapabilityDeactivationSyncParams& DeactivationParams)
	{
		if(WasActionStarted(ActionNames::MovementJump))
			DeactivationParams.AddActionState(n"Jumped");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		bool PlayerJumped = DeactivationParams.GetActionState(n"Jumped");

 		SwingComp.RawInput = FVector2D::ZeroVector;

		if(Player.IsCody())
			Swings.CodyInputSyncFloat.Value = .0f;
		else
			Swings.MayInputSyncFloat.Value = .0f;
			
		if(!PlayerJumped)
		{
			Swings.MinigameComp.PlayFailGenericVOBark(Player);
			SwingComp.bFailed = true;
		}
				
		PlayerSwing.bSwinging = false;
		PlayerSwing.bRequestLocomotionFromPlayer = false;

		Player.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);

		Player.UnblockCapabilities(n"FindOtherPlayer", Swings);
		Player.UnblockCapabilities(CapabilityTags::Movement, Swings);
		Player.UnblockCapabilities(CapabilityTags::Collision, Swings);
		Player.UnblockCapabilities(n"CameraControl", Swings);
		
		Player.DeactivateCameraByInstigator(Swings, 0.5f);

		Player.BlockCapabilities(CapabilityTags::MovementInput, Swings);

		if(HasControl())
		{
			float ImpulsePower;

			if(Player.GetActualVelocity().DotProduct(Swings.ActorForwardVector) < 0)
				ImpulsePower = ImpulsePowerBackwards;
			else
				ImpulsePower = ImpulsePowerForwards;


			FVector FinalImpulse = Player.GetActualVelocity() * ImpulsePower;

			if(FinalImpulse.X >= 0 && FinalImpulse.X < MinForwardImpulse)
				FinalImpulse.X = MinForwardImpulse;
			else if (FinalImpulse.X < 0 && FinalImpulse.X > MinBackwardsImpulse)
				FinalImpulse.X = MinBackwardsImpulse;

			if(FinalImpulse.Y >= 0 && FinalImpulse.Y < MinForwardImpulse)
				FinalImpulse.Y = MinForwardImpulse;
			else if (FinalImpulse.Y < 0 && FinalImpulse.Y > MinBackwardsImpulse)
				FinalImpulse.Y = MinBackwardsImpulse;

			if(FinalImpulse.Z < MinUpImpulse)
				FinalImpulse.Z = MinUpImpulse;
	
			//FinalImpulse = FinalImpulse.ConstrainToDirection(Player.ActorForwardVector);

			Print("" + FinalImpulse);
			Player.AddImpulse(FinalImpulse);
		}

	
		SwingComp.bInAir = true;
		PlayerSwing.bPlayerIsOnSwing = false;
		PlayerSwing.bPlayerHasJumped = true;

		Swings.PlayersJumpedOffSwing(Player);
		Player.PlayForceFeedback(Swings.JumpRumble, false, true, n"GardenSwingJump");
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
		{
 			SwingComp.RawInput = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw);

			if(Player.IsCody())
				Swings.CodyInputSyncFloat.Value = SwingComp.RawInput.Y;
			else
				Swings.MayInputSyncFloat.Value = SwingComp.RawInput.Y;
		}
		else
		{
			if(Player.IsCody())
				SwingComp.RawInput.Y = Swings.CodyInputSyncFloat.Value;
			else
				SwingComp.RawInput.Y = Swings.MayInputSyncFloat.Value;
		}
	}
}