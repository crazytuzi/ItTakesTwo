import Cake.LevelSpecific.Tree.Larvae.Behaviours.LarvaBehaviourComponent;
import Cake.Weapons.Sap.SapManager;

class ULarvaDetectSapCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Behaviour");
	default CapabilityTags.Add(n"DetectSap");
	default TickGroup = ECapabilityTickGroups::BeforeGamePlay;

    ULarvaBehaviourComponent BehaviourComponent = nullptr;
	float SapCheckTime = 0.f;
	float SapCheckInterval = 0.5f;
	float FoundSapTime = -BIG_NUMBER;
	ULarvaComposableSettings Settings = nullptr;

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
        // Check after sap regularly when we don't know about any sap and might be hungry
		if (BehaviourComponent.AttachedSap > 0.f)
			return EHazeNetworkActivation::DontActivate; // No need to look for sap, it's splattered all over us
		if (Time::GetGameTimeSeconds() < SapCheckTime)
			return EHazeNetworkActivation::DontActivate;
       	return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		// We never need to tick
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
        SapCheckTime = Time::GetGameTimeSeconds() + SapCheckInterval;

		// Increase detection radius for a while after finding sap, so we'll continue eating even if we've been nudged away slightly from the sap
		float DetectRadius = Settings.EatRadius;
		if (Time::GetGameTimeSince(FoundSapTime) < Settings.EatSapDuration)
			DetectRadius += 100.f;

		USapManager Manager = GetSapManager();
		if (Manager == nullptr)
			return;

		ASapBatch Sap = Manager.FindBatchAtLocation(BehaviourComponent.EatLocation, DetectRadius);
		if ((BehaviourComponent.EatableSap == nullptr) && (Sap != nullptr))
			FoundSapTime = Time::GetGameTimeSeconds();
		BehaviourComponent.EatableSap = Sap;
    }
}
