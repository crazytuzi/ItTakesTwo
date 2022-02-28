import Cake.SlotCar.SlotCarActor;
import Cake.SlotCar.SlotCarSettings;
import Cake.SlotCar.SlotCarTrackActor;

class USlotCarMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SlotCar");
	default CapabilityTags.Add(n"SlotCarMovement");

	default CapabilityDebugCategory = n"SlotCar";
	
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 100;

	ASlotCarActor SlotCar;
	ASlotCarTrackActor SlotCarTrackActor;
	UHazeSplineFollowComponent SplineFollowComp;
	UHazeCrumbComponent CrumbComp;

	// Networking
	float TargetCarDistanceAlongSpline = 0.f;
    float TargetCarSpeed = 0.f;
    int TargetLapNumber = 1;

	const float NetworkUpdateFrequency = 0.1f;
    float NetworkUpdateFreqencyTime = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		SlotCar = Cast<ASlotCarActor>(Owner);
		SlotCarTrackActor = Cast<ASlotCarTrackActor>(SlotCar.TrackActor);
		SplineFollowComp = UHazeSplineFollowComponent::GetOrCreate(Owner);
		CrumbComp = UHazeCrumbComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{	
		SplineFollowComp.ActivateSplineMovement(SlotCar.TrackSpline);
		SplineFollowComp.IncludeSplineInActorReplication(this);

		FHazeSplineSystemPosition InititalPosition;
		InititalPosition.FromData(SlotCarTrackActor.SplineComp, SlotCar.Distance, true);
		SplineFollowComp.UpdateSplineMovementFromPosition(InititalPosition);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{	
		// If the actor/hazeakcomp is disabled, then no rtpcs can be set.
		if (SlotCar.HasActorBegunPlay())
			SlotCar.HazeAkComp.SetRTPCValue("Rtpc_World_Shared_SideContent_SlotCars_Velocity", 0.f);

		UHazeSplineComponent Spline;
		bool bForward;
		SplineFollowComp.Position.BreakData(Spline, SlotCar.Distance, bForward);

		SplineFollowComp.DeactivateSplineMovement();
		SplineFollowComp.RemoveSplineFromActorReplication(this);		
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		float OldSpeed = SlotCar.CurrentSpeed;
		if (HasControl())
			UpdateSpeed(DeltaTime, SlotCar.PlayerInput);
			
		MoveCarAlongSpline(DeltaTime);		
		UpdateSlotCarRotation();

		SlotCar.HazeAkComp.SetRTPCValue("Rtpc_World_Shared_SideContent_SlotCars_Velocity", SlotCar.SpeedPercentage);
		//PrintToScreen("Speed: " + SlotCar.SpeedPercentage, 0.f);

		if (SlotCar.StartMovingEvent != nullptr)
		{
			if (OldSpeed == 0.f && SlotCar.CurrentSpeed != 0.f)
				SlotCar.HazeAkComp.HazePostEvent(SlotCar.StartMovingEvent);
		}

		if (SlotCar.StopMovingEvent != nullptr)
		{
			if (OldSpeed != 0.f && SlotCar.CurrentSpeed == 0.f)
				SlotCar.HazeAkComp.HazePostEvent(SlotCar.StopMovingEvent);
		}
	}

	void UpdateSpeed(float DeltaTime, float Input)
    {
		float Acceleration = ((SlotCarSettings::Speed.Acceleration * Input) - SlotCarSettings::Speed.Deceleration - SlotCar.CurrentSpeed * SlotCarSettings::Speed.Drag) * DeltaTime;
		SlotCar.CurrentSpeed = FMath::Max(SlotCar.CurrentSpeed + Acceleration, 0.f);
    }

	void MoveCarAlongSpline(float DeltaTime)
    {
		if (HasControl())
		{
			FHazeSplineSystemPosition PreviousSystemPosition = SplineFollowComp.Position;
			FHazeSplineSystemPosition SystemPosition;

			SplineFollowComp.UpdateSplineMovement(SlotCar.CurrentSpeed * DeltaTime, SystemPosition);
			CrumbComp.LeaveMovementCrumb();

			UHazeSplineComponentBase SplineComp;
			float PreviousDistance = 0.f;
			float NewDistance = 0.f;

			bool bForward;
			PreviousSystemPosition.BreakData(SplineComp, PreviousDistance, bForward);
			SystemPosition.BreakData(SplineComp, NewDistance, bForward);

			if (NewDistance < PreviousDistance && PreviousDistance != SystemPosition.Spline.SplineLength)
				SlotCarTrackActor.NetLapCompleted(SlotCar.OwningPlayer, SlotCarTrackActor.LapTimes[SlotCar.OwningPlayer].CurrentLapTime);
		}
		else
		{
			float DistanceBefore = SplineFollowComp.Position.DistanceAlongSpline;

			FHazeActorReplicationFinalized FrameFinal;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, FrameFinal);
			SplineFollowComp.UpdateReplicatedSplineMovement(FrameFinal);

			float DistanceAfter = SplineFollowComp.Position.DistanceAlongSpline;
			float DeltaDistance = DistanceAfter - DistanceBefore;
			if (DeltaDistance < 0.f)
				DeltaDistance += SplineFollowComp.Position.Spline.GetSplineLength();

			SlotCar.CurrentSpeed = DeltaDistance / DeltaTime;
		}		

        FVector Tangent = SplineFollowComp.Position.WorldForwardVector;
        FRotator TangentRot = Tangent.ToOrientationRotator();
        FVector RotatedOffset = SplineFollowComp.Position.GetWorldTransform().TransformVector(SlotCar.TrackSplineOffset);

		FVector NewLocation = SplineFollowComp.Position.WorldLocation;
        NewLocation += RotatedOffset;
		
		Owner.SetActorLocation(NewLocation);
		Owner.SetActorRotation(TangentRot);

		SlotCar.AddSlotCarHistoryData(FSlotCarHistoryData(SlotCar.CurrentSpeed, SlotCar.SplineFollowComp.Position, DeltaTime));
    }

	void UpdateSlotCarRotation()
	{
		FVector Forward = SplineFollowComp.Position.WorldForwardVector;
		FVector Up = SplineFollowComp.Position.WorldUpVector;

		SlotCar.CarBodyPivot.SetWorldRotation(FRotator::MakeFromXZ(Forward, Up));
	}
}