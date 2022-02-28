import Cake.FlyingMachine.Glider.FlyingMachineGlider;
import Cake.FlyingMachine.FlyingMachineOrientation;
import Cake.FlyingMachine.FlyingMachineSettings;
import Cake.FlyingMachine.FlyingMachineNames;

class UFlyingMachineGliderMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(FlyingMachineTag::Glider);

	default TickGroup = ECapabilityTickGroups::GamePlay;
	default CapabilityDebugCategory = FlyingMachineCategory::Glider;

	AFlyingMachineGlider Glider;
	UFlyingMachineGliderComponent GliderComp;
	UHazeCrumbComponent CrumbComponent;

	FFlyingMachineGliderSettings Settings;

	// Speed gained or lost for going up- or down-hill
	float ExtraSpeed = 0.f;

	FHazeAcceleratedRotator RemoteRotation;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Glider = Cast<AFlyingMachineGlider>(Owner);
		GliderComp = UFlyingMachineGliderComponent::GetOrCreate(Glider);
		CrumbComponent = UHazeCrumbComponent::Get(Glider);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!GliderComp.HasBothUsers())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!GliderComp.HasBothUsers())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams Params)
	{
		Glider.CallOnStartDrivingEvent();
		GliderComp.Rotation = Glider.GetActorRotation();
		RemoteRotation.Value = GliderComp.Rotation;

		// Draw spline when debugging
		if (IsDebugActive())
		{
			for(int si=0; si<GliderComp.FollowSplines.Num(); ++si)
			{
				UHazeSplineComponent Spline = GliderComp.FollowSplines[si];

				for(int i=0; i<400; ++i)
				{
					float DistanceStep = Spline.SplineLength / 400;
					float Distance = DistanceStep * i;

					FVector Start = Spline.GetLocationAtDistanceAlongSpline(Distance, ESplineCoordinateSpace::World);
					FVector End = Spline.GetLocationAtDistanceAlongSpline(Distance + DistanceStep, ESplineCoordinateSpace::World);

					System::DrawDebugLine(Start, End, FLinearColor::LucBlue, 80.f, Thickness = 7.f);
				}
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams Params)
	{
		Glider.CallOnStopDrivingEvent();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
		{
			{
				// Get the player weight
				float PlayerWeight = (GliderComp.LeftUser.Position + GliderComp.RightUser.Position) / 2.f;

				// Transorm player weight to [-1, 1]
				PlayerWeight = (PlayerWeight * 2.f) - 1.f;

				// Roll
				float TargetRoll = PlayerWeight * Settings.MaxRollAngle;
				float Roll = GliderComp.Rotation.Roll;
				Roll = FMath::Lerp(Roll, TargetRoll, Settings.RollLerpCoefficient * DeltaTime);

				GliderComp.Rotation.Roll = Roll;

				// Yaw based on roll
				GliderComp.Rotation.Yaw += (Roll / Settings.MaxRollAngle) * Settings.YawRate * DeltaTime;
			}

			{
				// Get target location based on all the followed splines
				FVector TargetLocation = FindWeightedAverageTargetPosition(GliderComp.FollowSplines);

				// Direction to turn towards
				FVector TargetDirection = TargetLocation - Glider.ActorLocation;
				TargetDirection.Normalize();

				// Pitch
				float TargetPitch = FMath::Asin(TargetDirection.DotProduct(FVector::UpVector)) * RAD_TO_DEG;
				float Pitch = GliderComp.Rotation.Pitch;

				Pitch = FMath::Lerp(Pitch, TargetPitch, Settings.PitchLerpSpeed * DeltaTime);

				GliderComp.Rotation.Pitch = Pitch;
			}

			{
				// Speed gained or lost from going up- and down-hill
				FVector Forward = GliderComp.Rotation.ForwardVector;
				float Angle = Forward.DotProduct(-FVector::UpVector);

				float TargetExtraSpeed = FMath::Lerp(
					Settings.MinEnvironmentalSpeed,
					Settings.MaxEnvironmentalSpeed,
					Math::Saturate(Angle)
				);

				ExtraSpeed = FMath::Lerp(
					ExtraSpeed,
					TargetExtraSpeed,
					Settings.EnvironmentalLerpSpeed * DeltaTime
				);
			}
		}
		else
		{
			FHazeActorReplicationFinalized CrumbParams;
			CrumbComponent.GetCurrentReplicatedData(CrumbParams);
			RemoteRotation.AccelerateTo(CrumbParams.Rotation, 1.1f, DeltaTime);

			GliderComp.Rotation = RemoteRotation.Value;
		}

		Glider.SetActorRotation(GliderComp.Rotation);

		if(HasControl())
		{
			FVector DeltaMove = GliderComp.Rotation.Vector() *
				(GliderComp.Speed + ExtraSpeed) *
				DeltaTime;

			// Translation
			// Trace for hits when moving
			TArray<AActor> IgnoreActors;
			TArray<FHitResult> Hits;
			Trace::SweepComponentForHits(Glider.Mesh, DeltaMove, Hits);

			for(int i=0; i<Hits.Num(); ++i)
			{
				// Not blocking, we dont care
				if (!Hits[i].bBlockingHit)
					continue;

				if (Network::IsNetworked())
				{
					// Leave a crumb that this hit happened baby
					FHazeCrumbDelegate Delegate;
					Delegate.BindUFunction(this, n"CrumbedAddMovementHit");
					FHazeDelegateCrumbParams Params;
					Params.AddStruct(n"Hit", Hits[i]);

					CrumbComponent.LeaveAndTriggerDelegateCrumb(Delegate, Params);
				}

				GliderComp.Hits.Add(Hits[i]);
				break;
			}

			Glider.AddActorWorldOffset(DeltaMove);
			CrumbComponent.LeaveMovementCrumb();
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComponent.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			Glider.AddActorWorldOffset(ConsumedParams.DeltaTranslation);
		}		

		Glider.CallOnTickEvent(DeltaTime);
	}

	FVector FindWeightedAverageTargetPosition(TArray<UHazeSplineComponent> Splines)
	{
		if (Splines.Num() == 0)
		{
			// No followed splines
			return FVector();
		}

		// We want to search for spline positions a bit forward so that we can predict a bit better where we're gonna go
		FVector PredictPosition = Glider.ActorLocation;
		FVector PredictForward = Glider.ActorForwardVector;
		PredictForward = PredictForward.ConstrainToPlane(FVector::UpVector);
		PredictPosition += PredictForward * GliderComp.Speed;

		// Do a weighted average of all the spline targets, where the weight is (1 / DistanceFromPredictionPoint), so that targets close to the machine get more weight
		FVector PositionSum;
		float WeightSum = 0.f;

		for(int i=0; i<Splines.Num(); ++i)
		{
			FVector SplineLoc = Splines[i].FindLocationClosestToWorldLocation(PredictPosition, ESplineCoordinateSpace::World);

			if (IsDebugActive())
			{
				System::DrawDebugSphere(SplineLoc, 100.f, LineColor = FLinearColor::Yellow);
			}

			float Distance = (SplineLoc - PredictPosition).Size();
			float Weight = FMath::Pow(1000.f / Distance, 3.f);

			WeightSum += Weight;
			PositionSum += SplineLoc * Weight;
		}

		FVector ResultLocation = PositionSum / WeightSum;

		if (IsDebugActive())
		{
			System::DrawDebugSphere(ResultLocation, 100.f, LineColor = FLinearColor::Green);
		}

		return ResultLocation;
	}

	UFUNCTION()
	void CrumbedAddMovementHit(FHazeDelegateCrumbData Data)
	{
		if (HasControl())
			return;

		FHitResult Hit;
		Data.GetStruct(n"Hit", Hit);

		GliderComp.Hits.Add(Hit);
	}
}