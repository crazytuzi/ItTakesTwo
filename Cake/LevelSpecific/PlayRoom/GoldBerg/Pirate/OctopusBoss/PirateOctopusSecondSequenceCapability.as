import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.OctopusBoss.PirateOctopusActor;
import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.OctopusBoss.PirateOctopusSecondSequence;


class UPirateOctopusSecondSequenceCapability : UHazeCapability
{
    default CapabilityTags.Add(n"PirateOctopus");

    default TickGroup = ECapabilityTickGroups::LastMovement;

	APirateOctopusActor Octopus;
	UPirateOctopusSecondSequenceComponent SecondSequenceComp;

	const int TotalNumberOfArms = 6;
	const float StartAttackDelay = 2.5f;
	const float SpawnDelay = 2.5f;
	const float TotalAttackDelay = 1.0f;
	const float FirstAttackDelay = 1.5f;

	int MaxAmountOfActiveArms = 3;
	int LastPointIndex = -1;
	float CurrentSpawnDelay = 0.f;
	float CurrentAttackDelay = 0.f;
	int NumberOfArmsSpawned = 0;

	const float CanonOffsetAmount = 16.f;
	const float SpeedMultiplier = 1.25f;

	TArray<int> FreeIndices;
	TArray<APirateOctopusArmSecondSequence> ActiveSecondSequenceArms;
	TArray<int> PendingArmsActivationIndices;

	bool bAwatingFullSyncPoint = false;
	
    UFUNCTION(BlueprintOverride)
    void Setup(FCapabilitySetupParams Params)
    {
		Octopus = Cast<APirateOctopusActor>(Owner);
		SecondSequenceComp = UPirateOctopusSecondSequenceComponent::Get(Octopus);
		SecondSequenceComp.Initialize(Octopus, TotalNumberOfArms, TotalNumberOfArms);
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkActivation ShouldActivate() const
    {
		if(!Octopus.bActivated)
			return EHazeNetworkActivation::DontActivate;

		if(Octopus.CurrentAttackSequence != 2)
            return EHazeNetworkActivation::DontActivate;

		if(Octopus.bParticipatingInCutscene)
            return EHazeNetworkActivation::DontActivate;
						
		if(!HasControl() && FreeIndices.Num() <= 0)
			return EHazeNetworkActivation::DontActivate;
			
    	return EHazeNetworkActivation::ActivateLocal;
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkDeactivation ShouldDeactivate() const
    {
		if(!Octopus.bActivated)
			 return EHazeNetworkDeactivation::DeactivateLocal;

		if(Octopus.CurrentAttackSequence != 2)
            return EHazeNetworkDeactivation::DeactivateLocal;

		if(Octopus.bParticipatingInCutscene)
            return EHazeNetworkDeactivation::DeactivateLocal;		
						

        return EHazeNetworkDeactivation::DontDeactivate;
    }

	bool AllArmsHaveBeenSpawned() const
	{
		return NumberOfArmsSpawned >= TotalNumberOfArms;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		CurrentSpawnDelay = StartAttackDelay;
		CurrentAttackDelay = FirstAttackDelay;

		SetCanonVariables(Octopus.WheelBoat.RightCannon, true);
		SetCanonVariables(Octopus.WheelBoat.LeftCannon, true);
	
		if(HasControl())
		{
			for(int i = 1; i < SecondSequenceComp.Points.Num(); ++i)
				FreeIndices.Add(i);

			FreeIndices.Insert(0, 0);

			NetSetFreeIndices(FreeIndices);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SetCanonVariables(Octopus.WheelBoat.RightCannon, false);
		SetCanonVariables(Octopus.WheelBoat.LeftCannon, false);
		LastPointIndex = -1;
		bAwatingFullSyncPoint = false;
	}

	void SetCanonVariables(AToyCannonActor Canon, bool bStatus)
	{
		if(bStatus)
		{
			Canon.SetWaveActor(Octopus.BossWavesActor);
			Canon.SavedRotation = Canon.CannonShootFromPoint.GetRelativeRotation();
			Canon.CannonShootFromPoint.AddRelativeRotation(FRotator(CanonOffsetAmount, 0.f, 0.f));
			Canon.CanonSpeedMultiplier = SpeedMultiplier;
		}
		else
		{
			Canon.SetWaveActor(nullptr);
			Canon.CannonShootFromPoint.SetRelativeRotation(Canon.SavedRotation);
			Canon.CanonSpeedMultiplier = 1.f;
		}
	}

	UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
		UpdateArmSpawning(DeltaTime);
		UpdateAttack(DeltaTime);
		
		if(AllArmsHaveBeenSpawned() 
			&& Octopus.GetActiveArmsCount() == 0
			&& !bAwatingFullSyncPoint
			&& !Octopus.WheelBoat.bIsDying
			&& !Octopus.WheelBoat.bDead)
		{
			bAwatingFullSyncPoint = true;
			Sync::FullSyncPoint(Octopus, n"InitalizeThirdAttackSequence");
		}
	}

	void UpdateArmSpawning(float DeltaTime)
	{
		if(AllArmsHaveBeenSpawned())
			return;

		CurrentSpawnDelay -= DeltaTime;
		if(CurrentSpawnDelay > 0)
			return;

		// you messed up if this happens
		ensure(FreeIndices.Num() > 0);

		//const FTransform BoatTransform = Octopus.WheelBoat.GetActorTransform();
		int FoundIndex = FreeIndices[0];
		FreeIndices.RemoveAt(0);
		APirateOctopusArmSecondSequence CurrentArm = Octopus.ActivateSecondSequenceArm(GetSlamPosition(FoundIndex));
		ActiveSecondSequenceArms.Add(CurrentArm);
		CreateBombDuck(FoundIndex);
		CurrentSpawnDelay += SpawnDelay;

		if(AllArmsHaveBeenSpawned())
		{
			float TimerLength = Octopus.PirateOctopusArmsSecondSequenceArray[0].PopUpAnim.PlayLength;
			System::SetTimer(Octopus, n"DeactivateAllSecondSequenceArm", TimerLength, false);
		}
	}

	void UpdateAttack(float DeltaTime)
	{
		if(PendingArmsActivationIndices.Num() == 0)
			return;
		
		CurrentAttackDelay -= DeltaTime;
		if(CurrentAttackDelay > 0)
			return;
		
		const int ArmIndex = PendingArmsActivationIndices[0];
		auto BombDuck = Cast<APirateOctopusSecondSequenceSlamArm>(SecondSequenceComp.Points[ArmIndex].CurrentArm);
		BombDuck.StartMoving();
		Sync::FullSyncPoint(BombDuck.CannonBallDamageableComponent, n"EnableDamageTaking");
		PendingArmsActivationIndices.RemoveAt(0);
		CurrentAttackDelay += TotalAttackDelay;
	}

	// UFUNCTION()
	// void ActivateCreateSlam(int Index)
	// {
	// 	// if(NumberOfArmsSpawned == 0)
	// 	// 	CreateSlam(LastPointIndex);
	// 	// else
	// 	// 	CreateSlam(SecondSequenceComp.GetNextPointIndex(LastPointIndex));

		
	// 	//Add slam to an array for disabling in correct order

	// 	if(AllArmsHaveBeenSpawned())
	// 	{
	// 		//bCanTimer = false;
	// 		CurrentDelay += StartAttackDelay;

	
	// 	}
	// }

	// UFUNCTION(NotBlueprintCallable)
	// void DisableAllArms()
	// {
	// 	Octopus.DeactivateAllSecondSequenceArm();
	// 	//bCanTimer = true;
	// }

	// UFUNCTION(NetFunction)
	// void NetActivateSlam(int PositionIndex)
	// {	
	// 	PendingArmsActivationIndices.Add(PositionIndex);
	// }

	UFUNCTION(NetFunction)
	void NetSetFreeIndices(TArray<int> Indexes)
	{	
		FreeIndices.Reset();
		FreeIndices = Indexes;
	}

	// UFUNCTION(NetFunction)
	// void NetSendInitialIndex(int PositionIndex)
	// {
	// 	LastPointIndex = PositionIndex;
	// }	

	void CreateBombDuck(int PositionIndex)
	{
		if(NumberOfArmsSpawned == 0)
		{
			PlayFoghornVOBankEvent(Octopus.VOBank, n"FoghornDBPlayRoomGoldbergBossFightDucks");
		}

		NumberOfArmsSpawned++;
		Octopus.CurrentFirstAttackMode = EPirateOctopusFirstAttackMode::Slam;
		auto BombDuck = Cast<APirateOctopusSecondSequenceSlamArm>(Octopus.ArmsContainerComponent.GetArm(Octopus.SecondSequenceSlamArmType));
		SecondSequenceComp.SetArmAtPosition(PositionIndex, BombDuck, 0.f);
		LastPointIndex = PositionIndex;
		PendingArmsActivationIndices.Add(PositionIndex);
		BombDuck.ActivateArm();
		BombDuck.CannonBallDamageableComponent.DisableDamageTaking();
		Octopus.OnPirateOctopusArmSpawned.Broadcast(BombDuck);
	}

	FVector GetSlamPosition(int PositionIndex)
	{
		return SecondSequenceComp.GetArmPosition(PositionIndex);
	}

}
