import Cake.LevelSpecific.Tree.Larvae.Behaviours.LarvaBehaviourComponent;
import Vino.Checkpoints.Statics.DeathStatics;

class ULarvaSelectTargetCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Behaviour");
	default CapabilityTags.Add(n"SelectTarget");
	default TickGroup = ECapabilityTickGroups::GamePlay;
    default TickGroupOrder = 100;

    ULarvaBehaviourComponent BehaviourComponent = nullptr;
	ULarvaComposableSettings Settings = nullptr;
    float CanSwitchTargetTime = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		BehaviourComponent = ULarvaBehaviourComponent::Get(Owner);
        ensure(BehaviourComponent != nullptr);
		Settings = ULarvaComposableSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{	
		if (!HasControl())
	       	return EHazeNetworkActivation::DontActivate;

		if (BehaviourComponent.GetTarget() == nullptr)
	       	return EHazeNetworkActivation::ActivateLocal;

		if (Time::GetGameTimeSeconds() > CanSwitchTargetTime)
	       	return EHazeNetworkActivation::ActivateLocal;

       	return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{	
       	return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		CanSwitchTargetTime = Time::GetGameTimeSeconds() + 2.f;

		AHazeActor Target = SelectTarget();        
		if ((Target != nullptr) && (Target != BehaviourComponent.Target))
		{
			NetSetTarget(Target);
		}
		else if ((BehaviourComponent.Target != nullptr) && !BehaviourComponent.HasValidTarget())
		{
			// Only lose previous target if it's invalid
			NetSetTarget(nullptr);
		}
    }

    AHazeActor SelectTarget()
    {
        float MaxDistanceSqr = FMath::Square(Settings.MaxTargetDistance);
        float ClosestTargetDistSqr = MaxDistanceSqr;
        AHazeActor BestTarget = nullptr;
        TArray<AHazePlayerCharacter> PotentialTargets = Game::GetPlayers();
        for (AHazePlayerCharacter PotentialTarget : PotentialTargets)
        {
			if (!BehaviourComponent.IsValidTarget(PotentialTarget))
				continue;

            float TargetDistSqr = Owner.GetSquaredDistanceTo(PotentialTarget);
            if (TargetDistSqr < ClosestTargetDistSqr)
            {
                ClosestTargetDistSqr = TargetDistSqr;
                BestTarget = PotentialTarget;
            }
        }

        return BestTarget;
    }

	UFUNCTION(NetFunction, NotBlueprintCallable)
	void NetSetTarget(AHazeActor Target)
	{
		BehaviourComponent.SetTarget(Target);
	}			
}
