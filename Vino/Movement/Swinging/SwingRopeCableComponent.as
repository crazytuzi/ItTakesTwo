import Vino.Movement.Swinging.SwingPointComponent;

enum ESwingRopeState
{
	Passive,
	Extending,
	Retracting,	
	Attached,
}

class USwingRopeCableComponent : UHazeCableComponent
{
	default bAutoActivate = true;
	default CableWidth = 8.f;
	default CableGravityScale = 3.f;
	default SubstepTime = 0.001;
	default EndLocation = FVector::ZeroVector;
	default CableLength = 400.f;
	default SolverIterations = 4;
	default NumSegments = 20;
	default SetHiddenInGame(true);

	default PrimaryComponentTick.bStartWithTickEnabled = false;
	default PrimaryComponentTick.TickGroup = ETickingGroup::TG_LastDemotable;

	USwingPointComponent AttachedSwingPoint;

	ESwingRopeState RopeState = ESwingRopeState::Passive;
	float ExtensionSpeed = 6000.f;
	float RetractionSpeed = 3500.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetComponentTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		UpdateEndPointLocation();
		// if (RopeState == ESwingRopeState::Passive)
		// 	return;

		// if (RopeState == ESwingRopeState::Attached)
		// 	return;

		// if (RopeState == ESwingRopeState::Extending)
		// {
		// 	ExtendRope(DeltaTime);
		// }
		// else if (RopeState == ESwingRopeState::Retracting)
		// {
		// 	RetractRope();
		// }	
	}

	void AttachToSwingPoint(USwingPointComponent SwingPoint)
	{
		if (SwingPoint == nullptr)
			return;

		AttachedSwingPoint = SwingPoint;
		ResetParticleForces();
		ResetParticleVelocities();
		SetHiddenInGame(false);
		SetComponentTickEnabled(true);

		// TargetSwingPoint = SwingPoint;
		// RopeState = ESwingRopeState::Extending;
	}

	void DetachFromSwingPoint()
	{
		SetHiddenInGame(true);
		SetComponentTickEnabled(false);

		AttachedSwingPoint = nullptr;
		EndLocation = FVector::ZeroVector;
		// TargetSwingPoint = nullptr;
		// RopeState = ESwingRopeState::Retracting;
	}

	void UpdateEndPointLocation()
	{
		if (AttachedSwingPoint == nullptr)
			return;

		SetRopeEndWorldLocation(AttachedSwingPoint.WorldLocation);
	}

	void ExtendRope(float DeltaTime)
	{
		FVector RopeEndWorld = GetRopeEndWorldLocation();
		FVector SwingPointWorld = AttachedSwingPoint.WorldLocation;
		FVector RopeEndToSwingPoint = SwingPointWorld - RopeEndLocation;

		System::DrawDebugLine(RopeEndWorld, SwingPointWorld);

		FVector DeltaMove = RopeEndToSwingPoint.GetSafeNormal() * ExtensionSpeed * DeltaTime;

		FVector NewRopeEndLocation = RopeEndWorld + DeltaMove;
		if (RopeEndToSwingPoint.Size() <= DeltaMove.Size())
			NewRopeEndLocation = SwingPointWorld;

		SetRopeEndWorldLocation(NewRopeEndLocation);
	}

	void RetractRope()
	{

	}

	FVector GetRopeEndLocation() property
	{
		FVector ParticalStartLocation;
		FVector ParticalEndLocation;
		GetEndPositions(ParticalStartLocation, ParticalEndLocation);

		return EndLocation;
	}

	FVector GetRopeEndWorldLocation() const property
	{
		return GetRopeEndTransform().TransformPosition(EndLocation);
	}

	FTransform GetRopeEndTransform() const property
	{
		USceneComponent EndComponent = GetAttachedComponent();
		if (EndComponent != nullptr && EndComponent != this)
		{
			if (GetAttachEndToSocketName() != NAME_None)
				return EndComponent.GetSocketTransform(GetAttachEndToSocketName());
			else
				return EndComponent.GetWorldTransform();
		}

		return FTransform::Identity;
	}

	void SetRopeEndWorldLocation(FVector InWorldLocation) property
	{
		EndLocation = GetRopeEndTransform().InverseTransformPosition(InWorldLocation);
	}
}
