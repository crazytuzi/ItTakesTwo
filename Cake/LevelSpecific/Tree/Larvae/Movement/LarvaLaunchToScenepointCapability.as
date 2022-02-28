import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.Tree.Larvae.Movement.LarvaMovementDataComponent;

class ULarvaLaunchToScenepointCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(n"Leaping");
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityDebugCategory = CapabilityTags::Movement;

	default TickGroup = ECapabilityTickGroups::LastMovement;
    default TickGroupOrder = 50;

	ULarvaMovementDataComponent LarvaMoveComp = nullptr;
	UScenepointComponent Scenepoint = nullptr;
    FHazeAcceleratedRotator Rotation;

	bool bHasLanded = false;
	FHazeAcceleratedVector LandingLocation;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		LarvaMoveComp = ULarvaMovementDataComponent::Get(Owner);
		ensure(LarvaMoveComp != nullptr);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (LarvaMoveComp.MoveType != ELarvaMovementType::Launch)
			return EHazeNetworkActivation::DontActivate;

		if (LarvaMoveComp.CurrentScenepoint == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		// To get timely behaviour, we run hatching locally and then start syncing up with crumbs when we've landed.
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (LarvaMoveComp.MoveType != ELarvaMovementType::Launch)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (LarvaMoveComp.CurrentScenepoint != Scenepoint)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(!MoveComp.CanCalculateMovement())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{	
		FVector WorldUp = MoveComp.WorldUp;
		Scenepoint = LarvaMoveComp.CurrentScenepoint;
		MoveComp.SetVelocity(GetLaunchVelocity(Scenepoint.WorldLocation, FMath::RandRange(1800.f, 2500.f)));
		Rotation.SnapTo(Owner.ActorRotation);
		Owner.BlockCapabilities(CapabilityTags::Collision, this);
		CharacterOwner.Mesh.SetRelativeRotation(FRotator::ZeroRotator);
		bHasLanded = false;

		LarvaMoveComp.UseNonPathfindingCollisionSolver();
	}

	FVector GetLaunchVelocity(const FVector& TargetLoc, float DefaultSpeed)
	{
		FVector OwnLoc = Owner.GetActorLocation();
		FVector ToTarget = (TargetLoc - OwnLoc);
		
		// We want to land a bit short of target so we'll slide up to it.
		ToTarget -= ToTarget.GetSafeNormal2D() * 200.f;
		
		float Speed = DefaultSpeed;
		if (MoveComp.GravityMagnitude == 0.f)
			return ToTarget.GetSafeNormal() * Speed;

		FVector WorldUp = MoveComp.WorldUp;
		float VDist = ToTarget.DotProduct(WorldUp);
		FVector ToTargetHorizontal = ToTarget - WorldUp * VDist;
		float HDist = ToTargetHorizontal.Size();
		float Gravity = MoveComp.GravityMagnitude;
		float SpeedSqr = FMath::Square(Speed);
		float SpeedQuad = FMath::Square(SpeedSqr);

		// Calculate aim height needed to hit target 
		float LaunchElevation;
		float Discriminant = SpeedQuad - Gravity * ((Gravity * FMath::Square(HDist)) + (2.f * VDist * SpeedSqr));
		if (Discriminant < 0.f)
		{
			// Can't reach target, increase velocity appropriately
			SpeedSqr = Gravity * (VDist + FMath::Sqrt(FMath::Square(VDist) + FMath::Square(HDist)));				
			Speed = FMath::Sqrt(SpeedSqr);
			LaunchElevation = SpeedSqr / Gravity;
		}
		else
		{
			// `SpeedSqr +` for high parabola
			LaunchElevation = (SpeedSqr + FMath::Sqrt(Discriminant)) / Gravity;
		}
	
		FVector LaunchDir = (ToTargetHorizontal + WorldUp * LaunchElevation).GetSafeNormal();
		return LaunchDir * Speed;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{	
		Owner.UnblockCapabilities(CapabilityTags::Collision, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Local movement
		if (!bHasLanded && HasLanded())
		{
			bHasLanded = true;
			LandingLocation.SnapTo(Owner.ActorLocation, MoveComp.Velocity);
		}

		FHazeFrameMovement Move = MoveComp.MakeFrameMovement(n"LaunchTo");
		if (bHasLanded)
		{
			FVector TargetLoc = Scenepoint.WorldLocation;
			TargetLoc.Z = Owner.ActorLocation.Z;
			LandingLocation.Value = Owner.ActorLocation;
			LandingLocation.AccelerateTo(TargetLoc, 0.5f, DeltaTime);
			Move.ApplyDelta(LandingLocation.Value - Owner.ActorLocation);
		}
		else
		{
			// Parabolic trajectory
			Move.OverrideStepUpHeight(0.f);
			Move.OverrideStepDownHeight(0.f);
			Move.ApplyActorHorizontalVelocity();
		}
		Move.ApplyActorVerticalVelocity();
		Move.ApplyGravityAcceleration();
		Rotation.Value = Owner.ActorRotation; // In case this is changed by outside system
		Rotation.AccelerateTo(Scenepoint.WorldRotation, 1.f, DeltaTime); 
		Move.SetRotation(FQuat(Rotation.Value));
		MoveCharacter(Move, n"LaunchTo");
	}

	bool HasLanded()
	{
		if (Owner.ActorLocation.Z > Scenepoint.WorldLocation.Z + 100.f)
			return false;
		if (Owner.ActorLocation.DistSquared2D(Scenepoint.WorldLocation) > FMath::Square(300.f))
			return false;
		return true;
	}
};
