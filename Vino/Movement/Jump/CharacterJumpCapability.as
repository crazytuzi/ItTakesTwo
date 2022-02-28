import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.Helpers.MovementJumpHybridData;
import Vino.Movement.Components.FloorJumpCallbackComponent;
import Vino.Movement.Jump.AirJumpsComponent;
import Vino.Movement.Jump.CharacterJumpBufferComponent;

class UCharacterJumpCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(MovementSystemTags::GroundMovement);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementInput);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(CapabilityTags::MovementAction);	
	default CapabilityTags.Add(MovementSystemTags::Jump);
	default CapabilityTags.Add(MovementSystemTags::FloorJump);

	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 149;

	default CapabilityDebugCategory = CapabilityTags::Movement;

	AHazePlayerCharacter Player;
	UCharacterJumpSettings JumpSettings;
	UCharacterAirJumpsComponent AirJumpsComp;
	UCharacterJumpBufferComponent JumpBufferComp;
	
	// Internal Variables
	FMovementCharacterJumpHybridData JumpData;
	bool bDashAndLedgeGrabBlocked = false;
	bool bIsHolding = false;
	float JumpTime = 0.f;
	float JumpHeight = 0.f;
	bool bStartedDecending = false;
	bool bForceJump = false;

	float SpeedDecelerationDuration = 0.2f;
	float Deceleration = 0.f;

	float InheritedHorizontalSpeed = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		Player = Cast<AHazePlayerCharacter>(Owner);
		JumpSettings = UCharacterJumpSettings::GetSettings(Owner);
		AirJumpsComp = UCharacterAirJumpsComponent::GetOrCreate(Owner);
		JumpBufferComp = UCharacterJumpBufferComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		bForceJump = ConsumeAction(n"ForceJump") == EActionStateStatus::Active;	
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;

		if(!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		if(bForceJump)
			return EHazeNetworkActivation::ActivateUsingCrumb;
		
		if(!MoveComp.IsWithinJumpGroundedGracePeriod())
			return EHazeNetworkActivation::DontActivate;
		
		if(WasActionStarted(ActionNames::MovementJump))
			return EHazeNetworkActivation::ActivateUsingCrumb;

		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!MoveComp.CanCalculateMovement())
		{
			if(HasControl())
				return EHazeNetworkDeactivation::DeactivateUsingCrumb;
			else
				return EHazeNetworkDeactivation::DeactivateLocal;
		}
				
		if (!MoveComp.IsAirborne())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (MoveComp.UpHit.bBlockingHit)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		// If any impulses are applied, cancel the jump
		FVector Impulse = FVector::ZeroVector;
		MoveComp.GetAccumulatedImpulse(Impulse);
		if (!Impulse.IsNearlyZero())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		// Reached terminal velocity
		if (JumpData.GetSpeed() <= -MoveComp.MaxFallSpeed)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{	
		bIsHolding = true;
		FName CurrentRequest = NAME_None;
		MoveComp.GetAnimationRequest(CurrentRequest);

		// Calculate horizontal deceleration speed
		FVector HorizontalVelocity = MoveComp.Velocity.ConstrainToPlane(MoveComp.WorldUp);
		Deceleration = FMath::Abs((MoveComp.HorizontalAirSpeed - HorizontalVelocity.Size()) / SpeedDecelerationDuration);

		if(CurrentRequest == NAME_None || bForceJump == false)
			MoveComp.SetAnimationToBeRequested(FeatureName::Jump);

		if (MoveComp.DownHit.Component != nullptr && MoveComp.DownHit.Actor != nullptr)
		{
			UFloorJumpCallbackComponent FloorJumpCallbackComp = UFloorJumpCallbackComponent::Get(MoveComp.DownHit.Actor);
			if (FloorJumpCallbackComp != nullptr)
				FloorJumpCallbackComp.JumpFromActor(Player, MoveComp.DownHit.Component);
		}

		FVector InheritedVelocity = StartJumpWithInheritedVelocity(JumpData, MoveComp.JumpSettings.FloorJumpImpulse);
		InheritedHorizontalSpeed = InheritedVelocity.Size2D(MoveComp.WorldUp);

		float CurrentHeight = Owner.GetActorTransform().InverseTransformVector(Owner.GetActorLocation()).Z;

		//Camera should not normally move vertically during jump
		if (!AllowCameraVerticalMovement(CurrentHeight))
			Player.ApplyPivotLagSpeed(FVector(0.5f, 0.5f, 0.f), this, EHazeCameraPriority::Low);
		Player.ApplyPivotLagMax(FVector(200.f, 200.f, 400.f), this, EHazeCameraPriority::Low);

		//Player.BlockCapabilities(n"Dash", this);
		bDashAndLedgeGrabBlocked = true;

		bStartedDecending = false;
		JumpHeight = CurrentHeight;
		JumpTime = Time::GetGameTimeSeconds();
		
		AirJumpsComp.JumpActivationRealTime = Time::RealTimeSeconds;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{	
		Player.ClearCameraSettingsByInstigator(this);
	}

	bool AllowCameraVerticalMovement(float CurrentHeight)
	{
		// Allow it to move if this is a second jump within a short duration which moved us vertically. 
		// This avoid a glitch where camera moves a bit after landing but does not complete movement until after second landing.
		if (Time::GetGameTimeSince(JumpTime) > 2.f)
			return false; 

		FTransform OwnerTransform = Owner.GetActorTransform();
		if (FMath::Abs(JumpHeight - CurrentHeight) < 100.f)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void NotificationReceived(FName Notification, FCapabilityNotificationReceiveParams NotificationParams)
	{
		if(Notification == n"StartDecending")
		{
			bStartedDecending = true;
		}
	}

	void MakeFrameMovementData(FHazeFrameMovement& FrameMoveData, float DeltaTime)
	{
		if(HasControl())
		{	
			FVector VerticalVelocity = FVector::ZeroVector;
			VerticalVelocity = JumpData.CalculateJumpVelocity(DeltaTime, bIsHolding, MoveComp);

			FVector MoveInput = GetAttributeVector(AttributeVectorNames::MovementDirection);
			float MoveSpeed = MoveComp.HorizontalAirSpeed + InheritedHorizontalSpeed;

			FVector HorizontalVelocity = MoveComp.Velocity.ConstrainToPlane(MoveComp.WorldUp);
			float CurrentMoveSpeed = HorizontalVelocity.Size();
			if (CurrentMoveSpeed > MoveSpeed)
			{
				CurrentMoveSpeed -= Deceleration * DeltaTime;

				if (CurrentMoveSpeed < MoveSpeed)
					CurrentMoveSpeed = MoveSpeed;

				MoveComp.Velocity = HorizontalVelocity.GetSafeNormal() * CurrentMoveSpeed;
			}

			FrameMoveData.ApplyDelta(GetHorizontalAirDeltaMovement(DeltaTime, MoveInput, MoveSpeed));
			FrameMoveData.ApplyAndConsumeImpulses();
			FrameMoveData.ApplyVelocity(VerticalVelocity);
			FrameMoveData.FlagToMoveWithDownImpact();
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
	 		CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			FrameMoveData.ApplyConsumedCrumbData(ConsumedParams);		
		}

		FrameMoveData.OverrideStepUpHeight(0.f);
		FrameMoveData.OverrideStepDownHeight(0.f);
		FrameMoveData.ApplyTargetRotationDelta();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (WasActionStarted(ActionNames::MovementJump))
			JumpBufferComp.RegisterJump(AirJumpsComp.PostJumpDoubleJumpCooldown);

		if(MoveComp.CanCalculateMovement())
		{
			if(bIsHolding && !IsActioning(ActionNames::MovementJump))
			{
				bIsHolding = false;
			}

			// Finalize Movement
			FHazeFrameMovement ThisFrameMove = MoveComp.MakeFrameMovement(MovementSystemTags::Jump);
			MakeFrameMovementData(ThisFrameMove, DeltaTime);

			// Sign used to see if we're ascending or falling
			const int VertSign = FMath::Sign(JumpData.GetSpeed());
			FName RequestTag = NAME_None;
			if (!bStartedDecending && VertSign <= 0.f)
			{
				TriggerNotification(n"StartDecending");
			}			

			MoveCharacter(ThisFrameMove, FeatureName::Jump);
			CrumbComp.LeaveMovementCrumb();
		}	
	}
};