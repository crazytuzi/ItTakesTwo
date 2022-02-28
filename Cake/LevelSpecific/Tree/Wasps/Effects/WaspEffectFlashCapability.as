import Peanuts.DamageFlash.DamageFlashStatics;
import Cake.LevelSpecific.Tree.Wasps.Effects.WaspEffectsComponent;

class UWaspEffectFlashCapability : UHazeCapability
{
	default CapabilityTags.Add(n"WaspEffects");
	default TickGroup = ECapabilityTickGroups::PostWork;

    UWaspEffectsComponent EffectsComp = nullptr;
	UHazeSkeletalMeshComponentBase Mesh = nullptr;
	float FlashTime = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		EffectsComp = UWaspEffectsComponent::Get(Owner);
        ensure(EffectsComp != nullptr);
		Mesh = UHazeSkeletalMeshComponentBase::Get(Owner);
		ensure(Mesh != nullptr);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        if (Time::GetGameTimeSeconds() > EffectsComp.FlashTime)
            return EHazeNetworkActivation::DontActivate; 
       	return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
        if (Time::GetGameTimeSeconds() > EffectsComp.FlashTime)
            return EHazeNetworkDeactivation::DeactivateLocal; 
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		FlashTime = Time::GetRealTimeSeconds();
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
		if (Time::GetRealTimeSeconds() > FlashTime)
		{
			Flash(Mesh, 0.1f);
			FlashTime += 0.2f;
		}
	}
}