import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.OctopusBoss.PirateOctopusActor;
import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.OctopusBoss.PirateOctopusJab;
import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.OctopusBoss.PirateOctopusThirdSequence;
import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.OctopusBoss.PirateOctopusThirdArmSlamLocation;

struct FPendingThirdSequenceArmData
{
	APirateOctopusThirdSequenceSlam Arm;
	int PositionIndex = 0;
	float DelayLeft = 0;
}

class UPirateOctopusThirdSequenceCapability : UHazeCapability
{
    default CapabilityTags.Add(n"PirateOctopus");
	default CapabilityTags.Add(n"PirateOctopusThirdSequence");

    default TickGroup = ECapabilityTickGroups::LastMovement;

	APirateOctopusActor Octopus;
	APirateOctopusJab JabArm;
	APirateOctopusArm StreamArm;
	UPirateOctopusThirdSequenceComponent ThirdSequenceComp;

	const int MaxAmountOfActiveArms = 5; // Must be uneven
	const FHazeMinMax StartAttackDelay = FHazeMinMax(3.5f, 4.5f);
	// const FHazeMinMax PhaseOneTimer = FHazeMinMax(25.0f, 27.0f);
	const FHazeMinMax HitPlayerCoolDownDuration = FHazeMinMax(5.0f, 8.f);
	const FHazeMinMax SpawnOffsetDistance =  FHazeMinMax(2500.f, 4000.f);

	const FHazeMinMax SpawnAngleOffsetForward = FHazeMinMax(-45.f, 45.f);
	const FHazeMinMax SpawnAngleOffsetLeft = FHazeMinMax(-90, -25);
	const FHazeMinMax SpawnAngleOffsetRight = FHazeMinMax(25, 90);
	const FHazeMinMax SpawnAngleOffsetBack = FHazeMinMax(-45.f, 45.f);

	const int MinAmountOfWallsSpawnedBeforeJabIsSpawned = 3;

	const float ArmDelay = 0.8f;

	float AttackTimer = 0.0f;
	float CoolDownTimer = 0.0f;
	float TotalDelay = 0;

	TArray<FPendingThirdSequenceArmData> PendingArms;
	FPendingThirdSequenceArmData PendingArmData;
	int NotSpawnedJabArms = 0;
	bool bActivatedArtillerySpawners = false;

	int SpawnedArms;

	int JabWaitCount;

	int PhaseThreeMaxHit = 10;

	float MinimumSpawnDistance = 3200.f;
	float MaxActiveDistance = 10000.f;

	bool bBossSubmerged;

	float InvulnerableTimer;
	float DefaultInvulnerableTimer = 3.5f;

	bool bCanInvulnerableTimer;

    UFUNCTION(BlueprintOverride)
    void Setup(FCapabilitySetupParams Params)
    {
		Octopus = Cast<APirateOctopusActor>(Owner);
		ThirdSequenceComp = UPirateOctopusThirdSequenceComponent::Get(Octopus);
		ThirdSequenceComp.Initialize(Octopus, MaxAmountOfActiveArms);
		Octopus.SetSpawnersActive(false, this);
		Octopus.OnThirdPhaseAllArmsKilled.AddUFunction(this, n"ActivatePhaseOne");
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkActivation ShouldActivate() const
    {
		if(!Octopus.bActivated)
			return EHazeNetworkActivation::DontActivate;

		if(Octopus.CurrentAttackSequence != 3)
            return EHazeNetworkActivation::DontActivate;

		if(Octopus.bParticipatingInCutscene)
            return EHazeNetworkActivation::DontActivate;
					
		// if(Octopus.TryingToActiveNextAttackSequence())
        //     return EHazeNetworkActivation::DontActivate;
			
    	return EHazeNetworkActivation::ActivateLocal;
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkDeactivation ShouldDeactivate() const
    {
		if(!Octopus.bActivated)
			 return EHazeNetworkDeactivation::DeactivateLocal;

		if(Octopus.CurrentAttackSequence != 3)
            return EHazeNetworkDeactivation::DeactivateLocal;

		if(Octopus.bParticipatingInCutscene)
            return EHazeNetworkDeactivation::DeactivateLocal;		
					
		// if(Octopus.TryingToActiveNextAttackSequence())
        //     return EHazeNetworkDeactivation::DeactivateLocal;				

        return EHazeNetworkDeactivation::DontDeactivate;
    }

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		TotalDelay = StartAttackDelay.GetRandomValue();
		Octopus.bLastAttackHitPlayer = false;
		Octopus.WheelBoat.TurnSpeedMultiplier = 3.25f;
		Octopus.WheelBoat.MoveSpeedMultiplier = 4.f;
		JabWaitCount = FMath::RandRange(2, 3);
		// CurrentPhaseOneTimer = PhaseOneTimer.GetRandomValue();
		Octopus.ResetSlamPhaseThreeKillCount();
		Octopus.PhaseThreeHitCounter = 0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Octopus.WheelBoat.TurnSpeedMultiplier = 1.f;
		Octopus.WheelBoat.MoveSpeedMultiplier = 1.f;
		Octopus.WheelBoat.AvoidPoint.Clear();

		if(bActivatedArtillerySpawners)
		{
			bActivatedArtillerySpawners = false;
			Octopus.SetSpawnersActive(false, this);
		}
	}	
	
    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
		Octopus.WheelBoat.AvoidPoint.Setup(Octopus.GetActorLocation(), 6000.f, 1000.f, 4000.f, 3.f);

		if(HasControl())
		{
			if (Octopus.WheelBoat.bIsAirborne)
				return;

			switch (ThirdSequenceComp.OctopusThirdPhaseState)
			{
				case EOctopusThirdPhaseState::PhaseOne: PhaseOneBehaviour(DeltaTime); ArtillerySpawn(); break;
				case EOctopusThirdPhaseState::PhaseTwo: PhaseTwoBehaviour(DeltaTime); break;
			}
		}
	}

	void PhaseOneBehaviour(float DeltaTime)
	{
		Octopus.ResetSlamPhaseThreeKillCount();

		if (bBossSubmerged)
		{
			EmergeBoss();
		}

		if(!Octopus.bSpawnedQuickJabArm)
		{
			NetActivateQuickJabArm();
			Octopus.bSpawnedQuickJabArm = true;
		}

		if (bCanInvulnerableTimer)
		{
			InvulnerableTimer -= DeltaTime;

			if (InvulnerableTimer <= 0.f)
			{
				BossInvulnerable(false);
				bCanInvulnerableTimer = false;
			}
		}

		if (Octopus.PhaseThreeHitCounter >= PhaseThreeMaxHit)
		{
			ActivatePhaseTwo();
		}
	}

	void PhaseTwoBehaviour(float DeltaTime)
	{
		if (!bBossSubmerged)
			SubmergeBoss();
		
		if(SpawnedArms < Octopus.MaxSlamPhaseThreeKillCount)
		{
			AttackTimer += DeltaTime;

			if(AttackTimer >= TotalDelay)
			{
				PrepareAttack();
				AttackTimer = 0;
				TotalDelay = StartAttackDelay.GetRandomValue();
			}
		}

		for(int i = PendingArms.Num() - 1; i >= 0; --i)
		{
			PendingArms[i].DelayLeft -= DeltaTime;
			if(PendingArms[i].DelayLeft <= 0)
			{
				TriggerDelayActivation(i);
				PendingArms.RemoveAtSwap(i);
			}
		}	
	}

	UFUNCTION()
	void ActivatePhaseOne()
	{
		ThirdSequenceComp.OctopusThirdPhaseState = EOctopusThirdPhaseState::PhaseOne;
		Octopus.ResetSlamPhaseThreeKillCount();
		Octopus.bSpawnedQuickJabArm = false;
		InvulnerableTimer = DefaultInvulnerableTimer;
		bCanInvulnerableTimer = true;
		Octopus.PhaseThreeHitCounter = 0;
	}

	UFUNCTION()
	void ActivatePhaseTwo()
	{
		ThirdSequenceComp.OctopusThirdPhaseState = EOctopusThirdPhaseState::PhaseTwo;
		TotalDelay = StartAttackDelay.GetRandomValue();
		AttackTimer = TotalDelay;
		SpawnedArms = 0;
	}

	UFUNCTION(NetFunction)
	void SubmergeBoss()
	{
		bBossSubmerged = true;
		Octopus.SubmergeBoss();
		BossInvulnerable(true);
	}

	UFUNCTION(NetFunction)
	void EmergeBoss()
	{
		bBossSubmerged = false;
		Octopus.EmergeBoss();
	}

	UFUNCTION(NetFunction)
	void BossInvulnerable(bool bIsInvulnerable)
	{
		if (bIsInvulnerable)
			Octopus.CannonBallDamageableComponent.DisableDamageTaking();
		else
			Octopus.CannonBallDamageableComponent.EnableDamageTaking();
	}

	void ArtillerySpawn()
	{
		if(!bActivatedArtillerySpawners && GetActiveDuration() > 1.f)
		{
			bActivatedArtillerySpawners = true;
			Octopus.SetSpawnersActive(true, this);
		}
	}

	void PrepareAttack()
	{
		const FVector SpawnLocation = GetSpawnArmLocation();

		CheckCurrentActiveSlams();
		NetActivateSlam(GetClosestInactiveLocation());
		SpawnedArms++;
	}

	UFUNCTION(NetFunction)
	void NetActivateQuickJabArm()
	{
		Octopus.CurrentFirstAttackMode = EPirateOctopusFirstAttackMode::Jab;
		JabArm = Cast<APirateOctopusJab>(Octopus.ArmsContainerComponent.GetArm(Octopus.JabArmType));
		JabArm.bSkipAnticipation = true;
		JabArm.SetArmPosition(PositionedLeft = true);
		JabArm.ActivateArm();		
		JabArm.FollowBoatComponent.bFollowBoat = false;
		Octopus.OnPirateOctopusArmSpawned.Broadcast(JabArm);
	}

	UFUNCTION(NetFunction)
	void NetActivateJabArm(FVector WorldPosition)
	{
		Octopus.CurrentFirstAttackMode = EPirateOctopusFirstAttackMode::Jab;
		JabArm = Cast<APirateOctopusJab>(Octopus.ArmsContainerComponent.GetArm(Octopus.JabArmType));
		JabArm.bSkipAnticipation = true;
		JabArm.SetArmPosition(WorldPosition);
		JabArm.ActivateArm();	
		JabArm.FollowBoatComponent.bFollowBoat = false;
		Octopus.OnPirateOctopusArmSpawned.Broadcast(JabArm);
	}

	UFUNCTION(NetFunction)
	void NetActivateArmWall(int PositionIndex)
	{	
		Octopus.CurrentFirstAttackMode = EPirateOctopusFirstAttackMode::Slam;
		PendingArms.SetNum(MaxAmountOfActiveArms);

		float OffsetDir = 1.f;
		int OffsetAmount = 1;
		InsertPendingArm(0, PositionIndex);

		for(int i = 1; i < MaxAmountOfActiveArms; ++i)
		{
			int NextIndex = ThirdSequenceComp.GetNextPointIndex(PositionIndex, OffsetAmount * OffsetDir * 3);

			// Get left, right flipped every next itteration
			OffsetDir = -OffsetDir;

			// Increase the offset every other
			if(OffsetDir > 0)
				OffsetAmount++;

			InsertPendingArm(i, NextIndex);
		}
	}

	// UFUNCTION(NetFunction)
	// void NetActivateStreamArm()
	// {
	// 	Octopus.CurrentFirstAttackMode = EPirateOctopusFirstAttackMode::StreamArm;
	// 	StreamArm = Octopus.ArmsContainerComponent.GetArm(Octopus.StreamArmType);
	// 	StreamArm.SetArmPosition(true);
	// 	StreamArm.ActivateArm();
	// 	Octopus.OnPirateOctopusArmSpawned.Broadcast(StreamArm);
	// }

	UFUNCTION(NetFunction)
	void NetActivateSlam(APirateOctopusThirdArmSlamLocation SlamLoc)
	{	
		if(SlamLoc == nullptr)
		{
			Print("SLAM LOC IS NULLPTR");
			return;
		}
		
		Octopus.CurrentFirstAttackMode = EPirateOctopusFirstAttackMode::Slam;
		APirateOctopusArm Arm = Octopus.GetPhaseThreeArm();
		APirateOctopusSlam SlamArm = Cast<APirateOctopusSlam>(Arm);
		
		SlamArm.FollowBoatComponent.bFaceBoat = true;
		SlamArm.Boss = Octopus;	
		SlamArm.ChosenLoc = SlamLoc;
		SlamArm.SetActorLocation(SlamLoc.ActorLocation);

		if(SlamLoc.bIsActive)
			return;
	
		SlamLoc.bIsActive = true;
		SlamArm.bIsRepeatableSlam = true;
		SlamArm.ActivateArm();	
		SlamArm.FollowBoatComponent.bFollowBoat = false;
		Octopus.OnPirateOctopusArmSpawned.Broadcast(SlamArm);
	}

	UFUNCTION(NetFunction)
	void CheckCurrentActiveSlams()
	{
		TArray<APirateOctopusSlam> SlamArray;

		GetAllActorsOfClass(SlamArray);

		float FurthestDistance = 0.f;
		APirateOctopusSlam ChosenSlam;

		for (APirateOctopusSlam Slam : SlamArray)
		{
			float Distance = (Slam.ActorLocation - Octopus.WheelBoat.ActorLocation).Size();

			if (Distance >= MaxActiveDistance)
			{
				if (Distance > FurthestDistance)
				{
					FurthestDistance = Distance;
					ChosenSlam = Slam;
				}
			}
		}

		// if (ChosenSlam != nullptr)
		// 	ChosenSlam.FinishAttack();
	}

	void InsertPendingArm(int ArrayIndex, int PositionIndex)
	{
		FPendingThirdSequenceArmData& Data = PendingArms[ArrayIndex];

		Data.Arm = Cast<APirateOctopusThirdSequenceSlam>(Octopus.ArmsContainerComponent.GetArm(Octopus.ThirdSequenceSlamArmType));
		Data.Arm.CurrentArmPositionIndexOffsetAlpha = 0;
		Data.Arm.FollowBoatComponent.bFollowBoat = false;
		Data.Arm.FollowBoatComponent.bFaceBoat = false;
		Data.PositionIndex = PositionIndex;
		Data.DelayLeft = ArrayIndex * ArmDelay;
	}

	void TriggerDelayActivation(int Index)
	{
		ThirdSequenceComp.SetArmAtPosition(PendingArms[Index].PositionIndex, PendingArms[Index].Arm);
		PendingArms[Index].Arm.ActivateArm();
		Octopus.OnPirateOctopusArmSpawned.Broadcast(PendingArms[Index].Arm);
	}

	FVector GetSpawnArmLocation()const
	{
		const FVector BoatLocation = Octopus.WheelBoat.ActorLocation;
		const FVector OctopusLocation = Octopus.ActorLocation;
		const float DistanceToBoss = OctopusLocation.Dist2D(BoatLocation, FVector::UpVector);
		FRotator DirToBoss = (OctopusLocation - BoatLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal().ToOrientationRotator();
		const float FaceAmount = Octopus.WheelBoat.ActorForwardVector.DotProduct(DirToBoss.ForwardVector);
		const float SideAmount = Octopus.WheelBoat.ActorForwardVector.DotProduct(DirToBoss.RightVector);

		// 0 forward,
		// 1 left
		// 2 right
		// 3 back
		int CreationType = 0;
		
		FVector FinalLocation = BoatLocation;

		if(DistanceToBoss < SpawnOffsetDistance.MaxValue + 1000.f)
		{
			// In front
			if(FaceAmount >= 0.f)
			{
				if(SideAmount >= 0)
					CreationType = 2;
				else
					CreationType = 1;
			}
			// Behind
			else 
			{
				if(FaceAmount < -0.7f)
				{
					CreationType = FMath::RandRange(0, 2);
				}
				else if(SideAmount >= 0)
				{
					if(FMath::RandBool())
						CreationType = 0;
					else
						CreationType = 2;
				}
				else
				{
					if(FMath::RandBool())
						CreationType = 0;
					else
						CreationType = 1;
				}	
			}			
		}
		else
		{
			// Facing outside wall
			if(FaceAmount < -0.8f)
			{
				CreationType = 3;
			}
			else if(FaceAmount > 0.6f)
			{
				CreationType = FMath::RandRange(0, 2);
			}
			// Facing boss
			else if(FaceAmount < 0.2f)
			{
				if(SideAmount >= 0)
				{
					CreationType = 1;		
				}
				else
				{
					CreationType = 2;
				}
			}
			else 
			{
				if(SideAmount >= 0)
				{
					if(FMath::RandBool())
						CreationType = 0;
					else
						CreationType = 1;
				}
				else
				{
					if(FMath::RandBool())
						CreationType = 0;
					else
						CreationType = 2;
				}
			}		
		}

		// Create the spawn offset
		FRotator SpawnRotation = Octopus.WheelBoat.GetActorRotation();

		// forward
		if(CreationType == 0)
		{
			SpawnRotation.Yaw += SpawnAngleOffsetForward.GetRandomValue();
		}
		// left
		else if(CreationType == 1)
		{
			SpawnRotation.Yaw += SpawnAngleOffsetLeft.GetRandomValue();
		}
		// right
		else if(CreationType == 2)
		{
			SpawnRotation.Yaw += SpawnAngleOffsetRight.GetRandomValue();
		}
		// back
		else if(CreationType == 3)
		{
			const FHazeMinMax SpawnOffsetAngle(-180 + SpawnAngleOffsetBack.Min, -180 + SpawnAngleOffsetBack.Max);
			SpawnRotation.Yaw += SpawnOffsetAngle.GetRandomValue();
		}

		FinalLocation += SpawnRotation.GetForwardVector() * SpawnOffsetDistance.GetRandomValue();

		return FinalLocation;
	}

	APirateOctopusThirdArmSlamLocation GetClosestInactiveLocation()
	{
		float ClosestDistance = BIG_NUMBER;

		APirateOctopusThirdArmSlamLocation ClosestLoc;

		for (APirateOctopusThirdArmSlamLocation SlamLoc : Octopus.ArmSlamLocsThirdPhaseArray)
		{
			float Distance = (Octopus.WheelBoat.ActorLocation - SlamLoc.ActorLocation).Size();
			Distance = FMath::Abs(Distance);

			if (Distance < ClosestDistance && Distance > MinimumSpawnDistance && !SlamLoc.bIsActive)
			{
				ClosestDistance = Distance;
				ClosestLoc = SlamLoc;
			}
		}
		return ClosestLoc;
	}
}
