import Cake.LevelSpecific.Garden.ControllablePlants.ControllablePlantsComponent;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.Garden.ControllablePlants.Beanstalk.Beanstalk;
import Cake.LevelSpecific.Garden.ControllablePlants.PlantMovementCapability;
import Cake.LevelSpecific.Garden.ControllablePlants.Beanstalk.BeanstalkTags;

class UBeanstalkMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	float TimeSpenteReversing = 0.0f;

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 10;

	FVector CurrentFacingDirection;
	float CurrentHeight = 0.0f;

	float PreviousMovementDirection = 0.0f;

	ABeanstalk Beanstalk;

	float RelativeLookYaw = 0.0f;
	float RelativeLookPitch = 0.0f;

	float AccumulatedSpring = 0.0f;
	float Spring = 0.0f;

	bool bIsReversing = false;
	bool bHitWall = false;
	bool bHasInput = true;
	FVector RawInput;

	bool bWasSpringReverse = false;

	UPROPERTY(NotEditable)
	UHazeMovementComponent MoveComp;

	UPROPERTY(NotEditable)
	UHazeCrumbComponent CrumbComp;

	UBeanstalkSettings Settings;

	TArray<FVector> SplinePointsToCheck;

	FVector HeightOrigin;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Beanstalk = Cast<ABeanstalk>(Owner);
		Settings = Beanstalk.BeanstalkSettings;
		MoveComp = UHazeMovementComponent::GetOrCreate(Owner);
		CrumbComp = UHazeCrumbComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;
		
		if (!Beanstalk.bSpawningDone)
			return EHazeNetworkActivation::DontActivate;

		if (!Beanstalk.bBeanstalkActive)
			return EHazeNetworkActivation::DontActivate;

		if(Beanstalk.CurrentState == EBeanstalkState::Active)
			return EHazeNetworkActivation::ActivateLocal;

		if(Beanstalk.CurrentState == EBeanstalkState::Submerging)
			return EHazeNetworkActivation::ActivateLocal;

		if(Beanstalk.CurrentState == EBeanstalkState::Hurt)
			return EHazeNetworkActivation::ActivateLocal;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!Beanstalk.bBeanstalkActive)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(Beanstalk.CurrentState == EBeanstalkState::Emerging)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(Beanstalk.CurrentState == EBeanstalkState::Inactive)
			return EHazeNetworkDeactivation::DeactivateLocal;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{

	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		//Beanstalk.CurrentVelocity = 0.0f;
		CrumbComp.SetCustomCrumbRotation(Beanstalk.HeadRotationNode.GetWorldRotation());
		CrumbComp.SetCustomCrumbVector(FVector::ZeroVector);
		Owner.CleanupCurrentMovementTrail();
		bIsReversing = false;
		HeightOrigin = Beanstalk.HeadRotationNode.WorldLocation;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		const bool bHasReachedMaxLength = Beanstalk.HasReachedMaxLength();
		const bool bHasReachedMaxMinHeight = Beanstalk.HasReachedMaxMinHeight();
		bool bSpringReverse = bHasReachedMaxLength || bHasReachedMaxMinHeight;
		bHitWall = false;

		Beanstalk.PerformAsyncTrace();

		FHazeFrameMovement MoveData = MoveComp.MakeFrameMovement(BeanstalkTags::Beanstalk);

		if(HasControl())
		{
			SplinePointsToCheck.Empty();
			int NumPointsOnEmergeSpline = Beanstalk.BeanstalkSoil.EmergeSplinePath.NumberOfSplinePoints;
			int HeadPointsOffset = 7;
			int PointsTotal = NumPointsOnEmergeSpline + HeadPointsOffset;
			float SplineDistanceMinSq = FMath::Square(1250.0f);

			if(Beanstalk.VisualSpline.NumberOfSplinePoints > PointsTotal)
			{
				for(int Index = NumPointsOnEmergeSpline, Num = Beanstalk.VisualSpline.NumberOfSplinePoints - HeadPointsOffset; Index < Num; ++Index)
				{
					FVector LocAtSplinePoint = Beanstalk.VisualSpline.GetLocationAtSplinePoint(Index, ESplineCoordinateSpace::World);
					
					if(Beanstalk.HeadRotationNode.WorldLocation.DistSquared2D(LocAtSplinePoint) < SplineDistanceMinSq)
					{
						SplinePointsToCheck.Add(LocAtSplinePoint);
					}
				}
			}


			const float CurrentDistanceOnSpline = Beanstalk.SplineComp.GetDistanceAlongSplineAtWorldLocation(Beanstalk.HeadRotationNode.WorldLocation);
			const bool bStopDistance = CurrentDistanceOnSpline < Beanstalk.StopDistance && Beanstalk.CurrentState != EBeanstalkState::Submerging;
			float SpeedFraction = Beanstalk.CurrentVelocity / Settings.MovementSpeedMaximum;
			
			Beanstalk.BeanstalkHead.SetBlendSpaceValues(Beanstalk.GetSplineLengthSpill(), SpeedFraction, false);
			const bool bIsMoving = Beanstalk.IsMoving();
			float MovementDirection = Beanstalk.WantedMovementDirection;
			const float InputSize = Beanstalk.RawInput.Size();
			float BeanstalkDamping = Settings.Deceleration;

			Beanstalk.CurrentVelocity = FMath::FInterpTo(Beanstalk.CurrentVelocity, 0.0f, DeltaTime, BeanstalkDamping);
			Beanstalk.CurrentVelocity = FMath::Clamp(Beanstalk.CurrentVelocity, -Settings.MovementSpeedMaximum, Settings.MovementSpeedMaximum);
			float AccelerationScalar = 1.0f;

			float Percent = 1.0f;
			FVector TargetFacingDirection = Beanstalk.WantedFacingDirection;
			float MaxLengthRotScalar = 1.0f;

			float HitWallModifier = 1.0f;

			RawInput = Beanstalk.RawInput;

			if(Beanstalk.CurrentVelocity > 0.0f && MoveComp.ForwardHit.Component != nullptr)
			{
				FVector Reflection = FMath::GetReflectionVector(Beanstalk.BeanstalkHead.UpVector, MoveComp.ForwardHit.Normal);
				TargetFacingDirection = Reflection;
				HitWallModifier = 0.7f;
			}

			float HeightOriginDiff = HeightOrigin.Z - Beanstalk.HeadRotationNode.WorldLocation.Z;
			const float MinimalHeightAffector = 50.0f;
			const float HeightDiffABs = FMath::Abs(HeightOriginDiff);
			const float HeightDiffSign = FMath::Sign(HeightOriginDiff);

			if(HeightDiffABs > MinimalHeightAffector)
			{
				TargetFacingDirection.Z = HeightDiffSign;
				Beanstalk.WantedZFacing = HeightDiffSign;
			}
			else
			{
				float HeightAlpha = HeightDiffABs / MinimalHeightAffector;
				float FacingDirectionZ = FMath::EaseIn(0.0f, 1.0f, HeightAlpha, 5.0f) * HeightDiffSign;
				TargetFacingDirection.Z = FacingDirectionZ;
				Beanstalk.WantedZFacing = FacingDirectionZ;
			}
		
			const FVector SplineCheckEnd = Beanstalk.HeadRotationNode.WorldLocation + ((Beanstalk.HeadRotationNode.ForwardVector + TargetFacingDirection).GetSafeNormal() ) * 600.0f;
			FHazeIntersectionLineSegment LineIntersection;
			LineIntersection.Start = Beanstalk.HeadRotationNode.WorldLocation;
			LineIntersection.End = SplineCheckEnd;
			FHazeIntersectionSphere SphereIntersection;
			SphereIntersection.Radius = 100.0f;

			bool bIsCollisingWithSpline = false;

			FHazeIntersectionSphere Sphere;
			Sphere.Origin = Beanstalk.HeadCenterLocation;
			Sphere.Radius = 256.0f;
			
			for(FVector SplineLoc : SplinePointsToCheck)
			{
				FHazeIntersectionSphere SplineSphere;
				SplineSphere.Origin = SplineLoc;
				SplineSphere.Radius = 100.0f;

				FHazeIntersectionResult Results;
				Results.QuerySphereSphere(SplineSphere, Sphere);
				if(Results.bIntersecting)
				{
					bIsCollisingWithSpline = true;
					break;
				}
			}

			if(bIsCollisingWithSpline)
			{
				TargetFacingDirection.Z = 1.0f;
				Beanstalk.WantedZFacing = 1.0f;
			}

			const float UpDot = Beanstalk.RawInput.DotProduct(FVector::UpVector);

			if(Beanstalk.RawInput.Y < 0.0f)
			{
				FHitResult Hit;
				TArray<AActor> IgnoreActors;
				IgnoreActors.Add(Game::GetMay());
				IgnoreActors.Add(Game::GetCody());
				IgnoreActors.Add(Owner);

				System::LineTraceSingle(Beanstalk.HeadRotationNode.WorldLocation, Beanstalk.HeadRotationNode.WorldLocation - FVector::UpVector * 680.0f, ETraceTypeQuery::Visibility, false, IgnoreActors, EDrawDebugTrace::None, Hit, false);
				if(Hit.bBlockingHit)
				{
					RawInput.Y = 0.0f;
					TargetFacingDirection = TargetFacingDirection.GetSafeNormal2D();
				}
			}

			if(bSpringReverse && bHasReachedMaxMinHeight && !bHasReachedMaxLength)
			{
				if(Beanstalk.HasReachedMinHeight() && RawInput.Y > 0.0f)
					bSpringReverse = false;
				else if(Beanstalk.HasReachedMaxHeight() && RawInput.Y < 0.0f)
					bSpringReverse = false;
			}

			if(bStopDistance || bSpringReverse)
			{
				AccumulatedSpring = FMath::Min(AccumulatedSpring + 300.0f * DeltaTime, 1000.0f);
			}

			if(!bHasInput)
			{
				if(bStopDistance)
					MovementDirection = 1.0f;
				else if(bSpringReverse)
					MovementDirection = -1.0f;
			}

			if(!bStopDistance && !bSpringReverse)
				bHasInput = true;


			if((MovementDirection > 0.0f && !bSpringReverse) || (MovementDirection < 0.0f && !bStopDistance))
			{
				Beanstalk.CurrentVelocity += MovementDirection * Settings.Acceleration * DeltaTime;
			}

			// push backwards if we have reached a limit and release the move forward button.
			if(MovementDirection <= 0.0f && PreviousMovementDirection > 0.0f && bSpringReverse)
			{
				float SpringVelocity = 0.0f;
				if(bHasReachedMaxLength)
				{
					float MaxLengthDiff = Beanstalk.SplineComp.SplineLength - Beanstalk.BeanstalkMaxLength;
					SpringVelocity = MaxLengthDiff * 2.0f;
				}
				else if(bHasReachedMaxMinHeight)
				{
					float HeightDiff = Beanstalk.MinMaxHeightDiff;
					SpringVelocity = FMath::Abs(HeightDiff) * 2.0f;
				}

				//Beanstalk.CurrentVelocity = -FMath::Max(500.0f, SpringVelocity);
				bHasInput = false;
				Beanstalk.CurrentVelocity = -AccumulatedSpring;
				AccumulatedSpring = 0.0f;
			}
			if(bStopDistance && MovementDirection >= 0.0f && PreviousMovementDirection < 0.0f)
			{
				float SpringVelocity = Beanstalk.StopDistance - CurrentDistanceOnSpline;
				//Beanstalk.CurrentVelocity = FMath::Max(500.0f, SpringVelocity);
				bHasInput = false;
				Spring = AccumulatedSpring;
				Beanstalk.CurrentVelocity = AccumulatedSpring;
				AccumulatedSpring = 0.0f;
			}

			if(Beanstalk.CurrentVelocity >= 0.0f)
				UpdateHeadRotation(DeltaTime);

			if(Beanstalk.CurrentVelocity > 0.0f)
			{
				bIsReversing = false;
				float ZFacing = FMath::Abs(Beanstalk.WantedZFacing) > 0.0f ? TargetFacingDirection.Z : CurrentHeight;
				const FVector NewFacingDirection(TargetFacingDirection.X, TargetFacingDirection.Y, ZFacing);
				if(!bSpringReverse)
				{
					const float SlerpSpeed = bIsCollisingWithSpline ? 5.0f : 2.0f;
					FRotator NewRotation = FQuat::Slerp(Beanstalk.HeadRotationNode.WorldRotation.Quaternion(), NewFacingDirection.ToOrientationQuat(), DeltaTime * (SlerpSpeed * MovementDirection) * MaxLengthRotScalar).Rotator();
					const float PitchLimit = 70.0f;
					NewRotation.Pitch = FMath::Clamp(NewRotation.Pitch, -PitchLimit, PitchLimit);
					NewRotation.Roll = 0.0f;
					Beanstalk.HeadRotationNode.SetWorldRotation(NewRotation);
				}

				CurrentHeight = FMath::Abs(Beanstalk.WantedZFacing) > 0.0f ? ZFacing : CurrentHeight * 0.9f;
				const FVector Velocity = Beanstalk.HeadRotationNode.GetForwardVector() * (Beanstalk.CurrentVelocity * HitWallModifier);
				
				MoveData.ApplyDelta(Velocity * DeltaTime);
			}
			else if(Beanstalk.CurrentVelocity < 0.0f && Beanstalk.SplineComp.NumberOfSplinePoints >= 2)
			{
				if(!bIsReversing)
				{
					StartReversing();
				}
				
				EHazeUpdateSplineStatusType SplineStatus = Beanstalk.SplineFollow.UpdateSplineMovement(-Beanstalk.CurrentVelocity * DeltaTime, Beanstalk.SplineSystemPosition);
				FVector Delta = Beanstalk.SplineSystemPosition.WorldLocation - Beanstalk.BeanstalkHead.WorldLocation;
				const float DistanceToLastSplinePoint = Beanstalk.SplineComp.GetDistanceAlongSplineAtWorldLocation(Beanstalk.SplineSystemPosition.WorldLocation);
				
				if(Beanstalk.SplineComp.NumberOfSplinePoints == 3)
				{
					if(DistanceToLastSplinePoint < 100.0f && Beanstalk.CurrentState == EBeanstalkState::Submerging)
					{
						Beanstalk.CurrentVelocity = 0.0f;
						Beanstalk.ExitPlant();
					}
				}

				FQuat NewRotation = FQuat::Slerp(Beanstalk.HeadRotationNode.WorldRotation.Quaternion(), (Beanstalk.SplineSystemPosition.WorldRotation.Vector() * -1.0f).ToOrientationQuat(), DeltaTime * 15.0f);
				Beanstalk.HeadRotationNode.SetWorldRotation(NewRotation);

				UpdateHeadRotation(DeltaTime);
				MoveData.ApplyDelta(Delta);
			}

			if(Beanstalk.HasSpawnedLeafPairs())
			{
				const float LeafDistance = Beanstalk.SplineComp.GetDistanceAlongSplineAtWorldLocation(Beanstalk.GetLocationOfLastLeafPair());
				const float TotalDistance = Beanstalk.GetDistanceAlongSplineFromLastPoint();
				const float DistanceDiff = TotalDistance - LeafDistance;

				if(DistanceDiff < Beanstalk.RemoveLeafPairDistance)
				{
					Owner.SetCapabilityActionState(BeanstalkTags::RemoveLastLeaf, EHazeActionState::ActiveForOneFrame);
					Beanstalk.InputModifierElapsed = 0.7f;
				}
			}

			if(bSpringReverse && !bWasSpringReverse && Beanstalk.VegetablePatchVOBank != nullptr)
			{
				NetPlayVOBark();
			}
			
			MoveData.OverrideStepDownHeight(0.f);
			MoveData.OverrideStepUpHeight(0.f);
			PreviousMovementDirection = MovementDirection;
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			MoveData.ApplyConsumedCrumbData(ConsumedParams);
			Beanstalk.HeadRotationNode.SetWorldRotation(ConsumedParams.CustomCrumbRotator);

			Beanstalk.YawAxis.RelativeRotation = FRotator(0.0f, 0.0f, ConsumedParams.CustomCrumbVector.Y);
			Beanstalk.PitchAxis.RelativeRotation = FRotator(ConsumedParams.CustomCrumbVector.X, 0.0f, 0.0f);
			const float ReplicatedVelocity = ConsumedParams.CustomCrumbVector.Z;
			const float SpeedFraction = ReplicatedVelocity / Settings.MovementSpeedMaximum;
			Beanstalk.BeanstalkHead.SetBlendSpaceValues(Beanstalk.GetSplineLengthSpill(), SpeedFraction, false);
			Beanstalk.CurrentVelocity = ReplicatedVelocity;
		}

		if(!MoveData.Velocity.IsNearlyZero())
		{
			MoveComp.Move(MoveData);
		}

		CrumbComp.LeaveMovementCrumb();

		bWasSpringReverse = bSpringReverse;
	}

	// Dont want this to be a net function but playing it currently depends on input from the player..
	UFUNCTION(NetFunction)
	private void NetPlayVOBark()
	{
		PlayFoghornVOBankEvent(Beanstalk.VegetablePatchVOBank, n"FoghornDBGardenVegetablePatchBeanstalkMax");
		Beanstalk.BP_OnMaxLengthReached();
	}

	private void UpdateHeadRotation(float DeltaTime)
	{
		CrumbComp.SetCustomCrumbRotation(Beanstalk.HeadRotationNode.GetWorldRotation());
		
		float InputSize = 0.0f;
		FVector TempInput = RawInput;
		
		if(Beanstalk.CurrentVelocity >= 0.0f)
			InputSize = RawInput.SizeSquared();
		else
			TempInput = FVector::ZeroVector;

		const float InterpSpeed = (FMath::IsNearlyZero(InputSize)) ? 7.0f : 2.0f;


		//RelativeLookYaw = FMath::FInterpTo(RelativeLookYaw, TempInput.X * 25.0f, DeltaTime, InterpSpeed);
		//RelativeLookPitch = FMath::FInterpTo(RelativeLookPitch, TempInput.Y * 25.0f, DeltaTime, InterpSpeed);

		RelativeLookYaw = FMath::FInterpTo(RelativeLookYaw, 0.0f, DeltaTime, InterpSpeed);
		RelativeLookPitch = FMath::FInterpTo(RelativeLookPitch, 0.0f, DeltaTime, InterpSpeed);

		Beanstalk.YawAxis.RelativeRotation = FRotator(0.0f, 0.0f, RelativeLookYaw);
		Beanstalk.PitchAxis.RelativeRotation = FRotator(RelativeLookPitch, 0.0f, 0.0f);
		float CombinedHeadRotationDelta = FMath::Abs(Beanstalk.YawAxis.RelativeRotation.Roll + Beanstalk.PitchAxis.RelativeRotation.Pitch);			
		Beanstalk.SetCapabilityAttributeValue(n"AudioHeadRotationDelta", CombinedHeadRotationDelta);
		CrumbComp.SetCustomCrumbVector(FVector(RelativeLookPitch, RelativeLookYaw, Beanstalk.CurrentVelocity));
	}

	private void StartReversing()
	{
		bIsReversing = true;
		Beanstalk.ReversalSplineComp.CopyFromOtherSpline(Beanstalk.VisualSpline);
		Beanstalk.SplineSystemPosition = Beanstalk.ReversalSplineComp.GetPositionClosestToWorldLocation(Beanstalk.BeanstalkHead.WorldLocation, false);
		Beanstalk.SplineFollow.ActivateSplineMovement(Beanstalk.SplineSystemPosition);
	}
}
