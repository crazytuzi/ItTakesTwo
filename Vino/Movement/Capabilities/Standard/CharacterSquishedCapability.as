
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.MovementSettings;

// This is a catch 'em all capability. If nothing else triggerd, this should trigger so we don't T pose
class UCharacterSquishedCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 200;

	default CapabilityDebugCategory = CapabilityTags::Movement;

	const bool bAlsoValidateCurrentFrameRequest = true;

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!MoveComp.CanCalculateMovement() && !CharacterOwner.Mesh.CanRequestLocomotion())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!MoveComp.CanCalculateMovement() && !CharacterOwner.Mesh.CanRequestLocomotion())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.CanCalculateMovement())
		{
			FHazeFrameMovement FinalMovement = MoveComp.MakeFrameMovement(n"Squished");
			MoveCharacter(FinalMovement, n"Movement");
		}
		else if(CharacterOwner.Mesh.CanRequestLocomotion())
		{
			FHazeRequestLocomotionData AnimationRequest;
 			AnimationRequest.AnimationTag = n"Movement";		
			CharacterOwner.RequestLocomotion(AnimationRequest);
		}
	}

	UFUNCTION(BlueprintOverride)
	FString GetDebugString()
	{
		return "";
	}
};
