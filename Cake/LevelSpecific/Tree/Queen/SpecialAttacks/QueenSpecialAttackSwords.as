import Vino.Camera.CameraStatics;
import Cake.LevelSpecific.Tree.Swarm.SwarmActor;
import Cake.LevelSpecific.Tree.Queen.QueenActor;
import Cake.LevelSpecific.Tree.Queen.SpecialAttacks.QueenSpecialAttackComponent;
import Cake.LevelSpecific.Tree.Queen.SpecialAttacks.Phase3RailSwordComponent;

class UQueenSpecialAttackSwords : UQueenSpecialAttackComponent
{
	// Queen P3 Capbility will switch shapes based on these values
	// (we keep them here so that the swarms can read from it)
	float ShapeDuration_Swords = 20.f;
	float ShapeDuration_Shields = 20.f;

	// 360 / numSwarms
	float DeltaAngleBetweenSwarms_Init = 90.f;

	// Delta Degrees between swarms == 360 / numSwords 
	float DeltaAngleBetweenSwarms_Sword = 120.f;

	// when the swords are vertical (only) 
	float RotationSpeed_SwordTelegraph = 50.f;

	// Speed used when we don't have any MasterShield, 
	// but we have other shields active. Rare case.
	float RotationSpeed_MasterlessShield = -30.f;

	// Settings
	//////////////////////////////////////////////////
	// Transient

	float TimeStampShapeDuration = 0.f;

	bool bIntroSwordsHaveBeenUnleashed = false;
	FTimerHandle TimerHandleResumeBossFight;
	bool bBossFightResumed = false;

	UPROPERTY()
	ASwarmActor RailSword1;

	UPROPERTY()
	ASwarmActor RailSword2;

	UPROPERTY()
	ASwarmActor RailSword4;

	UPROPERTY()
	AHazeActor FocusPoint;

	// this array should always have 4 spots. 
	// entries containing nullptr will indicate that the spot is free.
	// This ensures that assigned indices are preserved when swarms die.
	TArray<ASwarmActor> Swarms;
	default Swarms.SetNum(4);

	// the 4 swarms minus the master shields
	TArray<ASwarmActor> SlaveSwarms;
	default SlaveSwarms.SetNum(3);

	// Other swarms will be relative to this one
	ASwarmActor MasterShield;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Queen = Cast<AQueenActor>(Owner);
	}

	UFUNCTION()
	void StartIntroSwordAttack()
	{
		if(bIntroSwordsHaveBeenUnleashed)
			return;

		bIntroSwordsHaveBeenUnleashed = true;



		// !!! @TODO: we probably want to disable the parked swarms 
		// for performance reasons, once they are off screen.
		// Queen.ParkingSpotComp.SetParkingSpotsToWorldLoc(FVector::UpVector * 10000.f);
		// ParkAllSwarms(Queen);

		ActivateRailSword(RailSword1);
		ActivateRailSword(RailSword2);
		ActivateRailSword(RailSword4);

		PlayFoghornVOBankEvent(Queen.FoghornBank, n"FoghornDBBossFightThirdPhaseSwordWaspQueen", Queen);

		devEnsure(MasterShield != RailSword1, "RailSword1 became master shield upon activating");
		devEnsure(MasterShield != RailSword2, "RailSword2 became master shield upon activating");
		devEnsure(MasterShield != RailSword4, "RailSword4 became master shield upon activating");

		// this will ensure that the P3 capability doesn't change behaviour immediately
		TimeStampShapeDuration = Time::GetGameTimeSeconds();

		for (auto Player : Game::Players)
		{
			FLookatFocusPointData data;
			data.Actor = FocusPoint;
			data.Duration = 4.f;
			data.ShowLetterbox = false;
			data.FOV = 50;
			Player.LookAtFocusPoint(data);
		} 

		ResumeBossFight();
	}

	void ActivateRailSword(ASwarmActor InSwarm)
	{
		InSwarm.EnableActor(nullptr);

		// This will ensure that the swarmBuilder knows about the swarm
		Queen.BehaviourComp.RecruitSwarm(InSwarm);

		// Request TelegraphInit, otherwise they might attack immediately
		// (depends on what they have in their ShouldActivate())
		InSwarm.OverrideBehaviourState(ESwarmBehaviourState::TelegraphInitial);
	}

	void AddSwarm(ASwarmActor InSwarm)
	{

#if TEST
		// ensure that we have a vacant spot open
		TArray<ASwarmActor> CleanedArray = Swarms;
		CleanedArray.RemoveAll(nullptr);
		devEnsure(CleanedArray.Num() != Swarms.Num(), "Queen P3 isn't networked properly. We are trying to add a swarm to a list which is full.. \n please notify Sydney about this" );
		ensure(CleanedArray.Num() < 4);
#endif

		auto RailSwordSwarmComp = UPhase3RailSwordComponent::GetOrCreate(InSwarm);

		// occupy vacant slots 
		for(int i = 0; i < Swarms.Num(); ++i)
		{
			if(Swarms[i] == nullptr)
			{
				Swarms[i] = InSwarm;
				RailSwordSwarmComp.CurrentAngle = i * DeltaAngleBetweenSwarms_Init;
				RailSwordSwarmComp.AssignedIndex = i;
				break;
			}
		}

		if(InSwarm != MasterShield)
		{
			for (int i = 0; i < SlaveSwarms.Num(); ++i)
			{
				if (SlaveSwarms[i] == nullptr)
				{
					SlaveSwarms[i] = InSwarm;
					break;
				}
			}
		}

	}

	UFUNCTION()
	void ResumeBossFight()
	{
		if(bBossFightResumed)
			return;

		//PrintScaled("Resuming Boss fight", Duration = 3.f, Scale = 3.f);

		bBossFightResumed = true;

		System::ClearAndInvalidateTimerHandle(TimerHandleResumeBossFight);

		UnparkAllSwarms(Queen);
		Queen.ResumeBossSpawning();
		Queen.PopP3IntroSettings();
	}

	float CalculateSlaveAngle_Sword(ASwarmActor InSwarm) const
	{
		return CalculateSlaveAngle(
			InSwarm, 
			RotationSpeed_SwordTelegraph,
			DeltaAngleBetweenSwarms_Sword
		);
	}

	float CalculateSlaveAngle_Shield(ASwarmActor InSwarm) const
	{
		return CalculateSlaveAngle(
			InSwarm, 
			RotationSpeed_MasterlessShield,
			DeltaAngleBetweenSwarms_Shield
		);
	}

	float CalculateSlaveAngle(
		const ASwarmActor InSwarm,
		const float InRotationSpeed,
		const float InDeltaAngleBetween_DEG
	) const
	{
		const int Idx = SlaveSwarms.FindIndex(InSwarm);
		devEnsure(SlaveSwarms.IsValidIndex(Idx), "SlaveSwarm could not be found when calculating angle.. \n please notify Sydney about this" );

		// Base rotation offset
		float DesiredAngle = Idx * InDeltaAngleBetween_DEG;

		// PrintToScreen(Owner.GetName() + " [" + Idx + "]" + " >>>>>>> DesiredAngle: " +  DesiredAngle);

		if (InRotationSpeed != 0.f)
		{
			const float DeltaAngleFromSpeed = Time::GetGameTimeSeconds() * InRotationSpeed;
			DesiredAngle += DeltaAngleFromSpeed;
		}

		DesiredAngle = FMath::UnwindDegrees(DesiredAngle);
		DesiredAngle = FRotator::ClampAxis(DesiredAngle);

		// PrintToScreen(Owner.GetName() + " [" + Idx + "]" + " >>>>>>> CurrentAngle: " +  DesiredAngle);

		return DesiredAngle;
	}

	float CalculateShieldFormation_Row(ASwarmActor InShield) const
	{
		if(MasterShield == nullptr)
		{
			// This should always be valid. Things are being 
			// triggered in the wrong order if this fires
			devEnsure(false, "trying to calculate swarm formation with masterShield. Things are being triggered in the wrong order.. \n please notify Sydney about this" );
			return 0.f;
		}

		const int ShieldIdx = Swarms.FindIndex(InShield);
		const int MasterShieldIdx = Swarms.FindIndex(MasterShield);

		// This should always be valid. Things are being 
		// triggered in the wrong order if this fires
		devEnsure(MasterShieldIdx != -1, "MasterShield was not part of the swarms when calculating row formation... Things are being triggered in the wrong order.. \n please notify Sydney about this" );

		float DesiredAngle = 0.f;
		if(Swarms.IsValidIndex(MasterShieldIdx))
		{
			const auto MasterShieldSwarm = Swarms[MasterShieldIdx]; 
			const auto MasterShieldComp = UPhase3RailSwordComponent::Get(MasterShieldSwarm);
			DesiredAngle = MasterShieldComp.CurrentAngle;
		}

		const float DeltaIndexSteps = ShieldIdx - MasterShieldIdx;
		DesiredAngle += (DeltaIndexSteps * DeltaAngleBetweenSwarms_Shield);

		return DesiredAngle;
	}

	// float DeltaAngleBetweenSwarms_Shield = 15.f;
	// float DeltaAngleBetweenSwarms_Shield = 10.f;
	float DeltaAngleBetweenSwarms_Shield = 50.f;

	void CalculateShieldFormation_Star(
		ASwarmActor InShield,
		float& OutAngle,
		float& OutOffsetX,
		float& OutOffsetZ
	)
	{
		const int ShieldIdx = Swarms.FindIndex(InShield);
		const int MasterShieldIdx = Swarms.FindIndex(MasterShield);

		// This should always be valid. Things are being 
		// triggered in the wrong order if this fires
		devEnsure(MasterShieldIdx != -1, "MasterShield was not part of the swarms when calculating star formation... Things are being triggered in the wrong order.. \n please notify Sydney about this" );

		// we want to ensure that mastershield has index = 0 
		// and that the rest are relative to that.
		int AssignedSlot = ShieldIdx - MasterShieldIdx;

		const auto MasterShieldComp = UPhase3RailSwordComponent::Get(MasterShield);
		OutAngle = MasterShieldComp.CurrentAngle;

		// wrap it
		if (AssignedSlot <= 0)
			AssignedSlot = Swarms.Num() + AssignedSlot;

		// PrintToScreen("AssignedSlots" + AssignedSlot);

		if (AssignedSlot == 1)
		{
			OutOffsetX = -200.f;
			// OutOffsetZ = 350.f;
			OutOffsetZ = 100.f;
			OutAngle += DeltaAngleBetweenSwarms_Shield;
		}
		else if(AssignedSlot == 2)
		{
			OutOffsetX = -200.f;
			// OutOffsetZ = 350.f;
			OutOffsetZ = 100.f;
			OutAngle -= DeltaAngleBetweenSwarms_Shield;
		}
		else if(AssignedSlot == 3)
		{
			OutOffsetX = -300.f;
			OutOffsetZ = 700.f;
			// OutOffsetZ = 300.f;
		}
		else
		{
			// shouldn't get here.
			ensure(false);
		}
	}

	void RemoveSwarm(ASwarmActor InSwarm)
	{
		const auto Idx = Swarms.FindIndex(InSwarm);

		if(Idx == -1)
		{
			// they should always be in the array.. 
			// was the request deferred somehow?
			devEnsure(false, "Queen P3 isn't networked properly. Couldn't find Swarm to remove. \n please notify Sydney about this" );
			return;
		}

		Swarms[Idx] = nullptr;

		if (MasterShield == InSwarm)
		{
			MasterShield = nullptr;
		}
		else
		{
			const auto SlaveIdx = SlaveSwarms.FindIndex(InSwarm);

			if(SlaveIdx == -1)
			{
				devEnsure(false, "Queen P3 isn't networked properly. Couldn't find _SlaveSwarm_ to remove. \n please notify Sydney about this" );
				return;
			}

			SlaveSwarms[SlaveIdx] = nullptr;
		}

	}

	void UpdateDesiredAngles()
	{
		for (ASwarmActor SwarmIter : Swarms)
		{
			if(SwarmIter == nullptr)
				continue;

			if (MasterShield == SwarmIter)
				UpdateDesiredAngle_MasterShield(SwarmIter);
			else
				UpdateDesiredAngle_Slave(SwarmIter);
		}
	}

	void UpdateDesiredAngle_Slave(ASwarmActor InSwarm) 
	{
		if (InSwarm.IsShape(ESwarmShape::RailSword))
		{
			UpdateDesiredAngle_RailSword(InSwarm);
		}
		else if (InSwarm.IsShape(ESwarmShape::Shield))
		{
			UpdateDesiredAngle_Shield(InSwarm);
		}
		else
		{
			// we should never reach here
			ensure(false);
		}
	}

	void UpdateDesiredAngle_MasterShield(ASwarmActor InSwarm) 
	{
		// Cody fell off..
		if(InSwarm.VictimComp.PlayerVictim == nullptr)
			return;

		FVector PlayerPos = InSwarm.VictimComp.PlayerVictim.GetActorLocation();
		FVector ToPlayer = PlayerPos - InSwarm.GetActorLocation();
		ToPlayer = ToPlayer.VectorPlaneProject(FVector::UpVector);
		ToPlayer.Normalize();

		const float AngleDot_Forward = ToPlayer.DotProduct(FVector::ForwardVector);
		const float AngleForward_Rad = FMath::Acos(AngleDot_Forward);
		float AngleForward_Deg = FMath::RadiansToDegrees(AngleForward_Rad);

		// converto [0, 180] to [0, 360]
		const float AngleDot_Right = ToPlayer.DotProduct(FVector::RightVector);
		if(AngleDot_Right < 0.f)
			AngleForward_Deg = 360.f - AngleForward_Deg;

		////
		// Player grinding speed decides how fast they rotate
		////

		UPhase3RailSwordComponent ManagedSwarmComp = UPhase3RailSwordComponent::GetOrCreate(InSwarm);
		ManagedSwarmComp.CurrentAngle = AngleForward_Deg;
	}

	void UpdateDesiredAngle_Shield(ASwarmActor InSwarm) 
	{
		UPhase3RailSwordComponent ManagedSwarmComp = UPhase3RailSwordComponent::GetOrCreate(InSwarm);

		float DesiredAngle = 0.f;
		float DesiredOffsetX = 0.f;
		float DesiredOffsetZ = 0.f;

		if (MasterShield != nullptr)
		{
			// they'll be relative to the Mastershields speed, 
			// which is relative to the player grind speed.
			// DesiredAngle = Manager.CalculateShieldFormation_Row(InSwarm);

			CalculateShieldFormation_Star(
				InSwarm,
				DesiredAngle,
				DesiredOffsetX,
				DesiredOffsetZ
			);
		}
		else
		{
			// rare case of when we don't have a MasterShield, but we have other Shields. 
			// They will momentarily use this, until a MasterShield is assigned next tick
			DesiredAngle = CalculateSlaveAngle_Shield(InSwarm);
		}

		ManagedSwarmComp.CurrentAngle = DesiredAngle;
		ManagedSwarmComp.DesiredOffsetX= DesiredOffsetX;
		ManagedSwarmComp.DesiredOffsetZ= DesiredOffsetZ;
	}

	void UpdateDesiredAngle_RailSword(ASwarmActor InSwarm) 
	{
		UPhase3RailSwordComponent ManagedSwarmComp = UPhase3RailSwordComponent::GetOrCreate(InSwarm);
		ManagedSwarmComp.CurrentAngle = CalculateSlaveAngle_Sword(InSwarm);
	}

	void AssignMasterShield() 
	{
		for (ASwarmActor SwarmIter : Swarms)
		{
			if(SwarmIter == nullptr)
				continue;

			// don't steal an ongoing rail sword attack
			if (!SwarmIter.IsShape(ESwarmShape::Shield))
				continue;

			// ignore intro swarms until they are done
			UPhase3RailSwordComponent ManagedSwarmComp = UPhase3RailSwordComponent::GetOrCreate(SwarmIter);
			if(ManagedSwarmComp.bIntroSwarm)
				continue;

			NetAssignMasterShield(SwarmIter);

			break;
		}
	}

	UFUNCTION(NetFunction)
	void NetAssignMasterShield(ASwarmActor InSwarm)
	{
		MasterShield = InSwarm;
		InSwarm.VictimComp.OverrideClosestPlayer(Game::GetCody(), this);

		// Only remove from slaves array
		const auto SlaveIdx = SlaveSwarms.FindIndex(InSwarm);

		if(SlaveIdx != -1)
			SlaveSwarms[SlaveIdx] = nullptr;
		else
			devEnsure(false, "MasterShield candidate was not found among slave swarms. Network desync. \n Please notify Sydney");
	}

	void AssignVictimForMasterShield()
	{
		// We want the master shield to always block cody (when possible)
		AHazePlayerCharacter NewVictim = Game::GetCody();
		auto NewVictimHPComp = UPlayerHealthComponent::Get(NewVictim); 

		if (NewVictimHPComp.bIsDead)
		{
			NewVictim = Game::GetMay();
			NewVictimHPComp = UPlayerHealthComponent::Get(NewVictim); 
			if (NewVictimHPComp.bIsDead)
			{
				// Both are dead
				return;
			}
		}

		// both are falling?
		if(NewVictim == nullptr)
			return;

		// we already have that victim assigned
		if(NewVictim == MasterShield.VictimComp.PlayerVictim)
			return;

		// this will be picked up by a capability which will network sync the result
		MasterShield.VictimComp.OverrideClosestPlayer(NewVictim, this);
	}

}