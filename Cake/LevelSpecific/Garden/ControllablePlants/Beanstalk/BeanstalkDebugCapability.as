import Cake.LevelSpecific.Garden.ControllablePlants.Beanstalk.Beanstalk;

class UBeanstalkDebugCapability : UHazeDebugCapability
{
	default CapabilityTags.Add(n"Debug");
	default CapabilityTags.Add(n"Beanstalk");
	default TickGroup = ECapabilityTickGroups::Input;
    default CapabilityDebugCategory = n"Debug";

	ABeanstalk Beanstalk;

	UBeanstalkSettings Settings;

	bool bDebugDrawHeight = false;
	bool bDebugDrawSplinePoints = false;
	bool bDebugDrawEnvironmentScan = false;
	
	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Beanstalk = Cast<ABeanstalk>(Owner);
		Settings = UBeanstalkSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void SetupDebugVariables(FHazePerActorDebugCreationData& DebugValues) const
	{
		FHazeDebugFunctionCallHandler ToggleDebugDrawHeight = DebugValues.AddFunctionCall(n"ToggleDebugDrawHeight", "Toggle Draw Max Height");
		FHazeDebugFunctionCallHandler ToggleDrawSplinePoints = DebugValues.AddFunctionCall(n"ToggleDrawSplinePoints", "Toggle Draw Spline Points");
		FHazeDebugFunctionCallHandler ToggleEnvironmentScanHandle = DebugValues.AddFunctionCall(n"ToggleEnvironmentScan", "Toggle Draw Environment Scan");

		ToggleDebugDrawHeight.AddActiveUserButton(EHazeDebugActiveUserCategoryButtonType::DPadRight, n"Beanstalk");
		ToggleDrawSplinePoints.AddActiveUserButton(EHazeDebugActiveUserCategoryButtonType::DPadDown, n"Beanstalk");
		ToggleEnvironmentScanHandle.AddActiveUserButton(EHazeDebugActiveUserCategoryButtonType::DPadLeft, n"Beanstalk");
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(bDebugDrawHeight)
			DebugDrawHeight();

		if(bDebugDrawSplinePoints)
			DrawSplinePoints();

		if(bDebugDrawEnvironmentScan)
			DebugDrawEnvironmentScan();
	}

	void DebugDrawEnvironmentScan()
	{
		const FVector HeadOrigin = Beanstalk.HeadCenterLocation;
		const float CollisionRadius = Beanstalk.CollisionComp.SphereRadius;
		const float EnvironmentScanRadius = Settings.EnvironmentSphereRadius;
		const float EnvironmentScanRadiusOffset = Settings.EnvironmentScanOffset;

		System::DrawDebugSphere(HeadOrigin, CollisionRadius, 12, FLinearColor::Green);
		System::DrawDebugSphere(HeadOrigin, EnvironmentScanRadius, 12, FLinearColor::Blue);
		System::DrawDebugSphere(HeadOrigin, CollisionRadius + EnvironmentScanRadiusOffset, 12, FLinearColor::Red);
		PrintToScreen("EnvironmentScanFraction: " + Beanstalk.GetEnvironmentHitFraction());
	}

	void DebugDrawHeight()
	{
		FVector StartLocation = Beanstalk.BeanstalkStartLocation;
		FVector CurrentLocation = Beanstalk.HeadRotationNode.WorldLocation;
		StartLocation.X = CurrentLocation.X;
		StartLocation.Y = CurrentLocation.Y;
		float HeightDiff = Beanstalk.HeightDiff;
		float MaxHeight = Beanstalk.MaxHeight;
		float MinHeight = Beanstalk.MinHeight;

		System::DrawDebugLine(StartLocation, StartLocation + FVector::UpVector * MaxHeight, FLinearColor::Red);
		System::DrawDebugLine(StartLocation, StartLocation - FVector::UpVector * MinHeight, FLinearColor::Red);
		System::DrawDebugLine(StartLocation, CurrentLocation, FLinearColor::Green, 0.0f, 10.0f);

		if(!Beanstalk.HasSpawnedLeafPairs())
			return;

		const float LeafDistance = Beanstalk.SplineComp.GetDistanceAlongSplineAtWorldLocation(Beanstalk.GetLocationOfLastLeafPair());
		const float TotalDistance = Beanstalk.GetDistanceAlongSplineFromLastPoint();
		const float DistanceDiff = TotalDistance - LeafDistance;
		const float RemoveLeafDistance = Beanstalk.RemoveLeafPairDistance;

		System::DrawDebugPoint(Beanstalk.GetLocationOfLastLeafPair(), 30.0f, FLinearColor::Blue);

		const float RemoveDistanceTotal = LeafDistance + RemoveLeafDistance;
		FVector LocationAtRemoveDistance = Beanstalk.SplineComp.GetLocationAtDistanceAlongSpline(RemoveDistanceTotal, ESplineCoordinateSpace::World);
		System::DrawDebugPoint(LocationAtRemoveDistance, 25.0f, FLinearColor::Red);
	}

	void DrawSplinePoints()
	{
		for(int Index = 0; Index < Beanstalk.SplineComp.NumberOfSplinePoints; ++Index)
		{
			const FVector SplineLoc = Beanstalk.SplineComp.GetLocationAtSplinePoint(Index, ESplineCoordinateSpace::World);
			System::DrawDebugPoint(SplineLoc, 20.0f, FLinearColor::Blue);
		}
	}

	UFUNCTION()
	private void ToggleDebugDrawHeight()
	{
		bDebugDrawHeight = !bDebugDrawHeight;
	}

	UFUNCTION()
	private void ToggleDrawSplinePoints()
	{
		bDebugDrawSplinePoints = !bDebugDrawSplinePoints;
	}

	UFUNCTION()
	private void ToggleEnvironmentScan()
	{
		bDebugDrawEnvironmentScan = !bDebugDrawEnvironmentScan;
		Beanstalk.bDrawEnvironmentScanHitLocations = bDebugDrawEnvironmentScan;
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
}
