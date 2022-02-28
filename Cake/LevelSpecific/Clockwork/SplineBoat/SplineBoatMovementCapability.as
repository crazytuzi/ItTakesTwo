import Cake.LevelSpecific.Clockwork.SplineBoat.SplineBoatActor;
import Cake.LevelSpecific.Clockwork.SplineBoat.SplineBoatPath;
import Cake.LevelSpecific.Clockwork.SplineBoat.SplineBoatJumpComponent;
import Cake.LevelSpecific.Clockwork.SplineBoat.SplineBoatSpeedTrackerComponent;

class USplineBoatMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SplineBoatMovement");
	default CapabilityTags.Add(n"SplineBoat");

	default CapabilityDebugCategory = n"Gameplay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 110;

	ASplineBoatActor BoatActor;
	ASplineBoatPath SplineBoatPathActor;
	UHazeSplineFollowComponent SplineFollowComp;
	USplineBoatSpeedTrackerComponent SpeedTrackerComp;

	int EndSplinePointIndex;

	float MinDistance = 1000.f;
	float NetworkNewTime;
	float NetworkRate = 0.1f;
	float InterpSpeed = 0.45f;
	float DistanceAlongSpline;

	FVector HalfPosition;

	FHazeAcceleratedFloat AcceleratedAverage;

	float CogRotationSpeed = 10.f;

	float MayTargetRotSpeed;
	float CodyTargetRotSpeed;

	float MayPaddleSpeed;
	float CodyPaddleSpeed;

	bool bAudioMayPeddling;
	bool bAudioCodyPeddling;
	bool bAudioBoatMovement;

	float DistAlongSpline;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		BoatActor = Cast<ASplineBoatActor>(Owner);
		SplineBoatPathActor = Cast<ASplineBoatPath>(BoatActor.SplineBoatPath);
		SplineFollowComp = UHazeSplineFollowComponent::GetOrCreate(Owner);
		SplineFollowComp.ActivateSplineMovement(SplineBoatPathActor.Spline, true);
		SplineFollowComp.IncludeSplineInActorReplication(this);
		EndSplinePointIndex = SplineBoatPathActor.Spline.NumberOfSplinePoints - 1;
		SpeedTrackerComp = USplineBoatSpeedTrackerComponent::GetOrCreate(BoatActor);

		BoatActor.SetActorLocation(SplineFollowComp.Position.WorldLocation);
		BoatActor.SetActorRotation(SplineFollowComp.Position.WorldRotation);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (BoatActor == nullptr)
			return EHazeNetworkActivation::DontActivate;
		
		if (BoatActor.PlayerArray.Num() == 0)
			return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		BoatActor.bIsClose = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (BoatActor.PlayerCompMay != nullptr)
			BoatActor.PlayerCompMay.SplineFollowComp = SplineFollowComp;

		if (BoatActor.PlayerCompCody != nullptr)
			BoatActor.PlayerCompCody.SplineFollowComp = SplineFollowComp;
	
		MoveBoat(DeltaTime);
		DistAlongSpline = SplineFollowComp.Position.DistanceAlongSpline;
		NetworkControl(DistAlongSpline, DeltaTime);
	}

	void DistanceCheck()
	{
		FVector Direction = SplineBoatPathActor.Spline.GetLocationAtSplinePoint(EndSplinePointIndex, ESplineCoordinateSpace::World) - SplineFollowComp.Position.WorldLocation;
		float Distance = Direction.Size();

		if (Distance <= MinDistance)
			BoatActor.bIsClose = true;
	}

	void MoveBoat(float DeltaTime)
	{
		float TargetSpeed = 0.f;
		float CompTargetSpeedMay = 0.f;
		float CompTargetSpeedCody = 0.f;

		if (BoatActor.PlayerArray.Num() < 2)
		{
			if (BoatActor.PlayerCompMay != nullptr)
			{
				BoatActor.PlayerCompMay.bIsSlow = true;
				CompTargetSpeedMay = BoatActor.PlayerCompMay.TargetSpeed;
			}
			
			if (BoatActor.PlayerCompCody != nullptr)
			{
				BoatActor.PlayerCompCody.bIsSlow = true;
				CompTargetSpeedCody = BoatActor.PlayerCompCody.TargetSpeed;
			}
		}
		else
		{
			if (BoatActor.PlayerCompMay != nullptr)
			{
				CompTargetSpeedMay = BoatActor.PlayerCompMay.TargetSpeed;
				BoatActor.PlayerCompMay.bIsSlow = false;
			}

			if (BoatActor.PlayerCompCody != nullptr)
			{
				CompTargetSpeedCody = BoatActor.PlayerCompCody.TargetSpeed;
				BoatActor.PlayerCompCody.bIsSlow = false;
			}
		}

		RotateCogs(DeltaTime, CompTargetSpeedMay, CompTargetSpeedCody);

		if (BoatActor.PlayerCompMay != nullptr)
			MayPaddleSpeed = FMath::FInterpTo(MayPaddleSpeed, CompTargetSpeedMay, DeltaTime, InterpSpeed);
		if (BoatActor.PlayerCompCody != nullptr)
			CodyPaddleSpeed = FMath::FInterpTo(CodyPaddleSpeed, CompTargetSpeedCody, DeltaTime, InterpSpeed);
		
		BoatActor.BoatSpeed = MayPaddleSpeed + CodyPaddleSpeed;

		BoatActor.SystemPosition = SplineFollowComp.Position;
		
		FHazeSplineSystemPosition FuturePosition;
		FuturePosition = BoatActor.SystemPosition;
		FuturePosition.Move(20.f);
		
		float NewSpeed = BoatActor.BoatSpeed * SplineAngleModifySpeed(SplineFollowComp, FuturePosition);
		float NextMove = NewSpeed * DeltaTime; 
		BoatActor.SplineStatus = SplineFollowComp.UpdateSplineMovement(NextMove, BoatActor.SystemPosition);
		
		if (Network::IsNetworked())
		{
			UHazeSplineComponent DummySplineComp;
			float ControlDistance = 0.f;
			bool bForward = true;
			SplineFollowComp.Position.BreakData(DummySplineComp, ControlDistance, bForward);
			float HalfDistance;

			float Distance = ControlDistance - SpeedTrackerComp.OtherDistance;

			if (FMath::Abs(Distance) > BoatActor.SplineBoatPath.Spline.SplineLength / 2)
			{
				if (Distance < 0.f)
					Distance += BoatActor.SplineBoatPath.Spline.SplineLength;
				else
					Distance = BoatActor.SplineBoatPath.Spline.SplineLength - Distance;
			}

			HalfDistance = Distance / 2;

			float Current = NextMove + ControlDistance;
			float Target = SpeedTrackerComp.OtherDistance + HalfDistance;
			float Delta = Target - Current;

			if (FMath::Abs(Delta) > BoatActor.SplineBoatPath.Spline.SplineLength / 2)
			{
				if (Delta > 0.f)
					Delta = BoatActor.SplineBoatPath.Spline.SplineLength - Delta;
				else
					Delta += BoatActor.SplineBoatPath.Spline.SplineLength;
			}

			BoatActor.SplineStatus = SplineFollowComp.UpdateSplineMovement(Delta * DeltaTime, BoatActor.SystemPosition);
		}
		
		FVector NewLocation = SplineFollowComp.Position.WorldLocation;
		FRotator NewRotation = SplineFollowComp.Position.WorldRotation;
		
		BoatActor.SetActorLocation(NewLocation);
		BoatActor.SetActorRotation(NewRotation);
		
		AudioSplineBoatRTCPValues();
	}

	void AudioSplineBoatRTCPValues()
	{
		float RTCPMay = MayPaddleSpeed / 440.f;
		RTCPMay = FMath::Abs(RTCPMay);
		float RTCPCody = CodyPaddleSpeed / 440.f;
		RTCPCody = FMath::Abs(RTCPCody);
		float RTCPBoatMovement = BoatActor.BoatSpeed / 680.f;
		RTCPBoatMovement = FMath::Abs(RTCPBoatMovement);

		if (RTCPMay >= 0.02f && !bAudioMayPeddling)
		{
			BoatActor.AudioMayStartedPeddling();
			bAudioMayPeddling = true;
		}
		else if (RTCPMay <= 0.015f && bAudioMayPeddling)
		{
			BoatActor.AudioMayEndedPeddling();
			bAudioMayPeddling = false;
		}

		if (RTCPCody >= 0.02f && !bAudioCodyPeddling)
		{
			BoatActor.AudioCodyStartedPeddling();
			bAudioCodyPeddling = true;
		}
		else if (RTCPCody <= 0.015f && bAudioCodyPeddling)
		{
			BoatActor.AudioCodyEndedPeddling();
			bAudioCodyPeddling = false;
		}

		if (RTCPBoatMovement >= 0.02f && !bAudioBoatMovement)
		{
			BoatActor.AudioBoatMovementStarted();
			bAudioBoatMovement = true;
		}
		else if (RTCPBoatMovement <= 0.015f && bAudioBoatMovement)
		{
			BoatActor.AudioBoatMovementEnded();
			bAudioBoatMovement = false;
		}

		BoatActor.AudioRTCPMayPeddling(RTCPMay);
		BoatActor.AudioRTCPCodyPeddling(RTCPCody);
		BoatActor.AudioRTCPBoatMovement(RTCPBoatMovement);
	}

	float SplineAngleModifySpeed(UHazeSplineFollowComponent SplineFollowCompRef, FHazeSplineSystemPosition SystemPosition)
	{
		float Dot = SystemPosition.WorldForwardVector.DotProduct(SplineFollowComp.Position.WorldForwardVector);
		Dot = FMath::Clamp(Dot, 0.f, 1.f);
		float Angle = FMath::Acos(Dot) * RAD_TO_DEG;
		Angle = FMath::Clamp(1.f - Angle * 0.08f, 0.4f, 1.f);
		return Angle;
	}

	void RotateCogs(float DeltaTime, float CompTargetSpeedMay, float CompTargetSpeedCody)
	{
		float CogInterpSpeed = 1.1f;

		MayTargetRotSpeed = FMath::FInterpTo(MayTargetRotSpeed, CompTargetSpeedMay * 0.7f, DeltaTime, CogInterpSpeed);
		CodyTargetRotSpeed = FMath::FInterpTo(CodyTargetRotSpeed, CompTargetSpeedCody * 0.7f, DeltaTime, CogInterpSpeed);

		FRotator NewRot1 = FRotator(0,0,MayTargetRotSpeed * DeltaTime);
		FRotator NewRot2 = FRotator(0,0,CodyTargetRotSpeed * DeltaTime);
	}

	UFUNCTION()
	void NetworkControl(float DistanceTarget, float DeltaTime)
	{
		if (Network::IsNetworked())
		{
			if (NetworkNewTime <= System::GameTimeInSeconds)
			{
				NetworkNewTime = System::GameTimeInSeconds + NetworkRate;
				NetOtherSidePosition(DistanceTarget, HasControl());
			}
		}
	}

	UFUNCTION(NetFunction)
	void NetOtherSidePosition(float DistanceTarget, bool bControlSide)
	{
		if (HasControl() == bControlSide)
			return;

		SpeedTrackerComp.OtherDistance = DistanceTarget;
	}
}