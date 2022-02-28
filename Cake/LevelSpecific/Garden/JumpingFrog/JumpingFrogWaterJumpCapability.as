// import Cake.LevelSpecific.Garden.JumpingFrog.JumpingFrog;
// import Vino.Movement.Components.MovementComponent;
// import Vino.Trajectory.TrajectoryStatics;
// import Vino.Projectile.ProjectileMovement;

// class UJumpingFrogWaterJumpCapability : UHazeCapability
// {
// 	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

// 	default CapabilityDebugCategory = n"LevelSpecific";
	
// 	default TickGroup = ECapabilityTickGroups::ActionMovement;
// 	default TickGroupOrder = 40;

// 	AJumpingFrog Frog;
// 	UHazeMovementComponent MoveComp;
// 	UHazeCrumbComponent CrumbComp;
	
// 	float MaxForwardDistance = 500.f;
// 	float MaximumHeight = 1000.f;
// 	const float JumpSpeed = 2.5f;
// 	const float FindGroundDistance = 0.f;
// 	const float ApplyJumpVelocityDelay = 0.2;
// 	const float TraceGroundDistanceMax = 1000.f;
// 	const float RetriggerJumpDelay = 0.4;
// 	const float AirControlMoveSpeed = 150.f;

// 	FVector JumpInitialForce = FVector::ZeroVector;

// 	float CurrentApplyVelocityDelay = 0;
// 	float ImpulseScaler = 0.7f;
// 	float MaxImpulse = 700.0f;
// 	float MinImpulse = 300.0f;


// 	UFUNCTION(BlueprintOverride)
// 	void Setup(FCapabilitySetupParams SetupParams)
// 	{
// 		Frog = Cast<AJumpingFrog>(Owner);
// 		MoveComp = UHazeMovementComponent::GetOrCreate(Owner);
// 		CrumbComp = UHazeCrumbComponent::Get(Owner);
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	EHazeNetworkActivation ShouldActivate() const
// 	{
// 		if(!IsActioning(JumpingFrogTags::WaterJump))
// 			return EHazeNetworkActivation::DontActivate;

// 		if (!MoveComp.CanCalculateMovement())
// 			return EHazeNetworkActivation::DontActivate;

// 		if (!MoveComp.IsGrounded())
// 			return EHazeNetworkActivation::DontActivate;

// 		if (Frog.bWaterJumping)
// 			return EHazeNetworkActivation::DontActivate;

// 		if(IsActioning(JumpingFrogTags::Death))			
// 			return EHazeNetworkActivation::DontActivate;

// 		return EHazeNetworkActivation::ActivateUsingCrumb;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	EHazeNetworkDeactivation ShouldDeactivate() const
// 	{
// 		if (!MoveComp.CanCalculateMovement())
// 			return EHazeNetworkDeactivation::DeactivateLocal;

// 		if (!Frog.bWaterJumping)
// 			return EHazeNetworkDeactivation::DeactivateLocal;

// 		if(MoveComp.IsGrounded() && CurrentApplyVelocityDelay <= 0 && HasControl())
// 			return EHazeNetworkDeactivation::DeactivateLocal;

// 		return EHazeNetworkDeactivation::DontDeactivate;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
// 	{
// 		ActivationParams.AddVector(n"TargetLocation", Owner.ActorLocation + (Owner.ActorForwardVector * MaxForwardDistance));
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnActivated(FCapabilityActivationParams ActivationParams)
// 	{
// 		Frog.bWaterJumping = true;
// 		Frog.bJumping = false;
// 		Frog.VerticalTravelDirection = 1;
// 		Frog.DistanceToGround = 0;
// 		CurrentApplyVelocityDelay = ApplyJumpVelocityDelay;
// 		const FVector EndLocation = ActivationParams.GetVector(n"TargetLocation");
// 		const FVector StartLocation = Owner.ActorLocation;

// 		const float Gravity = MoveComp.GetGravityMagnitude();
// 		JumpInitialForce = CalculateVelocityForPathWithHeight(StartLocation, EndLocation, Gravity, MaximumHeight);
// 		MoveComp.StopMovement();
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
// 	{
// 		Frog.bWaterJumping = false;
// 		Frog.bBouncing = false;
// 		Frog.DistanceToGround = 0;
// 		Frog.VerticalTravelDirection = 0;
// 		if(HasControl())
// 		{
// 			Frog.CurrentChargeDelay = RetriggerJumpDelay;
// 		}
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void NotificationReceived(FName Notification, FCapabilityNotificationReceiveParams NotificationParams)
// 	{
// 		if(!NotificationParams.IsStale())
// 		{
// 			if(Notification == n"Bounce")
// 			{
// 				Frog.bBouncing = true;
// 			}
// 		}
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void TickActive(float DeltaTime)
// 	{	
// 		FHazeFrameMovement MoveData = MoveComp.MakeFrameMovement(JumpingFrogTags::Jump);

// 		float MovingUp = MoveComp.Velocity.ConstrainToDirection(MoveComp.GetWorldUp()).DotProduct(MoveComp.GetWorldUp());
// 		if(MovingUp < -0.1)
// 		{
// 			Frog.VerticalTravelDirection = -1;
// 		}

// 		// Check if we are close to the ground
// 		if(Frog.VerticalTravelDirection < 0)
// 		{
// 			FHitResult HitResult;
// 			if(MoveComp.LineTraceGround(Frog.ActorLocation, HitResult, TraceGroundDistanceMax))
// 			{
// 				Frog.DistanceToGround = HitResult.Distance;
// 			}
// 			else
// 			{
// 				Frog.DistanceToGround = TraceGroundDistanceMax;
// 			}
// 		} 
		
// 		if(HasControl())
// 		{	
// 			if(CurrentApplyVelocityDelay > 0)
// 			{
// 				CurrentApplyVelocityDelay -= DeltaTime;
// 				if(CurrentApplyVelocityDelay <= 0)
// 				{
// 					if(JumpInitialForce.SizeSquared() > 0)
// 					{
// 						MoveData.ApplyVelocity(JumpInitialForce);
// 						JumpInitialForce = FVector::ZeroVector;
// 					}

// 				}
// 			}
			
// 			MoveData.ApplyActorHorizontalVelocity();
// 			MoveData.ApplyActorVerticalVelocity();
// 			MoveData.ApplyGravityAcceleration();


// 			// AirControl
// 			if(Frog.VerticalTravelDirection < 0)
// 			{	
// 				const float VerticalMultiplier = FMath::Abs(Frog.ActorVelocity.GetSafeNormal().DotProduct(MoveComp.WorldUp.GetSafeNormal()));
// 				const FVector Input = FVector(Frog.CurrentMovementInput.X, Frog.CurrentMovementInput.Y, 0);
// 				const float RightAmount = Input.DotProduct(Frog.GetActorRightVector());
// 				const float ForwardAmount = Input.DotProduct(Frog.GetActorForwardVector());
// 				FVector WantedVelocity = (Frog.GetActorRightVector() * RightAmount) * (Frog.GetActorForwardVector() * ForwardAmount) * AirControlMoveSpeed;

// 				FVector CurrentVelocity = Frog.GetActorVelocity();
// 				const float VelocityAlpha = 1 - ((CurrentVelocity.GetSafeNormal().DotProduct(WantedVelocity.GetSafeNormal()) + 1) * 0.5f);
				
// 				MoveData.ApplyVelocity(WantedVelocity * VelocityAlpha * VerticalMultiplier);
// 			}	
		
// 			// Bounce
// 			if(Frog.bBouncing == false && Frog.VerticalTravelDirection > 0)
// 			{
// 				FHitResult BounceHit;
// 				if(MoveComp.ForwardHit.bBlockingHit)
// 				{
// 					BounceHit = MoveComp.ForwardHit;
// 				}
// 				else if(MoveComp.UpHit.bBlockingHit)
// 				{
// 					BounceHit = MoveComp.UpHit;
// 				}
				
// 				if(BounceHit.bBlockingHit)
// 				{
// 					const FVector HitLocation = MoveComp.ForwardHit.ImpactPoint;
// 					const FVector Velocity = Frog.ActorForwardVector;
// 					const FVector HitNormal = MoveComp.ForwardHit.ImpactNormal;
					
// 					const FVector FacingDirection2D = Velocity.GetSafeNormal2D() * -1.0f;
// 					const FVector ReflectedVector = HitNormal;
// 					//const FVector ReflectedVector = (HitNormal * (2.0f * FacingDirection2D.DotProduct(HitNormal))) - FacingDirection2D;
// 					const float Impulse = MoveComp.Velocity.Size2D();

// 					float ScaledImpulse = Impulse * ImpulseScaler;
// 					ScaledImpulse = FMath::Clamp(ScaledImpulse, MinImpulse, MaxImpulse);
// 					const FVector BounceDirection = (ReflectedVector * (Velocity.Size() * 0.5f))/*.ConstrainToPlane(MoveComp.WorldUp)*/.GetSafeNormal() * ScaledImpulse;
// 					Print("Impulse: " + ScaledImpulse, 3.0f);
					
// 					MoveData.ApplyVelocity(BounceDirection);
// 					Print("BounceDirection: " + BounceDirection, 3.0f);


// 					if(Frog.MountedPlayer != nullptr)
// 						Frog.MountedPlayer.PlayForceFeedback(Frog.ImpactForceFeedback, bLooping = false, bIgnoreTimeDilation = true, Tag = n"FrogImpact");

// 					TriggerNotification(n"Bounce");
// 				}
// 			}

// 			MoveData.ApplyTargetRotationDelta();
// 			MoveData.OverrideStepDownHeight(0.f);
// 			MoveData.OverrideStepUpHeight(0.f);
// 		}
// 		else
// 		{
// 			FHazeActorReplicationFinalized ConsumedParams;
// 			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
// 			MoveData.ApplyConsumedCrumbData(ConsumedParams);
// 		}

// 		MoveComp.Move(MoveData);
// 		CrumbComp.LeaveMovementCrumb();
// 	}
// }