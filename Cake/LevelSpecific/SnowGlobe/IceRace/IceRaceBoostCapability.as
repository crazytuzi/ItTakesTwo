import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingTags;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingComponent;;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.SnowGlobe.IceRace.IceRaceComponent;

class UIceRaceBoostCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(IceSkatingTags::IceSkating);
	default CapabilityTags.Add(n"IceRace");
	default CapabilityTags.Add(n"IceRaceBoost");

	default CapabilityDebugCategory = n"IceRace";
	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 106;

	AHazePlayerCharacter Player;
	UIceSkatingComponent SkateComp;
	UIceRaceComponent IceRaceComponent;

	float BoostTime = 0.5f;
	float BoostTimer = 0.f;
	float BoostForce = 7000.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		Player = Cast<AHazePlayerCharacter>(Owner);
		SkateComp = UIceSkatingComponent::GetOrCreate(Player);
		IceRaceComponent = UIceRaceComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!SkateComp.bIsIceSkating)
	        return EHazeNetworkActivation::DontActivate;

	    if (!IceRaceComponent.bHasBoost)
	        return EHazeNetworkActivation::DontActivate;

	//	if (!WasActionStarted(ActionNames::InteractionTrigger))
	//        return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!SkateComp.bIsIceSkating)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (BoostTimer <= 0)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		IceRaceComponent.bHasBoost = false;

		BoostTimer = BoostTime;

		Player.PlayForceFeedback(IceRaceComponent.BoostForceFeedback, true, false, n"IceRaceBoost");
		
		if (IceRaceComponent.PlayerBoostEffectComponent != nullptr)
			IceRaceComponent.PlayerBoostEffectComponent.Activate(true);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.StopForceFeedback(IceRaceComponent.BoostForceFeedback, n"IceRaceBoost");

		if (IceRaceComponent.PlayerBoostEffectComponent != nullptr)
			IceRaceComponent.PlayerBoostEffectComponent.Deactivate();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		SkateComp.MaxSpeed = 3500.f;

		BoostTimer -= DeltaTime;

		Player.AddImpulse(Player.ActorForwardVector * BoostForce * DeltaTime);
	}
}