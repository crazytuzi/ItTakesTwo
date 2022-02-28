import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;

class UCastleEnemyIdleAnimationCapability : UHazeCapability
{
    default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 500;

	ACastleEnemy Enemy;

    UFUNCTION(BlueprintOverride)
    void Setup(FCapabilitySetupParams Params)
    {
		Enemy = Cast<ACastleEnemy>(Owner);
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkActivation ShouldActivate() const
    {
		if (Enemy.Mesh.CanRequestLocomotion())
			return EHazeNetworkActivation::ActivateLocal; 
		else
			return EHazeNetworkActivation::DontActivate; 
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkDeactivation ShouldDeactivate() const
    {
		if (Enemy.Mesh.CanRequestLocomotion())
			return EHazeNetworkDeactivation::DontDeactivate; 
		else
			return EHazeNetworkDeactivation::DeactivateLocal; 
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        FHazeRequestLocomotionData AnimationRequest;
        AnimationRequest.WantedWorldFacingRotation = Enemy.ActorQuat;
        AnimationRequest.WantedWorldTargetDirection = Enemy.ActorForwardVector;
		AnimationRequest.AnimationTag = n"Movement";

		Enemy.RequestLocomotion(AnimationRequest);
    }
};