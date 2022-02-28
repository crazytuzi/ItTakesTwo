import Cake.LevelSpecific.Music.MusicalFlying.MusicalFlyingComponent;
import Cake.LevelSpecific.Music.Singing.SingingComponent;
import Cake.LevelSpecific.Music.MusicTargetingComponent;

UCLASS(Abstract)
class USingingPlayerFlyingCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"Singing");
	default CapabilityTags.Add(n"MusicFlyingTargeting");
	
	default CapabilityDebugCategory = n"LevelSpecific";

	USingingComponent SingingComp;
	UMusicalFlyingComponent FlyingComp;
	UMusicTargetingComponent TargetingComp;

	UPROPERTY()
	USingingSettings FlyingSingingSettings;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		SingingComp = USingingComponent::Get(Owner);
		FlyingComp = UMusicalFlyingComponent::Get(Owner);
		TargetingComp = UMusicTargetingComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!FlyingComp.bIsFlying)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		if(FlyingSingingSettings != nullptr)
		{
			Owner.ApplySettings(FlyingSingingSettings, this, EHazeSettingsPriority::Script);
		}

		SingingComp.bShoutWithoutAim = true;
		TargetingComp.bIsTargeting = true;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!FlyingComp.bIsFlying)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Owner.ClearSettingsByInstigator(this);
		SingingComp.bShoutWithoutAim = false;
		TargetingComp.bIsTargeting = false;
	}
}
