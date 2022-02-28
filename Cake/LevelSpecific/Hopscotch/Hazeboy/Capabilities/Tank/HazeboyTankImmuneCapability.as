import Cake.LevelSpecific.Hopscotch.Hazeboy.HazeboyTank;
import Cake.LevelSpecific.Hopscotch.Hazeboy.HazeboyManager;

class UHazeboyTankImmuneCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 102;

	AHazeboyTank Tank;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Tank = Cast<AHazeboyTank>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!HazeboyGameIsActive())
			return EHazeNetworkActivation::DontActivate;

		if (Tank.HurtTimer <= 0.f && Tank.ImmuneTimer <= 0.f)
			return EHazeNetworkActivation::DontActivate;
			
		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!HazeboyGameIsActive())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (Tank.HurtTimer <= 0.f && Tank.ImmuneTimer <= 0.f)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Tank.SetActorHiddenInGame(false);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Tank.HurtTimer -= DeltaTime;
		Tank.ImmuneTimer -= DeltaTime;

		// Should we blink?
		float Time = Time::GetRealTimeSeconds();
		Time = Time * Hazeboy::BlinkFrequency;

		bool bShouldBlink = FMath::Frac(Time) > 0.5f;
		Tank.SetActorHiddenInGame(!bShouldBlink);
	}
}