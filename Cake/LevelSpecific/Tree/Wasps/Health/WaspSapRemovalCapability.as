import Cake.LevelSpecific.Tree.Wasps.Animation.WaspAnimationComponent;
import Cake.LevelSpecific.Tree.Wasps.Settings.WaspComposableSettings;
import Cake.Weapons.Sap.SapResponseComponent;
import Cake.LevelSpecific.Tree.Wasps.Health.WaspHealthComponent;

class UWaspSapRemovalCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SapRemoval");
	default TickGroup = ECapabilityTickGroups::BeforeGamePlay;

	UWaspHealthComponent HealthComp;
	UWaspAnimationComponent AnimComp;
	UWaspComposableSettings Settings;
	USapResponseComponent SapComp;

	float InitialShakeOffTime = 0.4f;
	float SapShakeOffInterval = 0.5f;
	float ShakeOffSapTime = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		HealthComp = UWaspHealthComponent::Get(Owner);
		AnimComp = UWaspAnimationComponent::Get(Owner);
		Settings = UWaspComposableSettings::GetSettings(Owner);
		SapComp = USapResponseComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!HealthComp.bShouldRemoveSap)
			return EHazeNetworkActivation::DontActivate;
		if (HealthComp.SapMass <= 0.f)
			return EHazeNetworkActivation::DontActivate;
		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (FMath::IsNearlyZero(HealthComp.SapMass))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		float SapShakeOffDuration = Settings.StunnedMaxDuration - InitialShakeOffTime;
		ActivationParams.AddValue(n"ShakeOffInterval", GetSapShakeOffInterval(SapShakeOffDuration));
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		AnimComp.PlayAnimation(EWaspAnim::ShakeOffSap, 0.2f);
		SapShakeOffInterval = ActivationParams.GetValue(n"ShakeOffInterval");
		ShakeOffSapTime = Time::GetGameTimeSeconds() + InitialShakeOffTime;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		HealthComp.bShouldRemoveSap = false;
		AnimComp.StopAnimation(EWaspAnim::ShakeOffSap, 0.2f);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Time::GetGameTimeSeconds() > ShakeOffSapTime)
		{
			ShakeOffSapTime += SapShakeOffInterval;
			RemoveSapMassFrom(Owner.RootComponent, 0.5f);
		}
	}

	float GetSapShakeOffInterval(float SapShakeOffDuration)
	{
		if (FMath::IsNearlyZero(HealthComp.SapMass))
			return (0);
	
		if(HealthComp.SapMass < Settings.SapRemovalThreshold)
			return(SapShakeOffDuration / Settings.SapRemovalThreshold);

		return (SapShakeOffDuration / HealthComp.SapMass);
	}
}
