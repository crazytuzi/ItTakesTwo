import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.Helpers.MovementJumpHybridData;
import Vino.Movement.Jump.AirJumpsComponent;
import Rice.Math.MathStatics;

class UCharacterIsSmallAirJumpCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementInput);
	default CapabilityTags.Add(CapabilityTags::MovementAction);
	default CapabilityTags.Add(MovementSystemTags::GroundMovement);
	default CapabilityTags.Add(MovementSystemTags::Jump);
	default CapabilityTags.Add(n"AirJump");

	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 135;
	default SeperateInactiveTick(ECapabilityTickGroups::ActionMovement, 105);

	default CapabilityDebugCategory = CapabilityTags::Movement;

	UPROPERTY()
	float JumpImpulse = 162.f;

	// Internal Variables
	FMovementCharacterJumpHybridData JumpData;
	float InAirTimer;
	bool bDashAndLedgeGrabBlocked = false;
	float JumpTime = 0.f;
	float JumpHeight = 0.f;
	bool bStartedDecending = false;

	AHazePlayerCharacter Player;
	UCharacterAirJumpsComponent AirJumpsComp;

	float SpeedDecelerationDuration = 0.2f;
	float Deceleration = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);

		Player = Cast<AHazePlayerCharacter>(Owner);
		AirJumpsComp = UCharacterAirJumpsComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (MoveComp.IsGrounded())
		{
			InAirTimer = 0.f;
		}
		else
			InAirTimer += DeltaTime;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;		

		if(!WasActionStarted(ActionNames::MovementJump))
			return EHazeNetworkActivation::DontActivate;

		if (MoveComp.IsGrounded())
			return EHazeNetworkActivation::DontActivate;
			
		// Don't trigger during the grounded grace period
		if(MoveComp.IsWithinJumpGroundedGracePeriod())
		return EHazeNetworkActivation::DontActivate;

		if (!AirJumpsComp.CanJump())
			return EHazeNetworkActivation::DontActivate;		

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!MoveComp.CanCalculateMovement())
			return EHazeNetworkDeactivation::DeactivateLocal;
			
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
		//CalculatePeakHeight();
	}

	void ActivateAirJump()
	{
		FName CurrentRequest = NAME_None;
		MoveComp.GetAnimationRequest(CurrentRequest);
		if(CurrentRequest == NAME_None)
		{
			MoveComp.SetAnimationToBeRequested(n"DoubleJump");
		}
		
		FVector HorizontalVelocity = MoveComp.Velocity.ConstrainToPlane(MoveComp.WorldUp);
		Deceleration = FMath::Abs((MoveComp.HorizontalAirSpeed - HorizontalVelocity.Size()) / SpeedDecelerationDuration);

		// Update velocity
		FVector MoveInput = GetAttributeVector(AttributeVectorNames::MovementDirection);
		if (MoveInput.IsNearlyZero())
			MoveComp.SetVelocity(Player.ActorForwardVector * FMath::Min(MoveComp.HorizontalAirSpeed, HorizontalVelocity.Size()));
		else
			MoveComp.SetVelocity(MoveInput * MoveComp.HorizontalAirSpeed);

		StartJumpWithInheritedVelocity(JumpData, JumpImpulse);

		float CurrentHeight = Owner.GetActorTransform().InverseTransformVector(Owner.GetActorLocation()).Z;

		// Camera should not normally move vertically during jump
		if (!AllowCameraVerticalMovement(CurrentHeight))
			Player.ApplyPivotLagSpeed(FVector(0.5f, 0.5f, 0.36f), this, EHazeCameraPriority::Low);

		Player.ApplyPivotLagMax(FVector(200.f, 200.f, 800.f), this, EHazeCameraPriority::Low);

		bDashAndLedgeGrabBlocked = true;

		bStartedDecending = false;
		JumpHeight = CurrentHeight;
		JumpTime = Time::GetGameTimeSeconds();
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
		return true;

		// if (Time::GetGameTimeSince(JumpTime) > 2.f)
		// 	return false; 

		// FTransform OwnerTransform = Owner.GetActorTransform();
		// if (FMath::Abs(JumpHeight - CurrentHeight) < 100.f)
		// 	return false;

		// return true;
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
			VerticalVelocity = JumpData.CalculateJumpVelocity(DeltaTime, false, MoveComp.MaxFallSpeed, -MoveComp.GravityMagnitude * 0.55f, MoveComp.WorldUp);

			FVector Input = GetAttributeVector(AttributeVectorNames::MovementDirection);
			float MoveSpeed = MoveComp.HorizontalAirSpeed;
			// float MoveSpeed = 250.f;

			FVector HorizontalVelocity = MoveComp.Velocity.ConstrainToPlane(MoveComp.WorldUp);
			float CurrentMoveSpeed = HorizontalVelocity.Size();
			if (CurrentMoveSpeed > MoveSpeed)
			{
				CurrentMoveSpeed -= Deceleration * DeltaTime;

				if (CurrentMoveSpeed < MoveSpeed)
					CurrentMoveSpeed = MoveSpeed;

				MoveComp.Velocity = HorizontalVelocity.GetSafeNormal() * CurrentMoveSpeed;
			}

			FrameMoveData.ApplyDelta(GetHorizontalAirDeltaMovement(DeltaTime, Input, MoveSpeed));
			FrameMoveData.ApplyAndConsumeImpulses();
			FrameMoveData.ApplyVelocity(VerticalVelocity);
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
		if (WasActionStarted(ActionNames::MovementJump) && AirJumpsComp.ConsumeJump())
			ActivateAirJump();

		if(MoveComp.CanCalculateMovement())
		{
			// Finalize Movement
			FHazeFrameMovement ThisFrameMove = MoveComp.MakeFrameMovement(n"DoubleJump");
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

			if(IsDebugActive())
			{
				FVector PlayerLocation = Player.ActorLocation;
				FVector PreviousLocation = PlayerLocation - ThisFrameMove.MovementDelta;

				float SpeedAlpha = MoveComp.Velocity.ConstrainToDirection(MoveComp.WorldUp).Size() / MoveComp.MaxFallSpeed;

				TArray<FLinearColor> Colors;
				Colors.Add(FLinearColor::Red);
				Colors.Add(FLinearColor::Yellow);
				Colors.Add(FLinearColor::Green);
				FLinearColor Color = LerpColors(Colors, SpeedAlpha);

				System::DrawDebugLine(PreviousLocation, PlayerLocation, Color, 6.f, 3.f);
			}
		}
		
	}

	void CalculatePeakHeight()
	{
		// Not accurate - doesnt take into consideration variable gravity
		float MaxHeight = FMath::Square(JumpImpulse) / (2 * MoveComp.GravityMagnitude);
		System::DrawDebugPoint(Player.CapsuleComponent.WorldLocation + FVector(0.f, 0.f, Player.CapsuleComponent.CapsuleHalfHeight) + (MoveComp.WorldUp * MaxHeight), 5.f, FLinearColor::Red, 10.f);
	}
};
