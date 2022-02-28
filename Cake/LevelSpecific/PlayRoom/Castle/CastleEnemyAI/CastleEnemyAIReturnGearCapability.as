import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemyThiefComponent;
import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;

class UCastleEnemyAIReturnGearCapability : UCharacterMovementCapability
{
    default TickGroup = ECapabilityTickGroups::BeforeMovement;

	default CapabilityTags.Add(n"CastleEnemyMovement");
    default CapabilityTags.Add(n"CastleEnemyAI");

	ACastleEnemy OwningThief;
	UCastleEnemyThiefComponent ThiefComponent;

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

		if (!ThiefComponent.bGearStolen)
        	return EHazeNetworkActivation::DontActivate; 

		if (!ThiefComponent.bGearRecovered)
        	return EHazeNetworkActivation::DontActivate; 

        return EHazeNetworkActivation::ActivateUsingCrumb; 
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkDeactivation ShouldDeactivate() const
    {
		if (ThiefComponent.bGearReturned)
        	return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		// This shouldn't be able to happen
		if (!ensure(!ThiefComponent.DestinationElevator.bGearPlacedInElevator))
			return EHazeNetworkDeactivation::DeactivateFromControl; 

        return EHazeNetworkDeactivation::DontDeactivate; 
    }

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		OwningThief.MovementSpeed = 250.f;
		//UMovementSettings::SetMoveSpeed(Owner, ThiefComponent.MoveSpeedCarry, Instigator = this);
	}

	UFUNCTION(BlueprintOverride)
    void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
    {
		OwningThief.MovementSpeed = 500.f;

		//Owner.ClearSettingsByInstigator(this);

		ThiefComponent.SetThiefStealthed(true);	
		ThiefComponent.bGearStolen = false;
		ThiefComponent.bInsideRecoverRange = false;
		ThiefComponent.bGearRecovered = false;
		ThiefComponent.bGearReturned = false;		
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{

    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	

		FVector ReturnPoint = ThiefComponent.ReturnSpline.Spline.GetLocationAtSplinePoint(0, ESplineCoordinateSpace::World);
		System::DrawDebugLine(ReturnPoint, ReturnPoint + FVector(0, 0, 250.f));
		FVector ToReturnPoint = ReturnPoint - OwningThief.ActorLocation;

		if (ToReturnPoint.Size() > ThiefComponent.ReturnRange)
		{
			// Move to return point

			FHazeFrameMovement Movement = MoveComp.MakeFrameMovement(n"CastleEnemyReturnGear");
			if (HasControl())
			{
				float DistanceAlongSpline = ThiefComponent.ReturnSpline.Spline.GetDistanceAlongSplineAtWorldLocation(OwningThief.ActorLocation);
				FVector ClosestPointOnSpline = ThiefComponent.ReturnSpline.Spline.GetLocationAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World);
				FVector ToClosestPointOnSpline = ClosestPointOnSpline - OwningThief.ActorLocation;

				float AcceptanceDistanceToSpline = 50.f;			
				FVector ToTarget;


				if (ToClosestPointOnSpline.Size() > AcceptanceDistanceToSpline)
				{
					ToTarget = ToClosestPointOnSpline;
				}
				else
				{
					DistanceAlongSpline -= 10.f;
					DistanceAlongSpline = FMath::Clamp(DistanceAlongSpline, 0, ThiefComponent.ReturnSpline.Spline.GetSplineLength());
					ToTarget = ThiefComponent.ReturnSpline.Spline.GetLocationAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World) - OwningThief.ActorLocation;
				}
				ToTarget.Z = 0.f;

				float TargetDistance = FMath::Max(ToTarget.Size(), 0.01f);

				
				FVector MoveDirection = ToTarget / TargetDistance;

				float MoveDistance = FMath::Min(TargetDistance, DeltaTime * OwningThief.MovementSpeed * OwningThief.MovementMultiplier);

				FVector DeltaMove = MoveDirection * MoveDistance;
				Movement.ApplyDelta(DeltaMove);	
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
		else
		{
			// Return the gear
			ThiefComponent.GearToChase.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
			ThiefComponent.GearToChase.InteractionComponent.Enable(n"ThiefStolePickup");

			ThiefComponent.bGearReturned = true;
		}
	}
}