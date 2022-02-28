
// import Peanuts.Spline.SplineComponent;
// import Cake.LevelSpecific.SnowGlobe.Magnetic.Physics.MagneticPhysicsObjectLockedToSplineSettings;
// import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticMoveableComponent;


// class MagneticPhysicsObjectLockedToSplineCapability : UHazeCapability
// {
// 	default CapabilityTags.Add(n"MagnetCapability");
// 	default CapabilityDebugCategory = CapabilityTags::LevelSpecific;
// 	default TickGroup = ECapabilityTickGroups::AfterGamePlay;

// 	FVector Velocity;

// 	UHazeSplineComponent Spline;
// 	UMagneticComponent Magnet;
// 	UMeshComponent Mesh;

// 	FVector Forwardvector;

// 	UMagneticPhysicsObjectLockedToSplineSettings Settings;

// 	float OnePlayerLetGoTimer = 0;

// 	UFUNCTION(BlueprintOverride)
// 	void Setup(FCapabilitySetupParams SetupParams)
// 	{
//         Magnet = UMagneticComponent::GetOrCreate(Owner);
// 		Spline = UHazeSplineComponent::Get(Owner);
// 		Mesh = UMeshComponent::Get(Owner);
// 		Settings = UMagneticPhysicsObjectLockedToSplineSettings::Get(Owner);

// 		Forwardvector = Spline.GetLocationAtDistanceAlongSpline(0.f, ESplineCoordinateSpace::World) - Spline.GetLocationAtDistanceAlongSpline(Spline.GetSplineLength(), ESplineCoordinateSpace::World);
// 		Forwardvector.Normalize();
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	EHazeNetworkActivation ShouldActivate() const
// 	{
//         if (Magnet.GetInfluencerNum() > 0 || FMath::Abs(Settings.ConstantVelocity) > 0)
//         {
// 			return EHazeNetworkActivation::ActivateFromControl;
//         }

// 		else
// 		{
// 			return EHazeNetworkActivation::DontActivate;
// 		}
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	EHazeNetworkDeactivation ShouldDeactivate() const
// 	{
//         if (Magnet.GetInfluencerNum() < 0 || Velocity.Size() < 0.01f)
//         {
// 			return EHazeNetworkDeactivation::DeactivateFromControl;
//         }

// 		else
// 		{
// 			return EHazeNetworkDeactivation::DontDeactivate;
// 		}
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void TickActive(float DeltaTime)
// 	{
// 		MoveCubeOnSpline(DeltaTime);
// 	}

// 	void MoveCubeOnSpline(float DeltaTime)
// 	{
// 		TArray<FMagnetInfluencer> Influencers;
// 		Magnet.GetInfluencers(Influencers);
// 		if (Influencers.Num() > 0)
// 		{
// 			Velocity = FMath::Lerp(Velocity, GetForceDirection() * Settings.MaxSpeed, DeltaTime);
// 		}

// 		else 
// 		{
// 			Velocity = FMath::Lerp(Velocity, GetForceDirection() * Settings.ConstantVelocity, DeltaTime);
// 		}
// 		Velocity *= Settings.Friction;
// 		Velocity = Velocity.GetClampedToMaxSize(Settings.MaxSpeed);

// 		FVector Desiredlocation = Mesh.GetWorldLocation() + Velocity;
// 		Desiredlocation = Spline.FindLocationClosestToWorldLocation(Desiredlocation, ESplineCoordinateSpace::World);
// 		Mesh.SetWorldLocation(Desiredlocation);
// 	}

// 	FVector GetForceDirection()
// 	{
// 		FVector Forcedir;
// 		TArray<FMagnetInfluencer> Influencers;
// 		Magnet.GetInfluencers(Influencers);
// 		for (const FMagnetInfluencer& i : Influencers)
// 		{
// 			if (Settings.bIsAttractedByBoth && i.PositiveForce > 0 ||
// 			Settings.bIsAttractedByBoth && i.NegativeForce > 0)
// 			{
// 				Forcedir -= i.Instigator.ActorLocation - Mesh.GetWorldLocation();
// 			}

// 			else if (i.PositiveForce > 0)
// 			{
// 				Forcedir += i.Instigator.ActorLocation - Mesh.GetWorldLocation();
// 			}
// 			else if (i.NegativeForce > 0)
// 			{
// 				Forcedir -= i.Instigator.ActorLocation - Mesh.GetWorldLocation();
// 			}
// 		}
// 		FVector ConstantVelocityVector = FVector::ZeroVector;
// 		ConstantVelocityVector += Forwardvector * Settings.ConstantVelocity;
// 		Forcedir += ConstantVelocityVector;

// 		return Forcedir.GetSafeNormal();
// 	}
// }