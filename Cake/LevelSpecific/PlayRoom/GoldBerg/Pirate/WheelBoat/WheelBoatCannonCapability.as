import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.WheelBoat.WheelBoatActor;
import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.WheelBoat.ToyCannonActor;
import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.OctopusBoss.PirateOctopusArm;
import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.OctopusBoss.PirateOctopusActor;

struct FWheelBoatCanonData
{
	FWheelBoatCanonData(){}
	FWheelBoatCanonData(AToyCannonActor InCannon)
	{
		Cannon = InCannon;
		AkComponent = Cannon.AkComponent;
	}

	AToyCannonActor Cannon;
	UHazeAkComponent AkComponent;
	UOnWheelBoatComponent PlayerWheelboatComponent;
}

// This capability is used on the wheelboat and is handling the players canon input
class UWheelBoatCannonCapability : UHazeCapability
{
	default CapabilityTags.Add(n"WheelBoat");	
    default CapabilityTags.Add(n"WheelBoatCannon");
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	
    default TickGroup = ECapabilityTickGroups::ActionMovement;

	AWheelBoatActor WheelBoat;
	FWheelBoatCanonData LeftCannonData;
	FWheelBoatCanonData RightCannonData;

	bool bLeftSpamChecked = false;
	bool bRightSpamChecked = false;

    UFUNCTION(BlueprintOverride)
    void Setup(FCapabilitySetupParams Params)
    {
		WheelBoat = Cast<AWheelBoatActor>(Owner);
		LeftCannonData = FWheelBoatCanonData(WheelBoat.LeftCannon);
		RightCannonData = FWheelBoatCanonData(WheelBoat.RightCannon);
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkActivation ShouldActivate() const
    {
		if(!WheelBoat.BothPlayersAreReady())
			return EHazeNetworkActivation::DontActivate;

		if(WheelBoat.PlayerInLeftWheel == nullptr && WheelBoat.PlayerInRightWheel == nullptr)
            return EHazeNetworkActivation::DontActivate;

		if(WheelBoat.bDocked)
			return EHazeNetworkActivation::DontActivate;

		if(WheelBoat.bSpinning)
			return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateLocal;
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkDeactivation ShouldDeactivate() const
    {
		if(!WheelBoat.BothPlayersAreReady())
            return EHazeNetworkDeactivation::DeactivateLocal;

		if(WheelBoat.PlayerInLeftWheel == nullptr && WheelBoat.PlayerInRightWheel == nullptr)
            return EHazeNetworkDeactivation::DeactivateLocal;

		if(WheelBoat.bDocked)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(WheelBoat.bSpinning)
			return EHazeNetworkDeactivation::DeactivateLocal;

        return EHazeNetworkDeactivation::DontDeactivate;
    }

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{		
		LeftCannonData.PlayerWheelboatComponent = UOnWheelBoatComponent::Get(WheelBoat.PlayerInLeftWheel);
		RightCannonData.PlayerWheelboatComponent = UOnWheelBoatComponent::Get(WheelBoat.PlayerInRightWheel);

		// Since this is using netfunctions to fire, we need to initialize the player component with a netfunction
		if(WheelBoat.PlayerInLeftWheel.HasControl())
			NetSetupPlayerInCanon(WheelBoat.PlayerInLeftWheel, bLeft = true);

		if(WheelBoat.PlayerInRightWheel.HasControl())
			NetSetupPlayerInCanon(WheelBoat.PlayerInRightWheel, bLeft = false);
	}

	UFUNCTION(NetFunction)
	void NetSetupPlayerInCanon(AHazePlayerCharacter Player, bool bLeft)
	{
		if(bLeft)
			LeftCannonData.PlayerWheelboatComponent = UOnWheelBoatComponent::Get(Player);
		else
			RightCannonData.PlayerWheelboatComponent = UOnWheelBoatComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		// AToyCannonActor RigthCannon = RightCannonData.Cannon;
		// if(RigthCannon != nullptr)
		// 	RigthCannon.HideAimGui();

		// AToyCannonActor LeftCannon = LeftCannonData.Cannon;
		// if(LeftCannon != nullptr)
		// 	LeftCannon.HideAimGui();

		if(LeftCannonData.PlayerWheelboatComponent.CannonInput)
		{
			DeactivateCannonInput(LeftCannonData);
		}
		LeftCannonData.PlayerWheelboatComponent = nullptr;
		
		if(RightCannonData.PlayerWheelboatComponent.CannonInput)
		{
			DeactivateCannonInput(RightCannonData);
		}
		RightCannonData.PlayerWheelboatComponent = nullptr;
	}
	
    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {		
		// Left Canon
		if(LeftCannonData.Cannon.HasControl())
		{	
			if(LeftCannonData.Cannon.bRequestedInput && !bLeftSpamChecked)
			{
				//SpamCheckCannon(LeftCannonData);
				bLeftSpamChecked = true;
			}
			else if(!LeftCannonData.Cannon.bRequestedInput && bLeftSpamChecked)
				bLeftSpamChecked = false;

			if(LeftCannonData.Cannon.bRequestedInput
				&& !LeftCannonData.PlayerWheelboatComponent.CannonInput)
			{
				NetActivateLeftCannon();
			}
			else if(!LeftCannonData.Cannon.bRequestedInput
				&& LeftCannonData.PlayerWheelboatComponent.CannonInput
				&& LeftCannonData.Cannon.SpeedPercentage > 0.99f)
			{
					
				const FVector SpawnLocation = LeftCannonData.Cannon.CannonShootFromPoint.GetWorldLocation();
				const FRotator SpawnRotation = LeftCannonData.Cannon.CannonShootFromPoint.GetWorldRotation(); 
				NetFireLeftCannon(SpawnLocation, SpawnRotation, LeftCannonData.Cannon.TrajectoryHitResult);
			}
		}	

		if(LeftCannonData.PlayerWheelboatComponent.CannonInput)
		{
			UpdateActiveCannon(LeftCannonData, DeltaTime);
		}

		// Right Canon
		if(RightCannonData.Cannon.HasControl())
		{
			if(RightCannonData.Cannon.bRequestedInput && !bRightSpamChecked)
			{
				//SpamCheckCannon(RightCannonData);
				bRightSpamChecked = true;
			}
			else if(!RightCannonData.Cannon.bRequestedInput && bRightSpamChecked)
				bRightSpamChecked = false;

			if(RightCannonData.Cannon.bRequestedInput
				&& !RightCannonData.PlayerWheelboatComponent.CannonInput)
			{
				NetActivateRightCannon();
			}
			else if(!RightCannonData.Cannon.bRequestedInput
				&& RightCannonData.PlayerWheelboatComponent.CannonInput
				&& RightCannonData.Cannon.SpeedPercentage > 0.99f)
			{			
				const FVector SpawnLocation = RightCannonData.Cannon.CannonShootFromPoint.GetWorldLocation();
				const FRotator SpawnRotation = RightCannonData.Cannon.CannonShootFromPoint.GetWorldRotation(); 
				NetFireRightCannon(SpawnLocation, SpawnRotation, RightCannonData.Cannon.TrajectoryHitResult);
			}
		}	

		if(RightCannonData.PlayerWheelboatComponent.CannonInput)
		{
			UpdateActiveCannon(RightCannonData, DeltaTime);
		}

		AToyCannonActor RigthCannon = RightCannonData.Cannon;
		AToyCannonActor LeftCannon = LeftCannonData.Cannon;

		// If we want gui during the 1 phase where the camera is not locked behind he player, this could be used
		// if(WheelBoat.BossFightIndex == 1 && !WheelBoat.bBossIsPreparingNextAttackSequence)
		// {
		// 	RigthCannon.ScaleArrowWithSpeed(RigthCannon.GetMaxCannonSpeed());	
		// 	LeftCannon.ScaleArrowWithSpeed(LeftCannon.GetMaxCannonSpeed());	
		// }
		// else
		// {
		// 	RigthCannon.HideAimGui();
		// 	LeftCannon.HideAimGui();
		// }
		
	}

	bool ShouldBeActive()const
	{
		if(WheelBoat.PlayerInLeftWheel == nullptr && WheelBoat.PlayerInRightWheel == nullptr)
            return false;

		if(WheelBoat.bDocked)
			return false;

		if(WheelBoat.bSpinning)
			return false;

		return true;
	}

	UFUNCTION(NetFunction)
	void NetActivateLeftCannon()
	{
		ActivateCannon(LeftCannonData);
	}

	UFUNCTION(NetFunction)
	void NetActivateRightCannon()
	{
		ActivateCannon(RightCannonData);
	}

	void ActivateCannon(FWheelBoatCanonData CannonData)
	{
		if(CannonData.PlayerWheelboatComponent != nullptr)
		{
			AToyCannonActor Cannon = CannonData.Cannon;
			CannonData.PlayerWheelboatComponent.CannonInput = true;
			Cannon.ResetCannonSpeed();
			//Cannon.CannonSpeedArrow.SetHiddenInGame(false);
			if(Cannon.CannonWheelBoatAimCrankLoopStartEvent != nullptr)
				CannonData.AkComponent.HazePostEvent(Cannon.CannonWheelBoatAimCrankLoopStartEvent);
		}
	}

	// void SpamCheckCannon(FWheelBoatCanonData CannonData)
	// {				
	// 	const float TimeSinceEarlierShot = Time::GetGameTimeSince(CannonData.PlayerWheelboatComponent.LatestShotTimeStamp);

	// 	if(TimeSinceEarlierShot <= 1.0f) //Spam
	// 		CannonData.PlayerWheelboatComponent.ShootSpamCounter ++;
	// 	else if (CannonData.PlayerWheelboatComponent.ShootSpamCounter > 0)
	// 		CannonData.PlayerWheelboatComponent.ShootSpamCounter = 0;

	// 	CannonData.PlayerWheelboatComponent.LatestShotTimeStamp = Time::GetGameTimeSeconds();
	// }


	UFUNCTION(NetFunction)
	void NetFireLeftCannon(FVector CanonFireLocation, FRotator SpawnRotation, FHitResult TrajectoryHitResult)
	{
		FireCanon(CanonFireLocation, SpawnRotation, LeftCannonData, TrajectoryHitResult);
		DeactivateCannonInput(LeftCannonData);
	}

	UFUNCTION(NetFunction)
	void NetFireRightCannon(FVector CanonFireLocation, FRotator SpawnRotation, FHitResult TrajectoryHitResult)
	{
		FireCanon(CanonFireLocation, SpawnRotation, RightCannonData, TrajectoryHitResult);
		DeactivateCannonInput(RightCannonData);
	}

	void UpdateActiveCannon(FWheelBoatCanonData CannonData, float DeltaTime)
	{
		AToyCannonActor Cannon = CannonData.Cannon;
		Cannon.AddSpeedToCannon(DeltaTime);
		//Cannon.ScaleArrowWithSpeed();	
		CannonData.PlayerWheelboatComponent.ChargeRange = Cannon.SpeedPercentage;
		CannonData.AkComponent.SetRTPCValue("Rtpc_Weapon_Cannon_Wheelboat_Aim", Cannon.SpeedPercentage, 0);
	}

	void DeactivateCannonInput(FWheelBoatCanonData CannonData)
	{
		if(CannonData.PlayerWheelboatComponent != nullptr)
		{
			AToyCannonActor Cannon = CannonData.Cannon;
			CannonData.PlayerWheelboatComponent.CannonInput = false;

			//Cannon.CannonSpeedArrow.SetHiddenInGame(true);	
			Cannon.Crosshair.SetHiddenInGame(true, true);
						
			if(Cannon.CannonWheelBoatAimCrankLoopStopEvent != nullptr)
				CannonData.AkComponent.HazePostEvent(Cannon.CannonWheelBoatAimCrankLoopStopEvent);

			CannonData.AkComponent.SetRTPCValue("Rtpc_Weapon_Cannon_Wheelboat_Aim", Cannon.SpeedPercentage, 0);
		}
	}

	void FireCanon(FVector CanonFireLocation, FRotator SpawnRotation, FWheelBoatCanonData CannonData, FHitResult TrajectoryHitResult)
	{
		AToyCannonActor Cannon = CannonData.Cannon;
		ACannonBallActor Ball = InitializeCanonBall(CanonFireLocation, SpawnRotation, CannonData);

		// Force the cannons to follow the impact location in the first attack sequence
		if(WheelBoat.BossFightIndex == 1 && TrajectoryHitResult.Actor != nullptr)
		{
			if(TrajectoryHitResult.Actor.IsA(APirateOctopusArm::StaticClass()))
				Ball.ActivateRelativeMovement(TrajectoryHitResult.Actor);
			else if(TrajectoryHitResult.Actor.IsA(APirateOctopusActor::StaticClass()))
				Ball.ActivateRelativeMovement(TrajectoryHitResult.Actor);
		}

		// Camera
		Cannon.CurrentActiveShake = Cannon.Player.PlayCameraShake(Cannon.ShootCameraShake);

		// Force feedback
		if(Cannon.SpeedPercentage <= 0.5f)
			Cannon.Player.PlayForceFeedback(Cannon.LowShootForceFeedback, false, true, n"CannonBallShot");
		else
			Cannon.Player.PlayForceFeedback(Cannon.MediumShootForceFeedback, false, true, n"CannonBallShot");
		
		// Audio
		if(Cannon.CannonWheelBoatAimCrankLoopStopEvent != nullptr)
			CannonData.AkComponent.HazePostEvent(Cannon.CannonWheelBoatAimCrankLoopStopEvent);

		CannonData.AkComponent.SetRTPCValue("Rtpc_Weapon_Cannon_Wheelboat_Aim", Cannon.SpeedPercentage, 0);
	}

	ACannonBallActor InitializeCanonBall(FVector CanonFireLocation, FRotator SpawnRotation, FWheelBoatCanonData CannonData)
	{
		AToyCannonActor Cannon = CannonData.Cannon;

		//Niagara::SpawnSystemAtLocation(CurrentCannon.FireEffect, CurrentCannon.CannonSpeedArrow.WorldLocation + CurrentCannon.SpawnEffectLocationOffset, CurrentCannon.ActorRotation, true);
		Niagara::SpawnSystemAttached(Cannon.FireEffect, Cannon.FireEffectAttachPoint, NAME_None, FVector::ZeroVector, FRotator::ZeroRotator, EAttachLocation::SnapToTarget, true);

		const FVector Direction = SpawnRotation.GetForwardVector();
		const FVector InheritedVelocity = WheelBoat.GetActorVelocity();

		ACannonBallActor CannonBall = Cannon.CannonBallContainer[Cannon.CurrentCannonBallIndex];
			
		CannonBall.ActivateBall(CanonFireLocation, SpawnRotation, Direction * Cannon.CannonCurrentSpeed, Cannon.Gravity);
		if(Cannon.CannonWheelBoatFireEvent != nullptr)
		{
			CannonData.AkComponent.HazePostEvent(Cannon.CannonWheelBoatFireEvent);
		}

		Cannon.CurrentCannonBallIndex++;
		if(Cannon.CurrentCannonBallIndex >= Cannon.CannonBallContainer.Num())
			Cannon.CurrentCannonBallIndex = 0;

		return CannonBall;
	}
};