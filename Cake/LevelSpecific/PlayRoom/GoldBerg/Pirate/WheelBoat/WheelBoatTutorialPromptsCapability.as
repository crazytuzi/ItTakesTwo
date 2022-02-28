import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.WheelBoat.WheelBoatActor;

class UWheelBoatTutorialPromptsCapability : UHazeCapability
{
	default CapabilityTags.Add(n"WheelBoatTutorialPromptsCapability");
	default CapabilityTags.Add(n"WheelBoat");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UOnWheelBoatComponent BoatComp;

	bool bTutorialShootInputComplete = false;
	bool bTutorialMovementInputComplete = false;

	bool bTutorialShootActive = false;
	bool bTutorialMovementActive = false;

	USceneComponent AttachPoint;

	//int ShootSpamAmount = 3;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		BoatComp = UOnWheelBoatComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;

		if (BoatComp.WheelBoat == nullptr)
            return EHazeNetworkActivation::DontActivate;

		if (!BoatComp.WheelBoat.BothPlayersAreReady())
			return EHazeNetworkActivation::DontActivate;

		// if(HasPlayerSpammedShoot())
		// 	return EHazeNetworkActivation::ActivateLocal;

		if(!BoatComp.WheelBoat.bShowTutorials)
			return EHazeNetworkActivation::DontActivate;

		if(bTutorialShootInputComplete)
			return EHazeNetworkActivation::DontActivate;

		if(bTutorialMovementInputComplete)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (BoatComp.WheelBoat == nullptr)
            return EHazeNetworkDeactivation::DeactivateLocal;

		if (bTutorialShootInputComplete && bTutorialMovementInputComplete)
            return EHazeNetworkDeactivation::DeactivateLocal;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	// UFUNCTION()
	// bool HasPlayerSpammedShoot() const
	// {
	// 	if(BoatComp.ShootSpamCounter >= ShootSpamAmount)
	// 		return true;

	// 	return false;
	// }

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		//bool bSpamming = HasPlayerSpammedShoot();
		AttachPoint = Player.IsMay() ? BoatComp.WheelBoat.LeftWheelPlayerAttachPoint : BoatComp.WheelBoat.RightWheelPlayerAttachPoint;

		// if(bSpamming)
		// {
		// 	bTutorialMovementInputComplete = true;
		// 	bTutorialShootInputComplete = false;
		// 	BoatComp.ShootSpamCounter = 0;
		// 	BoatShootCannonTutorialActive();
		// }
		// else
		
		BoatMovementTutorialActive();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		NetHideAllTutorialPrompts();
	}


	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if(bTutorialMovementActive && BoatComp.PlayerWheelInput != 0)
		{
			if (!bTutorialMovementInputComplete)
				bTutorialMovementInputComplete = true;
			
			if (bTutorialMovementInputComplete)
			{
				NetHideAllTutorialPrompts();

				BoatShootCannonTutorialActive();
				bTutorialMovementActive = false;
			}
		}

		if(bTutorialShootActive &&  BoatComp.CannonInput)
		{
			if (!bTutorialShootInputComplete)
			{
				bTutorialShootInputComplete = true;
				
				if (bTutorialShootInputComplete)
				{
					bTutorialShootActive = false;
					NetHideAllTutorialPrompts();
				}
			}
		}
	}
	
	UFUNCTION(NetFunction)
	void NetShowMovementPrompt()
	{
		ShowTutorialPromptWorldSpace(Player, BoatComp.WheelBoat.MovementPrompt, this, AttachPoint);
	}

	UFUNCTION(NetFunction)
	void NetShowShootingPrompt()
	{
		ShowTutorialPromptWorldSpace(Player, BoatComp.WheelBoat.ShootingPrompt, this, AttachPoint);
	}

	UFUNCTION(NetFunction)
	void NetHideAllTutorialPrompts()
	{
		RemoveTutorialPromptByInstigator(Player, this);
	}

	UFUNCTION()
	void BoatMovementTutorialActive()
	{
		NetShowMovementPrompt();

		bTutorialMovementActive = true;
	}

	UFUNCTION()
	void BoatShootCannonTutorialActive()
	{
		if (bTutorialMovementInputComplete)
		{
			NetShowShootingPrompt();
			bTutorialShootActive = true;	
		}
	}
}