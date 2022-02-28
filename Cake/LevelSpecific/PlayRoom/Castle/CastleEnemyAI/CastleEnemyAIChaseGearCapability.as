import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemyThiefComponent;
import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;

class UCastleEnemyAIChaseGearCapability : UCharacterMovementCapability
{
    default TickGroup = ECapabilityTickGroups::BeforeMovement;

	default CapabilityTags.Add(n"CastleEnemyMovement");
    default CapabilityTags.Add(n"CastleEnemyAI");

	ACastleEnemy OwningThief;
	UCastleEnemyThiefComponent ThiefComponent;

	float WaitTimeCurrent = 0.f;

    UFUNCTION(BlueprintOverride)
    void Setup(FCapabilitySetupParams Params)
    {
		UCharacterMovementCapability::Setup(Params);

		OwningThief = Cast<ACastleEnemy>(Owner);
        ThiefComponent = UCastleEnemyThiefComponent::GetOrCreate(Owner);
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkActivation ShouldActivate() const
    {	
		if (ThiefComponent.ReturnSpline == nullptr)
        	return EHazeNetworkActivation::DontActivate; 

		if (ThiefComponent.DestinationElevator.bGearPlacedInElevator)
        	return EHazeNetworkActivation::DontActivate;
		
		if (WaitTimeCurrent < ThiefComponent.WaitTimeBeforeStartingRecovery)
        	return EHazeNetworkActivation::DontActivate;

		if (!ThiefComponent.bGearStolen)
        	return EHazeNetworkActivation::DontActivate; 

		if (ThiefComponent.bInsideRecoverRange)
        	return EHazeNetworkActivation::DontActivate; 

        return EHazeNetworkActivation::ActivateFromControl; 
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkDeactivation ShouldDeactivate() const
    {
		if (ThiefComponent.DestinationElevator.bGearPlacedInElevator)
        	return EHazeNetworkDeactivation::DeactivateUsingCrumb; 

		if (ThiefComponent.bInsideRecoverRange)
        	return EHazeNetworkDeactivation::DeactivateUsingCrumb; 

        return EHazeNetworkDeactivation::DontDeactivate; 
    }

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		ThiefComponent.SetThiefStealthed(false);

		float DistanceAlongSpline = ThiefComponent.ReturnSpline.Spline.GetDistanceAlongSplineAtWorldLocation(ThiefComponent.GearToChase.ActorLocation);
		DistanceAlongSpline -= 750.f;
		DistanceAlongSpline = FMath::Clamp(DistanceAlongSpline, 0, ThiefComponent.ReturnSpline.Spline.GetSplineLength());

		FVector SplineLocation = ThiefComponent.ReturnSpline.Spline.GetLocationAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World);


		Owner.SetActorLocation(SplineLocation);
	}

	UFUNCTION(BlueprintOverride)
    void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
    {
		WaitTimeCurrent = 0.f;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (!HasControl())
			return;

		if (ThiefComponent == nullptr)
			return;

		if (!ThiefComponent.bGearStolen)
			return;

		if (ThiefComponent.bGearRecovered || ThiefComponent.bInsideRecoverRange || ThiefComponent.bGearReturned)
			return;

		if (IsActive())
			return;

		WaitTimeCurrent += DeltaTime;
		Print("WaitTime" + WaitTimeCurrent);
    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		FHazeFrameMovement Movement = MoveComp.MakeFrameMovement(n"CastleEnemyChaseGear");
		if (HasControl())
		{
			FVector ToTarget = ThiefComponent.GearToChase.ActorLocation - OwningThief.ActorLocation;
			ToTarget.Z = 0.f;

			float TargetDistance = FMath::Max(ToTarget.Size(), 0.01f);

			
			FVector MoveDirection = ToTarget / TargetDistance;

			float ActualTargetDistance = (ThiefComponent.GearToChase.ActorLocation - OwningThief.ActorLocation).Size();

			if (ActualTargetDistance > ThiefComponent.RecoverRange)
			{
				float MoveDistance = FMath::Min(TargetDistance, DeltaTime * OwningThief.MovementSpeed * OwningThief.MovementMultiplier);

				FVector DeltaMove = MoveDirection * MoveDistance;
				Movement.ApplyDelta(DeltaMove);
			}	
			else
				ThiefComponent.bInsideRecoverRange = true;		

			Movement.ApplyGravityAcceleration();
			Movement.ApplyActorVerticalVelocity();

			MoveComp.SetTargetFacingRotation(Math::MakeRotFromX(ToTarget.GetSafeNormal()), OwningThief.FacingRotationSpeed);
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			Movement.ApplyConsumedCrumbData(ConsumedParams);
		}

		FVector PrevLocation = OwningThief.ActorLocation;

		Movement.ApplyTargetRotationDelta();
		Movement.FlagToMoveWithDownImpact();
		MoveComp.Move(Movement);

		FVector ActualMovement = OwningThief.ActorLocation - PrevLocation;

        FHazeRequestLocomotionData AnimationRequest;
        AnimationRequest.LocomotionAdjustment.DeltaTranslation = ActualMovement;
        AnimationRequest.LocomotionAdjustment.WorldRotation = Movement.Rotation;
 		AnimationRequest.WantedVelocity = ActualMovement / DeltaTime;
        AnimationRequest.WantedWorldTargetDirection = Movement.MovementDelta;
        AnimationRequest.WantedWorldFacingRotation = MoveComp.GetTargetFacingRotation();
		AnimationRequest.MoveSpeed = MoveComp.MoveSpeed;
		AnimationRequest.WantedVelocity.Z = 0.f;
		AnimationRequest.AnimationTag = n"Movement";
        OwningThief.RequestLocomotion(AnimationRequest);

		if (HasControl())
			CrumbComp.LeaveMovementCrumb();
	}
}