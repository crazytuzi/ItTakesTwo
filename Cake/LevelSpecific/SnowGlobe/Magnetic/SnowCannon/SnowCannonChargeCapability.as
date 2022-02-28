
import Cake.LevelSpecific.SnowGlobe.Magnetic.SnowCannon.SnowCannonActor;
import Vino.Trajectory.TrajectoryStatics;
import Vino.Trajectory.TrajectoryDrawer;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagnetSnowCanonComponent;

class USnowCannonChargeCapability : UHazeCapability
{
	default CapabilityTags.Add(n"MagnetCapability");
	default CapabilityDebugCategory = CapabilityTags::LevelSpecific;
	default TickGroup = ECapabilityTickGroups::AfterGamePlay;
	default TickGroupOrder = 120;

    UPrimitiveComponent MeshComponent;
	UMagnetSnowCanonComponent MagnetComponent;
	ASnowCannonActor SnowCannon;
	UHazeAkComponent HazeAkComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
        MagnetComponent = UMagnetSnowCanonComponent::Get(Owner);
        MeshComponent = Cast<UPrimitiveComponent>(Owner.RootComponent);
		SnowCannon = Cast<ASnowCannonActor>(Owner);
		HazeAkComp = UHazeAkComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        if (!IsActioning(n"PullingSnowCannon"))
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!IsActioning(n"PullingSnowCannon"))
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if(SnowCannon != nullptr && SnowCannon.Crosshair != nullptr)
			SnowCannon.Crosshair.SetHiddenInGame(true, true);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FTrajectoryPoints Points;
		float TrajectorySize = 100000.0f;
		FHitResult Hit;
		FVector Direction;
		TArray<AActor> ActorsToIgnore;
		Direction = SnowCannon.ShootLocation.GetForwardVector();

		Points = CalculateTrajectory(SnowCannon.ShootLocation.WorldLocation, TrajectorySize, Direction * SnowCannon.ProjectileSpeed, SnowCannon.ProjectileGravity, 1.0f);

		for(int i = 0; i < Points.Num()-1; i++)
		{
			System::LineTraceSingle(Points.Positions[i], Points.Positions[i+1], ETraceTypeQuery::Visibility, false, ActorsToIgnore, EDrawDebugTrace::None, Hit, true);
			if(Hit.bBlockingHit)
			{
				break;
			}
		}

		if(Hit.bBlockingHit)
		{
			SnowCannon.Crosshair.SetHiddenInGame(false, true);
			SnowCannon.Crosshair.SetWorldLocationAndRotation(Hit.Location - (Direction * 5.0f), Math::MakeRotFromX(Hit.Normal));

			FVector ToHit = Hit.Location - SnowCannon.ShootLocation.WorldLocation;
			ToHit = ToHit.ConstrainToPlane(FVector::UpVector);
			TrajectorySize = ToHit.Size();

			SnowCannon.bValidAimTarget = Hit.Component.HasTag(n"IceMagnetSlideable");

			// Set trajectory 
			DrawAimTrajectory(TrajectorySize, SnowCannon.bValidAimTarget);
		}
		else
		{
			SnowCannon.Crosshair.SetHiddenInGame(true, true);
			SnowCannon.Crosshair.SetWorldLocation(SnowCannon.ActorLocation + Direction * 1000.f);
			SnowCannon.bValidAimTarget = false;
		}
	}

	void DrawAimTrajectory(float TrajectorySize, bool bSurfaceIsMagnetStickable)
	{
		bool bTrajectoryIsValid = bSurfaceIsMagnetStickable && !SnowCannon.bInCooldown && SnowCannon.bThumperCocked;

		SnowCannon.CrosshairMesh.SetScalarParameterValueOnMaterialIndex(0, n"IsValidTarget", bTrajectoryIsValid ? 1.f : 0.f);
		SnowCannon.TrajectoryDrawer.DrawTrajectory(SnowCannon.ShootLocation.WorldLocation, TrajectorySize, SnowCannon.ShootLocation.ForwardVector * SnowCannon.ProjectileSpeed, SnowCannon.ProjectileGravity, 20.f, FLinearColor::White, Game::GetPlayer(SnowCannon.OwningPlayer), bTrajectoryIsValid = bTrajectoryIsValid);
	}
}