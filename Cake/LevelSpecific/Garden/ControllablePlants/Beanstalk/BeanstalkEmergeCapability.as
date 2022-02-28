import Cake.LevelSpecific.Garden.ControllablePlants.Beanstalk.Beanstalk;

class UBeanstalkEmergeCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 9;

	ABeanstalk Beanstalk;
	UHazeMovementComponent MoveComp;
	UHazeCrumbComponent CrumbComp;
	UBeanstalkSettings Settings;

	float DistanceCurrent = 0.0f;
	float DistanceTotal = 0.0f;

	bool bHasPlayedAppearVFX = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Beanstalk = Cast<ABeanstalk>(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		CrumbComp = UHazeCrumbComponent::Get(Owner);
		Settings = UBeanstalkSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(Beanstalk.CurrentState != EBeanstalkState::Emerging)
			return EHazeNetworkActivation::DontActivate;

		if(!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		if(BeanstalkSoil == nullptr)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		bHasPlayedAppearVFX = false;
		DistanceCurrent = 0.0f;
		DistanceTotal = BeanstalkSoil.EmergeSplinePath.SplineLength;
		Beanstalk.SetActorHiddenInGame(false);
		Beanstalk.SetCapabilityActionState(n"AudioBeanStalkEmerge", EHazeActionState::ActiveForOneFrame);
		FHazeSplineSystemPosition SplinePosition = BeanstalkSoil.SplineRegion.GetEndPosition();
		Beanstalk.AppearVFXDistance = SplinePosition.DistanceAlongSpline;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const float Alpha = DistanceCurrent / DistanceTotal;
		const float SplineMovementSpeed = FMath::EaseIn(900.0f, 200.0f, Alpha, 5.0f);
		//PrintToScreen("SplineMovementSpeed " + SplineMovementSpeed);

		DistanceCurrent = FMath::Min(DistanceCurrent + SplineMovementSpeed * DeltaTime, DistanceTotal);

		if(!bHasPlayedAppearVFX && DistanceCurrent > Beanstalk.AppearVFXDistance)
		{
			bHasPlayedAppearVFX = true;
			Beanstalk.BP_OnBeanstalkAppear(Beanstalk.HeadRotationNode.WorldLocation, Beanstalk.HeadRotationNode.ForwardVector);
		}

		FHazeFrameMovement MoveData = MoveComp.MakeFrameMovement(BeanstalkTags::Beanstalk);

		//if(HasControl())
		{
			FVector LocationOnSpline = Spline.GetLocationAtDistanceAlongSpline(DistanceCurrent, ESplineCoordinateSpace::World);
			FRotator RotationOnSpline = Spline.GetRotationAtDistanceAlongSpline(DistanceCurrent, ESplineCoordinateSpace::World);

			Beanstalk.HeadRotationNode.SetWorldRotation(RotationOnSpline);

			FVector DeltaMovement = LocationOnSpline - Beanstalk.CollisionComp.WorldLocation;

			MoveData.ApplyDelta(DeltaMovement);
		}

		MoveComp.Move(MoveData);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(Beanstalk.CurrentState != EBeanstalkState::Emerging)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(!MoveComp.CanCalculateMovement())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(BeanstalkSoil == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(DistanceCurrent >= DistanceTotal)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Beanstalk.CurrentState = EBeanstalkState::Active;
		//Beanstalk.CurrentVelocity = Settings.InitialVelocity;
		Beanstalk.bCanExitBeanstalk = true;
		Beanstalk.EnableBeanstalkCollisionSphere();
		Beanstalk.PlayerCollision.SetCollisionProfileName(n"BlockOnlyPlayerCharacter");
		Beanstalk.MinimumMovementDistance = Beanstalk.SplineComp.SplineLength;
		// 80 magic offset
		Beanstalk.StopDistance = Beanstalk.BeanstalkSoil.EmergeSplinePath.SplineLength;
	}

	ASubmersibleSoilBeanstalk GetBeanstalkSoil() const property
	{
		return Beanstalk.BeanstalkSoil;
	}

	UHazeSplineComponent GetSpline() const property
	{
		return BeanstalkSoil.EmergeSplinePath;
	}
}
