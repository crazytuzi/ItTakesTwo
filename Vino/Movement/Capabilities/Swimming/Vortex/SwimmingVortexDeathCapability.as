import Vino.Movement.Capabilities.Swimming.SnowGlobeSwimmingComponent;
import Vino.Movement.Capabilities.Swimming.SwimmingCollisionHandler;
import Vino.Movement.Capabilities.Swimming.Vortex.SwimmingVortexSettings;
import Vino.Movement.Capabilities.Swimming.Core.SwimmingTags;
import Vino.PlayerHealth.PlayerHealthStatics;

class USwimmingVortexDeathCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MovementSystemTags::Swimming);
	default CapabilityTags.Add(SwimmingTags::Underwater);
	default CapabilityTags.Add(SwimmingTags::Vortex);
	default CapabilityTags.Add(n"VortexDeath");

	default CapabilityDebugCategory = n"Movement Swimming";
	
	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UHazeMovementComponent MoveComp;
	USnowGlobeSwimmingComponent SwimComp;
	FSwimmingVortexSettings VortexSettings;

	FHazeAcceleratedVector AcceleratedHorizontalVelocity;
	FHazeAcceleratedFloat AcceleratedTurnRate;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UHazeMovementComponent::GetOrCreate(Owner);
		SwimComp = USnowGlobeSwimmingComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const 
	{
		if (!Player.IsAnyCapabilityActive(SwimmingTags::VortexDash))
			return EHazeNetworkActivation::DontActivate;

		if (SwimComp.VortexSafeVolumeCount > 0)
			return EHazeNetworkActivation::DontActivate;

		if (!MoveComp.HasAnyBlockingHit())
			return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		KillPlayer(Player);
	}
}