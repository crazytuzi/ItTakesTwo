import Cake.LevelSpecific.SnowGlobe.Swimming.AI.AnglerFish.Behaviours.FishBehaviourComponent;
import Cake.LevelSpecific.SnowGlobe.Swimming.AI.AnglerFish.Settings.FishComposableSettings;

class UFishAttackRunCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Attack");

	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 1.f;

	UFishBehaviourComponent BehaviourComp;
	UFishComposableSettings Settings;
	UHazeCrumbComponent CrumbComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		BehaviourComp = UFishBehaviourComponent::Get(Owner);
		Settings = UFishComposableSettings::GetSettings(Owner);
		CrumbComp = UHazeCrumbComponent::Get(Owner);
		ensure((BehaviourComp != nullptr) && (Settings != nullptr) && (CrumbComp != nullptr));
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (Time::GetGameTimeSeconds() > BehaviourComp.SustainedAttackEndTime)
			return EHazeNetworkActivation::DontActivate;
		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
        if (Time::GetGameTimeSeconds() > BehaviourComp.SustainedAttackEndTime)
            return EHazeNetworkDeactivation::DeactivateUsingCrumb;
        if (BehaviourComp.Food.Num() > 0)
            return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		// Check if we can eat any player. We might eat someone other than target by accident, big mouth after all :)
		TArray<AHazePlayerCharacter> Players = Game::GetPlayers();
		for (AHazePlayerCharacter Target : Players)
		{
			if (BehaviourComp.CanHitTarget(Target, Settings.AttackRunHitRadius, Settings.AttackRunHitDuration))
			{
				// To ensure best synced crumb trail we use our crumb component when hitting a target 
				// on our control side and the targets crumb component when hitting on on our remote side.
				UHazeCrumbComponent HitCrumbComp = HasControl() ? CrumbComp : UHazeCrumbComponent::Get(Target);
				FHazeDelegateCrumbParams CrumbParams;
				CrumbParams.AddObject(n"Food", Target);
				HitCrumbComp.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"CrumbEat"), CrumbParams);
			}
		}
	}

	UFUNCTION()
	void CrumbEat(const FHazeDelegateCrumbData& CrumbData)
	{
		// Glomp!
		AHazeActor Food = Cast<AHazeActor>(CrumbData.GetObject(n"Food"));
		BehaviourComp.Food.AddUnique(Food);
		BehaviourComp.OnAttackRunHit.Broadcast(Food);
	}
};
