import Cake.LevelSpecific.Garden.JumpingFrog.JumpingFrog;
import Vino.Movement.Components.MovementComponent;
import Vino.Trajectory.TrajectoryStatics;
import Vino.Projectile.ProjectileMovement;
import Cake.LevelSpecific.Garden.LevelActors.FrogPond.FrogPondScaleActor;
import Vino.Movement.Helpers.MovementJumpHybridData;
import Vino.Movement.Components.FloorJumpCallbackComponent;

class UJumpingFrogJumpNextGenCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(JumpingFrogTags::Jump);

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 41;

	const float InitalFrameCount = 5;

	AJumpingFrog Frog;
	UHazeFrogMovementComponent MoveComp;
	UHazeCrumbComponent CrumbComp;

	//bool bHadImpact = false;
	float WantsToJumpTimeLeft = 0;
	FVector JumpInitialDirection = FVector::ZeroVector;
	int ActiveFrames = 0;

	FVector CurrentStrafeVelocity = FVector::ZeroVector;

	float InAirTime = 0;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Frog = Cast<AJumpingFrog>(Owner);
		MoveComp = UHazeFrogMovementComponent::GetOrCreate(Owner);
		CrumbComp = UHazeCrumbComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		WantsToJumpTimeLeft = FMath::Max(WantsToJumpTimeLeft - DeltaTime, 0.f);
		if(ConsumeAttribute(n"JumpingNextGen", JumpInitialDirection))
		{
			WantsToJumpTimeLeft = 0.1f;
		}

		if(!IsActive() && !IsBlocked())
		{
			if(MoveComp.IsGrounded())
				InAirTime = 0;
			else
				InAirTime += DeltaTime;
		}

	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(Frog.CurrentChargeDelay > 0)
			return EHazeNetworkActivation::DontActivate;

		if(WantsToJumpTimeLeft <= 0)
			return EHazeNetworkActivation::DontActivate;

		if (!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		if (InAirTime > Frog.MovementSettings.AllowEdgeJumpTime)
			return EHazeNetworkActivation::DontActivate;
		
		if (Frog.bJumping)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!MoveComp.CanCalculateMovement())
		{
			if (HasControl())
				return EHazeNetworkDeactivation::DeactivateUsingCrumb;
			else
				return EHazeNetworkDeactivation::DeactivateLocal;
		}

		if (!Frog.bJumping)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(MoveComp.IsGrounded())
		{
			if(Frog.VerticalTravelDirection <= 0)
				return EHazeNetworkDeactivation::DeactivateUsingCrumb;
			else if(ActiveFrames > 1 && ActiveDuration > 0.2f)
				return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		}		

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		WantsToJumpTimeLeft = 0;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Frog.bBouncing = false;
		InAirTime = 0;
		ActiveFrames = 0;
		Frog.bJumping = true;
		Frog.VerticalTravelDirection = 1;
		Frog.DistanceToGround = 0;

		Frog.SetCapabilityActionState(n"AudioFrogBigJump", EHazeActionState::ActiveForOneFrame);

		if(Frog.bShouldPlayJumpReactionVO && Frog.VOBank != nullptr)
			PlayFoghornVOBankEvent(Frog.VOBank, Frog.MountedPlayer.IsMay() ? n"FoghornDBGardenFrogPondJumpReactionMay" : n"FoghornDBGardenFrogPondJumpReactionCody");

		if (Frog.MountedPlayer != nullptr)
			Frog.MountedPlayer.PlayForceFeedback(Frog.JumpForceFeedback, false, true, n"FrogJump");

		if(HasControl())
		{
			// Update velocity
			FVector ForwardVector = Frog.GetActorForwardVector();
			if (!JumpInitialDirection.IsNearlyZero())
				ForwardVector = JumpInitialDirection.GetSafeNormal();
			
			const FVector InheritedHorizontalVelocity = ForwardVector * MoveComp.Velocity.ConstrainToPlane(MoveComp.WorldUp).Size();

			const float InputAlpha = JumpInitialDirection.GetClampedToSize(0.f, 1.f).Size();
			const float InputMultiplier = FMath::Lerp(Frog.MovementSettings.JumpForwardForceStickInputMultiplier.Min, Frog.MovementSettings.JumpForwardForceStickInputMultiplier.Max, InputAlpha);
			//InputMultiplier * Frog.MovementSettings.JumpForwardForce;
			
			// Add the inherited amount
			FVector WantedForwardVelocity = FMath::Lerp(FVector::ZeroVector, InheritedHorizontalVelocity, Frog.MovementSettings.VelocityInheritancePercentage);
			
			// Add the input amount
			//WantedForwardVelocity += FMath::Lerp(FVector::ZeroVector, ForwardVector * Frog.MovementSettings.JumpForwardForce * InputMultiplier, Frog.MovementSettings.VelocityInheritancePercentage);
			
			WantedForwardVelocity += ForwardVector * (Frog.MovementSettings.JumpForwardForce * InputMultiplier);

			if(Frog.MovementSettings.bUseMaxAirSpeed)
				WantedForwardVelocity.GetClampedToSize(0.f, Frog.MovementSettings.MaxAirSpeed);
			MoveComp.SetVelocity(WantedForwardVelocity);

			// Add the up force
			const FVector UpForce = MoveComp.GetWorldUp() * (Frog.MovementSettings.JumpForce);
			MoveComp.AddImpulse(UpForce);
		}

		if (MoveComp.DownHit.Component != nullptr && MoveComp.DownHit.Actor != nullptr)
		{
			UFloorJumpCallbackComponent FloorJumpCallbackComp = UFloorJumpCallbackComponent::Get(MoveComp.DownHit.Actor);
			if (FloorJumpCallbackComp != nullptr)
				FloorJumpCallbackComp.JumpFromActor(Frog.MountedPlayer, MoveComp.DownHit.Component);
		}
		
		//bHadImpact = false;
		
		if(MoveComp.DownHit.Actor != nullptr)
		{
			if(Cast<AFrogPondScaleActor>(MoveComp.DownHit.Actor) != nullptr)
				return;

			if(MoveComp.DownHit.Actor.ActorHasTag(n"NotFrogRespawnable") || MoveComp.DownHit.Component.HasTag(n"NotFrogRespawnable"))
				return;
		}

		CurrentStrafeVelocity = FVector::ZeroVector;
		//Frog.RespawnTransform = Frog.ActorTransform;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreDeactivation(FCapabilityDeactivationSyncParams& DeactivationParams)
	{
		if(MoveComp.DownHit.Actor != nullptr)
		{
			if(!MoveComp.DownHit.Actor.ActorHasTag(n"Water") 
			&& !MoveComp.DownHit.Actor.ActorHasTag(n"Piercable") 
			&& !MoveComp.DownHit.Actor.ActorHasTag(n"Slime"))
				DeactivationParams.AddActionState(n"AudioFrogBigLand");
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Frog.bJumping = false;
		Frog.bBouncing = false;
		Frog.DistanceToGround = 0;
		Frog.BlendSpaceCharge = 0;
		Frog.VerticalTravelDirection = 0;	
		if(HasControl())
		{
			Frog.CurrentChargeDelay = Frog.MovementSettings.RetriggerJumpDelay;
			Frog.CurrentMovementDelay = Frog.MovementSettings.MovementDelayAfterJump;
		}

		if(DeactivationParams.GetActionState(n"AudioFrogBigLand"))
		{
			Frog.SetCapabilityActionState(n"AudioFrogBigLand", EHazeActionState::ActiveForOneFrame);
			if (Frog.MountedPlayer != nullptr)
				Frog.MountedPlayer.PlayForceFeedback(Frog.LandForceFeedback, false, true, n"FrogLand");
		}
	}

	UFUNCTION(BlueprintOverride)
	void NotificationReceived(FName Notification, FCapabilityNotificationReceiveParams NotificationParams)
	{
		if(!NotificationParams.IsStale())
		{
			if(Notification == n"Bounce")
			{
				Frog.bBouncing = true;
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		// Reset the blendspace after 1 frame
		ActiveFrames++;

		FHazeFrameMovement MoveData = MoveComp.MakeFrameMovement(JumpingFrogTags::Jump);
		
		MoveData.OverrideStepDownHeight(0.f);
		MoveData.OverrideStepUpHeight(2.f);

		// Check if we are close to the ground
		FHitResult GroundHitResult;
		if(Frog.VerticalTravelDirection < 0)
		{
			if(MoveComp.LineTraceGround(Frog.ActorLocation, GroundHitResult, Frog.MovementSettings.TraceGroundDistance))
			{
				Frog.DistanceToGround = GroundHitResult.Distance;
			}
			else
			{
				Frog.DistanceToGround = Frog.MovementSettings.TraceGroundDistance;
			}
		} 
		
		if(HasControl())
		{	
			const FVector Input(Frog.CurrentMovementInput.X, Frog.CurrentMovementInput.Y, 0.0f);
			Frog.BlendSpaceTurn = Input.DotProduct(Frog.GetActorRightVector());

			bool bHadImpactThisFrame = false;	
			{
				bool bIsHolding = true;

				if(ActiveFrames > InitalFrameCount)
				{
					bIsHolding = Frog.bCharging;
					if(GetActiveDuration() >= Frog.MovementSettings.MaxJumpInputTime)
						bIsHolding = false;

					if(MoveComp.GetImpacts().UpImpact.bBlockingHit)
					{
						bHadImpactThisFrame = true;
						FVector VelocityToApply = (-MoveComp.GetVelocity());
						VelocityToApply = VelocityToApply.ConstrainToDirection(MoveComp.WorldUp) * 1.25f;
						MoveData.ApplyVelocity(VelocityToApply);
					}
				}
			
				if(bIsHolding && !bHadImpactThisFrame)
					MoveData.ApplyVelocity(MoveComp.WorldUp * Frog.MovementSettings.JumpForce * DeltaTime);

				MoveData.ApplyAndConsumeImpulses();

				// Setup the horizontal velocity
				FVector WantedHorizontalVelocity = MoveComp.Velocity.ConstrainToPlane(MoveComp.WorldUp);

				const float AirControlAmount = MoveComp.GetAirControlAmount();
				if(AirControlAmount > 0)
				{
					// Break or Accelerate
					WantedHorizontalVelocity = GetForwardBackwardInput(WantedHorizontalVelocity, DeltaTime, Input, AirControlAmount);

					// Rotate the actor and the velocity
					WantedHorizontalVelocity = GetRotationVelocity(WantedHorizontalVelocity, DeltaTime, Input, AirControlAmount);

					// Clamp if we have clamps
					WantedHorizontalVelocity = ClampToMaxAirSpeed(WantedHorizontalVelocity, DeltaTime, Input);
					
					// Apply strafe movement
					const FVector StarfeHorizontalVelocoty = GetStrafeVelocity(WantedHorizontalVelocity, DeltaTime, Input, AirControlAmount);
					MoveData.ApplyDeltaWithCustomVelocity(StarfeHorizontalVelocoty * DeltaTime, FVector::ZeroVector);
				}
				
				MoveData.ApplyVelocity(WantedHorizontalVelocity);
				MoveData.ApplyActorVerticalVelocity();
				MoveData.ApplyGravityAcceleration();	

				
				// Bounce
				if(Frog.bBouncing == false && Frog.VerticalTravelDirection > 0 && ActiveFrames > InitalFrameCount)
				{
					if(MoveComp.ForwardHit.bBlockingHit)
					{
						if(ActiveDuration > 0.1f)
						{
							const float ReDirectionVelocityAmount = (-MoveData.Velocity).GetSafeNormal().DotProduct(MoveComp.ForwardHit.Normal);
							MoveData.ApplyVelocity((-MoveData.Velocity) * ReDirectionVelocityAmount * 0.5f);
						}
						
						if(Frog.MountedPlayer != nullptr)
							Frog.MountedPlayer.PlayForceFeedback(Frog.ImpactForceFeedback, bLooping = false, bIgnoreTimeDilation = true, Tag = n"FrogImpact");

						TriggerNotification(n"Bounce");
					}
					else if(MoveComp.UpHit.bBlockingHit)
					{
						const FVector HitLocation = MoveComp.ForwardHit.ImpactPoint;
						const FVector Velocity = Frog.ActorForwardVector;
						const FVector HitNormal = MoveComp.ForwardHit.ImpactNormal;
						
						const FVector FacingDirection2D = Velocity.GetSafeNormal2D() * -1.0f;
						const FVector ReflectedVector = HitNormal;
						//const FVector ReflectedVector = (HitNormal * (2.0f * FacingDirection2D.DotProduct(HitNormal))) - FacingDirection2D;
						const float Impulse = MoveComp.Velocity.Size2D();

						float ScaledImpulse = Impulse * Frog.MovementSettings.ImpulseScaler;
						ScaledImpulse = FMath::Clamp(ScaledImpulse, Frog.MovementSettings.MinImpulse, Frog.MovementSettings.MaxImpulse);
						const FVector BounceDirection = (ReflectedVector * (Velocity.Size() * 0.5f))/*.ConstrainToPlane(MoveComp.WorldUp)*/.GetSafeNormal() * ScaledImpulse;
						MoveData.ApplyVelocity(BounceDirection);

						if(Frog.MountedPlayer != nullptr)
							Frog.MountedPlayer.PlayForceFeedback(Frog.ImpactForceFeedback, bLooping = false, bIgnoreTimeDilation = true, Tag = n"FrogImpact");

						TriggerNotification(n"Bounce");
					}
				}

				// Facing dirction
				// First frame, we clear out the facing direction
				if(ActiveFrames == 1)
				{
					if(MoveComp.GetVelocity().SizeSquared() > 0.f)
						MoveComp.SetTargetFacingDirection(MoveComp.GetVelocity().GetSafeNormal());
				}
				else if(!WantedHorizontalVelocity.IsNearlyZero() && !Frog.bBouncing)
				{
					//We have now forced the velocity over to start accelerating backwards
					const FVector WantedVelocityDirection = WantedHorizontalVelocity.GetSafeNormal();
					if(WantedVelocityDirection.DotProduct(JumpInitialDirection) < 0.f)
					{
						const float ForceRotationSpeed = 5.f * AirControlAmount;
						MoveComp.SetTargetFacingDirection(WantedVelocityDirection, ForceRotationSpeed);
						if(Frog.GetActorForwardVector().DotProduct(JumpInitialDirection) < -0.99f)
						{
							JumpInitialDirection = WantedVelocityDirection;
						}
					}
					else
					{
						MoveComp.SetTargetFacingDirection(WantedHorizontalVelocity.GetSafeNormal());
					}
				}	
				else
				{
					MoveComp.SetTargetFacingRotation(Frog.GetActorRotation());
				}
			}
			
			MoveData.ApplyTargetRotationDelta();
			MoveData.OverrideStepDownHeight(1.f);
			MoveData.OverrideStepUpHeight(0.f);
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			MoveData.ApplyConsumedCrumbData(ConsumedParams);
		}

		MoveComp.Move(MoveData);
		CrumbComp.LeaveMovementCrumb();

		if(ActiveFrames > InitalFrameCount)
		{
			Frog.BlendSpaceCharge = 0.f;
			const float MovingUpVelDir = MoveComp.Velocity.ConstrainToDirection(MoveComp.GetWorldUp()).GetSafeNormal() .DotProduct(MoveComp.GetWorldUp());
			if(MovingUpVelDir < -0.1f)
			{
				Frog.VerticalTravelDirection = -1;
			}
		}
	}

	FVector GetForwardBackwardInput(FVector CurrentVelocity, const float DeltaTime, const FVector Input, const float AirControlAmount)
	{
		FRotator WantedFacingRotation = Frog.GetActorRotation();
		FVector WantedVelocity = CurrentVelocity;

		// Breaks
		const float InputAmount = Input.DotProduct(Frog.GetActorForwardVector()) * AirControlAmount;
		if(InputAmount < -KINDA_SMALL_NUMBER)
		{
			float BreakAmount = FMath::Abs(InputAmount);
			FVector BreakSpeed = (-Frog.GetActorForwardVector()) * Frog.MovementSettings.AirBreakSpeed * BreakAmount * DeltaTime;
			WantedVelocity += BreakSpeed;
		}	
		else 
		{
			// Accelerates
			if(InputAmount > 0.025f)
			{
				float AccAmount = InputAmount;
				FVector AccSpeed = (Frog.GetActorForwardVector()) * Frog.MovementSettings.AirAccelerationSpeed * AccAmount * DeltaTime;
				WantedVelocity += AccSpeed;
			}
		}

		return WantedVelocity;
	}

	FVector GetRotationVelocity(FVector CurrentVelocity, const float DeltaTime, const FVector Input, const float AirControlAmount)
	{
		const float RotationSpeed = MoveComp.GetRotationSpeed();
		const FVector NormalInput = Input.GetSafeNormal();
		if(NormalInput.IsNearlyZero())
			return CurrentVelocity;

		if(RotationSpeed <= 0)
			return CurrentVelocity;

		if(NormalInput.DotProduct(JumpInitialDirection) < 0)
			return CurrentVelocity;

		FRotator NewSteeringDirection =  FMath::RInterpConstantTo(CurrentVelocity.Rotation(), NormalInput.Rotation(), DeltaTime, RotationSpeed);
		FVector WantedVelocity = NewSteeringDirection.Vector() * CurrentVelocity.Size();

		FRotator NewInitialDirection =  FMath::RInterpConstantTo(JumpInitialDirection.Rotation(), NormalInput.Rotation(), DeltaTime, RotationSpeed);
		JumpInitialDirection = NewInitialDirection.Vector();

		return WantedVelocity;
	}

	FVector GetStrafeVelocity(FVector CurrentVelocity, const float DeltaTime, const FVector Input, const float AirControlAmount)
	{
		FQuat WantedMovementDirection = Math::MakeQuatFromXZ(CurrentVelocity.GetSafeNormal(), MoveComp.WorldUp);
		const float StrafeDot = Input.DotProduct(WantedMovementDirection.GetRightVector());
		const float StrafeAmount = StrafeDot * FMath::Pow(FMath::Abs(StrafeDot), 2.f) * AirControlAmount;
		const FVector WantedVelocity = WantedMovementDirection.GetRightVector() * StrafeAmount * Frog.MovementSettings.AirControlStrafeSpeed;
	
		if(!Input.IsNearlyZero(0.1f))
			CurrentStrafeVelocity = FMath::VInterpTo(CurrentStrafeVelocity, WantedVelocity, DeltaTime, 10.f);
		else
			CurrentStrafeVelocity = FMath::VInterpTo(CurrentStrafeVelocity, FVector::ZeroVector, DeltaTime, 0.1f);
		return CurrentStrafeVelocity;
	}

	FVector ClampToMaxAirSpeed(FVector CurrentVelocity, const float DeltaTime, const FVector Input)
	{
		// Clamp the airspeed if we have clamps active
		if(!Frog.MovementSettings.bUseMaxAirSpeed)
			return CurrentVelocity;

		float MaxAirMoveSpeed = Frog.MovementSettings.MaxAirSpeed;
		float NormalizedFowardInputAmount = Frog.MovementSettings.ZeroInputValueOnTheMaxAirSpeedMultiplier;
		if(!Input.IsNearlyZero())
			NormalizedFowardInputAmount = Math::GetNormalizedDotProduct(Input.GetSafeNormal(), Frog.GetActorForwardVector());

		MaxAirMoveSpeed *= Frog.MovementSettings.MaxAirSpeedMultiplierInRelationToInputAgainstForward.GetFloatValue(NormalizedFowardInputAmount, 1.f);
		FVector ClampedWantedHorizontalVelocity = CurrentVelocity.GetClampedToSize(0.f, MaxAirMoveSpeed);
		if(CurrentVelocity.SizeSquared() <= ClampedWantedHorizontalVelocity.SizeSquared())
			return CurrentVelocity;

		return FMath::VInterpConstantTo(CurrentVelocity, ClampedWantedHorizontalVelocity, DeltaTime, Frog.MovementSettings.AirBreakSpeed);
	}
}
