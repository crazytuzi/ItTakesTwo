import Vino.Movement.Helpers.MovementJumpHybridData;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Peanuts.Movement.NoWallCollisionSolver;
import Peanuts.Movement.DefaultCharacterCollisionSolver;
import Vino.Movement.MovementSystemTags;
import Vino.Movement.MovementSettings;
import Peanuts.Spline.SplineComponent;
import Vino.Movement.Capabilities.Sliding.SlidingNames;
import Vino.Movement.Capabilities.Sliding.SplineSlopeSlidingSettings;
import Vino.Movement.Capabilities.Sliding.CharacterSplineSlopeSlidingComponent;

class UCharacterSplineSlopeJumpCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(MovementSystemTags::Jump);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementInput);
	default CapabilityTags.Add(MovementSystemTags::SlopeSlide);
	default CapabilityTags.Add(MovementSystemTags::GroundMovement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(CapabilityTags::MovementAction);

	default CapabilityDebugCategory = CapabilityTags::Movement;

	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 125;

	FSplineSlopeSlidingSettings SlidingSettings;

	UCharacterSlopeSlideComponent SlideComp;
	
	// Internal Variables
	FMovementCharacterJumpHybridData JumpData;
	bool bIsHolding = false;
	float JumpTime = 0.f;
	float JumpHeight = 0.f;
	AHazePlayerCharacter Player;
	bool bStartedDecending = false;

	bool bHasAirJumped = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		Super::Setup(SetupParams);

		SlideComp = UCharacterSlopeSlideComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		if (SlideComp.GuideSpline == nullptr)
			return EHazeNetworkActivation::DontActivate;
		
		if(WasActionStarted(ActionNames::MovementJump))
			return EHazeNetworkActivation::ActivateUsingCrumb;

		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!HasControl())
			return EHazeNetworkDeactivation::DontDeactivate;

		if (SlideComp.GuideSpline == nullptr)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(!MoveComp.CanCalculateMovement())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
			
		if (!MoveComp.IsAirborne())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{	
		Owner.ApplySettings(SlopeSlidingTurnSettings, Instigator = this);
		
		MoveComp.SetAnimationToBeRequested(FeatureName::Jump);

		float CurrentHeight = Owner.GetActorTransform().InverseTransformVector(Owner.GetActorLocation()).Z;
		bStartedDecending = false;

		// Camera should not normally move vertically during jump
		if (!AllowCameraVerticalMovement(CurrentHeight))
			Player.ApplyPivotLagSpeed(FVector(0.5f, 0.5f, 0.f), this, EHazeCameraPriority::Low);
		Player.ApplyPivotLagMax(FVector(200.f, 200.f, 400.f), this, EHazeCameraPriority::Low);

		JumpHeight = CurrentHeight;
		JumpTime = Time::GetGameTimeSeconds();

		StartJump(false);
	}

	void StartJump(bool bIsSecondJump)
	{
		bIsHolding = true;
		StartJumpWithInheritedVelocity(JumpData, bIsSecondJump ? SlidingSettings.SecondJumpImpulse : SlidingSettings.JumpImpulse);

		bHasAirJumped = bIsSecondJump;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{	
		bHasAirJumped = false;

		Owner.ClearSettingsByInstigator(this);
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
			const FVector VerticalVelocity = JumpData.CalculateJumpVelocity(DeltaTime, bIsHolding, MoveComp);
			FrameMoveData.ApplyVelocity(VerticalVelocity);

			FVector Input = GetAttributeVector(AttributeVectorNames::MovementDirection);
			float MoveSpeed = MoveComp.HorizontalAirSpeed;

			FrameMoveData.ApplyVelocity(CalculateHorizontalVelocity(DeltaTime));
			FrameMoveData.ApplyAndConsumeImpulses();
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

	FVector CalculateHorizontalVelocity(float DeltaTime)
	{
		FVector ForwardDirection = FVector::ZeroVector;
		FVector RightVector = FVector::ZeroVector;
		SlideComp.GetCurrentDirectionAlongSpline(MoveComp, ForwardDirection, RightVector, false);

		FVector InputVector = GetAttributeVector(AttributeVectorNames::MovementDirection);
		FVector SideInput = InputVector.ConstrainToDirection(RightVector);
		
		FVector ForwardVelocity = ForwardDirection * SlideComp.CalculateSpeedInSplineDirection(MoveComp, ForwardDirection, InputVector, DeltaTime);
		FVector SideVelocity = SlideComp.CalculateSideVelocity(MoveComp, RightVector, SideInput, DeltaTime, IsDebugActive());
        
		return ForwardVelocity + SideVelocity;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!bIsHolding && !bHasAirJumped && WasActionStarted(ActionNames::MovementJump))
			StartJump(true);

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

			if(bStartedDecending)
			{
				RequestTag = FeatureName::AirMovement;
			}
			else if(HasControl())
			{
				RequestTag = FeatureName::Jump;
			}
			else 
			{
				if(ActiveDuration > 0.1f)
				{
					RequestTag = FeatureName::Jump;	
				}		
			}

			MoveCharacter(ThisFrameMove, RequestTag);
			CrumbComp.LeaveMovementCrumb();
		}	
	}
};
