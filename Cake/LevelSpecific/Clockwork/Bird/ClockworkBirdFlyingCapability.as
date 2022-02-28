import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.Components.MovementComponent;

import Cake.LevelSpecific.Clockwork.Bird.ClockworkBird;
import Cake.LevelSpecific.Clockwork.Bird.ClockworkBirdFlyingSettings;
import Cake.LevelSpecific.Clockwork.Bird.ClockworkBirdKeepAboveVolume;
import Cake.LevelSpecific.Clockwork.Bird.ClockworkBirdStayBelowVolume;
import Cake.LevelSpecific.Clockwork.Bird.ClockworkBirdTurnBackVolume;
import Cake.LevelSpecific.Clockwork.Bird.ClockworkBirdFlyingComponent;
import Cake.LevelSpecific.Clockwork.Bird.ClockworkBirdSpeedLimitSphere;
import Peanuts.Movement.GroundTraceFunctions;

class UClockworkBirdFlyingCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(n"ClockworkBirdFlying");

	default CapabilityDebugCategory = n"ClockworkBirdFlying";
	
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 90;

	UHazeMovementComponent MoveComp;
	UHazeCrumbComponent CrumbComp;
	AClockworkBird Bird;
	UClockworkBirdFlyingSettings Settings;

	FHazeAcceleratedFloat PitchAccel;
	FHazeAcceleratedFloat YawAccel;
	FHazeAcceleratedFloat RollAccel;

	UClockworkBirdFlyingComponent FlyingComp;

	FHazeAcceleratedRotator ControlRotation;
	FHazeAcceleratedRotator BirdRotation;

	bool bIsLaunchFromLand = false;

	float KeepAboveTimer = 0.f;
	float StayBelowTimer = 0.f;

	bool bInsideKeepAbove = false;
	bool bInsideStayBelow = false;

	float TurnBackTimer = 0.f;
	FVector TurnBackDirection;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		// Get ClockworkBird (owner)
		Bird = Cast<AClockworkBird>(Owner);
		
		// Setup MoveComp
		MoveComp = UHazeMovementComponent::Get(Bird);
		CrumbComp = UHazeCrumbComponent::Get(Bird);
		Settings = UClockworkBirdFlyingSettings::GetSettings(Bird);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		if (!Bird.bIsFlying)
			return EHazeNetworkActivation::DontActivate;

		if (Bird.ActivePlayer == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if (Bird.IsGrounded())
			return EHazeNetworkActivation::DontActivate;
        
        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	bool RemoteAllowShouldActivate(FCapabilityRemoteValidationParams ActivationParams) const
	{
		return MoveComp.CanCalculateMovement();
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

		if (!Bird.bIsFlying)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		if (Bird.ActivePlayer == nullptr)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		const bool bIsLaunching = IsActioning(ClockworkBirdTags::ClockworkBirdLaunch);
		if (Bird.IsGrounded() && !bIsLaunching)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
        
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	TArray<AActor> IgnoreActors;

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Bird.SetIsFlying(true);

		IgnoreActors.Reset();
		IgnoreActors.Add(Bird);

		MoveComp.SetVelocity(FVector(0.f));

		FRotator CurrentRotation = Bird.ActorRotation;
		CurrentRotation.Pitch = Bird.Mesh.RelativeRotation.Pitch;
		CurrentRotation.Roll = Bird.Mesh.RelativeRotation.Roll;
		BirdRotation.SnapTo(CurrentRotation);

		YawAccel.SnapTo(Bird.ActorRotation.Yaw, Velocity = 0.f);
		PitchAccel.SnapTo(Bird.Mesh.RelativeRotation.Pitch, Velocity = 0.f);
		RollAccel.SnapTo(Bird.Mesh.RelativeRotation.Roll, Velocity = 0.f);

		UMovementSettings::SetStepUpAmount(Bird, 0.f, this);

		if (Bird.ActivePlayer != nullptr)
		{
			ControlRotation.SnapTo(Bird.ActivePlayer.GetControlRotation());
			FlyingComp = UClockworkBirdFlyingComponent::Get(Bird.ActivePlayer);
		}

		Bird.SetCapabilityActionState(n"AudioStartedFlying", EHazeActionState::ActiveForOneFrame);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Bird.SetIsFlying(false);
		Bird.SetCapabilityActionState(ClockworkBirdTags::ClockworkBirdLaunch, EHazeActionState::Inactive);
		Bird.BirdRoot.SetRelativeRotation(FQuat::Identity);
		Bird.bCanLand = false;
		FlyingComp = nullptr;

		UMovementSettings::ClearStepUpAmount(Bird, this);

		Bird.SetCapabilityActionState(n"AudioStoppedFlying", EHazeActionState::ActiveForOneFrame);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeFrameMovement MoveData = MoveComp.MakeFrameMovement(n"ClockworkBirdFlying");
		if (HasControl())
		{
			AHazePlayerCharacter Player = Bird.ActivePlayer;
			if (Player == nullptr)
				return;

			const bool bIsLaunching = IsActioning(ClockworkBirdTags::ClockworkBirdLaunch);

			// Update the control rotation we will use to fly with
			ControlRotation.AccelerateTo(Player.GetControlRotation(), 0.3f, DeltaTime);
			UpdateForcedMovementVolumes(DeltaTime);
			UpdateLandingCheck();

			if (Bird.bIsDead)
			{
				// Stand still when dead
				MoveData.ApplyVelocity(FVector::ZeroVector);
			}
			else if (bIsLaunching)
			{
				// Launch straight up into the air first when launching
				MoveData.ApplyVelocity(FVector(0.f, 0.f, 1000.f));
			}
			else
			{
				// Update move direction
				float VerticalScale = 0.f;
				if (IsActioning(ClockworkBirdTags::ClockworkBirdJumping) || bInsideKeepAbove)
					VerticalScale += 1.5f;
				if (IsActioning(ClockworkBirdTags::ClockworkBirdLand) || bInsideStayBelow)
					VerticalScale -= 1.f;

				// Stop flying if we're going down and there is ground below us
				if (IsActioning(ClockworkBirdTags::ClockworkBirdLand) && Bird.bCanLand)
				{
					Bird.bIsFlying = false;
					MoveComp.SetVelocity(MoveComp.Velocity.GetClampedToMaxSize(700.f));
					return;
				}

				// Figure out what speed we should be flying at right now
				float TargetFlyingSpeed = Settings.FlyingSpeed;
				float CurrentAccelerationLimit = Settings.FlyingSpeedAcceleration;

				if (Bird.bIsHoldingBomb)
					TargetFlyingSpeed = FMath::Min(TargetFlyingSpeed, Settings.FlyingSpeed_WithBomb);

				// Apply speed limits from any actors placed in the level
				if (FlyingComp != nullptr)
				{
					for (auto SpeedLimitActor : FlyingComp.SpeedLimitActors)
					{
						auto SpeedLimitSphere = Cast<AClockworkBirdSpeedLimitSphere>(SpeedLimitActor);
						if (SpeedLimitSphere != nullptr)
						{
							float SpeedLimit = SpeedLimitSphere.GetSpeedLimitAtPosition(Bird.ActorLocation, Settings.FlyingSpeed);
							if (SpeedLimit < TargetFlyingSpeed)
								TargetFlyingSpeed = SpeedLimit;

							float AccelerationLimit = SpeedLimitSphere.GetAccelerationLimitAtPosition(Bird.ActorLocation, Settings.FlyingSpeedAcceleration);
							if (AccelerationLimit < CurrentAccelerationLimit)
								CurrentAccelerationLimit = AccelerationLimit;
						}
					}
				}

				const bool bIsBoosting = Bird.BoostDuration > 0.f;
				if (bIsBoosting)
				{
					TargetFlyingSpeed = FMath::Max(TargetFlyingSpeed,
						FMath::Lerp(
							Bird.CurrentBoostSpeed,
							Settings.FlyingSpeed,
							Bird.BoostTimer / Bird.BoostDuration));
				}

				FVector WantedDirection = ControlRotation.Value.RotateVector(Bird.PlayerRawInput) + (MoveComp.WorldUp * VerticalScale);
				WantedDirection = WantedDirection.GetClampedToMaxSize(1.f);

				// Stay below or above relevant volumes
				if ((KeepAboveTimer > 0.f && WantedDirection.Z < 0.f)
					|| (StayBelowTimer > 0.f && WantedDirection.Z > 0.f))
				{
					float OrigSize = WantedDirection.Size();
					WantedDirection.Z = 0.f;
					WantedDirection = WantedDirection.GetSafeNormal() * OrigSize;
				}

				// Automatically turn back if we hit a turn back volume
				if (TurnBackTimer > 0.f)
				{
					WantedDirection = TurnBackDirection;
				}
	
				FRotator CurrentRotation = Bird.ActorRotation;
				CurrentRotation.Pitch = Bird.Mesh.RelativeRotation.Pitch;

				FRotator TargetRotation = CurrentRotation;
				float TargetRoll = 0.f;

				// Determine which direction we want to be moving in based on input
				if (!WantedDirection.IsNearlyZero(0.01f))
				{
					TargetRotation = FRotator::MakeFromX(WantedDirection);

					if (FMath::Abs(Bird.PlayerRawInput.Y) > 0.1f)
						TargetRoll = Settings.RollDegreesWhenRotating * Bird.PlayerRawInput.Y;
					else if (FMath::Abs(BirdRotation.Velocity.Yaw) > 40.f)
						TargetRoll = Settings.RollDegreesWhenRotating * FMath::Sign(BirdRotation.Velocity.Yaw);
					else
						TargetRoll = 0.f;
				}
				else
				{
					TargetRotation.Pitch = 0.f;
					TargetRoll = 0.f;

					if (bIsBoosting && TargetFlyingSpeed > Settings.FlyingSpeed)
						WantedDirection = ControlRotation.Value.ForwardVector;
				}

				// Boost to max speed straight away
				//if (bIsBoosting && Bird.BoostTimer < 0.1f)
					//MoveComp.SetVelocity(WantedDirection * Bird.CurrentBoostSpeed);

				// Accelerate the bird's rotation to the direction we want to move in
				RollAccel.AccelerateTo(TargetRoll, Settings.RollAccelerationDuration, DeltaTime);
				BirdRotation.AccelerateTo(TargetRotation, Settings.RotationAccelerationDuration, DeltaTime);

				FRotator NewMeshRotation(BirdRotation.Value.Pitch, 0.f, RollAccel.Value);
				Bird.Mesh.RelativeRotation = NewMeshRotation;

				FRotator NewActorRotation(0.f, BirdRotation.Value.Yaw, 0.f);
				MoveComp.SetTargetFacingRotation(NewActorRotation);

				// Move the bird along our input
				FVector TargetVelocity = WantedDirection * TargetFlyingSpeed;
				FVector Velocity = FMath::VInterpConstantTo(MoveComp.Velocity, TargetVelocity, DeltaTime, CurrentAccelerationLimit);

				if (KeepAboveTimer > 0.f)
					Velocity.Z = FMath::Max(0.f, Velocity.Z);
				if (StayBelowTimer > 0.f)
					Velocity.Z = FMath::Min(0.f, Velocity.Z);

				// In a keep above volume, we cannot go sideways faster than our normal flying speed,
				// so dashing doesn't let us go through things
				if (KeepAboveTimer > 1.1f)
				{
					FVector HorizVelocity(Velocity.X, Velocity.Y, 0.f);

					float TotalSpeed = Velocity.Size();
					float HorizSpeed = HorizVelocity.Size();
					if (HorizSpeed > Settings.FlyingSpeed)
					{
						HorizVelocity *= (Settings.FlyingSpeed / HorizSpeed);
						float WantedVerticalSpeed = FMath::Sqrt(FMath::Square(TotalSpeed) - FMath::Square(HorizVelocity.X) - FMath::Square(HorizVelocity.Y));
						Velocity = HorizVelocity + FVector(0.f, 0.f, WantedVerticalSpeed);
					}
				}

				MoveData.ApplyVelocity(Velocity);
				MoveData.OverrideStepDownHeight(40.f);
			}

			MoveData.ApplyTargetRotationDelta();
			MoveComp.Move(MoveData);	

			Bird.SetNewFlightSpeed(MoveComp.Velocity.Size());
			CrumbComp.SetCustomCrumbRotation(Bird.Mesh.RelativeRotation);
			CrumbComp.LeaveMovementCrumb();		

			// If we hit something, drop out of flying
			if (HasControl())
			{
				if (MoveComp.Impacts.ForwardImpact.bBlockingHit)
				{
					float Speed = MoveData.Velocity.Size();

					bool bHitWalkableSurface = IsHitSurfaceWalkableDefault(MoveComp.Impacts.ForwardImpact, 55.f, FVector::UpVector);
					if (Speed >= Settings.ImpactMinSpeedDeath && !bHitWalkableSurface)
					{
						Bird.bIsDead = true;
					}
					else if (Speed >= Settings.ImpactMinSpeedStopFlying)
					{
						Bird.bIsFlying = false;
					}
				}
			}
		}
		else
		{
			FHazeActorReplicationFinalized ReplicatedMovement;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ReplicatedMovement);
			MoveData.ApplyConsumedCrumbData(ReplicatedMovement);
			Bird.BirdRoot.SetRelativeRotation(ReplicatedMovement.CustomCrumbRotator);
			MoveComp.Move(MoveData);
		}
	}

	/*void OldTick(float DeltaTime)
	{
		FHazeFrameMovement MoveData = MoveComp.MakeFrameMovement(n"ClockworkBirdFlying");
		if (HasControl())
		{
			float CurrentSpeed = MoveComp.Velocity.Size();
			const FVector Input = Bird.GetPlayerRawInput();
			const bool bIsLaunching = IsActioning(ClockworkBirdTags::ClockworkBirdLaunch);
			const bool bIsGliding = IsActioning(ClockworkBirdTags::Gliding);

			if (IsActioning(n"LaunchBirdAfterLand"))
				bIsLaunchFromLand = true;
			else if (!bIsLaunching)
				bIsLaunchFromLand = false;

			float LimitedMinSpeed = Settings.MinFlyingSpeed;
			float LimitedMaxSpeed = Settings.MaxFlyingSpeed;

			// Apply speed limits from any actors placed in the level
			if (FlyingComp != nullptr && !bIsLaunching)
			{
				for (auto SpeedLimitActor : FlyingComp.SpeedLimitActors)
				{
					auto SpeedLimitSphere = Cast<AClockworkBirdSpeedLimitSphere>(SpeedLimitActor);
					if (SpeedLimitSphere != nullptr)
					{
						float SpeedLimit = SpeedLimitSphere.GetSpeedLimitAtPosition(Bird.ActorLocation, Settings.MaxFlyingSpeed);
						if (SpeedLimitSphere.InnerSpeedLimit < LimitedMinSpeed)
							LimitedMinSpeed = SpeedLimitSphere.InnerSpeedLimit;
						if (SpeedLimit < LimitedMaxSpeed)
							LimitedMaxSpeed = SpeedLimit;
					}
				}
			}

			// Apply boost to max speed
			const bool bIsBoosting = Bird.BoostDuration > 0.f;
			if (bIsBoosting)
			{
				LimitedMaxSpeed = FMath::Max(LimitedMaxSpeed,
					FMath::Lerp(
						Bird.CurrentBoostSpeed,
						Settings.MaxFlyingSpeed,
						Bird.BoostTimer / Bird.BoostDuration));
			}

			// If our current speed is below our minimum flying speed, then we hit something and should drop into air move
			if ((!bIsLaunching && CurrentSpeed < LimitedMinSpeed - 1.f && !Bird.bIsLanding)
				|| MoveComp.Impacts.ForwardImpact.bBlockingHit)
			{
				Bird.bIsFlying = false;
				return;
			}

			// Calculate the pitch we want to be flying at
			float CurrentPitch = Bird.BirdRoot.RelativeRotation.Pitch;

			float TargetPitch;
			if (FMath::Abs(Input.Y) <= 0.05f)
			{
				TargetPitch = CurrentPitch;
			}
			else if (Input.Y < 0)
			{
				TargetPitch = Settings.MaxUpPitch * Input.Y;
			}
			else
			{
				TargetPitch = Settings.MaxDownPitch * Input.Y;
			}

			TargetPitch = FMath::Clamp(TargetPitch, -Settings.MaxDownPitch, Settings.MaxUpPitch);

			// Always pitch straight up if we're launching, can't control pitch during this
			if (bIsGliding)
				TargetPitch = 0.f;
			else if (bIsLaunching)
				TargetPitch = 0.f;
			else if (Bird.bIsLanding)
				TargetPitch = 0.f;

			// Interpolate the rotation of the bird based on our input
			FRotator CurrentRotation = Bird.ActorRotation;
			CurrentRotation.Pitch = Bird.Mesh.RelativeRotation.Pitch;
			CurrentRotation.Roll = Bird.Mesh.RelativeRotation.Roll;

			FRotator TargetRotation;
			TargetRotation.Pitch = TargetPitch;
			TargetRotation.Yaw = CurrentRotation.Yaw + (Input.X * 90.f);
			TargetRotation.Roll = Input.X * 60.f;

			if (bIsGliding)
				TargetRotation.Roll = 0.f;

			// Constrain our targeted rotation to not run into environment stuff we need to avoid
			TargetRotation = ConstrainTargetRotationToEnvironment(TargetRotation);

			float VerticalRotationSpeed = Settings.VerticalRotationSpeed;

			// Separate rotation speed for pitch while gliding
			if (bIsLaunching)
				VerticalRotationSpeed = Settings.VerticalRotationSpeed_Launching;
			else if (bIsGliding)
				VerticalRotationSpeed = Settings.VerticalRotationSpeed_Gliding;

			YawAccel.SnapTo(CurrentRotation.Yaw, YawAccel.Velocity);
			YawAccel.AccelerateTo(TargetRotation.Yaw, 180.f / Settings.HorizontalRotationSpeed, DeltaTime);

			PitchAccel.SnapTo(CurrentRotation.Pitch, PitchAccel.Velocity);
			PitchAccel.AccelerateTo(TargetRotation.Pitch, 180.f / VerticalRotationSpeed, DeltaTime);

			RollAccel.SnapTo(CurrentRotation.Roll, RollAccel.Velocity);
			RollAccel.AccelerateTo(TargetRotation.Roll, 180.f / Settings.HorizontalRotationSpeed, DeltaTime);

			FRotator NewRotation;
			NewRotation.Yaw = YawAccel.Value;
			NewRotation.Pitch = PitchAccel.Value;
			NewRotation.Roll = RollAccel.Value;

			FRotator NewMeshRotation(NewRotation.Pitch, 0.f, NewRotation.Roll);
			Bird.Mesh.RelativeRotation = NewMeshRotation;

			FRotator NewActorRotation(0.f, NewRotation.Yaw, 0.f);
			MoveComp.SetTargetFacingRotation(NewActorRotation);

			// Affect the flying speed based on our pitch angle
			float NewSpeed = CurrentSpeed;
			if (NewRotation.Pitch < 0.f)
				NewSpeed += Settings.DownwardSpeedGain * DeltaTime * (NewRotation.Pitch / -90.f);
			else
				NewSpeed -= Settings.UpwardSpeedLost * DeltaTime * (NewRotation.Pitch / 90.f);

			// Apply launch impulse if needed
			if (bIsLaunching && NewSpeed < Settings.LaunchToFlyingSpeed)
				NewSpeed += DeltaTime * ((Settings.LaunchToFlyingSpeed / Settings.LaunchDuration) + Settings.FlyingSpeedDrag);

			// Apply drag to the speed
			if (!bIsGliding && !bIsBoosting)
				NewSpeed -= Settings.FlyingSpeedDrag * DeltaTime;

			// Apply slowdown if landing
			if (Bird.bIsLanding)
				NewSpeed -= DeltaTime * Settings.LandingSlowdown;

			// Clamp the speed if we're not in a special situation
			if (!Bird.bIsLanding)
				NewSpeed = FMath::Clamp(NewSpeed, LimitedMinSpeed, LimitedMaxSpeed);

			// Slow down to our new maximum speed when holding a bomb
			if (Bird.bIsHoldingBomb && NewSpeed > Settings.MaxFlyingSpeed_WithBomb && !bIsBoosting)
				NewSpeed = FMath::FInterpConstantTo(NewSpeed, Settings.MaxFlyingSpeed_WithBomb, DeltaTime, 4000.f);

			// Apply the actual movement we're flying
			FVector FlyingVelocity = NewRotation.ForwardVector * NewSpeed;

			// Disregard the actual bird's rotation during launch
			if (bIsLaunching && !bIsLaunchFromLand)
			{
				if (ActiveDuration < 0.5f)
					FlyingVelocity = FVector(0.f, 0.f, NewSpeed);
				else
					FlyingVelocity = FRotator(Settings.MaxUpPitch, NewRotation.Yaw, 0.f).ForwardVector * NewSpeed;
			}

			MoveData.ApplyVelocity(FlyingVelocity);

			if (Bird.bIsLanding)
				MoveData.ApplyDeltaWithCustomVelocity(FVector(0.f, 0.f, DeltaTime * -1.f * Settings.LandingDownwardVelocity), FVector(0.f));

			MoveData.ApplyTargetRotationDelta();		
			MoveComp.Move(MoveData);	

			Bird.SetNewFlightSpeed(NewSpeed);
			CrumbComp.SetCustomCrumbRotation(Bird.Mesh.RelativeRotation);
			CrumbComp.LeaveMovementCrumb();		
		}
		else
		{
			FHazeActorReplicationFinalized ReplicatedMovement;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ReplicatedMovement);
			MoveData.ApplyConsumedCrumbData(ReplicatedMovement);
			Bird.BirdRoot.SetRelativeRotation(ReplicatedMovement.CustomCrumbRotator);
			MoveComp.Move(MoveData);
		}
	}*/

	void UpdateForcedMovementVolumes(float DeltaTime)
	{
		TArray<AActor> InsideActors;
		Bird.GetOverlappingActors(InsideActors);

		bInsideKeepAbove = false;
		bInsideStayBelow = false;

		for (auto Actor : InsideActors)
		{
			if (Cast<AClockworkBirdKeepAboveVolume>(Actor) != nullptr)
			{
				KeepAboveTimer = FMath::Max(1.f, KeepAboveTimer);
				bInsideKeepAbove = true;
			}

			if (Cast<AClockworkBirdStayBelowVolume>(Actor) != nullptr)
			{
				StayBelowTimer = FMath::Max(1.f, StayBelowTimer);
				bInsideStayBelow = true;
			}

			if (Cast<AClockworkBirdTurnBackVolume>(Actor) != nullptr)
			{
				if (TurnBackTimer <= 0.f)
				{
					TurnBackTimer = 2.f;
					TurnBackDirection = Cast<AClockworkBirdTurnBackVolume>(Actor).TurnBackDirection.ForwardVector; 
				}
			}
		}


		if (!bInsideKeepAbove)
		{
			KeepAboveTimer = FMath::Min(KeepAboveTimer, 1.f);
			KeepAboveTimer -= DeltaTime;
		}
		else
		{
			KeepAboveTimer += DeltaTime;
		}

		if (!bInsideStayBelow)
		{
			StayBelowTimer = FMath::Min(StayBelowTimer, 1.f);
			StayBelowTimer -= DeltaTime;
		}
		else
		{
			StayBelowTimer += DeltaTime;
		}
		
		if (TurnBackTimer > 0.f)
			TurnBackTimer -= DeltaTime;
	}

	void UpdateLandingCheck()
	{
		FHitResult Hit;
		if (System::LineTraceSingleByProfile(
			Bird.ActorLocation, Bird.ActorLocation - FVector(0.f, 0.f, Settings.AutomaticLandDistance),
			n"PlayerCharacter", false, IgnoreActors, EDrawDebugTrace::None,
			Hit, false))
		{
			if (Hit.bBlockingHit)
			{
				Bird.bCanLand = true;
				return;
			}
		}

		Bird.bCanLand = false;
	}

	/*FRotator ConstrainTargetRotationToEnvironment(FRotator WantedRotation)
	{
		bool bHitUpperLimit = false;
		bool bAppliedTurnBack = false;

		FRotator TargetRotation = WantedRotation;
		for(int Step = 0; Step < 20; ++Step)
		{
			TArray<EObjectTypeQuery> ObjectTypes;
			ObjectTypes.Add(EObjectTypeQuery::WorldDynamic);

			TArray<AActor> ActorsToIgnore;

			FVector Start = Bird.ActorLocation;
			FVector End = Start + TargetRotation.ForwardVector * MoveComp.Velocity.Size();

			TArray<FHitResult> Hits;
			System::LineTraceMultiForObjects(Start, End, ObjectTypes, false, ActorsToIgnore, EDrawDebugTrace::None, Hits, false);

			bool bHitKeepAbove = false;
			bool bHitStayBelow = false;
			bool bHitTurnBack = false;
			FRotator TurnBackDirection;

			for (const FHitResult& Hit : Hits)
			{
				if (Cast<AClockworkBirdKeepAboveVolume>(Hit.Actor) != nullptr)
					bHitKeepAbove = true;
				if (Cast<AClockworkBirdStayBelowVolume>(Hit.Actor) != nullptr)
					bHitStayBelow = true;

				auto TurnBack = Cast<AClockworkBirdTurnBackVolume>(Hit.Actor);
				if (TurnBack != nullptr)
				{
					bHitTurnBack = true;
					TurnBackDirection = TurnBack.TurnBackDirection.WorldRotation;
				}
			}
			
			bool bModified = false;
			if (TargetRotation.Pitch < Settings.MaxUpPitch && TargetRotation.Pitch > -Settings.MaxDownPitch)
			{
				if (bHitStayBelow)
				{
					bHitUpperLimit = true;
					TargetRotation.Pitch = FMath::Min(TargetRotation.Pitch - 10.f, Settings.MaxUpPitch);
				}
				else if (bHitKeepAbove && !bHitUpperLimit)
				{
					TargetRotation.Pitch = FMath::Min(TargetRotation.Pitch + 10.f, Settings.MaxUpPitch);
				}

				bModified = true;
			}

			if (bHitTurnBack && !bAppliedTurnBack)
			{
				bModified = true;
				bAppliedTurnBack = true;

				TargetRotation.Yaw = TurnBackDirection.Yaw;
			}

			if (!bModified)
				break;
		}

		return TargetRotation;
	}*/
}
