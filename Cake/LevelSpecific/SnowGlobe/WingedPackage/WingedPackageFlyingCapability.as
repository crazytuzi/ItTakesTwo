import Cake.LevelSpecific.SnowGlobe.WingedPackage.WingedPackage;
import Vino.Pickups.PlayerPickupComponent;

class UWingedPackageFlyingCapability : UHazeCapability
{
	default CapabilityTags.Add(n"LevelSpecific");
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(FMagneticTags::WingedMagnetPackageFlight);

	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 110;

	default CapabilityDebugCategory = CapabilityTags::Movement;

	float Speed = 650;
	float FlapTimer;

	FVector FlapDir;

	AWingedPackage Package;
	UHazeMovementComponent MoveComp;
	UMagneticComponent MagneticComponent;

	float DistanceAlongSpline;
	FVector LastMoveDir = FVector::ZeroVector;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Package = Cast<AWingedPackage>(Owner);
		MoveComp = UHazeMovementComponent::GetOrCreate(Owner);
		MagneticComponent = UMagneticComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(Package.IsPickedUp())
			return EHazeNetworkActivation::DontActivate;

		if(Package.bIsBeingInteractedWith)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(MagneticComponent.GetInfluencerNum() > 0)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		
		if(Package.IsPickedUp())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(Package.bIsBeingInteractedWith)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{

	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		FVector MoveTarget =GetMoveTarget(DeltaTime);
		if (MoveComp.CanCalculateMovement())
		{
			FHazeFrameMovement Movement = MoveComp.MakeFrameMovement(n"PackageMovement");
			FVector MoveDir = FVector::ZeroVector;
			FVector DesiredMoveDir = MoveTarget - Owner.ActorLocation;

			MoveDir = FMath::Lerp(LastMoveDir, DesiredMoveDir, DeltaTime);
			MoveDir.Normalize();
			MoveDir *= DeltaTime * Speed;
			MoveDir += FlapDir * DeltaTime;

			LastMoveDir = MoveDir;

			FQuat Rotation = Math::MakeQuatFromX(MoveDir);

			Movement.SetRotation(Rotation);
			Movement.ApplyDelta(MoveDir);
			MoveComp.Move(Movement);
		}

		if (!GetIsAboveTarget(MoveTarget))
		{
			FlapUpdate(DeltaTime);
		}

		else
		{
			FlapDir = FVector::UpVector * - 0.982f + FVector::ForwardVector;
		}
	}

	void FlapUpdate(float Deltatime)
	{
		FlapTimer += Deltatime;
		FlapDir *= 0.7f;

		if (FlapTimer > FMath::RandRange(-0.2f, 0.1f) + 0.6f)
		{
			Package.FlapWings();
			FlapTimer = 0;
			FlapDir = FVector::UpVector * 3000;
		}
	}

	bool GetIsAboveTarget(FVector Target)
	{
		float Distance = Target.Distance(Package.ActorLocation);

		FVector XYTarget = Target;
		XYTarget.Z = Package.ActorLocation.Z;
		float XYDistance = XYTarget.Distance(Package.ActorLocation);

		if (Target.Z < Package.ActorLocation.Z && FMath::Abs(Target.Z - Package.ActorLocation.Z) > 300)
		{
			return true;
		}

		return false;
	}

	bool GetIsCloseToSpline() property
	{
		float ClosestPointOnSpline = Package.FlyInCircleSplineActor.Spline.GetDistanceAlongSplineAtWorldLocation(Package.ActorLocation);
		FVector WorldlocationAtDistanceAlongSpline = Package.FlyInCircleSplineActor.Spline.GetLocationAtDistanceAlongSpline(ClosestPointOnSpline, ESplineCoordinateSpace::World);

		float DistanceToSpline = WorldlocationAtDistanceAlongSpline.Distance(Package.ActorLocation);

		return DistanceToSpline  < 700;
	}

	FVector GetMoveTarget(float DeltaTime)
	{
		if (IsCloseToSpline)
		{
			DistanceAlongSpline = Package.FlyInCircleSplineActor.Spline.GetDistanceAlongSplineAtWorldLocation(Package.ActorLocation);
			DistanceAlongSpline += 7500 * DeltaTime;

			if(DistanceAlongSpline > Package.FlyInCircleSplineActor.Spline.SplineLength)
			{
				DistanceAlongSpline = DistanceAlongSpline - Package.FlyInCircleSplineActor.Spline.SplineLength;
			}
			return Package.FlyInCircleSplineActor.Spline.GetLocationAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World);
		}

		else
		{
			float ClosestPointOnSpline = Package.FlyInCircleSplineActor.Spline.GetDistanceAlongSplineAtWorldLocation(Package.ActorLocation);
			FVector WorldlocationAtDistanceAlongSpline = Package.FlyInCircleSplineActor.Spline.GetLocationAtDistanceAlongSpline(ClosestPointOnSpline, ESplineCoordinateSpace::World);

			DistanceAlongSpline = ClosestPointOnSpline;
			
			return WorldlocationAtDistanceAlongSpline;
		}
	}
}