import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.Swinging.SwingComponent;
import Vino.Movement.Jump.AirJumpsComponent;
import Vino.Camera.Capabilities.CameraTags;

class USwingDetachCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementAction);
	default CapabilityTags.Add(MovementSystemTags::Swinging);
	default CapabilityTags.Add(n"SwingingDetach");

	default CapabilityDebugCategory = n"Movement Swinging";

	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 174;

	AHazePlayerCharacter OwningPlayer;
	USwingingComponent SwingingComponent;
	UHazeMovementComponent MoveComp;
	UCharacterAirJumpsComponent AirJumpsComp;
	UHazeAkComponent HazeAKComp;

	float GravityLerpTime = 0.4f;
	float GravityStartValue = 0.0f;
	// Will be updated to the correct value on activation
	float GravityEndValue = 6.f;

	float VelocityTimeMin = 0.25f;
	float VelocityTimeMax = 0.35f;

	const float JumpCooldown = 1.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		OwningPlayer = Cast<AHazePlayerCharacter>(Owner);
		SwingingComponent = USwingingComponent::GetOrCreate(Owner);
		MoveComp = UHazeMovementComponent::GetOrCreate(Owner);
		AirJumpsComp = UCharacterAirJumpsComponent::GetOrCreate(Owner);

		HazeAKComp = UHazeAkComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!SwingingComponent.IsSwinging())
			return EHazeNetworkActivation::DontActivate;

		if(SwingingComponent.ActiveSwingPoint == nullptr)
			return EHazeNetworkActivation::ActivateUsingCrumb;

		if (IsActioning(n"ForceSwingDetach"))
			return EHazeNetworkActivation::ActivateUsingCrumb;

		if (!SwingingComponent.ActiveSwingPoint.bEnabled)
			return EHazeNetworkActivation::ActivateUsingCrumb;

		if (MoveComp.IsGrounded())
			return EHazeNetworkActivation::ActivateUsingCrumb;

  		if (WasActionStarted(ActionNames::SwingJump) && (ActiveDuration + DeactiveDuration) >= JumpCooldown)
			return EHazeNetworkActivation::ActivateUsingCrumb;
		  
		if (WasActionStarted(ActionNames::SwingDetach))
			return EHazeNetworkActivation::ActivateUsingCrumb;

		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (SwingingComponent.ActiveSwingPoint != nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (ActiveDuration >= GravityLerpTime)
			return EHazeNetworkDeactivation::DeactivateLocal;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		if (WasActionStarted(ActionNames::SwingJump))
			SetExitVelocity(true);
		else
			SetExitVelocity(false);

		ConsumeAction(ActionNames::MovementGroundPound);

		if (SwingingComponent.SwingRope != nullptr)
			SwingingComponent.SwingRope.DetachFromSwingPoint();

		MoveComp.SetAnimationToBeRequested(n"SwingJump");
		UMovementSettings MoveSettings = UMovementSettings::GetSettings(OwningPlayer);
		GravityEndValue = MoveSettings.GravityMultiplier;

		AirJumpsComp.ResetJumpAndDash();

		if (SwingingComponent.ActiveSwingPoint != nullptr)
		{
			// Play Sounds
			if (SwingingComponent.EffectsData.SwingPointDetach != nullptr)
				UHazeAkComponent::HazePostEventFireForget(SwingingComponent.EffectsData.SwingPointDetach, SwingingComponent.ActiveSwingPoint.WorldTransform);

			OwningPlayer.ConsumeButtonInputsRelatedTo(ActionNames::MovementJump);		
		}
		else
		{
			// Play a special detach sound when point disabled?
		}

		if (SwingingComponent.IsSwinging())
			SwingingComponent.StopSwinging();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		UMovementSettings::ClearGravityMultiplier(OwningPlayer, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		float Alpha = 0.f;

		if (ActiveDuration == 0)
			Alpha = 0.f;
		else
			Alpha =  ActiveDuration / GravityLerpTime;

		float NewGravityValue = FMath::Lerp(GravityStartValue, GravityEndValue, Alpha);		
		UMovementSettings::SetGravityMultiplier(OwningPlayer, NewGravityValue, this);
	}
	
	void SetExitVelocity(bool bJump)
	{
		if (SwingingComponent.ActiveSwingPoint == nullptr)
			return;

		OwningPlayer.SetAnimBoolParam(n"SwingDetachJump", bJump);
			
		FSwingJumpOffSettings Settings = bJump ? SwingingComponent.ActiveSwingPoint.DetachSettings.Jump : SwingingComponent.ActiveSwingPoint.DetachSettings.Cancel;
		Settings.MinSpeed = FMath::Min(Settings.MinSpeed, Settings.MaxSpeed);
		Settings.MinAngle = FMath::Min(Settings.MinAngle, Settings.MaxAngle);

		// Jump off direction
		//FVector VelocityWithoutInherited = MoveComp.Velocity - SwingingComponent.InheritedVelocity;

		FVector JumpOffDirection = MoveComp.Velocity.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();
		FVector MoveInput = GetAttributeVector(AttributeVectorNames::MovementDirection);

		// Jump off angle
		float JumpOffAngle = JumpOffDirection.AngularDistance(MoveComp.Velocity) * RAD_TO_DEG;
		JumpOffAngle *= FMath::Sign(MoveComp.WorldUp.DotProduct(MoveComp.Velocity));
		JumpOffAngle = Settings.bClampAngle ? FMath::Clamp(JumpOffAngle, Settings.MinAngle, Settings.MaxAngle) : JumpOffAngle;

		// Jump off speed
		float JumpOffSpeed = Settings.bClampSpeed ? FMath::Clamp(MoveComp.Velocity.Size(), Settings.MinSpeed, Settings.MaxSpeed) : MoveComp.Velocity.Size();


		float VelocityInputAngleDifference = FMath::RadiansToDegrees(FMath::Acos(JumpOffDirection.DotProduct(MoveInput.GetSafeNormal())));
		if (bJump)
		{
			if ((!MoveInput.IsNearlyZero() && 
				FMath::IsNearlyEqual(SwingingComponent.GetSwingAnglePercentage(), 1.f, 0.1f) ||  VelocityInputAngleDifference < 30.f))
			{
				// If the player is giving input, and you are close to peak swing or your velocity  and input angle different is low enough
				/*
					If you are giving input, and your swing angle is close to peak or your velocity and input angle different is within range
					You should use your input direction as your jump off direction
				*/

				JumpOffDirection = MoveInput.GetSafeNormal();				
			}
			else if (FMath::IsNearlyEqual(SwingingComponent.GetSwingAnglePercentage(), 1.f, 0.05f) && SwingingComponent.PlayerToSwingPoint.DotProduct(JumpOffDirection) >= 0.f)
			{
				/*
					If your swing angle is small, and you are going towards the swing point
					You should jump off in the other direction, to protect against late button presses where you would jump 'backwards' accidentally
				*/

				JumpOffDirection = -SwingingComponent.PlayerToSwingPoint.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();
			}
		}

		FVector JumpOffRight = MoveComp.WorldUp.CrossProduct(JumpOffDirection).GetSafeNormal();
		FQuat JumpOffAngleQuat = FQuat(JumpOffRight, -JumpOffAngle * DEG_TO_RAD);

		FVector JumpOffVelocity = JumpOffDirection;
		JumpOffVelocity = JumpOffAngleQuat * JumpOffVelocity;
		JumpOffVelocity *= JumpOffSpeed;

		// Legacy fix to ensure that people that used VelocityWithoutInherited did not break when I made these changes
		JumpOffVelocity = FMath::Lerp(MoveComp.Velocity, JumpOffVelocity, SwingingComponent.ActiveSwingPoint.JumpFixedVelocityScale);

		// If you detach very quickly, use your original velocity, not the new one
		float OriginalVelocityLerpAlpha = FMath::GetMappedRangeValueClamped(FVector2D(VelocityTimeMin, VelocityTimeMax), FVector2D(0.f, 1.f), SwingingComponent.SwingDuration);
		JumpOffVelocity = FMath::Lerp(MoveComp.Velocity, JumpOffVelocity, OriginalVelocityLerpAlpha);

		JumpOffVelocity += SwingingComponent.InheritedVelocity * Settings.InheritedVelocityScale;

		MoveComp.Velocity = JumpOffVelocity;
	}
}
