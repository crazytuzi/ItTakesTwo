import Cake.LevelSpecific.SnowGlobe.Curling.CurlingStone;
import Cake.LevelSpecific.SnowGlobe.Curling.CurlingStoneComponent;

class UCurlingStoneMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(n"CurlingStoneMovementCapability");
	default CapabilityTags.Add(n"CurlingStoneMovement");
	default CapabilityTags.Add(CapabilityTags::Movement);

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	ACurlingStone CurlingStone;

	UHazeMovementComponent MoveComp;

	UCurlingStoneComponent StoneComp;

	UCurlingPlayerComp PlayerComp;
	FHazeAcceleratedQuat AccelQuat;

	FVector MovementForce;
	FVector PreviousLocation;
	float MinPreviousVelocity = 0.08f;

	float Gravity = 2500.f;
	float Drag;
	float IceDrag = 0.6f;
	float BeforeShootDrag = 1.4f; 
	float FinalAudioGlideValue;

	bool bAudioCanLoop;

	float MaxAudioCoolDownTime = 0.1f;
	float CurrentAudioTime;

	bool bCollisionHappened;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		CurlingStone = Cast<ACurlingStone>(Owner);

		// StartingRot = CurlingStone.ActorRotation;
		MoveComp = UHazeMovementComponent::Get(CurlingStone);
		StoneComp = UCurlingStoneComponent::Get(CurlingStone);

		Drag = BeforeShootDrag;

		StoneComp.EventReleaseStone.AddUFunction(this, n"SetToIceDrag");
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (CurlingStone.GetRootComponent().GetAttachParent() != nullptr)
        	return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (CurlingStone.GetRootComponent().GetAttachParent() != nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		CurlingStone.CleanupCurrentMovementTrail();
		// CurlingStone.SetActorRotation(StartingRot);

		MoveComp.ConsumeAccumulatedImpulse();
		MoveComp.Velocity = 0.f;
		AccelQuat.SnapTo(CurlingStone.ActorRotation.Quaternion());
		FinalAudioGlideValue = 0.f;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		CurlingStone.CleanupCurrentMovementTrail();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (MoveComp.CanCalculateMovement())
		{
			FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"CurlingStone");
			
			if (HasControl())
			{
				FVector DeltaFromEdge = CurlingStone.ActorLocation - CurlingStone.EdgeLine.ActorLocation;

				float DistanceFromEdge = CurlingStone.EdgeLine.ActorForwardVector.DotProduct(DeltaFromEdge);

				if (!CurlingStone.bIsControlledByPlayer && CurlingStone.bIsActive)
				{
					CalculateMovement(FrameMove, DeltaTime);
					MoveComp.Move(FrameMove);
				}

				CurlingStone.CrumbComp.LeaveMovementCrumb();
			}
			else
			{
				FHazeActorReplicationFinalized CrumbData;
				CurlingStone.CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, CrumbData);	
				FrameMove.ApplyConsumedCrumbData(CrumbData);
				MoveComp.Move(FrameMove);
			}
		}

		if (HasControl())
		{
			if (CurlingStone.ActorLocation.Z < CurlingStone.ZOutOfGameHeight && CurlingStone.bHeightInitialized)
			{
				if (!CurlingStone.bHaveFallen)
				{
					CurlingStone.EventStoneHasFallen.Broadcast(CurlingStone);
					CurlingStone.bHasPlayed = true;
					CurlingStone.bHaveFallen = true;
					CurlingStone.DisablePlayerInteraction();
				}
			}
		}

		float PreviousVelocity = (PreviousLocation - CurlingStone.ActorLocation).Size();

		if(!MoveComp.IsAirborne() && PreviousVelocity > MinPreviousVelocity && CurlingStone.bIsAboveZLevel)
		{
			FinalAudioGlideValue = FMath::FInterpTo(FinalAudioGlideValue, PreviousVelocity, DeltaTime, 1.85f);

			if (!bAudioCanLoop)
			{
				bAudioCanLoop = true;
				CurlingStone.AudioStartGlideEvent();
			}
		}
		else if (CurlingStone.bIsControlledByPlayer && PreviousVelocity > MinPreviousVelocity && CurlingStone.bIsAboveZLevel)
		{
			FinalAudioGlideValue = FMath::FInterpTo(FinalAudioGlideValue, PreviousVelocity, DeltaTime, 1.85f);

			if (!bAudioCanLoop)
			{
				bAudioCanLoop = true;
				CurlingStone.AudioStartGlideEvent();
			}
		}
		else
		{
			if (bAudioCanLoop)
			{
				bAudioCanLoop = false;
				CurlingStone.AudioEndGlideEvent();
			}
		}

		if (bAudioCanLoop && !CurlingStone.bIsAboveZLevel)
		{
			bAudioCanLoop = false;
			CurlingStone.AudioEndGlideEvent();
		}

		CurlingStone.AudioUpdateGlideRTPC(FinalAudioGlideValue);
		PreviousLocation = CurlingStone.ActorLocation;

		if (bCollisionHappened)
		{
			CurrentAudioTime -= DeltaTime;

			if (CurrentAudioTime <= 0.f)
				bCollisionHappened = false;
		}
	}

	UFUNCTION()
	void CalculateMovement(FHazeFrameMovement& FrameMove, float DeltaTime)
	{
		FVector VerticalVelocity = MoveComp.Velocity.ConstrainToDirection(FVector::UpVector);
		FVector HorizontalVelocity = MoveComp.Velocity - VerticalVelocity;

		HorizontalVelocity = GetCollisionReflectedVelocity(HorizontalVelocity);

		FVector Impulses;
		MoveComp.GetAccumulatedImpulse(Impulses);
		MoveComp.ConsumeAccumulatedImpulse();

		HorizontalVelocity += Impulses;

		if (MoveComp.IsAirborne() || CurlingStone.bOffEdge)
		{
			if (!CurlingStone.bFirstTimeFalling)
			{
				float EdgeAddedRot = (CurlingStone.FallDirection * (CurlingStone.DistanceFromLastHit * 2.5f)).Size();

				FVector StoneVelocityDirection = MoveComp.Velocity + FVector(0.f, 0.f, -EdgeAddedRot);

				StoneVelocityDirection.Normalize();

				FVector VelocityRightVector = FVector::UpVector.CrossProduct(StoneVelocityDirection);
				FVector VelocityUpVector = StoneVelocityDirection.CrossProduct(VelocityRightVector);

				FQuat DesiredQuat = Math::MakeQuatFromZX(VelocityUpVector, CurlingStone.ActorForwardVector);

				AccelQuat.AccelerateTo(DesiredQuat, 2.5f, DeltaTime);

				CurlingStone.MeshComp.SetWorldRotation(AccelQuat.Value);
				CurlingStone.SetActorRotation(AccelQuat.Value);
			}
		}

		HorizontalVelocity -= HorizontalVelocity * Drag * DeltaTime;
		const float Deceleration = FMath::Min(20.f * DeltaTime, HorizontalVelocity.Size());
		HorizontalVelocity -= HorizontalVelocity.GetSafeNormal() * Deceleration;
		HorizontalVelocity = HorizontalVelocity.ConstrainToPlane(FVector::UpVector);

		if (MoveComp.IsAirborne())
		{
			VerticalVelocity -= FVector::UpVector * Gravity * DeltaTime;
		}
		else if (!MoveComp.IsAirborne() && CurlingStone.bFirstTimeFalling)
		{
			CurlingStone.bFirstTimeFalling = false;
			CurlingStone.StoneZValues();
		}

		if (!MoveComp.IsAirborne() && CurlingStone.bAudioFirstTimeFalling)
		{
			CurlingStone.bAudioFirstTimeFalling = false;
			CurlingStone.AudioHitFloorEvent();
		}

		FrameMove.ApplyVelocity(HorizontalVelocity + VerticalVelocity);
	}

	FVector GetCollisionReflectedVelocity(FVector Velocity)
	{
		FVector _Velocity = Velocity;

		if (MoveComp.ForwardHit.bBlockingHit)
		{
			// Get impact point then normal direction  
			FVector ImpactPoint = MoveComp.ForwardHit.ImpactPoint;
			FVector Normal = Owner.ActorLocation - ImpactPoint;
			Normal = Normal.ConstrainToPlane(FVector::UpVector);
			Normal.Normalize();
			
			if (!bCollisionHappened)
			{
				CurrentAudioTime = MaxAudioCoolDownTime;

				FHazeDelegateCrumbParams Params;
				Params.AddValue(n"Velocity", Velocity.Size());
				CurlingStone.CrumbComp.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_AudioCollide"), Params);

				CurlingStone.PlayRumble();
				bCollisionHappened = true;
			}

			// If boundary, constrain to UpVector and return
			if (MoveComp.ForwardHit.Actor.ActorHasTag(n"Boundary"))
				return _Velocity.ConstrainToPlane(Normal) * 0.95f;
			
			// Otherwise cast to object we hit and check if curling stone with move comp   
			UHazeMovementComponent OtherMoveComp = UHazeMovementComponent::Get(MoveComp.ForwardHit.Actor);
			ACurlingStone OtherCurlingStone = Cast<ACurlingStone>(MoveComp.ForwardHit.Actor);

			// If null, return a reflected vector from where we hit 
			if (OtherMoveComp == nullptr || OtherCurlingStone == nullptr)
			{
				CurlingStone.SpawnImpactWithWallSystem(MoveComp.ForwardHit.ImpactPoint, CurlingStone.ActorRotation);
				return _Velocity = FMath::GetReflectionVector(_Velocity, Normal) * 0.95f;
			}

			if (!OtherCurlingStone.bHasPlayed)
			{
				CurlingStone.SpawnImpactWithPuckSystem(MoveComp.ForwardHit.ImpactPoint, CurlingStone.ActorRotation);
				return _Velocity = FMath::GetReflectionVector(_Velocity, Normal) * 0.95f;
			}

			// If other object is not blocking hit or our priority is higher than theirs
			if (!OtherMoveComp.ForwardHit.bBlockingHit || CurlingStone.Index < OtherCurlingStone.Index)
			{
				// Store other comps velocity, constrained to the direction we hit in 
				FVector OtherVelocityConstrained = OtherMoveComp.Velocity.ConstrainToDirection(Normal);
				// Store our velocity and constrain to direction we hit 
				FVector VelocityConstrained = _Velocity.ConstrainToDirection(Normal);
				
				// In that hit/normal direction, calculate the difference between our velocities 
				FVector VelocityDifference = (OtherVelocityConstrained - VelocityConstrained) * 0.8f;
				
				// Add difference to our velocity 
				_Velocity += VelocityDifference;
				
				// Reduce difference in other comps velocity
				OtherMoveComp.Velocity -= VelocityDifference;

				CurlingStone.SpawnImpactWithPuckSystem(MoveComp.ForwardHit.ImpactPoint, CurlingStone.ActorRotation);

				_Velocity *= 0.95f;
			}		
		}

		return _Velocity;
	}

	UFUNCTION()
	void Crumb_AudioCollide(const FHazeDelegateCrumbData& CrumbData)
	{
		float Velocity = CrumbData.GetValue(n"Velocity");
		CurlingStone.AudioOnCollideEvent(Velocity); 
	}

	UFUNCTION()
	void SetToIceDrag()
	{
		Drag = IceDrag;
	}
}