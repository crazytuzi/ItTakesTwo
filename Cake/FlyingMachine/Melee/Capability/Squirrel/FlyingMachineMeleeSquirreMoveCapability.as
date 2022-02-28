
import Cake.FlyingMachine.Melee.Capability.FlyingMachineMeleeCapabilityBase;
import Cake.FlyingMachine.Melee.Component.FlyingMachineMeleeSquirrelComponent;
import Cake.FlyingMachine.Melee.LocomotionFeatures.LocomotionFeaturePlaneFight180Turn;
import Cake.FlyingMachine.Melee.LocomotionFeatures.LocomotionFeaturePlaneFightTaunt;

class UFlyingMachineMeleeSquirreMoveCapability : UFlyingMachineMeleeCapabilityBase
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MeleeTags::Melee);
	default CapabilityTags.Add(MeleeTags::MeleeSquirrelAi);

	default CapabilityDebugCategory = MeleeTags::Melee;

	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 191;

	/*  EDITABLE VARIABLES */
	const float JumpImpulse = 1600.f;
	const float ValidMoveInput = 0.7f;
	const float MinMoveDistanceForward = 250.f;
	/* */

	AHazeCharacter Squirrel = nullptr;
	UFlyingMachineMeleeSquirrelComponent SquirrelMeleeComponent;

	FHazeMeleeTarget PlayerTarget;
	bool bHasTarget = false;
	float TimeToChangeDir = 0.f;
	float CurrentDir = 1.f;
	bool bIsJumping = false;

	bool bIsGoingDown = false;
	float LastRelativeHeight = 0;
	float JumpMoveSpeed = 0;

	FMovementCharacterJumpHybridData VerticalTranslation;
	float BlockJumpTime = 0;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Squirrel = Cast<AHazeCharacter>(Owner);
		SquirrelMeleeComponent = Cast<UFlyingMachineMeleeSquirrelComponent>(MeleeComponent);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		bHasTarget = MeleeComponent.GetCurrentTarget(PlayerTarget);
		BlockJumpTime = FMath::Max(BlockJumpTime - DeltaTime, 0.f);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!SquirrelMeleeComponent.bUseAi)
			return EHazeNetworkActivation::DontActivate;

		if(!IsStateActive(EHazeMeleeStateType::None))
			return EHazeNetworkActivation::DontActivate;

		if(!bHasTarget)
			return EHazeNetworkActivation::DontActivate;

		const float MaxStandingStillTime = SquirrelMeleeComponent.CurrentAiSetting.MaxStandingStillTime;
		if(MaxStandingStillTime < 0)
			return EHazeNetworkActivation::DontActivate;

		if(SquirrelMeleeComponent.IdleTime < MaxStandingStillTime)
			return EHazeNetworkActivation::DontActivate;

		if(PlayerTarget.Distance.X < MinMoveDistanceForward)
			return EHazeNetworkActivation::DontActivate;
		
		return EHazeNetworkActivation::ActivateUsingCrumb;
	}


	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{	
		if(!SquirrelMeleeComponent.bUseAi)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(!IsStateActive(EHazeMeleeStateType::None))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(!bHasTarget)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
	
		if(bIsJumping)
		{
			if((MeleeComponent.IsGrounded() && ActiveDuration > 0.5f)
				|| GetStateMovementType() != EHazeMeleeMovementType::Jumping)
			{
				return EHazeNetworkDeactivation::DeactivateUsingCrumb;
			}		
		}
		else
		{
			if(PlayerTarget.Distance.X < MinMoveDistanceForward)
				return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		}

 		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		if(PlayerTarget.Distance.X > MinMoveDistanceForward + 200.f && BlockJumpTime <= 0.f)
		{
			if(FMath::RandBool())
				ActivationParams.AddActionState(n"Jump");
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		bIsJumping = ActivationParams.GetActionState(n"Jump");
		CurrentDir = PlayerTarget.bIsToTheRightOfMe ? 1.f : -1.f;

		if(bIsJumping)
		{
			SetStateMovementType(EHazeMeleeMovementType::Jumping);
			VerticalTranslation.StartJump(JumpImpulse);

			const float DistanceAlpha = FMath::Min(PlayerTarget.Distance.X / 1000.f, 1.f);
			JumpMoveSpeed = FMath::Lerp(300.f, 500.f, DistanceAlpha);
			JumpMoveSpeed += FMath::RandRange(0.f, 50.f);	
		}
		else
		{
			SetStateMovementType(EHazeMeleeMovementType::Walking);	
			TimeToChangeDir = 1.f;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if(GetStateMovementType() == EHazeMeleeMovementType::Jumping
			&& DeactivationParams.DeactivationReason == ECapabilityStatusChangeReason::Natural)
		{
			SquirrelMeleeComponent.BlockAiTimeLeft = 0.3f;
			BlockJumpTime = 1.f;
		}
		
		SetStateMovementType(EHazeMeleeMovementType::Idling);
		SquirrelMeleeComponent.IdleTime = 0;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
		{
			if(bIsJumping)
			{
				MeleeComponent.OverrideAnimationRequest = n"Jump";

				FHazeMelee2DSpineData Spline;
				MeleeComponent.GetSplineData(Spline);
				bIsGoingDown = Spline.SplinePosition.Y < LastRelativeHeight;
				LastRelativeHeight = Spline.SplinePosition.Y;

				FVector JumpMoveAmount = VerticalTranslation.CalculateJumpVelocity(
				DeltaTime, 
				true, 
				SquirrelMeleeComponent.MaxFallSpeed, 
				SquirrelMeleeComponent.GravityAmount, 
				Spline.WorldUp);

				FVector2D MoveAmount;
				MoveAmount.Y = JumpMoveAmount.DotProduct(Spline.WorldUp);
				MoveAmount.X = JumpMoveSpeed * CurrentDir;

				MoveAmount *= DeltaTime;
				MeleeComponent.AddDeltaMovement(n"Jump", MoveAmount.X, MoveAmount.Y);
			}
			else
			{
				float MoveAmount = 220.f * DeltaTime * CurrentDir;
				SquirrelMeleeComponent.AddDeltaMovement(n"MoveCapabilty", MoveAmount, 0.f);

				TimeToChangeDir -= DeltaTime;
				if(TimeToChangeDir <= 0)
				{
					const float ForwardDir = PlayerTarget.bIsToTheRightOfMe ? 1.f : -1.f;
					CurrentDir = -CurrentDir;
					if((CurrentDir > 0 && ForwardDir > 0) || (CurrentDir < 0 && ForwardDir < 0))
						TimeToChangeDir = FMath::RandRange(0.75f, 1.5f);
					else
						TimeToChangeDir = FMath::RandRange(0.3f, 0.9f);
					
				}
			}
		}
		else
		{
			if(bIsJumping)
			{
				MeleeComponent.OverrideAnimationRequest = n"Jump";
			}
		}	
	}

	UFUNCTION(BlueprintOverride)
	FString GetDebugString()
	{
		FString Str = "";
		return Str;
	}
}
