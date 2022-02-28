import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.OctopusBoss.PirateOctopusActor;

class UPirateOctopusFirstSequenceCapability : UHazeCapability
{
    default CapabilityTags.Add(n"PirateOctopus");

    default TickGroup = ECapabilityTickGroups::LastMovement;

	APirateOctopusActor Octopus;

	APirateOctopusArm SlamArm;
	//APirateOctopusArm StreamArm;

	float StartAttackDelay = 5.0f;
	float HitPlayerCoolDownDuration = 3.0f;

	float AttackTimer = 0.0f;
	float TotalDelay = 0.0f;

	bool bPositionedLeft = true;

	bool bTryingToActiveNextAttackSequence = false;
	bool bAwatingFullSyncPoint = false;

    UFUNCTION(BlueprintOverride)
    void Setup(FCapabilitySetupParams Params)
    {
		Octopus = Cast<APirateOctopusActor>(Owner);
		Octopus.ArmsContainerComponent.InitializeArm(Octopus.SlamArmType);
		//Octopus.ArmsContainerComponent.InitializeArm(Octopus.JabArmType);
		//Octopus.ArmsContainerComponent.InitializeArm(Octopus.StreamArmType);
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkActivation ShouldActivate() const
    {
		if(!Octopus.bActivated)
			return EHazeNetworkActivation::DontActivate;

		if(Octopus.CurrentAttackSequence != 1)
            return EHazeNetworkActivation::DontActivate;
		
		if(Octopus.bParticipatingInCutscene)
            return EHazeNetworkActivation::DontActivate;

    	return EHazeNetworkActivation::ActivateLocal;
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkDeactivation ShouldDeactivate() const
    {
		if(!Octopus.bActivated)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(Octopus.CurrentAttackSequence != 1)
            return EHazeNetworkDeactivation::DeactivateLocal;
					
		if(Octopus.bParticipatingInCutscene)
            return EHazeNetworkDeactivation::DeactivateLocal;		
					
        return EHazeNetworkDeactivation::DontDeactivate;
    }

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		FHazePointOfInterest POI;
		POI.FocusTarget.Actor = Octopus;
		POI.Duration = -1;
		POI.Blend = 0.5f;	
		ActivatePOI(POI);
		TotalDelay = StartAttackDelay;
	}

    void ActivatePOI(FHazePointOfInterest POI)
    {
		Game::GetCody().ApplyPointOfInterest(POI, this, EHazeCameraPriority::Script);
		Game::GetCody().BlockCameraSyncronization(this);

		Game::GetMay().ApplyPointOfInterest(POI, this, EHazeCameraPriority::Script);
		Game::GetMay().BlockCameraSyncronization(this);

		Game::GetMay().BlockCapabilities(CameraTags::NonControlledTransition, this);
		Game::GetCody().BlockCapabilities(CameraTags::NonControlledTransition, this);

		devEnsure(Octopus.WheelBoat.PlayerWithFullscreen != nullptr, "Octopus activated PirateOctopusFirstSequenceCapability without full screen actor.");
	}


    void DeactivatePOI()
    {
		Game::GetCody().ClearPointOfInterestByInstigator(this);
		Game::GetCody().UnblockCameraSyncronization(this);

		Game::GetMay().ClearPointOfInterestByInstigator(this);
		Game::GetMay().UnblockCameraSyncronization(this);

		Game::GetMay().UnblockCapabilities(CameraTags::NonControlledTransition, this);
		Game::GetCody().UnblockCapabilities(CameraTags::NonControlledTransition, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		AttackTimer = 0.0f;
		TotalDelay = 0.0f;
		bTryingToActiveNextAttackSequence = false;
		bAwatingFullSyncPoint = false;
		DeactivatePOI();
	}
	
    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
		if(!bTryingToActiveNextAttackSequence
			&& Octopus.CannonBallDamageableComponent.CurrentHealth <= (Octopus.CannonBallDamageableComponent.MaximumHealth / 2))
		{
			bTryingToActiveNextAttackSequence = true;
		}

		if(!bAwatingFullSyncPoint)
		{
			if(bTryingToActiveNextAttackSequence)
			{
				if(Octopus.GetActiveArmsCount() == 0)
				{
					bAwatingFullSyncPoint = true;
					Sync::FullSyncPoint(Octopus, n"InitalizeSecondAttackSequence");
				}
				else if(SlamArm != nullptr && SlamArm.CannonBallDamageableComponent.CanTakeDamage())
				{
					// Force the arm to quit the attack
					SlamArm.HitByCannonBall();
				}
			}
			else if(HasControl())
			{
				if(Octopus.GetActiveArmsCount() == 0)
				{
					if(Octopus.bLastAttackHitPlayer)
					{
						TotalDelay += HitPlayerCoolDownDuration;
						Octopus.bLastAttackHitPlayer = false;
					}

					AttackTimer += DeltaTime;
					if(AttackTimer >= TotalDelay)
					{
						bPositionedLeft = !bPositionedLeft;
						NetActivateSlam(bPositionedLeft);
						AttackTimer = 0;
						TotalDelay = StartAttackDelay;
					}
				}
			}
		}	
	}

	UFUNCTION(NetFunction)
	void NetActivateSlam(bool PositionedLeft)
	{	
		Octopus.CurrentFirstAttackMode = EPirateOctopusFirstAttackMode::Slam;
		SlamArm = Octopus.ArmsContainerComponent.GetArm(Octopus.SlamArmType);
		SlamArm.SetArmPosition(PositionedLeft);
		SlamArm.ActivateArm();	
		Octopus.ActiveFirstPhaseArm = SlamArm;
		Octopus.OnPirateOctopusArmSpawned.Broadcast(SlamArm);
	}
}