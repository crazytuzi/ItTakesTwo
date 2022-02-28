import Cake.LevelSpecific.Music.Smooch.Smooch;
import Cake.LevelSpecific.Music.Smooch.SmoochNames;

class USmoochHoldCapability : UHazeCapability
{
	default CapabilityTags.Add(Smooch::Smooch);
	default CapabilityDebugCategory = n"Smooch";
	default TickGroup = ECapabilityTickGroups::GamePlay;

	AHazePlayerCharacter Player;
	USmoochUserComponent SmoochComp;
	float HoldTime = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		SmoochComp = USmoochUserComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!IsActioning(ActionNames::InteractionTrigger))
	        return EHazeNetworkActivation::DontActivate;

		if (HoldTime < 0.3f)
	        return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!IsActioning(ActionNames::InteractionTrigger))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		SmoochComp.bIsHolding = true;
		SmoochComp.ButtonWidget.FadeOut();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SmoochComp.bIsHolding = false;
		SmoochComp.ButtonWidget.FadeIn();

		HoldTime = 0.f;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (IsActioning(ActionNames::InteractionTrigger))
			HoldTime += DeltaTime;
		else
			HoldTime = 0.f;
	}
}
