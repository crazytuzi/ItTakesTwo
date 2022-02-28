import Cake.LevelSpecific.Garden.ControllablePlants.TurretPlant.TurretPlant;
import Cake.LevelSpecific.Garden.ControllablePlants.ControllablePlantsComponent;

class UTurretPlantRotationCapability : UHazeCapability
{
	ATurretPlant TurretPlant;
	UHazeCrumbComponent CrumbComponent;
	UCameraUserComponent CameraUser;
	UControllablePlantsComponent PlantsComp;

	FQuat CurrentRotation;
	TArray<AActor> ActorsToIgnore;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		TurretPlant = Cast<ATurretPlant>(Owner);
		CrumbComponent = UHazeCrumbComponent::Get(Owner);
		CameraUser = UCameraUserComponent::Get(TurretPlant.OwnerPlayer);
		PlantsComp = UControllablePlantsComponent::Get(TurretPlant.OwnerPlayer);

		ActorsToIgnore.Add(TurretPlant);
		ActorsToIgnore.Add(TurretPlant.OwnerPlayer);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!TurretPlant.IsPlantActive)
			return EHazeNetworkActivation::DontActivate;

		if(!CameraUser.CanControlCamera())
			return EHazeNetworkActivation::DontActivate;
        
        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		CurrentRotation = Owner.ActorRotation.Quaternion();
		CrumbComponent.IncludeCustomParamsInActorReplication(FVector::ZeroVector, FRotator::ZeroRotator, this);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!TurretPlant.IsPlantActive)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		CrumbComponent.RemoveCustomParamsFromActorReplication(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
		{
			FHitResult Hit;
			const FVector NeckLocation = TurretPlant.TurretBase.GetSocketLocation(n"Neck");
			
			FVector TraceStartLoc = TurretPlant.Camera.ViewLocation;
			FVector TraceEndLoc = TurretPlant.Camera.ViewLocation + (TurretPlant.Camera.ViewRotation.GetForwardVector() * 100000.0f);

			if(System::LineTraceSingle(TraceStartLoc, TraceEndLoc, ETraceTypeQuery::Visibility, false, ActorsToIgnore, EDrawDebugTrace::None, Hit, false))
			{
				TraceEndLoc = Hit.Location;
			}

			const FVector Loc = TurretPlant.TurretBase.GetSocketLocation(n"RightArm");
			const float BodyHeightWorld = Loc.Z;
			const FVector BodyPlane = FVector(NeckLocation.X, NeckLocation.Y, BodyHeightWorld);
			
			const FTransform RightArmTransform = TurretPlant.RightArmTransform;

			const FVector DirectionToRightArmLoc = (TraceEndLoc - RightArmTransform.Location).GetSafeNormal();

			FVector DirectionFromArms = (TraceEndLoc - BodyPlane).GetSafeNormal;

			float ProximityTargetAimAdjust = DirectionFromArms.AngularDistance(DirectionToRightArmLoc);

			FQuat TargetRotation = (TraceEndLoc - TurretPlant.ActorLocation).ConstrainToPlane(FVector::UpVector).ToOrientationQuat();
			CurrentRotation = FQuat::Slerp(CurrentRotation, TargetRotation, 8.0f * DeltaTime);
			const FVector DirectionToLook = (TraceEndLoc - NeckLocation).GetSafeNormal();
			const float PreviousAimPitch = TurretPlant.CurrentAimPitch;
			TurretPlant.CurrentAimPitch = FMath::FInterpConstantTo(TurretPlant.CurrentAimPitch, DirectionToLook.Rotation().Pitch, DeltaTime, 120.0f);
			TurretPlant.CurrentAimYaw = CurrentRotation.Vector().X;
			TurretPlant.YawRotationDelta = FMath::FindDeltaAngleDegrees(TargetRotation.Rotator().Yaw, CurrentRotation.Rotator().Yaw);
			TurretPlant.PitchRotationDelta = FMath::Abs(TurretPlant.CurrentAimPitch - PreviousAimPitch);
			FVector V = FVector(TurretPlant.CurrentAimPitch, TurretPlant.CurrentAimYaw, TurretPlant.YawRotationDelta);
			CrumbComponent.SetCustomCrumbVector(V);
			TurretPlant.SetActorRotation(CurrentRotation);
			CrumbComponent.LeaveMovementCrumb();

			TurretPlant.TargetProximityOffset.Value = FMath::FInterpConstantTo(TurretPlant.TargetProximityOffset.Value, ProximityTargetAimAdjust, DeltaTime, 1.0f);
			TurretPlant.AimAdjustX = TurretPlant.TargetProximityOffset.Value;
		}
		else
		{
			FHazeActorReplicationFinalized Params;
			CrumbComponent.ConsumeCrumbTrailMovement(DeltaTime, Params);
			
			TurretPlant.SetActorRotation(Params.Rotation);

			const float PreviousAimPitch = TurretPlant.CurrentAimPitch;
			TurretPlant.CurrentAimPitch = Params.CustomCrumbVector.X;
			TurretPlant.CurrentAimYaw = Params.CustomCrumbVector.Y;
			TurretPlant.YawRotationDelta = Params.CustomCrumbVector.Z;
			TurretPlant.AimAdjustX = TurretPlant.TargetProximityOffset.Value;
			TurretPlant.PitchRotationDelta = FMath::Abs(TurretPlant.CurrentAimPitch - PreviousAimPitch);
		}
	}
}
