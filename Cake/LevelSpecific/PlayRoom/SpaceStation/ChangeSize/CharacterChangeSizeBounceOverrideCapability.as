import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Peanuts.Animation.Features.LocomotionFeatureBounce;
import Vino.BouncePad.BouncePad;
import Vino.Pickups.PlayerPickupComponent;
import Vino.BouncePad.BouncePadResponseComponent;
import Vino.Movement.Capabilities.GroundPound.CharacterGroundPoundFallCapabilty;
import Cake.LevelSpecific.PlayRoom.SpaceStation.ChangeSize.CharacterChangeSizeComponent;

class UCharacterChangeSizeBounceOverrideCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(n"CharacterBouncePadCapability");

	default CapabilityDebugCategory = n"Movement";
	
	default TickGroup = ECapabilityTickGroups::ReactionMovement;
	default TickGroupOrder = 10;

	AHazePlayerCharacter Player;
	UCharacterChangeSizeComponent ChangeSizeComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);

		ChangeSizeComp = UCharacterChangeSizeComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!HasControl())
			return EHazeNetworkActivation::DontActivate;

		if (!IsActioning(n"Bouncing"))
        	return EHazeNetworkActivation::DontActivate;

		if (ChangeSizeComp.CurrentSize == ECharacterSize::Medium)
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
		float BounceVelocityMultiplier = 0.2f;
		if (ChangeSizeComp.CurrentSize == ECharacterSize::Large)
			BounceVelocityMultiplier = 0.7f;

		Player.SetCapabilityAttributeValue(n"VerticalVelocity", GetAttributeValue(n"VerticalVelocity") * BounceVelocityMultiplier);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{

	}
}
