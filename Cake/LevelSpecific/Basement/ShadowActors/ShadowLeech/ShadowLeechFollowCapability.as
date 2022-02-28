import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.Basement.ParentBlob.ParentBlobPlayerComponent;

class UShadowLeechFollowCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default CapabilityDebugCategory = n"Movement";
	
	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	AParentBlob ParentBlob;

	float FollowSpeed = 8000.f;

	UFUNCTION(BlueprintOverride)
	void Setup(const FCapabilitySetupParams& SetupParams)
	{
		Super::Setup(SetupParams);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (IsActioning(n"FollowPlayers"))
        	return EHazeNetworkActivation::ActivateFromControl;
        
        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!IsActioning(n"FollowPlayers"))
			return EHazeNetworkDeactivation::DeactivateFromControl;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		ParentBlob = GetActiveParentBlobActor();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
	
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{

    }

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{

    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		/*FVector DirToPlayer = ParentBlob.ActorLocation - Owner.ActorLocation;
		DirToPlayer = Math::HazeConstrainVectorToPlane(DirToPlayer, MoveComp.WorldUp);
		DirToPlayer.Normalize();

		FVector Velocity = DirToPlayer * FollowSpeed * DeltaTime;

		MoveComp.SetTargetFacingDirection(DirToPlayer);

		FHazeFrameMovement MoveData = MoveComp.MakeFrameMovement(n"LeechFollow");
		MoveData.ApplyVelocity(Velocity);
		MoveData.ApplyActorVerticalVelocity();
		MoveData.ApplyGravityAcceleration();
		MoveData.ApplyTargetRotationDelta();

		MoveCharacter(MoveData, n"LeechFollow");*/
	}
}