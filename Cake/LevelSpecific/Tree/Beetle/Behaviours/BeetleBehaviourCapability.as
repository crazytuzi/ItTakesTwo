import Cake.LevelSpecific.Tree.Beetle.Behaviours.BeetleBehaviourComponent;
import Cake.LevelSpecific.Tree.Beetle.Movement.BeetleMovementDataComponent;
import Cake.LevelSpecific.Tree.Beetle.Settings.BeetleSettings;
import Cake.LevelSpecific.Tree.Beetle.Animation.BeetleAnimFeature;
import Cake.LevelSpecific.Tree.Beetle.Health.BeetleHealthComponent;
import Cake.LevelSpecific.Tree.Beetle.Animation.BeetleAnimationComponent;

UCLASS(Abstract)
class UBeetleBehaviourCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Behaviour");
    default CapabilityDebugCategory = n"Behaviour";
	default TickGroup = ECapabilityTickGroups::GamePlay;
    default TickGroupOrder = 150;

	EBeetleState State = EBeetleState::None;
    UBeetleBehaviourComponent BehaviourComp = nullptr;
    UBeetleMovementDataComponent MoveDataComp = nullptr;
	UBeetleHealthComponent HealthComp = nullptr;
	UHazeCrumbComponent CrumbComp = nullptr;
	UBeetleAnimationComponent AnimComp = nullptr;
	UBeetleSettings Settings = nullptr;
	UBeetleAnimFeature AnimFeature = nullptr;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
        // Set common references 
		BehaviourComp = UBeetleBehaviourComponent::Get(Owner);
        MoveDataComp = UBeetleMovementDataComponent::Get(Owner);
		HealthComp = UBeetleHealthComponent::Get(Owner);
		CrumbComp = UHazeCrumbComponent::Get(Owner);
		AnimComp = UBeetleAnimationComponent::Get(Owner);
		Settings = UBeetleSettings::GetSettings(Owner);
		AnimFeature = Cast<UBeetleAnimFeature>(BehaviourComp.CharOwner.Mesh.GetFeatureByClass(UBeetleAnimFeature::StaticClass()));

        ensure((BehaviourComp != nullptr) && (MoveDataComp != nullptr) && (Settings != nullptr) && 
			   (AnimFeature != nullptr) && (HealthComp != nullptr) && (CrumbComp != nullptr));
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		// Use this behaviour if we match current state, so if a higher prio behaviour 
		// have changed state this tick we do not continue using behaviours in that state.
		if (BehaviourComp.State != State)
			return EHazeNetworkActivation::DontActivate;

		// We also need to match last updated state, so we won't use behaviours from next 
		// state during the same tick as that state was set.
		if (BehaviourComp.StateLastUpdate != State)
			return EHazeNetworkActivation::DontActivate;

       	return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (BehaviourComp.State != State)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
       	return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		// When crumb activates this on remote side we can locally set state safely
		BehaviourComp.LocalSetState(State);
		LogEvent("Activating " + GetName());
    }

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		LogEvent("Deactivating " + GetName());
	}

	void LogEvent(FString Desc, FString Postfix = "")
	{
		BehaviourComp.LogEvent(Desc, Postfix);
	}
}
