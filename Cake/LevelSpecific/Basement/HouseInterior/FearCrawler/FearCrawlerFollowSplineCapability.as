import Cake.LevelSpecific.Basement.HouseInterior.FearCrawler.FearCrawler;

class AFearCrawlerFollowSplineCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Example");

	default CapabilityDebugCategory = n"Example";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AFearCrawler FearCrawler;

	float CurrentDistanceAlongSpline = 0.f;
	float SpeedAlongSpline = 2000.f;

	bool bReachedEndOfSpline = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		FearCrawler = Cast<AFearCrawler>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!FearCrawler.bFollowingSpline)
			return EHazeNetworkActivation::DontActivate;

		if (FearCrawler.TargetFollowSpline == nullptr)
			return EHazeNetworkActivation::DontActivate;
		
		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!FearCrawler.bFollowingSpline)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		if (FearCrawler.TargetFollowSpline == nullptr)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		if (bReachedEndOfSpline)
			return EHazeNetworkDeactivation::DeactivateFromControl;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		bReachedEndOfSpline = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		FearCrawler.bFollowingSpline = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		CurrentDistanceAlongSpline += FearCrawler.MovementSpeed * DeltaTime;
		FVector Location = FearCrawler.TargetFollowSpline.GetLocationAtDistanceAlongSpline(CurrentDistanceAlongSpline, ESplineCoordinateSpace::World);
		FRotator Rotation = FearCrawler.TargetFollowSpline.GetRotationAtDistanceAlongSpline(CurrentDistanceAlongSpline, ESplineCoordinateSpace::World);
		FearCrawler.SetActorLocationAndRotation(Location, Rotation);

		if (CurrentDistanceAlongSpline >= FearCrawler.TargetFollowSpline.SplineLength)
			bReachedEndOfSpline = true;
	}
}