import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.Helpers.MovementJumpHybridData;
import Vino.Movement.Jump.AirJumpsComponent;
import Rice.Math.MathStatics;
import Cake.LevelSpecific.Music.NightClub.CharacterDiscoBallMovementComponent;

class UDiscoBallAirJumpCapability : UCharacterMovementCapability
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

	// Impulse when starting the jump (1320 default)
	UPROPERTY()
	float JumpImpulse = 1200.f;

	// Internal Variables
	FMovementCharacterJumpHybridData JumpData;
	float InAirTimer;
	bool bDashAndLedgeGrabBlocked = false;
	float JumpTime = 0.f;
	float JumpHeight = 0.f;
	bool bStartedDecending = false;

	AHazePlayerCharacter Player;
	UCharacterAirJumpsComponent AirJumpsComp;
	UCharacterDiscoBallMovementComponent DiscoComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);

		Player = Cast<AHazePlayerCharacter>(Owner);
		AirJumpsComp = UCharacterAirJumpsComponent::GetOrCreate(Owner);
		DiscoComp = UCharacterDiscoBallMovementComponent::Get(Owner);
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

		if(DiscoComp.DiscoBall == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(DiscoComp.DiscoBall.IsDiscoBallDestroyed())
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

		if(DiscoComp.DiscoBall == nullptr)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(DiscoComp.DiscoBall.IsDiscoBallDestroyed())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		// If any impulses are applied, cancel the jump
		// FVector Impulse = FVector::ZeroVector;
		// MoveComp.GetAccumulatedImpulse(Impulse);
		// if (!Impulse.IsNearlyZero())
		// 	return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		// // Reached terminal velocity
		// if (JumpData.GetSpeed() <= -MoveComp.MaxFallSpeed)
		// 	return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{	
		Player.BlockCapabilities(n"Cymbal", this);
		Player.BlockCapabilities(n"WeaponAim", this);
		Player.BlockCapabilities(n"SongOfLife", this);
		Player.BlockCapabilities(n"PowerfulSong", this);
	}

	void ActivateAirJump()
	{
		FName CurrentRequest = NAME_None;
		MoveComp.GetAnimationRequest(CurrentRequest);
		if(CurrentRequest == NAME_None)
		{
			MoveComp.SetAnimationToBeRequested(n"DoubleJump");
		}
			
		// Update velocity
		FVector MoveInput = GetAttributeVector(AttributeVectorNames::MovementDirection);
		FVector HorizontalVelocity = MoveComp.Velocity.ConstrainToPlane(MoveComp.WorldUp);
		if (MoveInput.IsNearlyZero())
			MoveComp.SetVelocity(Player.ActorForwardVector * FMath::Min(MoveComp.HorizontalAirSpeed, HorizontalVelocity.Size()));
		else
			MoveComp.SetVelocity(MoveInput * MoveComp.HorizontalAirSpeed);

		StartJumpWithInheritedVelocity(JumpData, JumpImpulse);

		float CurrentHeight = Owner.GetActorTransform().InverseTransformVector(Owner.GetActorLocation()).Z;

		// Camera should not normally move vertically during jump
		if (!AllowCameraVerticalMovement(CurrentHeight))
			Player.ApplyPivotLagSpeed(FVector(0.5f, 0.5f, 0.36f), this, EHazeCameraPriority::Script);

		Player.ApplyPivotLagMax(FVector(200.f, 200.f, 800.f), this, EHazeCameraPriority::Script);

		bDashAndLedgeGrabBlocked = true;

		bStartedDecending = false;
		JumpHeight = CurrentHeight;
		JumpTime = Time::GetGameTimeSeconds();
		//Player.BlockCapabilities(n"Cymbal", this);
		//Player.BlockCapabilities(n"PowerfulSong", this);
		//Player.BlockCapabilities(n"SongOfLife", this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{	
		Player.UnblockCapabilities(n"Cymbal", this);
		Player.UnblockCapabilities(n"WeaponAim", this);
		Player.UnblockCapabilities(n"SongOfLife", this);
		Player.UnblockCapabilities(n"PowerfulSong", this);

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
			VerticalVelocity = JumpData.CalculateJumpVelocity(DeltaTime, false, MoveComp);

			FVector Input = GetAttributeVector(AttributeVectorNames::MovementDirection);
			
			//Have tweaked this with dividing by 2, to slow down air control
			float MoveSpeed = MoveComp.HorizontalAirSpeed / 2.f;

			//This is what is changed from airjump capability:
			FrameMoveData.ApplyDelta(Input * MoveSpeed * DeltaTime);


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
		// This isn't networked, so will only be performed on control side! 
		// Known shippable unless Simon think we should fix. 
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
