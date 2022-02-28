import Cake.LevelSpecific.SnowGlobe.Boatsled.BoatsledComponent;

class UBoatsledFinishCapability : UHazeCapability
{
	default CapabilityTags.Add(BoatsledTags::Boatsled);
	default CapabilityTags.Add(BoatsledTags::BoatsledFinish);

	default TickGroup = ECapabilityTickGroups::ReactionMovement;

	default CapabilityDebugCategory = BoatsledTags::Boatsled;

	AHazePlayerCharacter PlayerOwner;
	UBoatsledComponent BoatsledComponent;
	UHazeMovementComponent BoatsledMovementComponent;

	const float Speed = 7000.f;

	bool bLevelSequenceDone;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		BoatsledComponent = UBoatsledComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(BoatsledComponent == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(!BoatsledComponent.IsFinishing())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		// Set velocity
		BoatsledMovementComponent = BoatsledComponent.Boatsled.MovementComponent;
		BoatsledMovementComponent.SetVelocity(BoatsledComponent.TrackSpline.GetDirectionAtDistanceAlongSpline(BoatsledComponent.TrackSpline.SplineLength, ESplineCoordinateSpace::World) * Speed);

		// Play level sequence if it's not already playing
		if(ShouldPlayLevelSequence())
		{
			PlayerOwner.ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen);
			BoatsledComponent.Boatsled.FinishSequence.PlayLevelSequenceSimple(FOnHazeSequenceFinished(this, n"OnLevelSequenceFinished"), PlayerOwner);
		}

		// Fire completion event on player
		BoatsledComponent.BoatsledEventHandler.OnBoatsledCompleted.Broadcast(PlayerOwner);

		// Init
		bLevelSequenceDone = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeFrameMovement MoveData = BoatsledMovementComponent.MakeFrameMovement(BoatsledTags::BoatsledFinish);
		MoveData.OverrideGroundedState(EHazeGroundedState::Airborne);
		MoveData.OverrideStepDownHeight(0.f);
		MoveData.OverrideStepUpHeight(0.f);

		if(HasControl())
		{
			FVector Velocity = BoatsledMovementComponent.Velocity;
			Velocity += BoatsledMovementComponent.Gravity * 0.8f * DeltaTime;
			MoveData.ApplyVelocity(Velocity);

			BoatsledMovementComponent.SetTargetFacingDirection(Velocity.GetSafeNormal(), 0.f);

			BoatsledMovementComponent.Move(MoveData);
			BoatsledComponent.Boatsled.CrumbComponent.LeaveMovementCrumb();
		}
		else
		{
			FHazeActorReplicationFinalized CrumbData;
			BoatsledComponent.Boatsled.CrumbComponent.ConsumeCrumbTrailMovement(DeltaTime, CrumbData);
			MoveData.ApplyConsumedCrumbData(CrumbData);
			BoatsledMovementComponent.Move(MoveData);
		}

		// Set boatsled mesh rotation
		FRotator MeshRotation = Math::MakeRotFromX(BoatsledMovementComponent.Velocity);
		BoatsledComponent.Boatsled.MeshOffsetComponent.OffsetRotationWithTime(MeshRotation, 0.2f);

		// Y'all got anymore o'them locomotions?
		BoatsledComponent.RequestPlayerBoatsledLocomotion();

		// Some rumble why not
		PlayerOwner.SetFrameForceFeedback(0.02f, 0.03f);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(bLevelSequenceDone)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		bLevelSequenceDone = false;
	}

	bool ShouldPlayLevelSequence() const
	{
		if(!HasControl())
			return false;

		if(PlayerOwner.ActiveLevelSequenceActor != nullptr)
			return false;

		if(PlayerOwner.OtherPlayer.ActiveLevelSequenceActor != nullptr)
			return false;

		return true;
	}

	UFUNCTION(NotBlueprintCallable)
	void OnLevelSequenceFinished()
	{
		UHazeCrumbComponent PlayerCrumbComponent = UHazeCrumbComponent::Get(Owner);
		PlayerCrumbComponent.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_OnLevelSequenceFinished"), FHazeDelegateCrumbParams());
	}

	UFUNCTION(NotBlueprintCallable)
	void Crumb_OnLevelSequenceFinished(const FHazeDelegateCrumbData& CrumbData)
	{
		BoatsledComponent.StopSledding();
	}
}