import Cake.LevelSpecific.SnowGlobe.Boatsled.BoatsledComponent;

class UBoatsledPreJumpRubberBandingCapability : UHazeCapability
{
	default CapabilityTags.Add(BoatsledTags::Boatsled);
	default CapabilityTags.Add(BoatsledTags::BoatsledPreJumpRubberBanding);

	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 90;

	default CapabilityDebugCategory = BoatsledTags::Boatsled;

	AHazePlayerCharacter PlayerOwner;
	UBoatsledComponent BoatsledComponent;

	ABoatsled Boatsled;
	UHazeSplineComponent TrackSpline;

	const float MinDistanceBetweenSleds = 800.f;

	float InitialMaxSpeed;
	float JumpDistanceAlongSpline;
	float TargetSpeed;

	bool bShouldActivate;
	bool bShouldDeactivate;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		BoatsledComponent = UBoatsledComponent::Get(Owner);

		// Fired when entering jump spline region
		BoatsledComponent.BoatsledEventHandler.OnBoatsledPreJumpRubberBand.AddUFunction(this, n"OnBoatsledPreJumpRubberBand");
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!bShouldActivate)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		bShouldActivate = false;
		Boatsled = BoatsledComponent.Boatsled;
		TrackSpline = BoatsledComponent.TrackSpline;
		InitialMaxSpeed = BoatsledComponent.GetBoatsledMaxSpeed(false);

		// Figure out position in track
		float DistanceAlongSpline = TrackSpline.GetDistanceAlongSplineAtWorldLocation(Boatsled.ActorLocation);
		float OtherBoatsledDistanceAlongSpline = TrackSpline.GetDistanceAlongSplineAtWorldLocation(Boatsled.OtherBoatsled.ActorLocation);

		// Slow down if player is behind
		TargetSpeed = InitialMaxSpeed * (DistanceAlongSpline < OtherBoatsledDistanceAlongSpline ? 0.72f : 1.1f);
		BoatsledComponent.ChangeMaxSpeedOverTime(TargetSpeed, 0.8f);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Don't screw around with speed if we're currently accelerating towards it
		if(PlayerOwner.IsAnyCapabilityActive(BoatsledTags::BoatsledSpeedModerator))
			return;

		// Restore speed once sleds are at a good distance
		if(BoatsledComponent.GetDistanceBetweenBoatsleds() >= MinDistanceBetweenSleds)
		{
			BoatsledComponent.ChangeMaxSpeedOverTime(InitialMaxSpeed, 0.5f);
		}
		// Otherwise rubber band a bit faster
		else
		{
			BoatsledComponent.ChangeMaxSpeedOverTime(TargetSpeed, 0.2f);
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!BoatsledComponent.IsSledding())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		// Restore max speed
		BoatsledComponent.SetBoatsledMaxSpeed(InitialMaxSpeed);

		TrackSpline = nullptr;
		TargetSpeed = 0.f;
		InitialMaxSpeed = 0.f;
		JumpDistanceAlongSpline = 0.f;
		bShouldDeactivate = false;
	}

	UFUNCTION(NotBlueprintCallable)
	void OnBoatsledPreJumpRubberBand(float _JumpDistanceAlongSpline)
	{
		bShouldActivate = true;
		JumpDistanceAlongSpline = _JumpDistanceAlongSpline;
	}
}