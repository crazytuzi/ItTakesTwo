import Vino.Movement.Components.MovementComponent;

import Vino.SwingBar.SwingBarActor;
import Vino.SwingBar.SwingPhysicsSettings;

import Cake.Weapons.Hammer.HammerWeaponStatics;
import Vino.Movement.Jump.AirJumpsComponent;

enum ESwingBarState
{
    Entering,
    Swinging,
    Releasing
};

UCLASS(Abstract)
class USwingBarCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(n"NailSwing");
	default CapabilityTags.Add(n"SwingBar");

	default TickGroupOrder = 90;
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default CapabilityDebugCategory = CapabilityTags::Movement;

    bool bDidTrigger = false;
    ASwingBarActor TriggeredSwingBar;

    ASwingBarActor SwingBar;
    ESwingBarState State;

    UPROPERTY(NotEditable)  
	UHazeMovementComponent MoveComp;

    UPROPERTY(NotEditable)  
	UHammerWielderComponent WielderComp;

	UPROPERTY()
	UCharacterAirJumpsComponent AirJumpComp;

    AHazePlayerCharacter Player;

    /* -- Settings -- */
    // Duration of time that the player lerps to the position it should be in to swing over
    UPROPERTY()
    float LerpToSwingPositionDuration = 0.4f;

    /* -- Animations -- */
    UPROPERTY()
    UAnimSequence EnterAnimation;

    UPROPERTY()
    UAnimSequence MHAnimation;

    UPROPERTY()
    UBlendSpace1D SwingBlendSpace;

    UPROPERTY()
    UAnimSequence ExitForwardAnimation;

    UPROPERTY()
    UAnimSequence ExitBackwardAnimation;

    /* -- Physics Settings -- */
    FSwingPhysicsSettings Physics;

	UPROPERTY()
	UCurveFloat SwingSpeedCurve;

    /* -- Physics State -- */
    // Angle in radians that we're off from the center
    float CurrentSwingAngle = 0.f;
    // Amount of time that we've been swinging for
    float TotalSwingingTime = 0.f;
    // Whether we're currently in the backwsing
    bool bIsInBackSwing = false;
    // Amount of time we've been in our backswing
    float TimeInBackSwing = 0.f;
    // Offset the player had when starting the swing, is kept relatively and rotated
    FTransform SwingPlayerOffset;
    // Whether we're swinging in the opposite direction from normal
    bool bSwingingReversed;
    // Whether we're playing an idle animation right now
    bool bInIdleSwing = false;
    // How long our velocity has been low enough for idle animation
    float IdleTimer = 0.f;
    // Current transform of the bar we're swinging on
    FTransform SwingPosition;
    // Position of the mesh while in 'initial lerp' mode
    FTransform PlayerInitialMeshPosition;
    // Amount of time remaining in 'initial lerp' mode
    float InitialLerpRemaining = 0.f;

	// Used to detect when we switch swinging direction. 
	float PrevSwingDirection = 0.f;
	float PrevDeltaSwingDirection = 0.f;

    /* -- Swing cooldown -- */
    // Current swing bar that's on cooldown
    ASwingBarActor CooldownSwingBar;
    float GlobalCooldownRemaining = 0.f;
    float LocalCooldownRemaining = 0.f;

    /* -- Release State -- */
    FTransform ReleaseLaunchPosition;
    FVector ReleaseLaunchForce;

    /* -- Activation -- */

    UFUNCTION(BlueprintOverride)
    void Setup(FCapabilitySetupParams SetupParams)
    {
        Player = Cast<AHazePlayerCharacter>(Owner);
        MoveComp = UHazeMovementComponent::GetOrCreate(Player);
		AirJumpComp = UCharacterAirJumpsComponent::GetOrCreate(Player);
		WielderComp = UHammerWielderComponent::GetOrCreate(Player);
    }

	UFUNCTION(BlueprintOverride)
    void PreTick(float DeltaTime)
    {
		// Find nearby swing bar activation points that we might want to use
		if (!IsActive() && !IsBlocked())
		{
			Player.QueryActivationPoints(USwingBarActivationPoint::StaticClass());
			if (GlobalCooldownRemaining <= 0.f)
				Player.UpdateActivationPointAndWidgets(USwingBarActivationPoint::StaticClass());
		}

        if (!IsActive() && WasActionStarted(ActionNames::WeaponFire))
        {
			auto ActivePoint = Cast<USwingBarActivationPoint>(Player.GetTargetPoint(USwingBarActivationPoint::StaticClass()));
			if (ActivePoint != nullptr)
			{
				bDidTrigger = true;
				TriggeredSwingBar = Cast<ASwingBarActor>(ActivePoint.Owner);
			}
			else
			{
				bDidTrigger = false;
			}

            if (TriggeredSwingBar == nullptr)
                bDidTrigger = false;
        }
		else
		{
			bDidTrigger = false;
		}

        // Update the cooldown for entering the same bar
        if (LocalCooldownRemaining > 0.f)
        {
            // Ignore triggers during cooldown
            if (bDidTrigger && TriggeredSwingBar == CooldownSwingBar)
            {
                bDidTrigger = false;
                TriggeredSwingBar = nullptr;
            }

            LocalCooldownRemaining -= DeltaTime;
            if (LocalCooldownRemaining <= 0.f)
            {
                LocalCooldownRemaining = 0.f;
				if (CooldownSwingBar != nullptr)
					CooldownSwingBar.ActivationPoint.CooldownForPlayer[Player] = false;
                CooldownSwingBar = nullptr;
            }
        }

        // Update the cooldown for entering any bar at all
        if (GlobalCooldownRemaining > 0.f)
        {
            // Ignore triggers during cooldown
            if (bDidTrigger)
            {
                bDidTrigger = false;
                TriggeredSwingBar = nullptr;
            }

            GlobalCooldownRemaining -= DeltaTime;
            if (GlobalCooldownRemaining <= 0.f)
                GlobalCooldownRemaining = 0.f;
        }
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkActivation ShouldActivate() const
    {
        if (bDidTrigger)
            return EHazeNetworkActivation::ActivateFromControl;
        return EHazeNetworkActivation::DontActivate;
    }

    // Send over the data for our triggered swing bar when the control side triggers it
    UFUNCTION(BlueprintOverride)
    void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
    { 
		UpdateSwingPosition(TriggeredSwingBar);

        FTransform LocalAnimAlignBoneTransform;
        Animation::GetAnimAlignBoneTransform(LocalAnimAlignBoneTransform, MHAnimation);

        // Calculate the angle to start swinging at with where we're entering the nail
        SwingPlayerOffset = FTransform(-LocalAnimAlignBoneTransform.GetLocation());

        FTransform PlayerTransform = Player.ActorTransform;
        FTransform SwingRotation = PlayerTransform * SwingPosition.Inverse();

        FVector ProjectedPendulumPosition = SwingRotation.GetLocation();
        ProjectedPendulumPosition.Y = 0.f;
        ProjectedPendulumPosition.Normalize();

        CurrentSwingAngle = -FMath::Atan2(ProjectedPendulumPosition.X, -ProjectedPendulumPosition.Z);

        // Entry angle is capped based on physics settings
        CurrentSwingAngle = FMath::Clamp(CurrentSwingAngle, -Physics.EntryMaxAngle, Physics.EntryMaxAngle);

        // Reverse the player if we jumped onto the other side
        bSwingingReversed = CurrentSwingAngle < 0;

		// If our angle is still fairly close to neutral, then
		// we should base our swing direction on the input
		// we're holding with the stick.
		if (FMath::Abs(CurrentSwingAngle) < Physics.EntryControllableDirectionAngle)
		{
			FVector SwingForward = SwingPosition.Rotation.ForwardVector;
			FVector InputForward = GetAttributeVector(AttributeVectorNames::MovementDirection);
			if (InputForward.Size() <= 0.1f)
				InputForward = Player.ActorVelocity.GetClampedToMaxSize(1.f);

			if (InputForward.Size() > 0.1f)
			{
				float SwingDot = SwingForward.DotProduct(InputForward.GetSafeNormal());
				if (FMath::Abs(SwingDot) > 0.25f)
					bSwingingReversed = SwingDot < 0.f;
			}
		}

        // Work backwards from the angle to find the swinging time we need to get that angle
        float GravityConstant = Player.GetActorGravity().Size();
        float PendulumConstant = FMath::Sqrt(GravityConstant / Physics.PendulumLength);

        // Below Asin()s are derived from this code in UpdateSwingPhysics():
        // ` float PendulumTime = PendulumConstant * TotalSwingingTime;
        // ` CurrentSwingAngle = Physics.MaximumSwingAngle * FMath::Sin(PendulumTime);

        if (bSwingingReversed)
        {
            float PendulumTime = FMath::Asin(CurrentSwingAngle / Physics.MaximumSwingAngle);
            TotalSwingingTime = PendulumTime / PendulumConstant;
        }
        else
        {
            // Flip the Asin in order to get the same angle position but with the opposite velocity
            float PendulumTime = FMath::Asin(-1.f * (CurrentSwingAngle / Physics.MaximumSwingAngle));
            TotalSwingingTime = (0.5f * PI + (PendulumTime - (-0.5f * PI))) / PendulumConstant;
        }

		ActivationParams.AddObject(n"SwingBar", TriggeredSwingBar);
		ActivationParams.AddVector(n"SwingPlayerOffsetLocation", SwingPlayerOffset.GetLocation());
		ActivationParams.AddVector(n"SwingPlayerOffsetRotation", SwingPlayerOffset.GetRotation().Vector());
		ActivationParams.AddValue(n"CurrentSwingAngle", CurrentSwingAngle);
		ActivationParams.AddValue(n"TotalSwingingTime", TotalSwingingTime);
		ActivationParams.AddValue(n"SwingingReversed", bSwingingReversed ? 1 : 0);
    }

    /* -- Overall Flow -- */
    UFUNCTION(BlueprintOverride)
    void OnActivated(FCapabilityActivationParams ActivationParams)
    {
		SwingBar = Cast<ASwingBarActor>(ActivationParams.GetObject(n"SwingBar"));

		Player.ConsumeButtonInputsRelatedTo(ActionNames::WeaponFire);

		if (!HasControl())
        {			
			SwingPlayerOffset.SetLocation(ActivationParams.GetVector(n"SwingPlayerOffsetLocation"));
			SwingPlayerOffset.SetRotation(ActivationParams.GetVector(n"SwingPlayerOffsetRotation").ToOrientationRotator());
			CurrentSwingAngle = ActivationParams.GetValue(n"CurrentSwingAngle");
			TotalSwingingTime = ActivationParams.GetValue(n"TotalSwingingTime");
			bSwingingReversed = ActivationParams.GetValue(n"SwingingReversed") > 0 ? true : false;		
		}

		if (SwingBar != nullptr)
			Physics = SwingBar.Physics;

        State = ESwingBarState::Entering;
        Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.TriggerMovementTransition(this);
        Player.BlockMovementSyncronization(this);
        Player.BlockCapabilities(CapabilityTags::GameplayAction, this);
        Player.BlockCapabilities(CapabilityTags::Collision, this);
		Player.BlockCapabilities(n"PiercedPlayer", this);

		if (SwingBar != nullptr)
		{
			Player.ActivatePoint(SwingBar.ActivationPoint, this);
			SwingPosition = SwingBar.GetSwingTransform();

			Player.MeshOffsetComponent.FreezeAndResetWithTime(0.f);
			Player.RootOffsetComponent.FreezeAndResetWithTime(0.5f);
			PlayerInitialMeshPosition = Player.MeshOffsetComponent.GetWorldTransform();
			InitialLerpRemaining = EnterAnimation != nullptr ? EnterAnimation.SequenceLength : 0.2f;

			// Calculate position to teleport the player to so everything aligns correctly
			FTransform AlignTransform = GetPlayerPositionAtAngle(0.f);
			//System::DrawDebugArrow(AlignTransform.GetLocation(), AlignTransform.GetLocation() + (AlignTransform.Rotation.Vector() * 300), LineColor = FLinearColor::Red, Duration = 10.f);

			FHitResult TempHitResult;
			Player.SetActorLocationAndRotation(AlignTransform.GetLocation(), AlignTransform.Rotator(), false, TempHitResult, true);

			//System::DrawDebugLine(SwingPosition.Location, SwingTransform.Location, FLinearColor::Red, 10.f, 10.f);
			UpdatePlayerPosition(0.f);
			StartEnterAnimation();
		}

		AirJumpComp.ResetJumpAndDash();

		WielderComp = UHammerWielderComponent::GetOrCreate(Player);
    }

	
    UFUNCTION(BlueprintOverride)
    EHazeNetworkDeactivation ShouldDeactivate() const
    {
        if (SwingBar == nullptr || SwingBar.IsActorBeingDestroyed())
            return EHazeNetworkDeactivation::DeactivateFromControl;
		if(WasActionStarted(ActionNames::MovementJump))
		 	return EHazeNetworkDeactivation::DeactivateFromControl;
        return EHazeNetworkDeactivation::DontDeactivate;
    }

	UFUNCTION(BlueprintOverride)
    void ControlPreDeactivation(FCapabilityDeactivationSyncParams& DeactivationParams)
	{
		if(WasActionStarted(ActionNames::MovementJump))
		{
			ReleaseLaunchPosition = Player.Mesh.GetWorldTransform();
			ReleaseLaunchPosition.SetRotation(Player.ActorRotation);

			Player.ConsumeButtonInputsRelatedTo(ActionNames::MovementJump);

			FVector SidewaysForce;
			FVector UpwardForce;

			// Find the correct jump off angle tangent
			FVector AngleTangent = GetTangentAtAngle(CurrentSwingAngle);
			FVector HorizontalDirection = SwingPosition.Rotation.ForwardVector;
			bool bJumpForward = false;

			if (IsGoingForwards())
			{
				AngleTangent *= -1.f;
				HorizontalDirection *= -1.f;
				bJumpForward = true;
			}
			if (bIsInBackSwing && TimeInBackSwing >= Physics.JumpOffSwingDirectionGracePeriod)
			{
				AngleTangent *= -1.f;
				HorizontalDirection *= -1.f;
				bJumpForward = true;
			}

			float VerticalStrength = FMath::Abs(CurrentSwingAngle) / Physics.MaximumSwingAngle;

			// Separate into a horizontal and a vertical component
			ReleaseLaunchForce = (HorizontalDirection * FMath::Lerp(Physics.JumpOffMaxHorizontalSpeed, Physics.JumpOffMinHorizontalSpeed, VerticalStrength));
			ReleaseLaunchForce += FVector::UpVector * FMath::Lerp(Physics.JumpOffMinVerticalSpeed, Physics.JumpOffMaxVerticalSpeed, VerticalStrength);

			// Calculate the auto-aim to the next nail
			if (Physics.JumpOffAutoAimPercentage > 0.f)
			{
				FVector ForceAngle = ReleaseLaunchForce.GetSafeNormal();
				float Speed = ReleaseLaunchForce.Size();

				// Auto aim disabled for now, let's see if anyone notices? It probably feels nicer without.
				/*FVector AutoAimAngle;
				if (ComputeAutoAim(ForceAngle, Speed, AutoAimAngle))
				{
					ReleaseLaunchForce = AutoAimAngle.GetSafeNormal() * Speed;
				}*/
			}
	
			DeactivationParams.AddActionState(ActionNames::MovementJump);
			if (bJumpForward)
				DeactivationParams.AddActionState(n"JumpForward");
			DeactivationParams.AddVector(n"ReleaseLaunchForce", ReleaseLaunchForce);
			DeactivationParams.AddVector(n"ReleaseLaunchPosition", ReleaseLaunchPosition.GetLocation());
			DeactivationParams.AddVector(n"ReleaseLaunchRotation", ReleaseLaunchPosition.GetRotation().Vector());

		}
	}

    UFUNCTION(BlueprintOverride)
    void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
    {
		Player.MeshOffsetComponent.ResetWithTime();
        Player.StopAnimation();
        Player.StopBlendSpace();

		if(DeactivationParams.GetActionState(ActionNames::MovementJump))
		{		
			if (DeactivationParams.GetActionState(n"JumpForward"))
			{
				Player.PlaySlotAnimation(Animation = ExitForwardAnimation);
			}
			else
			{
				Player.PlaySlotAnimation(Animation = ExitBackwardAnimation);
			}

			if(!HasControl())
			{
				ReleaseLaunchPosition.SetLocation(DeactivationParams.GetVector(n"ReleaseLaunchPosition"));
				ReleaseLaunchPosition.SetRotation(DeactivationParams.GetVector(n"ReleaseLaunchRotation").ToOrientationQuat());
				ReleaseLaunchForce = DeactivationParams.GetVector(n"ReleaseLaunchForce");
			}

			Player.AddImpulse(ReleaseLaunchForce);
			State = ESwingBarState::Releasing;

			if (CooldownSwingBar != nullptr)
				CooldownSwingBar.ActivationPoint.CooldownForPlayer[Player] = false;
			if (SwingBar != nullptr)
				SwingBar.ActivationPoint.CooldownForPlayer[Player] = true;

			CooldownSwingBar = SwingBar;
			LocalCooldownRemaining = Physics.SameSwingCooldownTime;
		}

		GlobalCooldownRemaining = Physics.AnySwingCooldownTime;
  		BP_OnPlayerReleasedFromSwingBar(); 
       
	   	SwingBar = nullptr;

		Player.DeactivateCurrentPoint(this);
       
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
        Player.UnblockMovementSyncronization(this);
        Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);
        Player.UnblockCapabilities(CapabilityTags::Collision, this);
		Player.UnblockCapabilities(n"PiercedPlayer", this);

		WielderComp = UHammerWielderComponent::GetOrCreate(Player);
		WielderComp.OnHammerSwingEnded.Broadcast();
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
		if (SwingBar == nullptr || SwingBar.IsActorBeingDestroyed())
			return;

        UpdateSwingPosition(SwingBar);
		//System::DrawDebugArrow(Owner.GetActorCenterLocation(), Owner.GetActorCenterLocation() + (Owner.GetActorForwardVector() * 300));

        if (State == ESwingBarState::Entering)
        {
            // Wait for the enter animation to transition us into swinging state
            UpdateSwingPhysics(DeltaTime);
            UpdatePlayerPosition(DeltaTime);
        }
        else  if (State == ESwingBarState::Swinging)
        {
            UpdateSwingPhysics(DeltaTime);
            UpdatePlayerPosition(DeltaTime);
            UpdateSwingAnimation(DeltaTime);
			Player.SetCapabilityActionState(n"FoghornSBEffortNailSwingingHammerhead", EHazeActionState::ActiveForOneFrame);
			Player.SetCapabilityActionState(n"FoghornSBNailSwingingHammerhead", EHazeActionState::ActiveForOneFrame);
        }
        else  if (State == ESwingBarState::Releasing)
        {
        }
    }

    void StartEnterAnimation()
    {
        Player.PlaySlotAnimation(
            Animation = EnterAnimation,
            OnBlendedIn = FHazeAnimationDelegate(this, n"OnEnterAnimationBlendedIn"),
            OnBlendingOut = FHazeAnimationDelegate(this, n"OnEnterAnimationDone")
        );
        //System::SetTimer(this, n"OnEnterAnimationBlendedIn", 0.2f, false);
        //System::SetTimer(this, n"OnEnterAnimationDone", 0.4f, false);*/
    }

    UFUNCTION()
    void OnEnterAnimationBlendedIn()
    {
		if (!IsActive())
			return;

        BP_OnSwingEnterBlendedIn();
    }

    UFUNCTION()
    void OnEnterAnimationDone()
    {
		if (!IsActive())
			return;

        State = ESwingBarState::Swinging;

        // Start the blend space for swining, we will control it from tick
        Player.PlayBlendSpace(SwingBlendSpace);
        bInIdleSwing = false;
    }

    /* -- Swinging -- */
	void UpdateSwingPosition(ASwingBarActor ForSwing)
    {
		if (ForSwing != nullptr)
			SwingPosition = ForSwing.GetSwingTransform();
    }

	float GetSwingAngleFromSwingTime(float SwingTime)
	{
        float GravityConstant = Player.GetActorGravity().Size();
        float PendulumConstant = FMath::Sqrt(GravityConstant / Physics.PendulumLength);
        float PendulumTime = PendulumConstant * SwingTime;
        float SwingAngle = Physics.MaximumSwingAngle * FMath::Sin(PendulumTime);

        // Unwind our swing angle so it stays within sane range
        if (SwingAngle < -PI)
            SwingAngle += 2.f * PI;
        if (SwingAngle > PI)
            SwingAngle -= 2.f * PI;

		return SwingAngle;
	}

	void ProgressSwingTime(float& SwingTime, float DeltaTime)
	{
		if (SwingSpeedCurve == nullptr)
		{
			SwingTime += DeltaTime;
			return;
		}

		float RemainingDeltaTime = DeltaTime;
		while (!FMath::IsNearlyZero(RemainingDeltaTime))
		{
			float SegmentTimeStart = FMath::FloorToFloat(SwingTime * 60.f) / 60.f;
			float SegmentTimeEnd = SegmentTimeStart + (1.f / 60.f);

			// Proceed to the next segment if we already reached the end
			// of this segment. Can happen with floating point math inaccuracy.
			if (FMath::IsNearlyEqual(SegmentTimeEnd, SwingTime))
			{
				SegmentTimeStart += (1.f / 60.f);
				SegmentTimeEnd += (1.f / 60.f);
			}

			float SegmentTimeRemaining = (SegmentTimeEnd - SwingTime);
			float SegmentStartAngle = GetSwingAngleFromSwingTime(SegmentTimeStart);
			float SegmentTimeSpeed = SwingSpeedCurve.GetFloatValue(FMath::Abs(SegmentStartAngle / Physics.MaximumSwingAngle));

			float ConsumeDeltaTime = FMath::Min(RemainingDeltaTime, SegmentTimeRemaining / SegmentTimeSpeed);

			SwingTime += ConsumeDeltaTime * SegmentTimeSpeed;
			RemainingDeltaTime -= ConsumeDeltaTime;
		}
	}

    void UpdateSwingPhysics(float DeltaTime)
    {
        float SwingSpeed = 1.f;
        if (IsInInitialLerp())
            SwingSpeed *= Physics.EntryAnimationSwingSpeedFactor;

		// The amount of actual delta time we add to the swinging time
		// is dependent on the swing speed curve, but we make it discrete
		// in order to keep it framerate independent and so it doesn't desync
		// in network.
		ProgressSwingTime(TotalSwingingTime, DeltaTime * SwingSpeed);
		CurrentSwingAngle = GetSwingAngleFromSwingTime(TotalSwingingTime);

        float PrevSwingAngle = CurrentSwingAngle;

        // Update our pendulum angle based on the time we've been swinging
        float GravityConstant = Player.GetActorGravity().Size();
        float PendulumConstant = FMath::Sqrt(GravityConstant / Physics.PendulumLength);
        float PendulumTime = PendulumConstant * TotalSwingingTime;
        CurrentSwingAngle = Physics.MaximumSwingAngle * FMath::Sin(PendulumTime);

        bIsInBackSwing = false;
        if (CurrentSwingAngle > 0 && PrevSwingAngle > CurrentSwingAngle)
            bIsInBackSwing = true;
        if (CurrentSwingAngle < 0 && PrevSwingAngle < CurrentSwingAngle)
            bIsInBackSwing = true;
        
        if (bIsInBackSwing)
            TimeInBackSwing += DeltaTime;
        else
            TimeInBackSwing = 0.f;
    }

    FTransform GetPlayerPositionAtAngle(float Angle)
    {
        FTransform AlignTransform = SwingPosition;

        // Apply rotation from swing
        if (Angle != 0.f)
        {
            FQuat RelativeRotation = FQuat(FVector::RightVector, Angle);
            FTransform SwingRotation(RelativeRotation);
            
            AlignTransform = SwingRotation * AlignTransform;
        }

        // Apply align bone offset
        AlignTransform = SwingPlayerOffset * AlignTransform;

        // Apply rotation from reverse swing
        if (bSwingingReversed)
        {
            FQuat ReverseRotation(SwingPosition.TransformVector(FVector::UpVector), PI);
            AlignTransform = FTransform(ReverseRotation) * AlignTransform;
        }

        return AlignTransform;
    }

    bool IsInInitialLerp()
    {
        return InitialLerpRemaining > 0.f;
    }

    void UpdatePlayerPosition(float DeltaTime)
    {
        FTransform TargetTransform = GetPlayerPositionAtAngle(CurrentSwingAngle);
        FVector TargetLocation = TargetTransform.Location;
        FQuat TargetRotation = TargetTransform.GetRotation();

        if (InitialLerpRemaining > 0.f)
        {
            float AlphaThisFrame = FMath::Clamp(DeltaTime / InitialLerpRemaining, 0.f, 1.f);

            FVector InitialLocation = PlayerInitialMeshPosition.Location;
            TargetLocation = FMath::Lerp(InitialLocation, TargetLocation, AlphaThisFrame);
            PlayerInitialMeshPosition.Location = TargetLocation;

            FQuat InitialRotation = PlayerInitialMeshPosition.GetRotation();
            TargetRotation = FQuat::Slerp(InitialRotation, TargetRotation, AlphaThisFrame);
            PlayerInitialMeshPosition.SetRotation(TargetRotation);

            InitialLerpRemaining -= DeltaTime;
            if (InitialLerpRemaining <= 0.f)
            {
				// Play effects just as the hammer touches the nail visually. (could perhaps be moved to an animnotify?)
				WielderComp.OnHammerSwingStarted.Broadcast();
                InitialLerpRemaining = 0.f;
            }
        }

        Player.MeshOffsetComponent.OffsetWithTime(TargetLocation, TargetRotation.Rotator(), 0.f, 0.f);

		FTransform PlayerTransform = GetPlayerPositionAtAngle(0.f);
		if (!Player.GetActorLocation().Equals(PlayerTransform.Location))
		{
			FHitResult Result;
			Player.SetActorLocationAndRotation(PlayerTransform.Location, Player.GetActorRotation(), false, Result, false);
		}
    }

    void UpdateSwingAnimation(float DeltaTime)
    {
        bool bWouldBeIdle = CurrentSwingAngle < 0.1f;
        if (bWouldBeIdle)
            IdleTimer += DeltaTime;
        else
            IdleTimer = 0.f;

        bool bUseIdleSwing = IdleTimer > 2.f;
        if (bUseIdleSwing != bInIdleSwing)
        {
            bInIdleSwing = bUseIdleSwing;
            if (bUseIdleSwing)
            {
                // Start the idle MH
                Player.PlaySlotAnimation(
                    Animation = MHAnimation,
                    bLoop = true
                );

                Player.StopBlendSpace();
            }
            else
            {
                // Start the blend space for swining, we will control it from tick
                Player.StopAnimation();
                Player.PlayBlendSpace(SwingBlendSpace);
            }
        }

        if (!bUseIdleSwing)
        {
            float SwingDirection = FMath::Clamp(CurrentSwingAngle / (0.5f * PI), -1.f, 1.f);
            if (bSwingingReversed)
                SwingDirection *= -1.f;
            Player.SetBlendSpaceValues(SwingDirection * -10.f);

			// Propagate out switch swing direction events for audio and visual effects.
			const float DeltaSwingDirection = SwingDirection - PrevSwingDirection;
			if(FMath::Sign(DeltaSwingDirection) != FMath::Sign(PrevDeltaSwingDirection))
				WielderComp.OnHammerSwingSwitchedDirection.Broadcast();
			PrevSwingDirection = SwingDirection;
			PrevDeltaSwingDirection = DeltaSwingDirection;
        }
    }

    FVector GetTangentAtAngle(float Angle)
    {
        // We can probably calculate this tangent exactly using math,
        // but I can't be bothered, so I'm just going to do it numerically.

        FTransform Rotation1 = FTransform(FQuat(FVector::RightVector, Angle - 0.01f));
        FTransform Rotation2 = FTransform(FQuat(FVector::RightVector, Angle + 0.01f));

        FVector Position1 = (Rotation1 * SwingPosition).TransformPosition(FVector(0.f, 0.f, Physics.PendulumLength));
        FVector Position2 = (Rotation2 * SwingPosition).TransformPosition(FVector(0.f, 0.f, Physics.PendulumLength));
        FVector Direction = Position2 - Position1;
        return Direction.GetSafeNormal();
    }

    bool IsGoingForwards()
    {
        // We assume that we always jump off in the angle that we're facing,
        // rather than the angle that our velocity is in.
        return CurrentSwingAngle > 0;
    }

    bool ComputeAutoAim(FVector InitialAngle, float InitialSpeed, FVector& OutAngle)
    {
        TArray<ASwingBarActor> SwingBars;
		GetAllActorsOfClass(SwingBars);

        ASwingBarActor AutoAimTarget = nullptr;
        FVector AutoAimAngle;
        FVector AutoAimLocation;
        float AutoAimDistanceWeight = -1.f;

        FVector TargetAngle = InitialAngle.GetSafeNormal(); 

        //FVector SwingLocation = SwingBar.GetSwingTransform().GetLocation();
        FVector SwingLocation = Player.ActorLocation;
        float MaxDistSQ = FMath::Square(Physics.JumpOffAutoAimMaxDistance);
        for (ASwingBarActor OtherSwing : SwingBars)
        {
            if (OtherSwing == SwingBar)
                continue;

            FVector OtherLocation = OtherSwing.GetSwingTransform().GetLocation();
            float OtherDistSQ = OtherLocation.DistSquared(SwingLocation);

            // Ignore swings that are too far away
            if (OtherDistSQ > MaxDistSQ)
                continue;

            // Need to take into account gravity and bend upwards
            //   Note: this isn't physically accurate, since
            //   bending will increase jump duration. I'm going
            //   to assume air control force will compensate sufficiently.
            float OtherDist = FMath::Sqrt(OtherDistSQ);
            float JumpDuration = OtherDist / InitialSpeed;
            float GravityHeightLoss = 0.5f * Player.GetActorGravity().Size() * FMath::Square(JumpDuration);

			FVector AimLocation;
			AimLocation = SwingLocation + Math::ConstrainVectorToPlane((OtherLocation - SwingLocation), SwingPosition.Rotation.RightVector);
            AimLocation += FVector(0.f, 0.f, GravityHeightLoss);

            FVector AimAngle = (AimLocation - SwingLocation).GetSafeNormal();
            FQuat NeedRotation = FQuat::FindBetweenNormals(TargetAngle, AimAngle);

            FVector Axis;
            float NeedAngle = 0.f;
            NeedRotation.ToAxisAndAngle(Axis, NeedAngle);

            // Ignore swings that need too much bend
            if (NeedAngle > Physics.JumpOffAutoAimMaxAngleBend)
                continue;

            // We should never be able to go 'backwards' compared to our swing velocity
            FVector LateralTangent = GetTangentAtAngle(0.f);
            bool bJumpingForwards = IsGoingForwards();
            if (bJumpingForwards)
                LateralTangent *= -1.f;

            float LateralDirection = LateralTangent.DotProduct(AimAngle);
            if (LateralDirection < 0.f)
                continue;

            // Weigh both the angle and the distance to see which is the closest nail,
            //  we count distance in height heavier than horizontal distance
            float DistanceWeight = FMath::Square(OtherDist + FMath::Abs(OtherLocation.Z - SwingLocation.Z) * 5.f);
            DistanceWeight = NeedAngle * (DistanceWeight / Physics.JumpOffAutoAimMaxDistance);
            if (AutoAimDistanceWeight > 0.f && DistanceWeight > AutoAimDistanceWeight)
                continue;

            // Calculate the actual angle we would auto-aim at
            AutoAimTarget = OtherSwing;
            AutoAimDistanceWeight = DistanceWeight;
            AutoAimAngle = FQuat(Axis, NeedAngle * Physics.JumpOffAutoAimPercentage) * TargetAngle;
            AutoAimLocation = AimLocation;
        }

        if (AutoAimTarget != nullptr)
        {
            if (IsDebugActive())
            {
                System::DrawDebugPoint(AutoAimTarget.ActorLocation, 50.f, FLinearColor::Yellow, 5.f);
                System::DrawDebugPoint(AutoAimLocation, 50.f, FLinearColor::Red, 5.f);
                System::DrawDebugLine(Player.ActorLocation, Player.ActorLocation + AutoAimAngle * 500.f, FLinearColor::Red, 5.f, 5.f);
                System::DrawDebugLine(Player.ActorLocation, Player.ActorLocation + InitialAngle * 500.f, FLinearColor::Blue, 5.f, 5.f);
            }

            OutAngle = AutoAimAngle;
            return true;
        }

        return false;
    }

    /* -- Overrides for blueprint to trigger visual stuff -- */

    UFUNCTION(BlueprintEvent, Meta = (DisplayName = "On Swing Enter Blended In"))
    void BP_OnSwingEnterBlendedIn()
    {
    }

    UFUNCTION(BlueprintEvent, Meta = (DisplayName = "On Player Released From Swing Bar"))
    void BP_OnPlayerReleasedFromSwingBar()
    {
    }
};