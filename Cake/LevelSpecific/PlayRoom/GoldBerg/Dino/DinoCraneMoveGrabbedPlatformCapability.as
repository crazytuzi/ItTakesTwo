import Cake.LevelSpecific.PlayRoom.GoldBerg.Dino.DinoCrane;
import Cake.LevelSpecific.PlayRoom.GoldBerg.Dino.DinoCraneRidingComponent;
import Cake.LevelSpecific.PlayRoom.GoldBerg.Dino.DinoCranePlatformInteraction;
import Peanuts.Audio.AudioStatics;

class UDinoCraneMoveGrabbedPlatformCapability : UHazeCapability
{
    default CapabilityTags.Add(n"Movement");
    default CapabilityTags.Add(n"DinoCrane");
	default CapabilityTags.Add(n"GrabbedPlatform");

    default TickGroup = ECapabilityTickGroups::ActionMovement;

	/* How long after grabbing the platform before we're allowed to move it. */
	UPROPERTY()
	float DelayBeforeAllowingMovement = 0.5f;

    UHazeBaseMovementComponent MoveComp;
	ADinoCrane DinoCrane;
	UHazeCrumbComponent CrumbComp;

	float MoveDelayTimer = 0.f;

	float GetMoveSpeed() property
	{
		return DinoCrane.MovePlatformSpeed;
	}

    UFUNCTION(BlueprintOverride)
    void Setup(FCapabilitySetupParams Params)
    {
        MoveComp = UHazeBaseMovementComponent::Get(Owner);
		DinoCrane = Cast<ADinoCrane>(Owner);
        CrumbComp = UHazeCrumbComponent::Get(Owner);

		Owner.BlockCapabilities(n"GroundMovement", this);
    }

    UFUNCTION(BlueprintOverride)
    void OnRemoved()
    {
		Owner.UnblockCapabilities(n"GroundMovement", this);
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkActivation ShouldActivate() const
    {
		if (DinoCrane.RidingPlayer == nullptr)
			return EHazeNetworkActivation::DontActivate; 
		if (DinoCrane.GrabbedPlatform == nullptr)
			return EHazeNetworkActivation::DontActivate; 
        return EHazeNetworkActivation::ActivateLocal; 
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkDeactivation ShouldDeactivate() const
    {
		if (DinoCrane.RidingPlayer == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal; 
		if (DinoCrane.GrabbedPlatform == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal; 
        return EHazeNetworkDeactivation::DontDeactivate; 
    }

    UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		MoveDelayTimer = DelayBeforeAllowingMovement;
		DinoCrane.GrabbedPlatform.SetControlSide(DinoCrane);
	}

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
		MoveDelayTimer -= DeltaTime;
		const bool bMovementAllowed = MoveDelayTimer <= 0.f;	

		auto RideComp = GetDinoRidingComponent(DinoCrane);
		auto Platform = Cast<ADinoCranePlatformInteraction>(DinoCrane.GrabbedPlatform);

		if (HasControl())
		{
			FVector Input = RideComp.SteeringInput;

			float VerticalInput = RideComp.VerticalInput;
			if (FMath::Abs(VerticalInput) < FMath::Abs(RideComp.RawInput.X))
				VerticalInput = RideComp.RawInput.X;

			/* Move the platform with the input along the spline. */
			bool bReleaseFromPenetration = false;

			if (bMovementAllowed)
			{
				float MoveMagnitude = FMath::Clamp(Input.Size(), 0.f, 1.f);

				FVector CurPlatformPos = Platform.ActorLocation;

				float SplineDist = 0.f;
				FVector ClosestSplinePos;
				Platform.Spline.FindDistanceAlongSplineAtWorldLocation(CurPlatformPos, ClosestSplinePos, SplineDist);

				FVector WantPosition = ClosestSplinePos + Input * (DeltaTime * MoveSpeed);

				FVector PosDirection = Platform.Spline.GetDirectionAtDistanceAlongSpline(SplineDist, ESplineCoordinateSpace::World);
				if(FMath::Abs(PosDirection.Z) >= 0.25f)
				{
					WantPosition.Z += VerticalInput * DeltaTime * MoveSpeed;
				}

				FVector NewPosition = Platform.Spline.FindLocationClosestToWorldLocation(WantPosition, ESplineCoordinateSpace::World);

				bool bIsOverlapping = false;
				NewPosition = Platform.ModifyMovementForCollision(CurPlatformPos, NewPosition, bIsOverlapping);

				if(bIsOverlapping)
					bReleaseFromPenetration = true;

				UpdateAudio(Platform, DeltaTime, CurPlatformPos, NewPosition);
				Platform.ActorLocation = NewPosition;
			}

			/* Move the dino with the platform. */
			FHazeFrameMovement Movement = MoveComp.MakeFrameMovement(n"DinoCraneMoveGrabbedPlatform");

			Movement.ApplyTargetRotationDelta();
			Movement.OverrideStepDownHeight(0.f);
			Movement.OverrideStepUpHeight(0.f);
			MoveComp.Move(Movement);
			CrumbComp.LeaveMovementCrumb();

			DinoCrane.SetPositionOfDinoHead(Platform.ActorLocation, Platform.ActorForwardVector);

			/* Release the platform if we are penetrating something. */
			if (bReleaseFromPenetration)
			{
				Platform.ReleasePlatform();
			}
		}
		else
		{
			FHazeFrameMovement Movement = MoveComp.MakeFrameMovement(n"DinoCraneMoveGrabbedPlatform");

			// Sync to crumb
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			Movement.ApplyConsumedCrumbData(ConsumedParams);
			MoveComp.Move(Movement);
			
			UpdateAudio(Platform, DeltaTime, Platform.ActorLocation, Platform.SyncPosition.Value);
			Platform.ActorLocation = Platform.SyncPosition.Value;
			DinoCrane.SetPositionOfDinoHead(Platform.ActorLocation, Platform.ActorForwardVector);
		}
    }

	void UpdateAudio(ADinoCranePlatformInteraction Platform, float DeltaTime, FVector CurPlatformPos, FVector NewPosition)
	{
		FVector PlatformMovement = (NewPosition - CurPlatformPos);

		float VerticalMovementRTPC = FMath::Clamp(FMath::Abs((PlatformMovement.Z) / (MoveSpeed * DeltaTime)), 0.f, 1.f);
		float HorizontalMovementRTPC = FMath::Max(FMath::Abs(PlatformMovement.X), FMath::Abs(PlatformMovement.Y));
		HorizontalMovementRTPC = FMath::Clamp(FMath::Abs((HorizontalMovementRTPC) / (MoveSpeed * DeltaTime)), 0.f, 1.f);								

		Platform.HazeAkComp.SetRTPCValue(HazeAudio::RTPC::DinoCraneVerticalMovement, VerticalMovementRTPC, 0);
		Platform.HazeAkComp.SetRTPCValue(HazeAudio::RTPC::DinoCraneHorizontalMovement, HorizontalMovementRTPC, 0);
		DinoCrane.DinoCraneHeadNormalizedVelo = FMath::Max(VerticalMovementRTPC, HorizontalMovementRTPC);
	}
};