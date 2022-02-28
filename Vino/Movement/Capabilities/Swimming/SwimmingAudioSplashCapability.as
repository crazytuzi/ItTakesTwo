import Vino.Movement.Capabilities.Swimming.SnowGlobeSwimmingComponent;
import Vino.Movement.Components.MovementComponent;
import Vino.Movement.Capabilities.Swimming.Core.SwimmingTags;

class USwimmingAudioSplashCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MovementSystemTags::Swimming);

	default CapabilityDebugCategory = n"Movement Swimming";
	
	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 200;

	AHazePlayerCharacter Player;
	USnowGlobeSwimmingComponent SwimComp;
	UHazeMovementComponent MoveComp;
	UPlayerHazeAkComponent HazeAkComp;
	
	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		SwimComp = USnowGlobeSwimmingComponent::GetOrCreate(Player);
		MoveComp = UHazeMovementComponent::GetOrCreate(Owner);
		HazeAkComp = UPlayerHazeAkComponent::Get(Owner);
	}
	

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (Player.IsAnyCapabilityActive(SwimmingTags::Surface))
        	return EHazeNetworkActivation::ActivateLocal;
		
		if (SwimComp.bIsUnderwater)
        	return EHazeNetworkActivation::ActivateLocal;

        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (SwimComp.bIsUnderwater)
        	return EHazeNetworkDeactivation::DontDeactivate;

		if (Player.IsAnyCapabilityActive(SwimmingTags::Surface))
        	return EHazeNetworkDeactivation::DontDeactivate;
			
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{	
		if (!Player.IsAnyCapabilityActive(SwimmingTags::Surface))
			SwimComp.PlaySplashSound(HazeAkComp, MoveComp.Velocity.Size());
	}

}