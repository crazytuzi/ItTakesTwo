
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.MovementSystemTags;
import Vino.PlayerHealth.PlayerHealthComponent;

class UBurstForceCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(FeatureName::BurstForce);
	default CapabilityDebugCategory = CapabilityTags::Movement;
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 50;

	default CapabilityDebugCategory = CapabilityTags::Movement;
	
	// Internal Variables
	UHazeBurstForceComponent BurstForceComponent;
	UHazeCrumbComponent CrumbComponent;
	FName CurrentForceType = NAME_None;
	
	FHazeBurstForceReturnData CurrentBurst;
	FVector ActivationVelocity = FVector::ZeroVector;
	bool bIsFirstFrame = true;
	
	TArray<FName> ForceTypes;
	bool bIsPlayingAnimation = false;
	float CurrentNetworkTimeDilationMultiplier = 1.f;
	float CurrentNetworkTimeDilationMultiplierLerpSpeed = 10.f;

	float MinEndTime = 0.f;
	UPlayerHealthComponent PlayerHealthComp = nullptr;  

	// Force Functions
	void AddForceTypes()
	{
		// Add the forces here...
		ForceTypes.Add(n"Default");
		ForceTypes.Add(n"WallImpactGrounded");
		ForceTypes.Add(n"WallImpactAir");
	}

	FVector CalculateActivationVelocity() const
	{
		const FVector TotalForce = BurstForceComponent.GetTotalBurstForce(CurrentBurst.Forces); 
		return TotalForce;
	}

	bool DeactivateIfGrounded()const
	{
		if(CurrentForceType == n"WallImpactGrounded")
		{
			return !bIsPlayingAnimation;
		}
		else
		{
			return true;
		}	
	}

	bool DeactivateIfFalling()const
	{
		if(CurrentForceType == n"WallImpactGrounded")
		{
			return !bIsPlayingAnimation;
		}
		else if(CurrentForceType == n"WallImpactAir")
		{
			return !bIsPlayingAnimation;
		}
		else
		{
			return true;
		}	
	}

	bool DeactivateFromHorizontalVelocitySpeed(const float CurrentSpeed)const
	{
		return false;
	}

	float GetTargetRotationSpeed()const
	{
		return 30.f;
	}

	UFUNCTION()
    void OnAnimationFinished()
    {
    	bIsPlayingAnimation = false;
    }

	// CapabilityFunctions
	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerHealthComp = UPlayerHealthComponent::Get(Owner); 
		Super::Setup(SetupParams);
		BurstForceComponent = UHazeBurstForceComponent::GetOrCreate(Owner);
		CrumbComponent = UHazeCrumbComponent::Get(Owner);
		OnAnimationFinished();
		AddForceTypes();
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(!IsActive() && !IsBlocked())
		{		 
			for(int i = 0; i < ForceTypes.Num(); ++i)
			{
				CurrentForceType = ForceTypes[i];
				if(BurstForceComponent.ConsumeForce(CurrentForceType, CurrentBurst))
					break;
				else
					CurrentForceType = NAME_None;
			}

			if(CurrentForceType != NAME_None)
			{
				// We only activate forces that is significant
				ActivationVelocity = CalculateActivationVelocity();
				if(ActivationVelocity.IsNearlyZero(10.f))
				{
					CurrentForceType = NAME_None;
				}
			}
		}

		if ((PlayerHealthComp != nullptr) && PlayerHealthComp.bIsDead && IsBlocked())
		{
			// We dont want any remaining burst force to haunt us in our next life.
			BurstForceComponent.ClearAllForces();
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(CurrentForceType == NAME_None)
			return EHazeNetworkActivation::DontActivate;

		if(!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (Time::GetGameTimeSeconds() > MinEndTime)
		{
			if(MoveComp.IsGrounded() && DeactivateIfGrounded())
				return EHazeNetworkDeactivation::DeactivateLocal;

			const bool bIsFalling = MoveComp.Velocity.GetSafeNormal().DotProduct(MoveComp.WorldUp) <= 0;
			if(bIsFalling && DeactivateIfFalling())
				return EHazeNetworkDeactivation::DeactivateLocal;

			const FVector HorizontalVelocity = MoveComp.GetVelocity().ConstrainToPlane(MoveComp.WorldUp);
			if(DeactivateFromHorizontalVelocitySpeed(HorizontalVelocity.Size()))
				return EHazeNetworkDeactivation::DeactivateLocal;
		}

		return EHazeNetworkDeactivation::DontDeactivate;	
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{	
		if(HasControl())
			CharacterOwner.BlockMovementSyncronization(this);

		SetMutuallyExclusive(FeatureName::BurstForce, true);
		CharacterOwner.BlockCapabilities(CapabilityTags::CharacterFacing, this);
		MoveComp.SetVelocity(FVector::ZeroVector);

		FHazePlaySlotAnimationParams AnimToPlay;
		AnimToPlay.Animation = CurrentBurst.Feature.AnimationData.Sequence;
	 	
		if(AnimToPlay.Animation != nullptr)
		{
			FHazeAnimationDelegate BlendingOut;
			BlendingOut.BindUFunction(this, n"OnAnimationFinished");
			CharacterOwner.PlaySlotAnimation(FHazeAnimationDelegate(), BlendingOut, AnimToPlay);
			bIsPlayingAnimation = true;
		}

		if(CurrentBurst.Feature.Effect != nullptr)
		{
			Niagara::SpawnSystemAtLocation(CurrentBurst.Feature.Effect, MoveComp.OwnerLocation);
		}

		if(IsDebugActive())
		{
			System::DrawDebugArrow(CharacterOwner.GetActorCenterLocation(), CharacterOwner.GetActorCenterLocation() + (ActivationVelocity), Duration = 3.f);
		}

		FVector DebugDirection = CharacterOwner.GetActorForwardVector();
		MoveComp.SetVelocity(ActivationVelocity);
		if(!CurrentBurst.TargetFacingDirection.IsNearlyZero())
		{
			MoveComp.SetTargetFacingDirection(CurrentBurst.TargetFacingDirection, GetTargetRotationSpeed());
			DebugDirection = CurrentBurst.TargetFacingDirection;
		}
		else
		{
			MoveComp.SetTargetFacingRotation(CharacterOwner.GetActorQuat(), GetTargetRotationSpeed());
		}	

		if(IsDebugActive())
		{
			FVector DebugLocation = CharacterOwner.GetActorCenterLocation();
			System::DrawDebugArrow(DebugLocation, DebugLocation + (DebugDirection * 500.f), LineColor = FLinearColor::Red, Duration = 5.f);
		}

		if(!HasControl())
		{
			CurrentNetworkTimeDilationMultiplier = 0.25f;
			CurrentNetworkTimeDilationMultiplierLerpSpeed = FMath::Max(5.f - (CrumbComp.GetPredictionLag() * 2), 0.1f); 
		}
		
		MinEndTime = Time::GetGameTimeSeconds() + CurrentBurst.Feature.MinDuration;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if(HasControl())
			CharacterOwner.UnblockMovementSyncronization(this);

		bIsFirstFrame = true;
		SetMutuallyExclusive(FeatureName::BurstForce, false);
		CharacterOwner.UnblockCapabilities(CapabilityTags::CharacterFacing, this);
		if(bIsPlayingAnimation)
		{
			CharacterOwner.StopAnimation();
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeFrameMovement Movement = MoveComp.MakeFrameMovement(n"BurstForce");

		if(bIsFirstFrame)
		{
			bIsFirstFrame = false;
		}
		else
		{
			if(MoveComp.IsGrounded() && (CurrentBurst.Feature.GroundFriction > 0.f))
			{	
				const FVector TargetVelocity = FMath::VInterpConstantTo(MoveComp.GetVelocity(), FVector::ZeroVector, DeltaTime, CurrentBurst.Feature.GroundFriction);
				MoveComp.SetVelocity(TargetVelocity);
			}
		}

		Movement.ApplyActorHorizontalVelocity();
		Movement.ApplyActorVerticalVelocity();
		Movement.ApplyGravityAcceleration();
		Movement.ApplyTargetRotationDelta();

		if(Movement.Velocity.GetSafeNormal().DotProduct(MoveComp.WorldUp) <= 0)
		{
			Movement.FlagToMoveWithDownImpact();
		}
		else
		{
			Movement.OverrideStepUpHeight(0.f);
			Movement.OverrideStepDownHeight(0.f);
			Movement.OverrideGroundedState(EHazeGroundedState::Airborne);
		}

		MoveCharacter(Movement, FeatureName::AirMovement);
		CurrentBurst.FadeOutTimer.Update(DeltaTime);

		if(CrumbComponent != nullptr)
		{
			if(!HasControl() && CurrentNetworkTimeDilationMultiplier < 1.f)
			{
				CrumbComponent.SetFrameNetworkDeltaTimeModifier(CurrentNetworkTimeDilationMultiplier);
				CurrentNetworkTimeDilationMultiplier = FMath::FInterpConstantTo(CurrentNetworkTimeDilationMultiplier, 1.f, DeltaTime, CurrentNetworkTimeDilationMultiplierLerpSpeed);
			}
		}
	
		
	}
}
