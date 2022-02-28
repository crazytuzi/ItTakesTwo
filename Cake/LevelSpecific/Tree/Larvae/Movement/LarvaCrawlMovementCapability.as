import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.Tree.Larvae.Movement.LarvaMovementDataComponent;
import Cake.LevelSpecific.Tree.Larvae.Settings.LarvaComposableSettings;
import Cake.LevelSpecific.Tree.Larvae.Behaviours.LarvaBehaviourComponent;

class ULarvaCrawlMovementCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(n"Crawling");
	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = ECapabilityTickGroups::LastMovement;
    default TickGroupOrder = 100;

    ULarvaMovementDataComponent MoveDataComp = nullptr;
	ULarvaBehaviourComponent BehaviourComp = nullptr;
	UCapsuleComponent CollisionComp = nullptr;
	UHaze2DPathfindingComponent PathfindingComp = nullptr;
	ULarvaComposableSettings Settings;

    FHazeAcceleratedFloat Speed;
    FHazeAcceleratedQuat Rotation;
    FHazeAcceleratedQuat UpRotation;
    FHazeAcceleratedQuat MeshRotation;

	FHazeAcceleratedVector RepulseVelocity;
	FHazeAcceleratedVector CollisionRepulseVelocity;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
        MoveDataComp = ULarvaMovementDataComponent::Get(Owner);
        BehaviourComp = ULarvaBehaviourComponent::Get(Owner);
		CollisionComp = UCapsuleComponent::Get(Owner);
		PathfindingComp = UHaze2DPathfindingComponent::Get(Owner);
		Settings = ULarvaComposableSettings::GetSettings(Owner);
        ensure((MoveDataComp != nullptr) && (CollisionComp != nullptr) && (Settings != nullptr) && (BehaviourComp != nullptr) && (PathfindingComp != nullptr));
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        if (MoveDataComp.MoveType != ELarvaMovementType::Crawl)
            return EHazeNetworkActivation::DontActivate;
		if (!MoveComp.CanCalculateMovement())
    		return EHazeNetworkActivation::DontActivate;
		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
        if (MoveDataComp.MoveType != ELarvaMovementType::Crawl)
            return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		if (!MoveComp.CanCalculateMovement())
			return RemoteLocalControlCrumbDeactivation();
		return EHazeNetworkDeactivation::DontDeactivate;
	}

    UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
    {
        Speed.SnapTo(Owner.GetActualVelocity().DotProduct(Owner.GetActorForwardVector()));
        Rotation.SnapTo(FQuat(Owner.GetActorRotation()));
        UpRotation.SnapTo(MoveComp.WorldUp.ToOrientationQuat());
		MeshRotation.SnapTo(Rotation.Value);
		MoveDataComp.UsePathfindingCollisionSolver();
    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
        FHazeFrameMovement MoveData = MoveComp.MakeFrameMovement(n"LarvaCrawlMovement");

		// Move towards destination
		if (HasControl())
		{
			FVector ToDest = FVector::ZeroVector;
			FVector Velocity = FVector::ZeroVector;
			if (MoveDataComp.bHasDestination)
			{
				// We have a destination
				FVector Destination = MoveDataComp.Destination;
				ToDest = Destination - Owner.GetActorLocation();
				ToDest.Z = 0.f; // Larva think in two dimensions, much like Khan

				// Accelerate when moving towards destination, otherwise come to a stop
				float TargetSpeed = (ToDest.SizeSquared() > 40.f*40.f) ? Settings.CrawlSpeed : 0.f; 
				Speed.AccelerateTo(TargetSpeed, 0.5f, DeltaSeconds);

				if (!ToDest.IsNearlyZero(1.f))
					Velocity = ToDest.GetSafeNormal() * Speed.Value;
			}
			else
			{
				// No destination, come to a stop
				Speed.AccelerateTo(0.f, 0.5f, DeltaSeconds);
				Velocity = Owner.GetActorForwardVector() * Speed.Value; 
			}

			if (!ToDest.IsZero())
			{
				// Turn towards destination
				FQuat TargetRotation = Velocity.ToOrientationQuat(); 
				Rotation.Value = FQuat(Owner.GetActorRotation());
				Rotation.AccelerateTo(TargetRotation, 1.5f, DeltaSeconds);
				MoveComp.SetTargetFacingRotation(Rotation.Value); 
			}

			if (MoveDataComp.bTurnOnly)
				Velocity = FVector::ZeroVector;
			else if (!MoveDataComp.bUsingPathfindingCollision)
				Velocity = RepulseFromCollision(Velocity, DeltaSeconds);

			Velocity = RepulseFromOtherLarvae(Velocity, DeltaSeconds);
			Velocity.Z = 0.f;

			MoveData.ApplyVelocity(Velocity);
			MoveData.ApplyActorVerticalVelocity();
			MoveData.ApplyGravityAcceleration();
			MoveData.ApplyTargetRotationDelta();
		}
		else
		{
			// Remote, follow crumbs
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaSeconds, ConsumedParams);
			MoveData.ApplyConsumedCrumbData(ConsumedParams);
		}
        MoveCharacter(MoveData, n"Crawl");
		CrumbComp.LeaveMovementCrumb();

        // Consume destination
        MoveDataComp.bHasDestination = false;

		// Rotate mesh to match ground 
		// TODO: do this separately for each bone, so it'll hug ground
		FQuat TargetRot = GetGroundForwardRotation();
		MeshRotation.AccelerateTo(TargetRot, 1.0f, DeltaSeconds);
		CharacterOwner.Mesh.WorldRotation = MeshRotation.Value.Rotator();
	}

    FQuat GetGroundForwardRotation()
    {
		if (MoveComp.DownHit.bBlockingHit)
		{
			// On ground, follow slope
			FVector SlopeFwd = Math::ConstrainVectorToSlope(Owner.ActorForwardVector, MoveComp.DownHit.Normal, FVector::UpVector);
			return SlopeFwd.ToOrientationQuat();			
		}

		// Falling
        return FQuat(Owner.ActorRotation);
    }

	FVector RepulseFromOtherLarvae(const FVector& Velocity, float DeltaSeconds)
	{
		FVector RepulseTarget = FVector::ZeroVector;
		TSet<AHazeActor> Larvae = BehaviourComp.Team.GetMembers();
		const FVector OwnLoc = Owner.ActorLocation;
		const float RepulseMaxDistance = CollisionComp.GetScaledCapsuleRadius() + Settings.RepulseDistance;
		const float RepulseMinDistance = CollisionComp.GetScaledCapsuleRadius();
		const float RepulseFactor = 1.f ;
		const FVector WorldUp = MoveComp.WorldUp;
		for (AHazeActor Larva : Larvae)
		{
			if (Larva == Owner)
				continue;
			if (Larva.IsActorDisabled())
				continue;
			FVector FromOther = OwnLoc - Larva.ActorLocation;
			if (!FromOther.IsNearlyZero(RepulseMaxDistance))
				continue;
			float OtherDist = FromOther.Size();
			FVector RepulseVec = Math::ConstrainVectorToPlane(FromOther, WorldUp);
			float RepulseSpeed = Settings.RepulseSpeed * FMath::Min(1.f, 1.f - FMath::Square((OtherDist - RepulseMinDistance) / (RepulseMaxDistance - RepulseMinDistance)));
			RepulseTarget += RepulseVec.GetSafeNormal() * RepulseSpeed;
		}

		// Check that we won't get pushed out of path any time soon
		if ((RepulseTarget != FVector::ZeroVector) && 
			!IsPathFindingValidRepulsion(Owner.ActorLocation + (RepulseTarget + Velocity) * 0.5f))
			return Velocity;

		RepulseVelocity.AccelerateTo(RepulseTarget, 1.f, DeltaSeconds);
		if (!RepulseVelocity.Value.IsZero())		
			return (Velocity + RepulseVelocity.Value).GetClampedToMaxSize(Settings.CrawlSpeed);	

		return Velocity;
	}

	bool IsPathFindingValidRepulsion(FVector RepulseLoc)
	{
		if (!MoveDataComp.bUsingPathfindingCollision)
			return true;

		// Only push when we have a valid path location
		if (!MoveDataComp.Path.Locations.IsValidIndex(MoveDataComp.PathIndex))
			return false; 

		// Don't push outside of nearby path polys (good enough, and cheaper than checking entire navmesh)
		for (int i = 0; i < 3; i++)
		{
			int iPath = MoveDataComp.PathIndex + (((i % 2) == 0) ? i : -i-1) / 2; // 0,-1,1...
			if (MoveDataComp.Path.Locations.IsValidIndex(iPath) &&
				PathfindingComp.IsWithinSamePolygon(RepulseLoc, MoveDataComp.Path.Locations[iPath]))
				return true;
		}
		return false;		
	}

	FVector RepulseFromCollision(const FVector& Velocity, float DeltaSeconds)
	{
		if (MoveComp.ForwardHit.bBlockingHit)
		{
			FVector Origin = Owner.ActorLocation + FVector(0,0,100);

			// Bumped something, try to repulse around it
			FVector RepulseDir = MoveComp.ForwardHit.Normal;
			if (RepulseDir.DotProduct(Owner.ActorForwardVector) < 0.f)
			{
				// Clamp at owner right/left 
				if (CollisionRepulseVelocity.Value.IsNearlyZero(10.f))
				{
					// Just started repulsion, use direction normal points toward
					RepulseDir =  Owner.ActorRightVector * ((RepulseDir.DotProduct(Owner.ActorRightVector) > 0.f) ? 1.f : -1.f);
				}
				else
				{
					// Maintain momentum
					RepulseDir = Owner.ActorRightVector * ((CollisionRepulseVelocity.Value.DotProduct(Owner.ActorRightVector) > 0.f) ? 1.f : -1.f);
				}
			}
			CollisionRepulseVelocity.AccelerateTo(RepulseDir * 500.f, 0.5f, DeltaSeconds);
		}
		else
		{
			// No collision, accelerate out repulsion
			CollisionRepulseVelocity.AccelerateTo(FVector::ZeroVector, 1.f, DeltaSeconds);
		} 

		if (!CollisionRepulseVelocity.Value.IsZero())
			return (Velocity + CollisionRepulseVelocity.Value).GetClampedToMaxSize(Settings.CrawlSpeed);	

		return Velocity;
	}
};

