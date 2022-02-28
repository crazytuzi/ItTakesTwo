import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.Swinging.SwingComponent;

class USwingEmilMovementCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementAction);
	default CapabilityTags.Add(MovementSystemTags::Swinging);
	default CapabilityTags.Add(n"SwingingMovement");

	default CapabilityDebugCategory = n"Movement Swinging";

	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 5;

	AHazePlayerCharacter Player;
	USwingingComponent SwingingComponent;

	USwingPointComponent ActiveSwingPoint;

	FVector AngularVelocity;
	FVector Offset;

	FVector TargetDirection;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);

		Player = Cast<AHazePlayerCharacter>(Owner);
		SwingingComponent = USwingingComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		USwingPointComponent SwingPoint = SwingingComponent.GetActiveSwingPoint();
		if (SwingPoint == nullptr)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;		
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		USwingPointComponent CurrentPoint = SwingingComponent.GetActiveSwingPoint();
		if (ActiveSwingPoint != CurrentPoint)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (!MoveComp.CanCalculateMovement())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		ActiveSwingPoint = SwingingComponent.GetActiveSwingPoint();

		TargetDirection = ActiveSwingPoint.WorldLocation - Player.ActorLocation;
		TargetDirection = TargetDirection.ConstrainToPlane(FVector::UpVector);
		TargetDirection.Normalize();

		AngularVelocity = GetSwingTorqueAxis() * 2.f;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		ActiveSwingPoint = nullptr;
	}

	FVector CalculateFlatDirection(FVector PlayerOffset)
	{
		FVector FlatOffset = PlayerOffset.ConstrainToPlane(MoveComp.WorldUp);
		return FlatOffset.GetSafeNormal();
	}

	FVector GetSwingTorqueAxis()
	{
		return TargetDirection.CrossProduct(MoveComp.WorldUp);
	}

	FVector CalculateGravityForce(FVector PlayerOffset)
	{
		FVector OffsetNorm = PlayerOffset.GetSafeNormal();
		return MoveComp.WorldUp.CrossProduct(OffsetNorm) * 5.f;
	}

	FVector CalculateConstantForce(FVector PlayerOffset)
	{
		FVector FlatDirection = CalculateFlatDirection(PlayerOffset);
		return FVector::OneVector;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		FVector PointLocation = ActiveSwingPoint.WorldLocation;
		FVector PointToPlayer = Player.ActorLocation - PointLocation;

		FVector FlatDirectionToPoint = ActiveSwingPoint.WorldLocation - Player.ActorLocation;
		FlatDirectionToPoint = FlatDirectionToPoint.ConstrainToPlane(FVector::UpVector);
		FlatDirectionToPoint.Normalize();
		float ForceDirection = FMath::Sign(FlatDirectionToPoint.DotProduct(TargetDirection));

		FVector Force = GetSwingTorqueAxis() * ForceDirection * 10.f;
		FVector GravityForce = CalculateGravityForce(PointToPlayer);

		FVector Friction = -AngularVelocity * 1.2f;
		//AngularVelocity += (Force + GravityForce + Friction) * DeltaTime;
		AngularVelocity += (GravityForce) * DeltaTime;

		FQuat DeltaRotation = FQuat(AngularVelocity.GetSafeNormal(), AngularVelocity.Size() * DeltaTime);
		FVector NextLocation = DeltaRotation * PointToPlayer;
		FVector DeltaMove = NextLocation - PointToPlayer;

		FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"Swinging");
		FrameMove.ApplyDelta(DeltaMove);
		MoveCharacter(FrameMove, NAME_None);
	}
}