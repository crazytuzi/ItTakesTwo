import Cake.FlyingMachine.Melee.Capability.FlyingMachineMeleeCapabilityBase;
import Cake.FlyingMachine.Melee.Component.FlyingMachineMeleePlayerComponent;

class UFlyingMachineMeleePlayerJumpCapability : UFlyingMachineMeleeCapabilityBase
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MeleeTags::Melee);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(MeleeTags::MeleeBlockedWhenGrabbed);

	default TickGroupOrder = 90;
	default TickGroup = ECapabilityTickGroups::LastMovement;

	AHazePlayerCharacter Player;
	UFlyingMachineMeleePlayerComponent PlayerMeleeComponent;
	FMovementCharacterJumpHybridData VerticalTranslation;

	/*  EDITABLE VARIABLES */
	const float JumpImpulse = 1600.f;
	const float ValidMoveInput = 0.7f;
	/* */

	float InAirTimer = 0;
	bool bIsHolding = false;

	//float ActiveCooldown = 0;
	bool bIsGoingDown = false;
	float LastRelativeHeight = 0;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerMeleeComponent = Cast<UFlyingMachineMeleePlayerComponent>(MeleeComponent);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;

		if(MeleeComponent.GetActionType() != EHazeMeleeActionInputType::None)
			return EHazeNetworkActivation::DontActivate;

		if(!WasActionStartedDuringTime(ActionNames::MovementJump, 0.2f))
			return EHazeNetworkActivation::DontActivate;
		
		if(!MeleeComponent.IsGrounded())
			return EHazeNetworkActivation::DontActivate;
		
		if(PlayerMeleeComponent.JumpIsBlocked())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{	
		if(GetStateMovementType() != EHazeMeleeMovementType::Jumping)
		{
			if(HasControl())
				return EHazeNetworkDeactivation::DeactivateUsingCrumb;
			else
				return EHazeNetworkDeactivation::DeactivateLocal;
		}
		
		if(MeleeComponent.IsGrounded())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
				
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		SetStateMovementType(EHazeMeleeMovementType::Jumping);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{	
		MeleeComponent.ClearTranslationData();
		if(HasControl())
		{
			bIsHolding = true;
			VerticalTranslation.StartJump(JumpImpulse);
			LastRelativeHeight = 0;
			bIsGoingDown = false;
		}
		else
		{
			SetStateMovementType(EHazeMeleeMovementType::Jumping);
		}	
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{					
		if(GetStateMovementType() == EHazeMeleeMovementType::Jumping)
			SetStateMovementType(EHazeMeleeMovementType::Idling);		
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
		{
			FHazeMelee2DSpineData Spline;
			MeleeComponent.GetSplineData(Spline);
			bIsGoingDown = Spline.SplinePosition.Y < LastRelativeHeight;
			LastRelativeHeight = Spline.SplinePosition.Y;

			FVector JumpMoveAmount = VerticalTranslation.CalculateJumpVelocity(
				DeltaTime, 
				bIsHolding, 
				PlayerMeleeComponent.MaxFallSpeed, 
				PlayerMeleeComponent.GravityAmount, 
				Spline.WorldUp);

			FVector2D MoveAmount;
			MoveAmount.Y = JumpMoveAmount.DotProduct(Spline.WorldUp);

			MoveAmount *= DeltaTime;
			MeleeComponent.AddDeltaMovement(n"Jump", MoveAmount.X, MoveAmount.Y);

			//if(!bIsGoingDown)
			{
				FHazeMeleeTarget SquirrelTarget;
				if(MeleeComponent.GetCurrentTarget(SquirrelTarget))
				{
					if(SquirrelTarget.bIsToTheRightOfMe)
						FaceRight();
					else
						FaceLeft();
				}
			}

			// UPDATE JUMP INPUT
			if(bIsHolding)
			{
				if(!IsActioning(ActionNames::MovementJump))
				{
					bIsHolding = false;
				}
			}
		}

		MeleeComponent.OverrideAnimationRequest = n"Jump";
	}
}
