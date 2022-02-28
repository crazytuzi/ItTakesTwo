import Cake.LevelSpecific.Clockwork.Bird.ClockworkBird;
import Cake.LevelSpecific.Clockwork.Bird.ClockworkBirdLandingPerch;

class UClockworkBirdLandOnPerchCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default CapabilityDebugCategory = n"ClockworkBirdFlying";

	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 90;

	UHazeMovementComponent MoveComp;
	UHazeCrumbComponent CrumbComp;
	AClockworkBird Bird;

	AClockworkBirdLandingPerch LandOnPerch;
	UClockworkBirdFlyingSettings Settings;

	bool bReachedLanding = false;
	FVector StartLocation;
	FHazeAcceleratedRotator BirdDirection;

    UFUNCTION(BlueprintOverride)
    void Setup(FCapabilitySetupParams SetupParams)
    {
		Bird = Cast<AClockworkBird>(Owner);
		MoveComp = UHazeMovementComponent::Get(Bird);
		CrumbComp = UHazeCrumbComponent::Get(Bird);
		Settings = UClockworkBirdFlyingSettings::GetSettings(Bird);
	}

	UFUNCTION(BlueprintOverride)
    void PreTick(float DeltaTime)
    {
		auto LandingPerch = Cast<AClockworkBirdLandingPerch>(GetAttributeObject(ClockworkBirdTags::LandOnPerch));

		// Stop the landing if our player got forcably dismounted some way
		if (!IsActive() && Bird.ActivePlayer == nullptr && LandingPerch != nullptr)
		{
			LandingPerch = nullptr;
			Bird.SetCapabilityAttributeObject(ClockworkBirdTags::LandOnPerch, nullptr);
		}

		if (HasControl() && !IsActive() && LandingPerch != nullptr)
			LandOnPerch = LandingPerch;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (LandOnPerch != nullptr)
			return EHazeNetworkActivation::ActivateUsingCrumb;
		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (bReachedLanding)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		if (LandOnPerch == nullptr)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		if (LandOnPerch.PerchedBird != nullptr && LandOnPerch.PerchedBird != Bird)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		if (LandOnPerch.ApproachingBird != nullptr && LandOnPerch.ApproachingBird != Bird)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		ActivationParams.AddObject(n"Point", LandOnPerch);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Bird.BlockCapabilities(n"ClockworkBirdFlying", this);
		Bird.BlockCapabilities(n"ClockworkBirdAirMove", this);
		Bird.BlockCapabilities(n"ClockworkBirdJump", this);
		Bird.BlockCapabilities(n"ClockworkBirdLand", this);

		Bird.SetIsFlying(true);
		Bird.bIsLanding = true;
		bReachedLanding = false;

		LandOnPerch = Cast<AClockworkBirdLandingPerch>(ActivationParams.GetObject(n"Point"));
		LandOnPerch.StartApproaching(Bird);
		Bird.CurrentPerch = LandOnPerch;

		StartLocation = Bird.ActorLocation;

		FRotator CurrentRotation = Bird.ActorRotation;
		CurrentRotation.Pitch = Bird.Mesh.RelativeRotation.Pitch;
		CurrentRotation.Roll = Bird.Mesh.RelativeRotation.Roll;

		BirdDirection.SnapTo(CurrentRotation);
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreDeactivation(FCapabilityDeactivationSyncParams& DeactivationParams)
	{
		if (LandOnPerch != nullptr && LandOnPerch.ApproachingBird == Bird)
			DeactivationParams.AddActionState(n"SuccessPerch");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Bird.UnblockCapabilities(n"ClockworkBirdFlying", this);
		Bird.UnblockCapabilities(n"ClockworkBirdAirMove", this);
		Bird.UnblockCapabilities(n"ClockworkBirdJump", this);
		Bird.UnblockCapabilities(n"ClockworkBirdLand", this);

		Bird.SetIsFlying(false);
		Bird.bIsLanding = false;

		Bird.SetCapabilityAttributeObject(ClockworkBirdTags::LandOnPerch, nullptr);
		Bird.MoveComp.SetVelocity(FVector::ZeroVector);

		if (DeactivationParams.GetActionState(n"SuccessPerch"))
		{
			Bird.SetCapabilityAttributeObject(ClockworkBirdTags::PerchedOnPerch, LandOnPerch);
			LandOnPerch.BirdPerched(Bird);
		}
		else
		{
			LandOnPerch.StopApproaching(Bird);
			Bird.CurrentPerch = nullptr;
		}

		LandOnPerch = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!MoveComp.CanCalculateMovement())
			return;

		FHazeFrameMovement MoveData = MoveComp.MakeFrameMovement(n"ClockworkBirdLandOnPerch");
		if (HasControl())
		{
			float LandPct = FMath::Clamp(ActiveDuration / Settings.LandOnPerchDuration, 0.f, 1.f);
			FVector TargetPosition = FMath::Lerp(
				StartLocation,
				LandOnPerch.ActorLocation,
				LandPct);

			if (LandPct >= 1.f && LandOnPerch.ApproachingBird == Bird)
				bReachedLanding = true;

			FVector MoveDelta = TargetPosition - Bird.ActorLocation;
			FRotator TargetRotation;
			if (MoveDelta.Size() < 0.01f)
				TargetRotation = FRotator();
			else
				TargetRotation = FRotator::MakeFromX(MoveDelta.GetSafeNormal());

			if (ActiveDuration > 1.f)
				TargetRotation.Pitch = FMath::Clamp(TargetRotation.Pitch, -15.f, 15.f);

			BirdDirection.AccelerateTo(TargetRotation, 1.f, DeltaTime);

			FRotator NewMeshRotation(BirdDirection.Value.Pitch, 0.f, BirdDirection.Value.Roll);
			Bird.Mesh.RelativeRotation = NewMeshRotation;

			FRotator NewActorRotation(0.f, BirdDirection.Value.Yaw, 0.f);
			MoveComp.SetTargetFacingRotation(NewActorRotation);

			MoveData.ApplyDelta(MoveDelta);
			MoveData.ApplyTargetRotationDelta();		
			MoveData.OverrideCollisionProfile(n"OverlapAllDynamic");
			MoveComp.Move(MoveData);	

			Bird.SetNewFlightSpeed(MoveComp.Velocity.Size());
			CrumbComp.SetCustomCrumbRotation(Bird.Mesh.RelativeRotation);
			CrumbComp.LeaveMovementCrumb();		
		}
		else
		{
			FHazeActorReplicationFinalized ReplicatedMovement;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ReplicatedMovement);
			MoveData.ApplyConsumedCrumbData(ReplicatedMovement);
			Bird.BirdRoot.SetRelativeRotation(ReplicatedMovement.CustomCrumbRotator);
			MoveComp.Move(MoveData);
		}
	}
};