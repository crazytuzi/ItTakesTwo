import Cake.LevelSpecific.Clockwork.BullMiniBoss.CapabilityBull.ClockworkBullBossMoveCapability;

// This will tick while we are switching controlside in network
class UClockworkBullBossIdle : UClockworkBullBossMoveCapability
{
	default CapabilityTags.Add(ClockworkBullBossTags::ClockworkBullBoss);
	default CapabilityTags.Add(ClockworkBullBossTags::ClockworkBullBossAttackTarget);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MovementSystemTags::GroundMovement);
	default CapabilityTags.Add(MovementSystemTags::BasicFloorMovement);

	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 150;

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!BullOwner.CanInitializeMovement(MoveComp))
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	
	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!BullOwner.CanInitializeMovement(MoveComp))
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
	
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeFrameMovement FinalMovement = MoveComp.MakeFrameMovement(n"BullIdle");	
		
		if(!HasControl())
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			FinalMovement.ApplyConsumedCrumbData(ConsumedParams);
		}

		BullOwner.InitializeMovement(MoveComp, FinalMovement, BullOwner.ActorLocation, n"WatingForNetwork", NAME_None, false);
	}
}


// This will tick while we are switching controlside in network
class UClockworkBullBossIdleDuringNetworkChange : UClockworkBullBossMoveCapability
{
	default CapabilityTags.Add(ClockworkBullBossTags::ClockworkBullBoss);
	default CapabilityTags.Add(ClockworkBullBossTags::ClockworkBullBossAttackTarget);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MovementSystemTags::GroundMovement);
	default CapabilityTags.Add(MovementSystemTags::BasicFloorMovement);

	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 50;

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		// if(BullOwner.PendingControlSidePlayer == nullptr)
		// 	return EHazeNetworkActivation::DontActivate;

		// if(BullOwner.PendingControlSidePlayer.HasControl() && BullOwner.HasControl())
		// 	return EHazeNetworkActivation::DontActivate;

		// if(!BullOwner.CanInitializeMovement(MoveComp))
		// 	return EHazeNetworkActivation::DontActivate;

		// return EHazeNetworkActivation::ActivateUsingCrumb;

		return EHazeNetworkActivation::DontActivate;
	}

	
	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		// if(BullOwner.PendingControlSidePlayer == nullptr)
		// 	return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(!BullOwner.CanInitializeMovement(MoveComp))
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
	
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeFrameMovement FinalMovement = MoveComp.MakeFrameMovement(n"BullIdle");	
		
		if(!HasControl())
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			FinalMovement.ApplyConsumedCrumbData(ConsumedParams);
		}

		BullOwner.InitializeMovement(MoveComp, FinalMovement, BullOwner.ActorLocation, n"WatingForNetwork", NAME_None, false);
	}
}