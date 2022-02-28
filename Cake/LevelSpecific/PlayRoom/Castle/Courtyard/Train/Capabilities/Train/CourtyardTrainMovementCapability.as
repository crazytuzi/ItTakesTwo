import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.Train.CourtyardTrain;

class UCourtyardTrainMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Gameplay");

	//default CapabilityDebugCategory = n"Example";
	
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 100;

	ACourtyardTrain Train;
	UHazeSplineFollowComponent SplineFollowComp;
	UHazeCrumbComponent CrumbComp;

	FHazeAcceleratedRotator AcceleratedTrainRotation;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Train = Cast<ACourtyardTrain>(Owner);
		SplineFollowComp = UHazeSplineFollowComponent::GetOrCreate(Owner);
		CrumbComp = UHazeCrumbComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		//SplineFollowComp.ActivateSplineMovement(Train.Track.Spline, true);
		FHazeSplineSystemPosition Position;
		Position.FromData(Train.Track.Spline, Train.DistanceAlongSpline, true);
		SplineFollowComp.ActivateSplineMovement(Position);
		SplineFollowComp.IncludeSplineInActorReplication(this);

		AcceleratedTrainRotation.SnapTo(Train.ActorRotation);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SplineFollowComp.DeactivateSplineMovement();
		SplineFollowComp.RemoveSplineFromActorReplication(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		// Update speed and move follow comp
		if (HasControl())
		{
			FHazeSplineSystemPosition Position;
			SplineFollowComp.UpdateSplineMovement(Train.CurrentSpeed * DeltaTime, Position);
			CrumbComp.LeaveMovementCrumb();
		}
		else
		{
			float DistanceBefore = SplineFollowComp.Position.DistanceAlongSpline;

			FHazeActorReplicationFinalized ReplicationFinalized;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ReplicationFinalized);
			SplineFollowComp.UpdateReplicatedSplineMovement(ReplicationFinalized);

			float DistanceAfter = SplineFollowComp.Position.DistanceAlongSpline;
			float DeltaDistance = DistanceAfter - DistanceBefore;
			if (DeltaDistance < 0.f)
				DeltaDistance += SplineFollowComp.Position.Spline.GetSplineLength();

			Train.CurrentSpeed = DeltaDistance / DeltaTime;
		}

		Train.Angle = Math::DotToDegrees(FVector::UpVector.DotProduct(Train.ActorUpVector));
		Train.Angle *= -FMath::Sign(FVector::UpVector.DotProduct(Train.ActorForwardVector));
		Train.Angle = FMath::Max(0.f, Train.Angle);

		// Rotate wheels
		{				
			float LargeWheelAngle = (Train.CurrentSpeed * DeltaTime* RAD_TO_DEG) / Train.LargeWheelRadius;
			float SmallWheelAngle = (Train.CurrentSpeed * DeltaTime * RAD_TO_DEG) / Train.SmallWheelRadius;

			Train.LargeWheelsFront.AddLocalRotation(FRotator(0.f, 0.f, -LargeWheelAngle));
			Train.LargeWheelsBack.AddLocalRotation(FRotator(0.f, 0.f, -LargeWheelAngle));
			Train.SmallWheelsBack.AddLocalRotation(FRotator(0.f, 0.f, -SmallWheelAngle));
			Train.SmallWheelsFront.AddLocalRotation(FRotator(0.f, 0.f, -SmallWheelAngle));

			for (ACourtyardTrainCarriage Carriage : Train.Carriages)
			{
				Carriage.SmallWheelsFront.AddLocalRotation(FRotator(0.f, 0.f, -SmallWheelAngle));
				Carriage.SmallWheelsRear.AddLocalRotation(FRotator(0.f, 0.f, -SmallWheelAngle));
			}
		}

		// Update rods
		FVector RodForward = Train.ActorRightVector;
		FVector RodUp = Train.ActorUpVector;
		FRotator RodRotation = FRotator::MakeFromXZ(RodForward, RodUp);
		Train.ConnectingRodPivot.SetWorldRotation(RodRotation);

		// Update Forward Rods
		FVector ToRods = Train.ConnectingRodPivot.WorldLocation - Train.ConnectingRodFrontPivot.WorldLocation;
		FRotator ForwardRodRotation = FRotator::MakeFromYZ(ToRods, RodUp);
		FVector Scale = FVector(Train.ConnectingRodFrontPivot.GetWorldScale().X, ToRods.Size() / 100.f, Train.ConnectingRodFrontPivot.GetWorldScale().Z);
		Train.ConnectingRodFrontPivot.SetWorldRotation(ForwardRodRotation);
		Train.ConnectingRodFrontPivot.SetWorldScale3D(Scale);

		if (IsDebugActive())
			PrintToScreenScaled("Speed: " + Train.CurrentSpeed);

		const float RotationInterpSpeed = 40.f;

		// Update train location
		FTransform TrainTransform = Train.GetTrainTransform(SplineFollowComp.Position);
		Owner.SetActorLocationAndRotation(TrainTransform.Location, FMath::RInterpTo(Owner.ActorRotation, TrainTransform.Rotation.Rotator(), DeltaTime, RotationInterpSpeed));
		//Owner.ActorRotation = AcceleratedTrainRotation.AccelerateTo(TrainTransform.Rotation.Rotator(), 0.15f, DeltaTime);

		// Update any carraiges following the train		
		for (int Index = 0; Index < Train.Carriages.Num(); Index++)
		{
			ACourtyardTrainCarriage Carriage;

			Train.Carriages[Index].Speed = Train.CurrentSpeed;
			Train.Carriages[Index].Angle = Math::DotToDegrees(FVector::UpVector.DotProduct(Train.Carriages[Index].ActorUpVector));
			Train.Carriages[Index].Angle *= -FMath::Sign(FVector::UpVector.DotProduct(Train.Carriages[Index].ActorForwardVector));
			Train.Carriages[Index].Angle = FMath::Max(0.f, Train.Carriages[Index].Angle);

			FTransform CarriageTransform;
			if (Train.GetCarriageTransfromAtIndex(Index, Carriage, CarriageTransform))
				Carriage.SetActorLocationAndRotation(CarriageTransform.Location, FMath::RInterpTo(Carriage.ActorRotation, CarriageTransform.Rotation.Rotator(), DeltaTime, RotationInterpSpeed));

			// Update the hook mesh
			const FVector HookLocation = Carriage.FrontHook.WorldLocation;
			FVector HookTargetLocation;
			if (Index == 0)
				HookTargetLocation = Train.RearHook.WorldLocation;
			else
				HookTargetLocation = Train.Carriages[Index - 1].RearHook.WorldLocation;
			
			const FVector ToTarget = HookTargetLocation - HookLocation;

			// System::DrawDebugLine(HookLocation, HookTargetLocation, FLinearColor::Green);
			const float DistanceToHook = ToTarget.Size();
			
			const FVector HookScale = FVector(1.f, DistanceToHook / 100.f, 1.f);
			FRotator HookRotation = FRotator::MakeFromX(ToTarget);

			Carriage.HookRoot.SetWorldScale3D(HookScale);
			Carriage.HookRoot.SetWorldRotation(HookRotation);
		}
	}
}