import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.PlayRoom.Circus.Cannon.CannonToShootMarblePlayerComponent;
import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.SideContent.Cannon.CourtyardCannonShootCapability;
import Vino.PlayerHealth.PlayerHealthStatics;

class UCourtyardCannonHitDeathCapability : UHazeCapability
{	
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"CourtyardCannon");
	
	default TickGroup = ECapabilityTickGroups::ReactionMovement;
	default TickGroupOrder = 110;

	//default CapabilityDebugCategory = CapabilityTags::Movement;

	AHazePlayerCharacter Player;
	UCannonToShootMarblePlayerComponent CannonComponent;
	UHazeMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		CannonComponent = UCannonToShootMarblePlayerComponent::Get(Player);
		MoveComp = UHazeMovementComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!Player.IsAnyCapabilityActive(UCourtyardCannonShootCapability::StaticClass()))
			return EHazeNetworkActivation::DontActivate;

		if (!MoveComp.HasAnyBlockingHit())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;	
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