import Cake.LevelSpecific.Garden.ControllablePlants.ControllablePlantsComponent;
import Cake.LevelSpecific.Garden.ControllablePlants.Beanstalk.Beanstalk;
import Cake.LevelSpecific.Garden.ControllablePlants.Beanstalk.BeanstalkTags;

class UBeanstalkStemCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 11;

	ABeanstalk Beanstalk;
	UHazeCrumbComponent CrumbComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Beanstalk = Cast<ABeanstalk>(Owner);
		CrumbComp = UHazeCrumbComponent::Get(Owner);
	}

	FVector SplinePointSecondCurrent;
	FVector SplinePointCurrent;

	FVector SmoothSplinePoint;

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!Beanstalk.bBeanstalkActive)
			return EHazeNetworkActivation::DontActivate;

		if (!Beanstalk.bSpawningDone)
			return EHazeNetworkActivation::DontActivate;

		if(Beanstalk.SplineComp.NumberOfSplinePoints < 3)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!Beanstalk.bBeanstalkActive)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(Beanstalk.SplineComp.NumberOfSplinePoints < 3)
			return EHazeNetworkDeactivation::DeactivateLocal;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Beanstalk.ClearSplines();

		SmoothSplinePoint = Beanstalk.SplineComp.GetLocationAtSplinePoint(Beanstalk.SplineComp.NumberOfSplinePoints - 2, ESplineCoordinateSpace::World);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		
		if(HasControl())
		{
			if(Beanstalk.CurrentVelocity > 0.0f || Beanstalk.CurrentState == EBeanstalkState::Emerging)
			{
				if(Beanstalk.ShouldAddNewSegment())
				{
					AddSegment();
				}
			}
			else if(Beanstalk.CurrentVelocity < 0.0f && Beanstalk.SplineComp.NumberOfSplinePoints > 3)
			{
				const float DistanceToSecondLastPoint = Beanstalk.VisualSpline.GetDistanceAlongSplineAtSplinePoint(Beanstalk.VisualSpline.NumberOfSplinePoints - 2);
				const float DistanceDiff = Beanstalk.SplineSystemPosition.DistanceAlongSpline - DistanceToSecondLastPoint;

				if(DistanceDiff < 2.0f)
				{
					RemoveSegment();
				}
			}
		}

		const float ForwardLength = Beanstalk.SegmentLength;
		
		const FVector ThirdLastSplinePoint = Beanstalk.SplineComp.GetLocationAtSplinePoint(Beanstalk.SplineComp.NumberOfSplinePoints - 3, ESplineCoordinateSpace::World);
		FVector DirectionToHeadEntrance = (Beanstalk.HeadCenterLocation - ThirdLastSplinePoint).GetSafeNormal();
		
		FVector SecondSplinePointLocation = ThirdLastSplinePoint + DirectionToHeadEntrance * ForwardLength;

		if(Beanstalk.CurrentState == EBeanstalkState::Emerging)
		{
			SmoothSplinePoint = SecondSplinePointLocation;
		}
		else
		{
			SmoothSplinePoint = FMath::VInterpTo(SmoothSplinePoint, SecondSplinePointLocation, DeltaTime, 5.0f);
		}

		SplinePointSecondCurrent = FMath::VInterpTo(SplinePointSecondCurrent, SecondSplinePointLocation, DeltaTime, 5.0f);
		
		Beanstalk.SplineComp.SetLocationAtSplinePoint(Beanstalk.SplineComp.NumberOfSplinePoints - 2, SmoothSplinePoint, ESplineCoordinateSpace::World, false);

		const FVector SecondLastSplinePoint = Beanstalk.SplineComp.GetLocationAtSplinePoint(Beanstalk.SplineComp.NumberOfSplinePoints - 2, ESplineCoordinateSpace::World);
		const FVector TargetLoc = Beanstalk.HeadCenterLocation;
		FVector DirectionToHead = (TargetLoc - SecondLastSplinePoint).GetSafeNormal();
		float DistanceToHeadCenter = SecondSplinePointLocation.Distance(Beanstalk.HeadCenterLocation);
		
		float LastPointForwardLength = FMath::Min(ForwardLength, DistanceToHeadCenter);
		FVector LastPointLoc = SmoothSplinePoint + DirectionToHead * DistanceToHeadCenter;

		if(HasControl() && Beanstalk.CurrentVelocity < 0.0f)
		{
			float PredictedDistanceOnSplineForLastPoint = Beanstalk.VisualSpline.GetDistanceAlongSplineAtWorldLocation(LastPointLoc);
			float PredictedDistanceOnSplineForSecondLastPoint = Beanstalk.VisualSpline.GetDistanceAlongSplineAtWorldLocation(SmoothSplinePoint);
			if(PredictedDistanceOnSplineForLastPoint < PredictedDistanceOnSplineForSecondLastPoint)
				LastPointLoc = SmoothSplinePoint;
		}

		Beanstalk.SplineComp.SetLocationAtSplinePoint(Beanstalk.SplineComp.NumberOfSplinePoints - 1, LastPointLoc, ESplineCoordinateSpace::World, false);

		Beanstalk.VisualSpline.SetLocationAtSplinePoint(Beanstalk.VisualSpline.NumberOfSplinePoints - 2, SmoothSplinePoint, ESplineCoordinateSpace::World, false);
		Beanstalk.VisualSpline.SetLocationAtSplinePoint(Beanstalk.VisualSpline.NumberOfSplinePoints - 1, LastPointLoc, ESplineCoordinateSpace::World, false);

		const float MaxLength = 2.0f;
		double GameTime = double(System::GameTimeInSeconds);

		if(Beanstalk.VisualSpline.NumberOfSplinePoints > 5)
		{
			const float WiggleSize = Beanstalk.CurrentVelocity >= 0.0f ? 1.0f : 0.5f;
			for(int Index = 1, Num = Beanstalk.LocalSplinePoints.Num(); Index < Num; ++Index)
			{
				const int VisualSplineIndex = Index + 1;
				FVector LocalSplinePos = Beanstalk.LocalSplinePoints[Index];
				FVector LocalRotation = Beanstalk.SplineComp.GetRotationAtSplinePoint(Index, ESplineCoordinateSpace::Local).Vector();

				float PulseValue = (FMath::MakePulsatingValue(GameTime, 0.05f) * 2.0f) - 1.0f;
				LocalSplinePos += LocalRotation * PulseValue * WiggleSize;
				
				Beanstalk.LocalSplinePoints[Index] = FMath::VInterpTo(Beanstalk.LocalSplinePoints[Index], LocalSplinePos, DeltaTime, 10.0f);
				Beanstalk.VisualSpline.SetLocationAtSplinePoint(VisualSplineIndex, Beanstalk.LocalSplinePoints[Index], ESplineCoordinateSpace::Local, false);
			}
		}

		Beanstalk.SplineComp.UpdateSpline();
		Beanstalk.VisualSpline.UpdateSpline();
		Beanstalk.UpdateSplineMeshes();
	}

	private void AddSegment()
	{
		FHazeDelegateCrumbParams CrumbParams;
		//float SegmentDistance = FMath::Min((Beanstalk.SplineComp.GetDistanceAlongSplineAtSplinePoint(Beanstalk.SplineComp.NumberOfSplinePoints - 2) + Beanstalk.SegmentLength), Beanstalk.SplineComp.SplineLength);
		//FVector Segmentlocation = Beanstalk.SplineComp.GetLocationAtDistanceAlongSpline(SegmentDistance, ESplineCoordinateSpace::World);
		CrumbParams.AddVector(n"SegmentLocation", Beanstalk.HeadCenterLocation);
		CrumbComp.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_AddSegment"), CrumbParams);
	}

	UFUNCTION()
	private void Crumb_AddSegment(const FHazeDelegateCrumbData& CrumbData)
	{
		const FVector SegmentLocation = CrumbData.GetVector(n"SegmentLocation");
		Beanstalk.AddNewSegment(SegmentLocation);
		SmoothSplinePoint = Beanstalk.VisualSpline.GetLocationAtSplinePoint(Beanstalk.VisualSpline.NumberOfSplinePoints - 2, ESplineCoordinateSpace::World);
	}

	private void RemoveSegment()
	{
		FHazeDelegateCrumbParams CrumbParams;
		CrumbComp.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_RemoveSegment"), CrumbParams);
	}

	UFUNCTION()
	private void Crumb_RemoveSegment(const FHazeDelegateCrumbData& CrumbData)
	{
		Beanstalk.RemoveLastSegment();
		SmoothSplinePoint = Beanstalk.VisualSpline.GetLocationAtSplinePoint(Beanstalk.VisualSpline.NumberOfSplinePoints - 2, ESplineCoordinateSpace::World);
	}
}
