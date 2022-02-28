import Cake.LevelSpecific.Shed.Vacuum.VacuumHoseActor;
import Cake.LevelSpecific.Shed.Vacuum.VacuumStatics;
import Vino.Trajectory.TrajectoryStatics;
import Vino.Trajectory.TrajectoryDrawer;
import Cake.LevelSpecific.Shed.Vacuum.VacuumShootingActor;

class UVacuumShootingComponent : UActorComponent
{
	UPROPERTY()
	AVacuumShootingActor ShootingActor;

    UPROPERTY(NotVisible)
    USceneComponent AttachmentPoint;

    UPROPERTY(NotVisible)
    FVector DebrisLaunchForce;

    AVacuumHoseActor Hose;
	UTrajectoryDrawer TrajectoryDrawer;

    UPROPERTY()
    EVacuumMountLocation ShootingNozzle;

	UPROPERTY()
	float ForwardVectorModifier = 3250.f;

	UPROPERTY()
	FVector2D PitchModiferRange = FVector2D(-2000.f, -1500.f);

	UPROPERTY()
	FVector2D HeightRange = FVector2D(0.f, 500.f);

	bool bEnabled = true;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        Hose = Cast<AVacuumHoseActor>(Owner);
		USceneComponent CurrentAttachmentPoint = ShootingNozzle == EVacuumMountLocation::Front ? Hose.FrontAttachmentPoint : Hose.BackAttachmentPoint;
		ShootingActor.AttachToComponent(CurrentAttachmentPoint);
		TrajectoryDrawer = UTrajectoryDrawer::GetOrCreate(ShootingActor);
    }

	UFUNCTION()
	void SetTrajectoryEnabled(bool bEnable)
	{
		bEnabled = bEnable;
		SetComponentTickEnabled(bEnabled);
	}

    UFUNCTION(BlueprintOverride)
    void Tick(float Delta)
    {
        CalculateObjectLaunchVelocity();
    }

    void CalculateObjectLaunchVelocity()
	{
		USceneComponent CurrentAttachmentPoint = ShootingNozzle == EVacuumMountLocation::Front ? Hose.FrontAttachmentPoint : Hose.BackAttachmentPoint;

		float AttachmentPointPitch = CurrentAttachmentPoint.WorldRotation.Pitch;

		FVector StartLocation = CurrentAttachmentPoint.WorldLocation;
		FVector EndLocation = StartLocation + (CurrentAttachmentPoint.ForwardVector * ForwardVectorModifier);
		float PitchModifier = FMath::GetMappedRangeValueClamped(FVector2D(0.f, 50.f), PitchModiferRange, FMath::Abs(AttachmentPointPitch));
		EndLocation = EndLocation + FVector(0.f, 0.f, PitchModifier);

		DebrisLaunchForce = CalculateVelocityForPathWithHeight(StartLocation, EndLocation, 980.f, FMath::GetMappedRangeValueClamped(FVector2D(0.f, 50.f), HeightRange, AttachmentPointPitch));

		FTrajectoryPoints TrajectoryPositions =  CalculateTrajectory(CurrentAttachmentPoint.WorldLocation, 10000.f, DebrisLaunchForce, 980.f, 1.f);

		if (GetShootingPlayer() != nullptr)
		{
			FHitResult Hit;
			TArray<AActor> ActorsToIgnore;
			ActorsToIgnore.Add(Owner);
			ActorsToIgnore.Add(Game::GetMay());
			ActorsToIgnore.Add(Game::GetCody());

			for (int Index = 0, Count = TrajectoryPositions.Positions.Num() -2; Index < Count; ++ Index)
			{
				System::LineTraceSingle(TrajectoryPositions.Positions[Index], TrajectoryPositions.Positions[Index+1], ETraceTypeQuery::Visibility, false, ActorsToIgnore, EDrawDebugTrace::None, Hit, true);
				if (Hit.bBlockingHit)
					break;
			}

			FVector ToHit = Hit.Location - CurrentAttachmentPoint.WorldLocation;
			ToHit = ToHit.ConstrainToPlane(FVector::UpVector);
			float TrajectorySize = ToHit.Size();
			TrajectoryDrawer.DrawTrajectory(CurrentAttachmentPoint.WorldLocation, TrajectorySize, DebrisLaunchForce, 980.f, 15.f, FLinearColor::Red, GetShootingPlayer(), 10.f);
		}
	}

    AHazePlayerCharacter GetShootingPlayer()
	{
		if (Hose.FrontPlayer != nullptr && ShootingNozzle == EVacuumMountLocation::Front)
			return Hose.FrontPlayer;
		else if (Hose.BackPlayer != nullptr && ShootingNozzle == EVacuumMountLocation::Back)
			return Hose.BackPlayer;
		else
			return nullptr;
	}
}