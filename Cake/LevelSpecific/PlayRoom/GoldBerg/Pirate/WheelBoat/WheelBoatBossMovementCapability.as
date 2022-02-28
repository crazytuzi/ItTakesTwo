import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.WheelBoat.WheelBoatActor;
import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.WheelBoat.WheelBoatStreamComponent;
import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.OctopusBoss.PirateOctopusActor;

class UWheelBoatBossMovementCapability : UHazeCapability
{
    default CapabilityTags.Add(n"WheelBoat");
	default CapabilityTags.Add(n"WheelBoatBossMovement");	

    default TickGroup = ECapabilityTickGroups::LastMovement;

	AWheelBoatActor WheelBoat;
	UHazeBaseMovementComponent MoveComp;
	UHazeCrumbComponent LeftCrumbComponent;
	UHazeCrumbComponent RightCrumbComponent;
	UWheelBoatStreamComponent StreamComponent;
	APirateOctopusActor OctopusBoss;

	FRotator RootStreamRotation;
	FRotator StreamRotation;
	FRotator SpinRotation;

	//bool StartedSpinning;
	float AddedSpinForce;
	float ModifyCrumbRotationBlockTime = 0;
	float CanChangeDirectionTime = 0;
	
    UFUNCTION(BlueprintOverride)
    void Setup(FCapabilitySetupParams Params)
    {
		WheelBoat = Cast<AWheelBoatActor>(Owner);
		MoveComp = UHazeBaseMovementComponent::Get(WheelBoat);
		LeftCrumbComponent = UHazeCrumbComponent::Get(WheelBoat.LeftWheelSubActor);
		RightCrumbComponent = UHazeCrumbComponent::Get(WheelBoat.RightWheelSubActor);
		StreamComponent = WheelBoat.StreamComponent;

		WheelBoat.OnStopSpinning.AddUFunction(this, n"OnStoppedSpinning");
    }
	
    UFUNCTION(BlueprintOverride)
    EHazeNetworkActivation ShouldActivate() const
    {
		if(!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		if(!WheelBoat.UseBossFightMovement())
            return EHazeNetworkActivation::DontActivate;

		if(WheelBoat.PlayerInLeftWheel == nullptr)
            return EHazeNetworkActivation::DontActivate;

		if(WheelBoat.PlayerInRightWheel == nullptr)
            return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;   
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkDeactivation ShouldDeactivate() const
    {
		if(!MoveComp.CanCalculateMovement())
			 return EHazeNetworkDeactivation::DeactivateLocal;

		if(WheelBoat.bDocked)
		    return EHazeNetworkDeactivation::DeactivateLocal;

		if(!WheelBoat.UseBossFightMovement())
		    return EHazeNetworkDeactivation::DeactivateLocal;

		if(WheelBoat.PlayerInLeftWheel == nullptr)
		    return EHazeNetworkDeactivation::DeactivateLocal;

		if(WheelBoat.PlayerInRightWheel == nullptr)
		    return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
    }

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		WheelBoat.StopMovement();
		WheelBoat.CapsuleComponent.CollisionEnabled == ECollisionEnabled::NoCollision;
		WheelBoat.LeftWheelSubActor.TriggerMovementTransition(this);
		WheelBoat.RightWheelSubActor.TriggerMovementTransition(this);
		OctopusBoss = Cast<APirateOctopusActor>(WheelBoat.OctopusBoss);
		// if(WheelBoat.IsInStream())
		// {
		// 	WheelBoat.RotationBase.WorldRotation = FRotator::ZeroRotator;
		// }

		CanChangeDirectionTime = Time::GetGameTimeSeconds() * 0.5f;
		WheelBoat.SpinDirection = 1;

		TArray<AHazePlayerCharacter> Players = Game::GetPlayers();
		for(auto Player : Players)
		{
			Player.BlockCapabilities(n"CameraWheelBoatLazyChase", this);
		}
	}
	
	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		WheelBoat.SetActorRotation(WheelBoat.RotationBase.WorldRotation);
		WheelBoat.RotationBase.SetRelativeRotation(FRotator::ZeroRotator);
		TArray<AHazePlayerCharacter> Players = Game::GetPlayers();
		for(auto Player : Players)
		{
			Player.UnblockCapabilities(n"CameraWheelBoatLazyChase", this);
		}
	}


    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
		FWheelBoatMovementData& LeftMovementData = WheelBoat.LeftWheelSubActor.MovementData;
		FWheelBoatMovementData& RightMovementData = WheelBoat.RightWheelSubActor.MovementData;

		FHazeFrameMovement Movement = MoveComp.MakeFrameMovement(n"WheelBoatMovement");

		FRotator DeltaRotation;
		DeltaRotation.Yaw += LeftMovementData.RequestedDeltaRotationYaw;
		DeltaRotation.Yaw -= RightMovementData.RequestedDeltaRotationYaw;

		FRotator FinalRotation;

		if(WheelBoat.bSpinning)
			UpdateSpin(DeltaTime);	

		else
		{
			AddedSpinForce = 0;
			ModifyCrumbRotationBlockTime = FMath::Max(ModifyCrumbRotationBlockTime, 0.f);		
		}
		
		bool bShouldSyncLocation = true;
		FVector FinalDelta;
		if(WheelBoat.IsInStream())
		{
			bShouldSyncLocation = OctopusBoss.GetActiveArmsCount() == 0;
			FVector FaceBossDir = (OctopusBoss.ActorLocation - WheelBoat.ActorLocation);
			FaceBossDir.Z = 0;
			FaceBossDir = -(FaceBossDir.Rotation().RightVector);

			MoveComp.ForceActorRotationWithoutUpdatingMovement(FaceBossDir.Rotation());
			Movement.ApplyTargetRotationDelta();

			FinalRotation = WheelBoat.RotationBase.WorldRotation + DeltaRotation;
			ModifyFromStreamData(DeltaTime, FinalDelta, FinalRotation);
			
			if(!WheelBoat.bSpinning)
			{
				// Change the current spin direction after we started to turn
				if(HasControl() && Time::GetGameTimeSeconds() > CanChangeDirectionTime)
				{
					const float ChangeAmount = LeftMovementData.WheelMovementRange - RightMovementData.WheelMovementRange;
					if(FMath::Abs(ChangeAmount) > 0.9f)
					{
						float WantedDir = FMath::Sign(ChangeAmount);
						if(WantedDir !=  WheelBoat.SpinDirection)
							NetSetSpinDirection(WantedDir);
					}
				}

				if(FMath::Abs(LeftMovementData.WheelMovementRange) < 0.5f && FMath::Abs(RightMovementData.WheelMovementRange) < 0.5f)
				{
					ModifyFromAutoRotation(DeltaTime, FinalRotation);
				}			
			}
		}
		else
		{
			FinalRotation = WheelBoat.ActorRotation + DeltaRotation;
		}

		if (Network::IsNetworked())
		{
			ModifyFromCrumbData(LeftCrumbComponent, DeltaTime, FinalDelta, FinalRotation, bSyncLocation = bShouldSyncLocation);
			ModifyFromCrumbData(RightCrumbComponent, DeltaTime, FinalDelta, FinalRotation, bSyncLocation = bShouldSyncLocation);
		}

		if(!WheelBoat.IsInStream())
		{
			MoveComp.SetTargetFacingRotation(FinalRotation);
			Movement.ApplyTargetRotationDelta();
		}

		// Always align the boat to the Z plain
		Movement.ApplyDeltaWithCustomVelocity(FVector(0.f, 0.f, WheelBoat.BoatZLocation - WheelBoat.ActorLocation.Z), FVector::ZeroVector);

		Movement.ApplyDelta(FinalDelta);
		
		FVector LastActorLocation = WheelBoat.ActorLocation;
		MoveComp.Move(Movement);

		// Update the base rotation last
		if(WheelBoat.IsInStream())
		{
			LeftCrumbComponent.SetCustomCrumbRotation(FinalRotation);
			RightCrumbComponent.SetCustomCrumbRotation(FinalRotation);
			WheelBoat.RotationBase.SetWorldRotation(FinalRotation);
	
			// Finalize the position on the spline
			FHazeSplineSystemPosition LockedStreamPosition = StreamComponent.LockedStream.Spline.GetPositionClosestToWorldLocation(WheelBoat.ActorLocation, true);
			StreamComponent.UpdateSplineMovementFromPosition(LockedStreamPosition);
		}
		else
		{
			WheelBoat.RotationBase.SetRelativeRotation(FRotator::ZeroRotator);
		}
	
		LeftCrumbComponent.LeaveMovementCrumb();
		RightCrumbComponent.LeaveMovementCrumb();

		WheelBoat.FinalizeMovement(DeltaTime);
	}

	UFUNCTION(NetFunction)
	void NetSetSpinDirection(float Dir)
	{
		WheelBoat.SpinDirection = Dir;
		CanChangeDirectionTime = Time::GetGameTimeSeconds() + 0.5f;
	}

	void UpdateSpin(float DeltaTime)
	{
		if(AddedSpinForce >= WheelBoat.TotalAmountToSpin - KINDA_SMALL_NUMBER)
		{
			WheelBoat.StopSpinning();
			ModifyCrumbRotationBlockTime = Time::GetGameTimeSeconds() + 0.5f;
			return;
		}

	 	float ForceToAdd = FMath::Min(WheelBoat.CurrentSpinForce * DeltaTime, WheelBoat.TotalAmountToSpin - AddedSpinForce);
		AddedSpinForce += FMath::Abs(ForceToAdd);
		ModifyCrumbRotationBlockTime = -1;
	}

	UFUNCTION(NotBlueprintCallable)
	void OnStoppedSpinning()
	{
		ModifyCrumbRotationBlockTime = 0;
		AddedSpinForce = 0;
	}

	void ModifyFromStreamData(float DeltaTime, FVector& OutFinalDelta, FRotator& OutFinalRotation)
	{
		FVector BossLocation = OctopusBoss.GetActorLocation();
		BossLocation.Z = WheelBoat.BoatZLocation;
		
		const FVector DirToBoss = (BossLocation - WheelBoat.ActorLocation).GetSafeNormal();

		float StreamDeltaMovement = StreamComponent.StreamMovementForce * DeltaTime;

		EHazeUpdateSplineStatusType Status = EHazeUpdateSplineStatusType::Invalid;
		FHazeSplineSystemPosition NewSplinePosition = StreamComponent.PeekPosition(StreamDeltaMovement, Status);
		if(Status != EHazeUpdateSplineStatusType::Invalid && Status != EHazeUpdateSplineStatusType::Unreachable)
		{
			OutFinalDelta += NewSplinePosition.WorldLocation - WheelBoat.ActorLocation;
			OutFinalDelta.Z = 0;
		}
	}

	void ModifyFromAutoRotation(float DeltaTime, FRotator& OutFinalRotation)
	{
		const float AutoTurnSpeed = WheelBoat.BoatSettings.BossStreamAutoRotationSpeed;
		OutFinalRotation.Yaw += WheelBoat.SpinDirection * AutoTurnSpeed * DeltaTime;
	}

	void ModifyFromCrumbData(UHazeCrumbComponent CrumbComp, float DeltaTime, FVector& OutFinalDelta, FRotator& OutFinalRotation, bool bSyncLocation = true, bool bSyncRotation = true)
	{
		if(CrumbComp.HasControl())
			return;

		FHazeActorReplicationFinalized ConsumedParams;
		CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);

		// Sync location
		if(bSyncLocation)
		{
			const FVector BoatLocation = WheelBoat.ActorLocation;
			const float Distance = ConsumedParams.Location.Distance(BoatLocation);
			float SyncAmount = FMath::Min(FMath::Max(Distance - 100.f, 0.f) / 1000.f, 1.f);
			float SyncAlpha = FMath::Lerp(0.f, 0.5f, SyncAmount);

			if(SyncAlpha > 0)
			{
				const FVector MedianLocation = FMath::Lerp(BoatLocation, ConsumedParams.Location, SyncAlpha);
				const FVector FinalLocation = FMath::VInterpTo(BoatLocation, MedianLocation, DeltaTime, 2.0f);
				OutFinalDelta += (FinalLocation - BoatLocation);
			}
		}

		if(ModifyCrumbRotationBlockTime < 0)
			return;

		if(ModifyCrumbRotationBlockTime > Time::GetGameTimeSeconds())
			return;

		// Sync Rotation
		if(bSyncRotation)
		{
			FRotator BoatRotation = WheelBoat.ActorRotation;
			FRotator CrumbRotation = ConsumedParams.Rotation;
			
			if(WheelBoat.IsInStream())
			{
				BoatRotation = WheelBoat.RotationBase.WorldRotation;
				CrumbRotation = ConsumedParams.CustomCrumbRotator;
			}

			float AngleDiff = Math::GetAngle(BoatRotation.ForwardVector, CrumbRotation.ForwardVector);
			float SyncAmount = FMath::Min(FMath::Max(AngleDiff - 2.f, 0.f) / 10.f, 1.f);
			float SyncAlpha = FMath::Lerp(0.f, 0.5f, SyncAmount);

			if(SyncAlpha > 0)
			{
				const FRotator MedianRotation = FMath::LerpShortestPath(BoatRotation, CrumbRotation, SyncAlpha);
				const FRotator FinalRotation = FMath::RInterpTo(BoatRotation, MedianRotation, DeltaTime, 0.5f);
				OutFinalRotation.Yaw += (FinalRotation - BoatRotation).Yaw;
			}
		}
	}
};