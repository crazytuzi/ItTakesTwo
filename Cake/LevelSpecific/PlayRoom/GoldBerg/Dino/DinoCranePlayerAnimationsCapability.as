import Cake.LevelSpecific.PlayRoom.GoldBerg.Dino.DinoCraneRidingComponent;

class UDinoCranePlayerAnimationsCapability : UHazeCapability
{
	default TickGroup = ECapabilityTickGroups::ActionMovement;

	AHazePlayerCharacter Player;
	UDinoCraneRidingComponent RideComp;
	UHazeBaseMovementComponent MoveComp;

	FVector PrevLocation;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams& Params)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		RideComp = UDinoCraneRidingComponent::GetOrCreate(Owner);
		MoveComp = UHazeBaseMovementComponent::Get(Owner);
	}

    UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (RideComp.DinoCrane == nullptr)
            return EHazeNetworkActivation::DontActivate;

        if (!Player.Mesh.CanRequestLocomotion())
            return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (RideComp.DinoCrane == nullptr)
            return EHazeNetworkDeactivation::DeactivateLocal;

        if (!Player.Mesh.CanRequestLocomotion())
            return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

    UFUNCTION(BlueprintOverride)
    void OnActivated(FCapabilityActivationParams ActivationParams)
    {
		PrevLocation = Owner.ActorLocation;
	}

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
		FVector NewLocation = Owner.ActorLocation;
		FVector MovedDelta = NewLocation - PrevLocation;
		PrevLocation = NewLocation;

		if (Player.Mesh.CanRequestLocomotion())
		{
			FHazeRequestLocomotionData AnimationRequest;
			AnimationRequest.LocomotionAdjustment.DeltaTranslation = MovedDelta;
			AnimationRequest.LocomotionAdjustment.WorldRotation = Owner.ActorQuat;
			AnimationRequest.WantedVelocity = MovedDelta / DeltaTime;
			AnimationRequest.WantedWorldTargetDirection = MovedDelta.GetSafeNormal();
			AnimationRequest.WantedWorldFacingRotation = Owner.ActorQuat;
			AnimationRequest.MoveSpeed = MoveComp.MoveSpeed;
			AnimationRequest.AnimationTag = n"RideDinocrane";
			Player.RequestLocomotion(AnimationRequest);
		}
    }
};