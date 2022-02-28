import Vino.Movement.Components.MovementComponent;
import Peanuts.Audio.AudioStatics;

class UPlayerGameplayStatusUpdateCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Audio");
	default CapabilityDebugCategory = n"Audio";

	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UHazeMovementComponent MoveComp;
	UAkComponent AkComp;	

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		AkComp = UAkComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{		
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}
}