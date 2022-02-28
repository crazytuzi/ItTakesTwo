import Vino.Movement.MovementSystemTags;
import Cake.LevelSpecific.Music.NightClub.RhythmDanceAreaActor;
import Vino.Movement.Components.MovementComponent;

class UPlayerRhythmCapability : UHazeCapability
{
	default CapabilityDebugCategory = n"LevelSpecific";

	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 10;

	AHazePlayerCharacter Player;
	UPlayerRhythmComponent RhythmComp;
	UHazeMovementComponent MoveComp;
	UHazeCrumbComponent CrumbComp;

	ARhythmActor DanceArea;

	bool bWasAnyButtonPressed = false;
	bool bMoveToCenter = false;

	FVector DanceLocation;

	UFUNCTION(BlueprintOverride)
	void Setup(const FCapabilitySetupParams& SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		RhythmComp = UPlayerRhythmComponent::Get(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		CrumbComp = UHazeCrumbComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;

		if(RhythmComp.RhythmDanceArea == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(!RhythmComp.RhythmDanceArea.IsRhythmActorActive())
			return EHazeNetworkActivation::DontActivate;

		if(PlayerWantsToMove)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& OutParams)
	{
		OutParams.AddObject(n"DanceArea", RhythmComp.RhythmDanceArea);

		FHitResult Hit;
		const FVector StartLoc = RhythmComp.RhythmDanceArea.DanceLocation;
		const FVector EndLoc = StartLoc - FVector::UpVector * 5000.0f;
		TArray<AActor> IgnoreActors;
		IgnoreActors.Add(Game::GetMay());
		IgnoreActors.Add(Game::GetCody());
		IgnoreActors.Add(RhythmComp.RhythmDanceArea);
		System::LineTraceSingle(StartLoc, EndLoc, ETraceTypeQuery::Visibility, false, IgnoreActors, EDrawDebugTrace::None, Hit, false);
		DanceLocation = Hit.ImpactPoint;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Owner.CleanupCurrentMovementTrail();
		RhythmComp.RhythmDanceArea = Cast<ARhythmActor>(ActivationParams.GetObject(n"DanceArea"));
		Owner.BlockCapabilities(MovementSystemTags::GroundMovement, this);
		Owner.BlockCapabilities(MovementSystemTags::Jump, this);
		Owner.BlockCapabilities(MovementSystemTags::Crouch, this);
		Owner.BlockCapabilities(MovementSystemTags::Dash, this);
		Owner.BlockCapabilities(MovementSystemTags::SlopeSlide, this);
		Player.AddLocomotionFeature(Player.IsMay() ? RhythmComp.MayDance : RhythmComp.CodyDance);
		bMoveToCenter = false;
		RhythmComp.StartDancing();

		
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		//Owner.CleanupCurrentMovementTrail();
		Owner.UnblockCapabilities(MovementSystemTags::GroundMovement, this);
		Owner.UnblockCapabilities(MovementSystemTags::Jump, this);
		Owner.UnblockCapabilities(MovementSystemTags::Crouch, this);
		Owner.UnblockCapabilities(MovementSystemTags::Dash, this);
		Owner.UnblockCapabilities(MovementSystemTags::SlopeSlide, this);
		Player.ClearLocomotionAssetByInstigator(this);
		RhythmComp.StopDancing();
	}	

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(RhythmComp.RhythmDanceArea == nullptr)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(!RhythmComp.RhythmDanceArea.IsRhythmActorActive())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(PlayerWantsToMove)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		RhythmComp.bLeftMiss = false;
		RhythmComp.bLeftHit = false;
		RhythmComp.bTopMiss = false;
		RhythmComp.bTopHit = false;
		RhythmComp.bRightMiss = false;
		RhythmComp.bRightHit = false;

		if(MoveComp.CanCalculateMovement())
		{
			FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"PlayerDance");

			if(HasControl())
			{
				if(PlayerAnyInput)
				{
					FVector DirToTarget = (Player.ViewLocation - Player.ActorCenterLocation).GetSafeNormal2D() * -1.0f;
					MoveComp.SetTargetFacingDirection(DirToTarget);
					FrameMove.SetRotation(DirToTarget.ToOrientationQuat());
					const FVector DirectionToDanceLocation = (DanceLocation - Player.ActorLocation);
					const float DistanceToDanceLocation = DirectionToDanceLocation.Size();
					const float MovementSpeed = DistanceToDanceLocation / 0.1f;
					FrameMove.ApplyDelta(DirectionToDanceLocation.GetSafeNormal() * MovementSpeed * DeltaTime);
				}
			}
			else
			{
				FHazeActorReplicationFinalized ConsumedParams;
				CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
				FrameMove.ApplyConsumedCrumbData(ConsumedParams);
			}

			MoveComp.Move(FrameMove);
			CrumbComp.LeaveMovementCrumb();
		}

		FHazeRequestLocomotionData AnimationRequest;
		AnimationRequest.AnimationTag = n"Dance";
		Player.RequestLocomotion(AnimationRequest);

		MoveComp.SetAnimationToBeRequested(n"Dance");
	}

	bool GetPlayerAnyInput() const property
	{
		return WasActionStarted(ActionNames::DanceLeft) || 
		WasActionStarted(ActionNames::DanceTop) || 
		WasActionStarted(ActionNames::DanceRight);
	}

	bool GetPlayerWantsToMove() const property
	{
		return !GetAttributeVector(AttributeVectorNames::MovementDirection).IsNearlyZero(0.1f);
	}
}
