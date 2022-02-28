import Cake.LevelSpecific.Clockwork.BullMiniBoss.ClockworkBullBoss;
import Cake.LevelSpecific.Clockwork.BullMiniBoss.ClockworkBullBossTags;

class UClockworkBullBossAquireTargetCapability : UHazeCapability
{
	default CapabilityTags.Add(ClockworkBullBossTags::ClockworkBullBoss);
	default CapabilityTags.Add(ClockworkBullBossTags::ClockworkBullBossAttackTarget);

	default TickGroup = ECapabilityTickGroups::GamePlay;
	//default TickGroupOrder = 110;

	default CapabilityDebugCategory = CapabilityTags::Movement;

	AClockworkBullBoss BullOwner;
	float NextActivationGameTime = 0;
	float TimeWithoutPlayerTarget = 0;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		BullOwner = Cast<AClockworkBullBoss>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;

		// If we are not allowed to target the current targeted player. We need to force change target
		auto CurrentPlayerTarget = BullOwner.GetCurrentTargetPlayer();
		if(CurrentPlayerTarget != nullptr)
		{	
			if(!BullOwner.CanTargetPlayer(CurrentPlayerTarget, true))
				return EHazeNetworkActivation::ActivateLocal;
		}
					
		if(!BullOwner.CanChangeTarget())
			return EHazeNetworkActivation::DontActivate;

		if(BullOwner.GetCurrentTarget() != nullptr)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!HasControl())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(!BullOwner.CanChangeTarget())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(BullOwner.GetCurrentTarget() != nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams Params)
	{
		NextActivationGameTime = 0;
		TimeWithoutPlayerTarget = 0;
	}
	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeIntersectionCone Cone;
		BullOwner.GetAttackIntersectionCone(Cone);
		AHazePlayerCharacter BestPlayer;
		if(BullOwner.AvailableTargets.Num() == 2)
			BestPlayer = BullOwner.GetBestVisiblePlayerTarget(Cone);
		else
			BestPlayer = BullOwner.GetBestPlayerTarget();

		if(Time::GetGameTimeSeconds() >= NextActivationGameTime)
		{
			// We can only retrigger the search with this intervall
			NextActivationGameTime = Time::GetGameTimeSeconds() + 0.25f;

			float RandomValue = FMath::RandRange(0.f, 1.f);
			if(RandomValue < BullOwner.Settings.RandomFactorWhenSelectingTarget || BullOwner.Settings.RandomFactorWhenSelectingTarget >= 1.f)
			{
				// We should pick a random target
				BestPlayer = BullOwner.GetRandomPlayerTarget();	
			}
			else if(BestPlayer == nullptr && TimeWithoutPlayerTarget >= BullOwner.Settings.MaxTimeWithoutTarget)
			{
				// We could not see any target so we pick a new target
				BestPlayer = BullOwner.GetBestPlayerTarget();
			}
		}

		if(BestPlayer != nullptr)
		{
			BullOwner.SetPlayerTargetFromControl(BestPlayer);
		}
		else
		{
			BullOwner.ClearCurrentTargetFromControl();
			TimeWithoutPlayerTarget += DeltaTime;
		}
	}

	UFUNCTION(BlueprintOverride)
	FString GetDebugString()
	{	
		FString Str = "";
		return Str;
	} 
};
