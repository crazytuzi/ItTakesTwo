import Cake.LevelSpecific.Music.NightClub.DJVinylPlayer;
import Cake.LevelSpecific.Music.NightClub.DJStationComponent;
import Vino.Movement.Components.MovementComponent;
import Vino.Movement.MovementSystemTags;
import Vino.Movement.Dash.CharacterDashSettings;

// just for the class type
class USyncedDJPlayRateComponent : UHazeSmoothSyncFloatComponent
{

}

UCLASS(abstract)
class UDJStationBaseCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityDebugCategory = n"LevelSpecific";
	default CapabilityTags.Add(n"DJStationBaseCapability");
	
	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 200;

	AHazePlayerCharacter Player;
	UDJStationComponent DJStationComp;
	ADJVinylPlayer VinylPlayer;
	UHazeMovementComponent MoveComp;
	UHazeCrumbComponent CrumbComp;
	USyncedDJPlayRateComponent SyncedPlayRate;

	EDJStandType TargetDJStandType = EDJStandType::None;

	bool bMoveToCenter = false;
	bool bPlayAnimation = false;

	float PlayRateDelay = 0.25f;
	float PlayRateDelayCurrent = 0.0f;
	float CurrentPlayRate = 0.0f;
	bool bIsPlayingAnimation = false;
	bool bBlockedMovementTags = false;

	FVector TargetLocation;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		DJStationComp = UDJStationComponent::Get(Owner);
		CrumbComp = UHazeCrumbComponent::Get(Owner);
		SyncedPlayRate = USyncedDJPlayRateComponent::GetOrCreate(Owner, n"DJStation_SyncedPlayRate");
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;
		
		if(TargetDJStandType == EDJStandType::None)
			return EHazeNetworkActivation::DontActivate;

		if(DJStationComp.VinylPlayer != nullptr)
		{
			ADJVinylPlayer DJStand = Cast<ADJVinylPlayer>(DJStationComp.VinylPlayer);
			if(DJStand != nullptr && DJStand.StationState == EDJStationState::Active && DJStand.DJStandType == TargetDJStandType && DJStand.AvailablePlayers.Contains(Player))
			{
				return EHazeNetworkActivation::ActivateUsingCrumb;
			}
		}
			
		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		ActivationParams.AddObject(n"VinylPlayer", DJStationComp.VinylPlayer);

		ADJVinylPlayer TempDJStation = Cast<ADJVinylPlayer>(DJStationComp.VinylPlayer);

		FHitResult Hit;
		const FVector StartLoc = TempDJStation.GetTargetLocation(Player);
		const FVector EndLoc = StartLoc - FVector::UpVector * 5000.0f;
		TArray<AActor> IgnoreActors;
		IgnoreActors.Add(Game::GetMay());
		IgnoreActors.Add(Game::GetCody());
		IgnoreActors.Add(DJStationComp.VinylPlayer);
		System::LineTraceSingle(StartLoc, EndLoc, ETraceTypeQuery::Visibility, false, IgnoreActors, EDrawDebugTrace::None, Hit, false);
		TargetLocation = Hit.ImpactPoint;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		VinylPlayer = Cast<ADJVinylPlayer>(ActivationParams.GetObject(n"VinylPlayer"));
		VinylPlayer.OnPlayerInteractionBegin(Player);
		bMoveToCenter = false;
		PlayRateDelayCurrent = 0.0f;
		SyncedPlayRate.Value = 0.0f;
		CurrentPlayRate = 0.0f;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!HasControl())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(DJStationComp.VinylPlayer == nullptr)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(DJStationComp.VinylPlayer != VinylPlayer)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(VinylPlayer.StationState != EDJStationState::Active)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(IsActioning(DashTags::GroundDashing))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		StopAnimation();
		UnblockMovementTags();

		VinylPlayer.OnPlayerInteractionEnd(Player);
		SyncedPlayRate.Value = 0.0f;
		bPlayAnimation = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		UpdateAnimation();
		if(!HasControl())
		{
			UpdateRemote(DeltaTime);
			return;
		}

		if(WasInputPressed())
		{
			bMoveToCenter = true;
			if(!bPlayAnimation)
			{
				NetPlayAnimation(true);
				BlockMovementTags();
			}
		}
		else if(bMoveToCenter && WantsToMove())
		{
			bMoveToCenter = false;
		}

		if(bIsPlayingAnimation)
			BlockMovementTags();

		if(MoveComp.CanCalculateMovement() && bMoveToCenter)
		{
			FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"PlayerDJStation");
			FQuat WantedRotation = VinylPlayer.GetTargetRotation(Player);
			MoveComp.SetTargetFacingRotation(WantedRotation);
			FrameMove.SetRotation(WantedRotation);

			const FVector DirectionToDanceLocation = (TargetLocation - Player.ActorLocation);
			const float DistanceToDanceLocation = DirectionToDanceLocation.Size();
			const float MovementSpeed = DistanceToDanceLocation / 0.1f;
			FrameMove.ApplyDelta(DirectionToDanceLocation.GetSafeNormal() * MovementSpeed * DeltaTime);
			MoveComp.Move(FrameMove);
			CrumbComp.LeaveMovementCrumb();
		}

		// Set play rate of the animation based on input
		if(bIsPlayingAnimation)
		{
			CurrentPlayRate = FMath::FInterpTo(CurrentPlayRate, GetPlayRate(), DeltaTime, 8.0f);
			SyncedPlayRate.Value = CurrentPlayRate;
			Player.SetSlotAnimationPlayRate(GetAnimation(Player), CurrentPlayRate);

			if(ShouldStopAnimation() && bPlayAnimation)
			{
				PlayRateDelayCurrent += DeltaTime;
				if(PlayRateDelayCurrent > PlayRateDelay)
				{
					NetPlayAnimation(false);
					UnblockMovementTags();
				}
			}
		}
	}

	private void UpdateRemote(float DeltaTime)
	{
		Player.SetSlotAnimationPlayRate(GetAnimation(Player), SyncedPlayRate.Value);

		FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"PlayerDJStation");
		FHazeActorReplicationFinalized ConsumedParams;
		CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
		FrameMove.ApplyConsumedCrumbData(ConsumedParams);
		MoveComp.Move(FrameMove);
	}

	bool WasInputPressed() const
	{
		return WasActionStarted(ActionNames::InteractionTrigger);
	}

	bool WantsToMove() const
	{
		return !GetAttributeVector(AttributeVectorNames::MovementDirection).IsNearlyZero(0.1f);
	}

	private void UpdateAnimation()
	{
		
		if(bPlayAnimation)
			StartAnimation();
		else
			StopAnimation();
	}

	private void StartAnimation()
	{
		if(bIsPlayingAnimation)
			return;

		FHazePlaySlotAnimationParams AnimParams;
		AnimParams.Animation = GetAnimation(Player);
		AnimParams.BlendTime = 0.09f;
		AnimParams.bLoop = ShouldLoopAnimation();

		Player.ResetMeshPose();
		Player.PlaySlotAnimation(AnimParams);
		bIsPlayingAnimation = true;
		VinylPlayer.OnPlayerAnimationStart();

		VinylPlayer.SetCapabilityActionState(n"AudioAnimationStarted", EHazeActionState::ActiveForOneFrame);
	}

	private void StopAnimation()
	{
		if(!bIsPlayingAnimation)
			return;

		Player.StopAnimationByAsset(GetAnimation(Player));
		bIsPlayingAnimation = false;
		PlayRateDelayCurrent = 0.0f;
		VinylPlayer.OnPlayerAnimationEnd();
		VinylPlayer.SetCapabilityActionState(n"AudioAnimationStopped", EHazeActionState::Active);
	}

	bool ShouldLoopAnimation() const
	{
		return true;
	}

	UFUNCTION(NetFunction)
	private void NetPlayAnimation(bool bValue)
	{
		bPlayAnimation = bValue;
	}

	UAnimSequence GetAnimation(AHazePlayerCharacter Player) const
	{
		return nullptr;
	}

	bool ShouldStopAnimation() const
	{
		return true;
	}

	UFUNCTION()
	private void HandleCrumb_StopAnimation(const FHazeDelegateCrumbData& CrumbData)
	{
		if(bIsPlayingAnimation)
		{
			Player.StopAllSlotAnimations();
			bIsPlayingAnimation = false;
			PlayRateDelayCurrent = 0.0f;
			ADJVinylPlayer LastVinylPlayer = Cast<ADJVinylPlayer>(CrumbData.GetObject(n"DJVinylPlayer"));
			LastVinylPlayer.OnPlayerAnimationEnd();
		}

		UnblockMovementTags();
	}

	float GetPlayRate() const
	{
		return 1.0f;
	}

	private void BlockMovementTags()
	{
		if(!bBlockedMovementTags && HasControl())
		{
			bBlockedMovementTags = true;
			Owner.BlockCapabilities(CapabilityTags::Movement, this);
			Owner.BlockCapabilities(CapabilityTags::CharacterFacing, this);
			Owner.BlockCapabilities(MovementSystemTags::BasicFloorMovement, this);
		}
	}

	private void UnblockMovementTags()
	{
		if(bBlockedMovementTags && HasControl())
		{
			bBlockedMovementTags = false;
			Owner.UnblockCapabilities(CapabilityTags::Movement, this);
			Owner.UnblockCapabilities(CapabilityTags::CharacterFacing, this);
			Owner.UnblockCapabilities(MovementSystemTags::BasicFloorMovement, this);
		}
	}
}
