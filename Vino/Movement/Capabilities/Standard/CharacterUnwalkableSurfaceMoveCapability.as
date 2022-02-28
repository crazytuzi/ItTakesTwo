
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;

class UCharacterUnwalkableSurfaceMoveCapability : UCharacterMovementCapability
{
	default RespondToEvent(MovementActivationEvents::Airbourne);

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MovementSystemTags::GroundMovement);
	default CapabilityTags.Add(MovementSystemTags::BasicFloorMovement);

	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 145;

	default CapabilityDebugCategory = CapabilityTags::Movement;

	//Static value of how much we keep of the force
	const float ForceGroundFrictionValue = 0.14f;

	float CurrentForwardSpeed = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate_EventBased() const
	{
		if(!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		if (MoveComp.IsGrounded())
			return EHazeNetworkActivation::DontActivate;

		FHitResult Dummy;
		if (!GetRelevantUnwalkableHit(Dummy))
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!MoveComp.CanCalculateMovement())
			return RemoteLocalControlCrumbDeactivation();

		if(ShouldBeGrounded())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		FHitResult Dummy;
		if (!GetRelevantUnwalkableHit(Dummy))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams Params)
	{
		Owner.BlockCapabilities(CapabilityTags::CharacterFacing, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Owner.UnblockCapabilities(CapabilityTags::CharacterFacing, this);
	}
	
	void CalculateControlMove(FHazeFrameMovement& OutMove, float DeltaTime)
	{
		FHitResult UnwalkableHit;
		GetRelevantUnwalkableHit(UnwalkableHit);

		FVector ToGetPlaneDown = -MoveComp.WorldUp;
		if (FMath::Abs(MoveComp.WorldUp.DotProduct(UnwalkableHit.ImpactNormal)) > 0.995f)
			ToGetPlaneDown = Owner.ActorQuat.ForwardVector;

		FVector PlaneDownDirection = ToGetPlaneDown.ConstrainToPlane(UnwalkableHit.Normal).GetSafeNormal();
		FVector SlideDelta = PlaneDownDirection * 850 * DeltaTime;

		MoveComp.SetTargetFacingDirection(PlaneDownDirection, 15.f);

		OutMove.ApplyDelta(SlideDelta);
		OutMove.ApplyTargetRotationDelta();
	}

	void CalculateRemoteMove(FHazeFrameMovement& OutMovement, float DeltaTime)
	{
		FHazeActorReplicationFinalized ConsumedParams;
		CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
		OutMovement.ApplyConsumedCrumbData(ConsumedParams);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeFrameMovement UnwalkMove = MoveComp.MakeFrameMovement(n"UnwalkableSurfaceMove");
		if (HasControl())
			CalculateControlMove(UnwalkMove, DeltaTime);
		else
			CalculateRemoteMove(UnwalkMove, DeltaTime);
		
		MoveCharacter(UnwalkMove, FeatureName::AirMovement);
		CrumbComp.LeaveMovementCrumb();
	}

	bool GetRelevantUnwalkableHit(FHitResult& OutHit) const
	{
		if (MoveComp.DownHit.bBlockingHit && MoveComp.DownHit.Component != nullptr)
		{
			if (!MoveComp.DownHit.Component.HasTag(ComponentTags::Walkable))
			{
				OutHit = MoveComp.DownHit;
				return true;
			}
		}

		if (MoveComp.ForwardHit.bBlockingHit && MoveComp.ForwardHit.Component != nullptr)
		{
			if (!MoveComp.ForwardHit.Component.HasTag(ComponentTags::Walkable) && !FMath::IsNearlyZero(MoveComp.ForwardHit.ImpactNormal.DotProduct(MoveComp.WorldUp)))
			{
				OutHit = MoveComp.ForwardHit;
				return true;
			}
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	FString GetDebugString()
	{	
		FString Str = "";
		Str += "Velocity: <Yellow>" + MoveComp.Velocity.Size() + "</> (" + MoveComp.Velocity.ToString() + ")\n";
		
		return Str;
	} 
};
