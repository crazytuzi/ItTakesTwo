import Cake.LevelSpecific.Tree.Wasps.Behaviours.WaspBehaviourComponent;
import Cake.LevelSpecific.Tree.Wasps.Attacks.PlayerResponses.WaspAttackRunHitResponseCapability;
import Cake.LevelSpecific.Tree.Wasps.Settings.WaspComposableSettings;

class UWaspAttackRunCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Attack");
	default CapabilityTags.Add(n"AttackRun");

	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 1.f;

	UWaspBehaviourComponent BehaviourComp;
	UWaspComposableSettings Settings;
	UHazeAkComponent AudioComp;

	TArray<AHazeActor> AvailableTargets;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		BehaviourComp = UWaspBehaviourComponent::Get(Owner);
		AudioComp = UHazeAkComponent::Get(Owner);
		Settings = UWaspComposableSettings::GetSettings(Owner);

		// Add response capability for all players when there are members of the team
		BehaviourComp.Team.AddPlayersCapability(UWaspAttackRunHitResponseCapability::StaticClass());
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
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
        SetMutuallyExclusive(n"Attack", true); 
		AudioComp.SetRTPCValue("Rtpc_Characters_Enemies_Wasps_IsAttacking", 1.f, 500);
		AvailableTargets.AddUnique(Game::GetCody());
		AvailableTargets.AddUnique(Game::GetMay());
    }

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
        SetMutuallyExclusive(n"Attack", false); 
		AudioComp.SetRTPCValue("Rtpc_Characters_Enemies_Wasps_IsAttacking", 0.f, 500);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		for (int i = AvailableTargets.Num() - 1; i >= 0; i--)
		{
			AHazeActor Target = AvailableTargets[i];
			if (BehaviourComp.IsValidTarget(Target) && Target.HasControl())
			{
				if (BehaviourComp.CanHitTarget(Target, Settings.AttackRunHitRadius, Settings.AttackRunHitDuration, false))
				{
					// As a hit won't affect wasp itself, we'll use the targets crumb comp to notify hit.
					UHazeCrumbComponent TargetCrumbComp = UHazeCrumbComponent::Get(Target);
					if (ensure(TargetCrumbComp != nullptr))
					{
						FHazeDelegateCrumbParams CrumbParams;
						CrumbParams.AddObject(n"Target", Target);
						TargetCrumbComp.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"CrumbHitTarget"), CrumbParams);
					}
				}
			}
		}
	}

	UFUNCTION()
	void CrumbHitTarget(const FHazeDelegateCrumbData& CrumbData)
	{
		AHazeActor Target = Cast<AHazeActor>(CrumbData.GetObject(n"Target"));
		if (!ensure(Target != nullptr))
			return;

		AvailableTargets.Remove(Target);

		// Set ourselves as attacker for response capability
		Target.SetCapabilityAttributeObject(n"AttackingWasp", Owner);	

		// Note that we will report all hits, which means we can potentially report 
		// hits in different order on control and remote side. Users should handle this.
		BehaviourComp.OnAttackRunHit.Broadcast(Target);
		BehaviourComp.LastAttackRunHitTime = Time::GetGameTimeSeconds();
	}
};
