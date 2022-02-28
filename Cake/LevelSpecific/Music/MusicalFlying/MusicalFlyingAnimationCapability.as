import Cake.LevelSpecific.Music.MusicalFlying.MusicalFlyingComponent;
import Vino.Movement.Components.MovementComponent;

// Requests an animation each frame so the three different flying movement capabilities can deactivate/activate in whatever order without having to worry about missing a frame.

UCLASS(Deprecated)
class UMusicalFlyingAnimationCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(n"MusicalFlyingAnimation");

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 30;
	
	UMusicalFlyingComponent FlyingComp;
	UHazeMovementComponent MoveComp;
	AHazePlayerCharacter Player;
	FQuat LastFrameRotation;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		FlyingComp = UMusicalFlyingComponent::Get(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (FlyingComp.CurrentState == EMusicalFlyingState::Inactive)
		{
			return EHazeNetworkActivation::DontActivate;
		}
		
		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (FlyingComp.CurrentState == EMusicalFlyingState::Inactive)
		{
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		}

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!Player.Mesh.CanRequestLocomotion())
			return;

		FHazeRequestLocomotionData AnimationRequest;
		
		if(!MoveComp.GetAnimationRequest(AnimationRequest.AnimationTag))
		{
			AnimationRequest.AnimationTag = n"JetPack";
		}

		Player.RequestLocomotion(AnimationRequest);
	}
}
