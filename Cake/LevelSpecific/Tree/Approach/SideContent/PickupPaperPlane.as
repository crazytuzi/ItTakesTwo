import Vino.Pickups.PickupActor;
import Peanuts.Spline.SplineMesh;
import Vino.Pickups.Throw.Capabilities.PickupConstrainedAimCapability;
import Vino.Tutorial.TutorialStatics;

UCLASS(hidecategories="Rendering Collision Replication Input")
class APickupPaperPlane : APickupActor
{
	default bDrawAimTrajectory = false;
	default bShouldPlayerStandAtActorLocationAfterPickup = true;
	default bPlayerIsAllowedToPutDown = false;

	UPROPERTY()
	ASplineMesh SplineToFollow;

	UPROPERTY()
	FTutorialPrompt ThrowPrompt;
	default ThrowPrompt.Action = ActionNames::WeaponFire;
	default ThrowPrompt.Text = NSLOCTEXT("PickupSystem", "ThrowPrompt", "Throw");

	bool bFollowingSpline = false;
	float DistanceAlongSpline = 3500;
	float CurrentFollowSpeed = 500;
	float DesiredFollowSpeed = 1000;
	FVector ThrowDirection;
	bool bCapabilitesUnblocked = false;

	float ForwardSpeed = 2200;
	float ForwardSpeedDrag = 300;

	float RotationSpeed = 0.2;
	float RotationSpeedAntiDrag = 0.2f;
	
	FVector StartLocation;
	FRotator CurrentRotation;
	float Distance;

	FVector CurrentLocation;

	FVector TargetPointLocation;

	UPROPERTY()
	AActor DebugSphere;

	UPROPERTY()
	AActor ForwardDirectionActor;

	FHazeAcceleratedVector AcceleratedVelocity;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
	}

	UFUNCTION(NotBlueprintCallable)
	protected bool CanPlayerPickUp(UHazeTriggerComponent TriggerComponent, AHazePlayerCharacter PlayerCharacter) override
	{
		if(bFollowingSpline)
			return false;

		return Super::CanPlayerPickUp(TriggerComponent, PlayerCharacter);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		//PrintToScreen("Rotation " + GetActorRotation());
		//PrintToScreen("Forward " + GetActorForwardVector());
		//PrintToScreen("DistanceAlongSpline " + DistanceAlongSpline);
		// PrintToScreen("RotationSpeed " + RotationSpeed);
		//PrintToScreen("Distance " + Distance);
		//PrintToScreen("CurrentFollowSpeed " + CurrentFollowSpeed);


		if(bFollowingSpline && SplineToFollow != nullptr)
		{
			CurrentFollowSpeed = FMath::FInterpTo(CurrentFollowSpeed, DesiredFollowSpeed, DeltaTime, 2);
			if(DistanceAlongSpline < SplineToFollow.Spline.GetSplineLength())
			{
				DistanceAlongSpline += CurrentFollowSpeed * DeltaTime * 0.585f;
			}
			else
			{
				bFollowingSpline = false;
				return;
			}

			TargetPointLocation = SplineToFollow.Spline.GetLocationAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World);
			FVector TowardsSplineLocation = (TargetPointLocation - ActorLocation).GetSafeNormal();
			//FRotator TargetRotation = Math::MakeRotFromX(TowardsSplineLocation);
			//CurrentRotation = FMath::LerpShortestPath(CurrentRotation, TargetRotation, DeltaTime * RotationSpeed);

			if(ForwardSpeed > 1400)
				ForwardSpeed -= DeltaTime * ForwardSpeedDrag;
			if(RotationSpeed < 20)
				RotationSpeed += DeltaTime * RotationSpeedAntiDrag;

			Distance += ForwardSpeed * DeltaTime;
			// FVector TargetActorLocationPlane = StartLocation + GetActorForwardVector() * Distance;

			// CurrentLocation = FMath::Lerp(CurrentLocation, TargetActorLocationPlane, DeltaTime * 12.f);
			//SetActorLocationAndRotation(CurrentLocation, CurrentRotation);

			// Create frame move structure
			FHazeFrameMovement MoveData = MovementComponent.MakeFrameMovement(n"PickupPaperPlane");
			MoveData.OverrideCollisionProfile(n"NoCollision");

			// Accelerate current velocity towards point in spline
			FVector Velocity = AcceleratedVelocity.AccelerateTo(TowardsSplineLocation * ForwardSpeed, 10.f, DeltaTime);
			MoveData.ApplyVelocity(Velocity);
			MoveData.SetRotation(Velocity.ToOrientationQuat());

			// Set pickup root rotation
			FQuat MeshRotation = Velocity.ToOrientationQuat() * OriginalPickupRootRelativeRotation;
			Mesh.SetWorldRotation(MeshRotation.Rotator());

			// Finally move!
			MovementComponent.Move(MoveData);

			DebugSphere.SetActorLocation(TargetPointLocation);
			// DebugSphere.SetActorLocation(SplineToFollow.Spline.GetLocationAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World)); 
			// DebugSphere.SetActorRotation(SplineToFollow.Spline.GetRotationAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World));
		}
	}

	UFUNCTION(NotBlueprintCallable)
	protected void OnPickedUpDelegate(AHazePlayerCharacter Player, APickupActor PickupActor)
	{
		Super::OnPickedUpDelegate(Player, PickupActor);
		Player.BlockCapabilities(CapabilityTags::MovementInput, this);
		bCapabilitesUnblocked = false;

		// This is the default forward rotation from where to clamp the aiming
		FVector ForwardVector = ForwardDirectionActor.ActorForwardVector.GetSafeNormal();

		// Instruct pickup system to use constrained aiming
		Player.SetCapabilityActionState(PickupTags::StartPickupConstrainedAim, EHazeActionState::ActiveForOneFrame);
		Player.SetCapabilityAttributeVector(PickupTags::PickupConstrainedAimStartForward, ForwardVector);
		Player.SetCapabilityActionState(n"CancelActionThrows", EHazeActionState::ActiveForOneFrame);

		ShowTutorialPrompt(Player, ThrowPrompt, this);
	}

	UFUNCTION(NotBlueprintCallable)
	protected void OnPutDownDelegate(AHazePlayerCharacter Player, APickupActor PickupActor)
	{
		if(!bCapabilitesUnblocked)
		{
			bCapabilitesUnblocked = true;
			Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
		}

		RemoveTutorialPromptByInstigator(Player, this);

		Super::OnPutDownDelegate(Player, PickupActor);
	}

	UFUNCTION(NotBlueprintCallable)
	protected void OnThrownDelegate(AHazePlayerCharacter Player, APickupActor PickupActor)
	{
		Super::OnThrownDelegate(Player, PickupActor);

		StartLocation = GetActorLocation();
		CurrentRotation = GetActorRotation();
		CurrentLocation = GetActorLocation();
		CurrentFollowSpeed = 2000.f;
		DesiredFollowSpeed = CurrentFollowSpeed + 500;
		bFollowingSpline = true;

		RemoveTutorialPromptByInstigator(Player, this);

		if(!bCapabilitesUnblocked)
		{
			bCapabilitesUnblocked = true;
			Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
		}

		// Snap velocity acceleration to throw velocity; clamp to max speed
		AcceleratedVelocity.SnapTo(ThrowParams.ThrowVelocity.GetClampedToMaxSize(CurrentFollowSpeed));

		// Throw params need to be deleted to cancel air travel and cleanup throw
		PickupActor.ThrowParams = nullptr;
	}
}