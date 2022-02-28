import Vino.Movement.MovementSystemTags;
import Vino.Movement.Capabilities.Swimming.Core.SwimmingTags;
import Vino.Movement.Capabilities.Swimming.SnowGlobeSwimmingComponent;

class USwimmingForceSurfaceCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MovementSystemTags::Swimming);
	default CapabilityTags.Add(SwimmingTags::Surface);
	default CapabilityTags.Add(n"SwimmingForceSurface");

	default CapabilityDebugCategory = n"Movement Swimming";
	
	default TickGroup = ECapabilityTickGroups::BeforeGamePlay;
	default TickGroupOrder = 20;

	AHazePlayerCharacter Player;
	USnowGlobeSwimmingComponent SwimComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		SwimComp = USnowGlobeSwimmingComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		SwimComp.bForceSurface = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SwimComp.bForceSurface = false;
	}
}