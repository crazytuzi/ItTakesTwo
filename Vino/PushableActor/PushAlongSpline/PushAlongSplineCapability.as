import Vino.PushableActor.PushAlongSpline.PushAlongSplineComponent;
import Vino.Movement.Components.MovementComponent;
import Peanuts.Spline.SplineComponent;

class UPushAlongSplineCapability : UHazeCapability
{
    default CapabilityTags.Add(n"PushObject");
    default CapabilityTags.Add(n"MoveObject");
	default CapabilityTags.Add(n"SplineMovement");

  	default TickGroup = ECapabilityTickGroups::ActionMovement;

    UPushAlongSplineComponent TriggerUser;

    AActor ActorToMove;
	FVector ActorExtents;

    UHazeSplineComponent SplineComponent;

    AHazePlayerCharacter PlayerOwner;

    UHazeMovementComponent Movement;

	FVector ReplicatedRawInputVector;
    FVector ReplicatedInputVector;

	FVector RawInputValue;
    FVector CharacterOffset;
    FVector CurrentMovementDelta;

    float SplineResistance = 0.f;
    float ObjectSplineDistance = 0.f;
	float PlayerSplineDistance = 0.f;

    bool bWasActive = false;
	bool bIsAtDestination = false;
	bool bCanActivate = false;

    UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
        PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		TriggerUser = UPushAlongSplineComponent::GetOrCreate(Owner);
	}

    UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        if(bCanActivate)
        {
            if (WasActionStarted(ActionNames::InteractionTrigger))
		        return EHazeNetworkActivation::ActivateFromControl;
        }

		return EHazeNetworkActivation::DontActivate;
	}

    UFUNCTION(BlueprintOverride)
    void OnActivated(FCapabilityActivationParams ActivationParams)
    {	
		TriggerUser.OnCapabilityActivated();

		bIsAtDestination = false;

        ActorToMove = Cast<AHazeActor>(GetAttributeObject(n"ActorToMove"));
        SplineComponent = Cast<UHazeSplineComponent>(GetAttributeObject(n"Spline"));
        SplineResistance =  1 - GetAttributeValue(n"SplineResistance");

		FVector Origin;
		ActorToMove.GetActorBounds(true, Origin, ActorExtents);
		UStaticMeshComponent Comp = Cast<UStaticMeshComponent>(ActorToMove.GetComponentByClass(UStaticMeshComponent::StaticClass()));
		if(Comp != nullptr)
		{
			FVector MeshLoc = Comp.GetWorldLocation();
			FVector Diff = Origin - MeshLoc;
			ActorExtents -= Diff;
		}

        Movement = UHazeMovementComponent::GetOrCreate(PlayerOwner);

		//Smooth Teleport to correct location.
		FVector Destination = FindClosestInteractionPoint();

		// FHazeDestinationSettings Settings;
		// Settings.bCanCancel = false;
		// Settings.MovementMethod = EHazeMovementMethod::SmoothTeleport;
		// Settings.ReachedDestinationTolerance = 0.f;

		// FHazeDestinationEvents Events;
		// Events.OnDestinationReached.BindUFunction(this, n"OnDestinationReached");
		// PlayerOwner.GoToPosition(Destination, Settings, Events);
    }

	UFUNCTION()
	void OnDestinationReached(AHazeActor Actor)
	{
		if(SplineComponent != nullptr)
		{
			ObjectSplineDistance = SplineComponent.GetDistanceAlongSplineAtWorldLocation(ActorToMove.GetActorLocation());
			PlayerSplineDistance = ObjectSplineDistance;
		}

        PlayerOwner.BlockCapabilities(n"CharacterFacing", this);
		PlayerOwner.BlockCapabilities(n"Movement", this);

		FRotator Rotation = (ActorToMove.GetActorLocation() - PlayerOwner.GetActorLocation()).GetSafeNormal().Rotation();
		PlayerOwner.SetActorRotation(Rotation);

		bIsAtDestination = true;
	}

    UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
        if(WasActionStarted(ActionNames::Cancel))
        {
            return EHazeNetworkDeactivation::DeactivateFromControl;
        }

        return EHazeNetworkDeactivation::DontDeactivate;
	}

    UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		PlayerOwner.ConsumeButtonInputsRelatedTo(ActionNames::Cancel);
		TriggerUser.OnCapabilityDeactivated();

        ActorToMove = nullptr;
        SplineComponent = nullptr;

        PlayerOwner.UnblockCapabilities(n"CharacterFacing", this);
	    PlayerOwner.UnblockCapabilities(n"Movement", this);
	}

    bool CheckCanActivate()
    {
        if(bWasActive && !TriggerUser.bTriggerIsActivated)
        {
            ConsumeAttribute(n"ActorToMove", ActorToMove);
            ConsumeAttribute(n"Spline", SplineComponent);
            ConsumeAttribute(n"SplineResistance", SplineResistance);
        }

		if(TriggerUser.bRequiresBothPlayers)
		{
			return false;
		}

        return bWasActive = TriggerUser.bTriggerIsActivated;
    }

    UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		bCanActivate = CheckCanActivate();
	}

    UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!bIsAtDestination)
		{
			return;
		}

		FVector Input;
		
		if(HasControl())
		{
			RawInputValue = GetAttributeVector(AttributeVectorNames::MovementDirection).ConstrainToPlane(Movement.WorldUp);
			Input = RawInputValue;
			SetReplicatedInputVector(RawInputValue, Input);
		}
		else
		{
			Input = ReplicatedInputVector;
		}

		FVector LookAtVector = (ActorToMove.GetActorLocation() - PlayerOwner.GetActorLocation()).GetSafeNormal();
		FRotator DesiredRotation = PlayerOwner.GetActorRotation();
		DesiredRotation.Yaw = LookAtVector.Rotation().Yaw;

		Movement.SetTargetFacingRotation(DesiredRotation, 200.f);
		
		FVector DeltaMovement = Input * Movement.MoveSpeed * DeltaTime;
		DeltaMovement *= SplineResistance;
		
		AnimationRequest(DeltaMovement, DesiredRotation.Quaternion());
	}

	void AnimationRequest(FVector DeltaMovement, FQuat DesiredRotation)
	{
		CurrentMovementDelta = DeltaMovement;

		FHazeRequestLocomotionData RequestData;
		FName FloorAnimationToTag;

		if(!Movement.GetAnimationRequest(FloorAnimationToTag))
		{
			FloorAnimationToTag = n"Movement";
		}

		RequestData.AnimationTag = FloorAnimationToTag;
		Movement.GetSubAnimationRequest(RequestData.SubAnimationTag);
	
		RequestData.LocomotionAdjustment.DeltaTranslation = CurrentMovementDelta;
		RequestData.LocomotionAdjustment.WorldRotation = Movement.GetTargetFacingRotation();
        RequestData.WantedWorldFacingRotation = Movement.GetTargetFacingRotation();

		if(HasControl())
		{
			RequestData.WantedWorldTargetDirection = RawInputValue;
		}
		else
		{
			RequestData.WantedWorldTargetDirection = ReplicatedRawInputVector;
		}

		//Wait for the animation system to return root motion before finalizing the movement
		PlayerOwner.RequestLocomotion(RequestData);
		PushObjectAlongSpline(RequestData.LocomotionAdjustment.DeltaTranslation);
	}

	void PushObjectAlongSpline(FVector CalculatedDelta)
	{	
		FVector SplineDirection = SplineComponent.GetDirectionAtDistanceAlongSpline(ObjectSplineDistance, ESplineCoordinateSpace::World);
		float Dot = 0;

		if(SplineDirection.Size() == 0)
		{
			Dot = -1.f;
		}
		else
		{
			Dot = SplineDirection.GetSafeNormal().DotProduct(CalculatedDelta.GetSafeNormal());
		}

		if(Dot > 0.5f || Dot < -0.5f)
		{
			float Direction = FMath::Sign(Dot);
        	float Length = (FVector(1, 1, 0) * CalculatedDelta).Size() * Direction;

        	ObjectSplineDistance += Length;
			PlayerSplineDistance += Length;

			float SplineLength = FMath::RoundToFloat(100.f * SplineComponent.GetSplineLength()) * 0.01f;
			
			ObjectSplineDistance = FMath::Clamp(ObjectSplineDistance, 0, SplineLength);
			PlayerSplineDistance = FMath::Clamp(PlayerSplineDistance, 0, SplineLength);
               
        	FVector ObjectLocationAtNewDistance = SplineComponent.GetLocationAtDistanceAlongSpline(ObjectSplineDistance, ESplineCoordinateSpace::World);
			FVector PlayerLocationAtNewDistance = SplineComponent.GetLocationAtDistanceAlongSpline(PlayerSplineDistance, ESplineCoordinateSpace::World);

			//Set Move Actor at right position
			FVector GroundLocation = GetGroundVector(ActorToMove, ObjectLocationAtNewDistance);
			ObjectLocationAtNewDistance.Z = GroundLocation.Z + ActorExtents.Z;

			ActorToMove.SetActorLocation(ObjectLocationAtNewDistance);
			FRotator Rotation = SplineComponent.GetRotationAtDistanceAlongSpline(ObjectSplineDistance, ESplineCoordinateSpace::World);
			ActorToMove.SetActorRotation(Rotation);

			//Set Player at right position
			FVector PlayerGroundLocation = GetGroundVector(PlayerOwner, PlayerLocationAtNewDistance + CharacterOffset);
			PlayerLocationAtNewDistance.Z = PlayerGroundLocation.Z;

			PlayerOwner.SetActorLocation(PlayerLocationAtNewDistance + CharacterOffset);
		}
	}

	UFUNCTION()
	FVector FindClosestInteractionPoint()
	{
		FVector CurrentLocation = ActorToMove.GetActorLocation() - PlayerOwner.GetActorLocation();
		float ShortestDistance = FVector::MAX_flt;

		for(FTransform CurrentPoint : TriggerUser.CurrentInteractionPoints)
		{
			FVector WorldLocation = ActorToMove.GetActorLocation() + CurrentPoint.GetLocation();
			float Distance = WorldLocation.Dist2D(PlayerOwner.GetActorLocation());
			if(Distance < ShortestDistance)
			{
				CurrentLocation = CurrentPoint.GetTranslation();
				ShortestDistance = Distance;
			}
		}

		CharacterOffset = CurrentLocation;
		CharacterOffset.Z = 0.f;

		FVector NewLocation = ActorToMove.GetActorLocation() + CurrentLocation;
		NewLocation.Z = PlayerOwner.GetActorLocation().Z;

		return NewLocation;
	}

	FVector GetGroundVector(AActor InActor, FVector TargetLocation)
    {
        TArray<AActor> IgnoreActors;
        IgnoreActors.Add(InActor);
        IgnoreActors.Add(PlayerOwner);

		TArray<FHitResult> OutHits;

        FVector GroundVector;
        FVector HitNormal;
        bool bDidHitGround = false;

		System::LineTraceMulti(TargetLocation + FVector(0.f,0.f,100.f), TargetLocation + FVector(0.f,0.f, -1000.f), ETraceTypeQuery::TraceTypeQuery1, false, IgnoreActors, EDrawDebugTrace::None, OutHits, true);

		for(FHitResult Hit : OutHits)
		{
			if(Hit.bBlockingHit)
			{
				GroundVector = Hit.Location;
				bDidHitGround = true;
				break;
			}
		}
   
        if(bDidHitGround)
        {
			return GroundVector;
		}

        return TargetLocation;
    }

	UFUNCTION(NetFunction)
    void SetReplicatedInputVector(FVector RawInput, FVector Input)
    {
		ReplicatedRawInputVector = RawInput;
        ReplicatedInputVector = Input;
    }
}