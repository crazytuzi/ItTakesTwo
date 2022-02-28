import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.WheelBoat.WheelBoatActor;

class UWheelBoatBossThrownInAirCapability : UHazeCapability
{
    default CapabilityTags.Add(n"WheelBoat");
	default CapabilityTags.Add(n"WheelBoatBossMovement");	

    default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 90;

	AWheelBoatActor WheelBoat;
	UHazeBaseMovementComponent MoveComp;
	UHazeCrumbComponent LeftCrumbComponent;
	UHazeCrumbComponent RightCrumbComponent;
	UWheelBoatStreamComponent StreamComponent;

	const float UpForceToApply = 10000.f;
	const float DownForceToApply = 982.f * 4;
	FVector CurrentUpForce;


    UFUNCTION(BlueprintOverride)
    void Setup(FCapabilitySetupParams Params)
    {
		WheelBoat = Cast<AWheelBoatActor>(Owner);
		MoveComp = UHazeBaseMovementComponent::Get(WheelBoat);
		LeftCrumbComponent = UHazeCrumbComponent::Get(WheelBoat.LeftWheelSubActor);
		RightCrumbComponent = UHazeCrumbComponent::Get(WheelBoat.RightWheelSubActor);
		StreamComponent = WheelBoat.StreamComponent;
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkActivation ShouldActivate() const
    {
		if(!WheelBoat.bSpinning)
			return EHazeNetworkActivation::DontActivate;

		if(WheelBoat.BossFightIndex != 3)
			return EHazeNetworkActivation::DontActivate;
	
		if(!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		if(!WheelBoat.IsInBossFight())
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
		if(ActiveDuration < 0.5f)
			return EHazeNetworkDeactivation::DontDeactivate;

		if(!WheelBoat.bSpinning)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(WheelBoat.BossFightIndex != 3)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(!MoveComp.CanCalculateMovement())
			 return EHazeNetworkDeactivation::DeactivateLocal;

		if(!WheelBoat.IsInBossFight())
		    return EHazeNetworkDeactivation::DeactivateLocal;

		if(WheelBoat.PlayerInLeftWheel == nullptr)
		    return EHazeNetworkDeactivation::DeactivateLocal;

		if(WheelBoat.PlayerInRightWheel == nullptr)
		    return EHazeNetworkDeactivation::DeactivateLocal;

		if(WheelBoat.ActorLocation.Z <= WheelBoat.BoatZLocation)
			return EHazeNetworkDeactivation::DeactivateLocal;

        return EHazeNetworkDeactivation::DontDeactivate;
    }

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		// if (WheelBoat.OnBoatJabbedEvent.IsBound())
		// 	WheelBoat.OnBoatJabbedEvent.Broadcast();
		// else
		// 	Print("NOT BOUND");

		// Print("JAB THROWN IN AIR ACTIVATED");


		// FRotator CurrentRelativeRotation = WheelBoat.RotationBase.GetRelativeRotation();

		// WheelBoat.OctopusBoss.BlockCapabilities(n"PirateOctopusThirdSequence", this);
		
		// // This will reset the current move and that will reset the relative rotation
		// SetMutuallyExclusive(n"WheelBoatBossMovement", true);
		// SetMutuallyExclusive(n"WheelBoatBossMovement", false);

		// WheelBoat.bIsAirborne = true;

		// WheelBoat.LeftWheelSubActor.CleanupCurrentMovementTrail();
		// WheelBoat.LeftWheelSubActor.BlockMovementSyncronization(this);
		
		// WheelBoat.RightWheelSubActor.CleanupCurrentMovementTrail();
		// WheelBoat.RightWheelSubActor.BlockMovementSyncronization(this);

		// WheelBoat.RotationBase.SetRelativeRotation(CurrentRelativeRotation);

		// WheelBoat.StopMovement();
		// WheelBoat.CapsuleComponent.CollisionEnabled == ECollisionEnabled::NoCollision;

		// CurrentUpForce = FVector(0.f, 0.f, UpForceToApply);

		// TArray<AHazePlayerCharacter> Players = Game::GetPlayers();
		// for(auto Player : Players)
		// {
		// 	Player.BlockCapabilities(n"CameraWheelBoatLazyChase", this);
		// }
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		// if(WheelBoat.OctopusBoss != nullptr)
		// 	WheelBoat.OctopusBoss.UnblockCapabilities(n"PirateOctopusThirdSequence", this);

		// TArray<AHazePlayerCharacter> Players = Game::GetPlayers();
		// for(auto Player : Players)
		// {
		// 	Player.UnblockCapabilities(n"CameraWheelBoatLazyChase", this);
		// }

		// WheelBoat.StopSpinning();
		// WheelBoat.LeftWheelSubActor.UnblockMovementSyncronization(this);
		// WheelBoat.RightWheelSubActor.UnblockMovementSyncronization(this);

		// WheelBoat.bIsAirborne = false;
	}

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
		// FWheelBoatMovementData& LeftMovementData = WheelBoat.LeftWheelSubActor.MovementData;
		// LeftMovementData.WheelDeltaVelocity = LeftMovementData.WheelRange - WheelBoat.LeftWheelRange;
	 	// WheelBoat.LeftWheelRange = LeftMovementData.WheelRange;

		// FWheelBoatMovementData& RightMovementData = WheelBoat.RightWheelSubActor.MovementData;
		// RightMovementData.WheelDeltaVelocity = RightMovementData.WheelRange - WheelBoat.RightWheelRange;
	 	// WheelBoat.RightWheelRange = RightMovementData.WheelRange;

		// FHazeFrameMovement Movement = MoveComp.MakeFrameMovement(n"WheelBoatThrownInAirMovement");

		// FRotator DeltaRotation;
		// //DeltaRotation.Yaw += LeftMovementData.RequestedDeltaRotationYaw;
		// //DeltaRotation.Yaw -= RightMovementData.RequestedDeltaRotationYaw;
		// DeltaRotation.Yaw += WheelBoat.CurrentSpinForce * DeltaTime;

		// FRotator FinalRotation = WheelBoat.RotationBase.WorldRotation + DeltaRotation;

		// CurrentUpForce -= FVector::UpVector * DownForceToApply * DeltaTime;
		// FVector DeltaMove = CurrentUpForce * DeltaTime;
	
		// if(DeltaMove.GetSafeNormal().DotProduct(FVector::UpVector) < -0.5f)
		// {
		// 	// So we don't overshoot the ground
		// 	const float DistanceToGround = WheelBoat.ActorLocation.Z - WheelBoat.BoatZLocation;
		// 	const float DeltaMoveSize = DeltaMove.Size();
		// 	Movement.ApplyDelta(-FVector::UpVector * FMath::Min(DistanceToGround, DeltaMoveSize));
		// }
		// else
		// {
		// 	Movement.ApplyDelta(DeltaMove);
		// }

		// MoveComp.Move(Movement);

		// LeftCrumbComponent.LeaveMovementCrumb();
		// RightCrumbComponent.LeaveMovementCrumb();
    }

}