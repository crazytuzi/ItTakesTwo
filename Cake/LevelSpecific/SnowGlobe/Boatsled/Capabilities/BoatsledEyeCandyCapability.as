import Cake.LevelSpecific.SnowGlobe.Boatsled.BoatsledComponent;
import Peanuts.SpeedEffect.SpeedEffectStatics;

class UBoatsledEyeCandyCapability : UHazeCapability
{
	default CapabilityTags.Add(BoatsledTags::Boatsled);
	default CapabilityTags.Add(BoatsledTags::BoatsledEyeCandy);

	default TickGroup = ECapabilityTickGroups::AfterGamePlay;

	default CapabilityDebugCategory = n"Boatsled";

	AHazePlayerCharacter PlayerOwner;
	UBoatsledComponent BoatsledComponent;

	ABoatsled Boatsled;

	bool bBoatsledIsGoingFullSpeed;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		BoatsledComponent = UBoatsledComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!PlayerOwner.IsAnyCapabilityActive(BoatsledTags::Boatsled))
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Boatsled = BoatsledComponent.Boatsled;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Set speed shimmer
		if(bBoatsledIsGoingFullSpeed)
		{
			if(BoatsledComponent.NormalizedSpeed < 0.95f)
			{
				bBoatsledIsGoingFullSpeed = false;
				Boatsled.OnBoatsledLostMaxSpeed();
			}
		}
		else
		{
			if(BoatsledComponent.NormalizedSpeed >= 0.95f)
			{
				bBoatsledIsGoingFullSpeed = true;
				Boatsled.OnBoatsledReachedMaxSpeed();
			}
		}

		SpeedEffect::RequestSpeedEffect(PlayerOwner, FSpeedEffectRequest(BoatsledComponent.NormalizedSpeed, this));
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!PlayerOwner.IsAnyCapabilityActive(BoatsledTags::Boatsled))
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Boatsled = nullptr;
		bBoatsledIsGoingFullSpeed = false;
	}
}
