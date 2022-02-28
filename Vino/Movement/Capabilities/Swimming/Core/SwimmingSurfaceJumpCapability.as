import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.Helpers.MovementJumpHybridData;
import Rice.Math.MathStatics;
import Vino.Movement.Capabilities.Swimming.SnowGlobeSwimmingComponent;

class USwimmingSurfaceJumpCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementInput);
	default CapabilityTags.Add(CapabilityTags::MovementAction);
	default CapabilityTags.Add(MovementSystemTags::Jump);

	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 20;
	default SeperateInactiveTick(ECapabilityTickGroups::ActionMovement, 10);

	default CapabilityDebugCategory = n"Movement Swimming";

	// Internal Variables
	FMovementCharacterJumpHybridData JumpData;
	float JumpHeight = 0.f;
	bool bStartedDecending = false;

	AHazePlayerCharacter Player;
	USnowGlobeSwimmingComponent SwimComp;
	UPlayerHazeAkComponent HazeAkComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);

		Player = Cast<AHazePlayerCharacter>(Owner);
		SwimComp = USnowGlobeSwimmingComponent::GetOrCreate(Owner);
		HazeAkComp = UPlayerHazeAkComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		if (SwimComp.SwimmingState != ESwimmingState::Surface)
			return EHazeNetworkActivation::DontActivate;

		if(!WasActionStarted(ActionNames::MovementJump))
			return EHazeNetworkActivation::DontActivate;	

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!MoveComp.CanCalculateMovement())
			return RemoteLocalControlCrumbDeactivation();
			
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
		SwimComp.SwimmingState = ESwimmingState::SurfaceJump;

		FName CurrentRequest = NAME_None;
		MoveComp.GetAnimationRequest(CurrentRequest);
		if(CurrentRequest == NAME_None)
		{
			MoveComp.SetAnimationToBeRequested(n"SwimmingJump");
		}
			
		// Update velocity
		FVector HorizontalVelocity = MoveComp.Velocity.ConstrainToPlane(MoveComp.WorldUp);	
		MoveComp.SetVelocity(MoveComp.Velocity.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal() * FMath::Min(MoveComp.HorizontalAirSpeed, HorizontalVelocity.Size()));

		StartJumpWithInheritedVelocity(JumpData, SwimmingSettings::Surface.JumpImpulse);

		float CurrentHeight = Owner.GetActorTransform().InverseTransformVector(Owner.GetActorLocation()).Z;

		// Camera should not normally move vertically during jump
		if (!AllowCameraVerticalMovement(CurrentHeight))
			Player.ApplyPivotLagSpeed(FVector(0.5f, 0.5f, 0.36f), this, EHazeCameraPriority::Script);

		Player.ApplyPivotLagMax(FVector(200.f, 200.f, 800.f), this, EHazeCameraPriority::Script);

		bStartedDecending = false;
		JumpHeight = CurrentHeight;

		if (SwimComp.AudioData[Player].SurfaceExitJump != nullptr)
			HazeAkComp.HazePostEvent(SwimComp.AudioData[Player].SurfaceExitJump);		

		SwimComp.CallOnSurfaceJump();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{	
		Player.ClearCameraSettingsByInstigator(this);
		
		if (SwimComp.SwimmingState == ESwimmingState::SurfaceJump)
			SwimComp.SwimmingState = ESwimmingState::Inactive;
	}

	bool AllowCameraVerticalMovement(float CurrentHeight)
	{
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
			VerticalVelocity = JumpData.CalculateJumpVelocity(DeltaTime, true, MoveComp);

			FVector Input = GetAttributeVector(AttributeVectorNames::MovementDirection);
			float MoveSpeed = MoveComp.HorizontalAirSpeed;

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
		// Finalize Movement
		FHazeFrameMovement ThisFrameMove = MoveComp.MakeFrameMovement(n"SwimmingJump");
		MakeFrameMovementData(ThisFrameMove, DeltaTime);			

		// Sign used to see if we're ascending or falling
		const int VertSign = FMath::Sign(JumpData.GetSpeed());
		FName RequestTag = NAME_None;
		if (!bStartedDecending && VertSign <= 0.f)
		{
			TriggerNotification(n"StartDecending");
		}

		MoveCharacter(ThisFrameMove, n"SwimmingJump");
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

	void CalculatePeakHeight()
	{
		// Not accurate - doesnt take into consideration variable gravity
		float MaxHeight = FMath::Square(MoveComp.JumpSettings.AirJumpImpulse) / (2 * MoveComp.GravityMagnitude);
		System::DrawDebugPoint(Player.CapsuleComponent.WorldLocation + FVector(0.f, 0.f, Player.CapsuleComponent.CapsuleHalfHeight) + (MoveComp.WorldUp * MaxHeight), 5.f, FLinearColor::Red, 10.f);
	}
};
