
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Peanuts.Animation.Features.LocomotionFeatureKnockDown;
import Vino.Movement.Helpers.BurstForceStatics;
import Vino.Movement.AnimNotify.Knockdown.AnimNotify_KnockdownStop;
import Vino.PlayerHealth.PlayerRespawnComponent;

enum EKnockDownDirection
{
	Front,
	Back,
	Right,
	Left
}

EKnockDownDirection GetKnockDownDirection(float YawAngle)
{
	if (FMath::Abs(YawAngle) < 45.f) 
		return EKnockDownDirection::Back;
	else if (FMath::Abs(YawAngle) > 135.f) 
		return EKnockDownDirection::Front;
	else if (YawAngle > 0.f)
		return EKnockDownDirection::Left;
	return EKnockDownDirection::Right;
}

class UCharacterKnockDownCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(n"KnockDown");
	default CapabilityTags.Add(n"MovementAction");
	default CapabilityTags.Add(n"GameplayAction");
	default TickGroup = ECapabilityTickGroups::ActionMovement;

	FVector KnockDirection;
	FRotator AlignRotation;
	float HaltMomentumTime = 0;
	float MaxTime = BIG_NUMBER;
	bool bKnockdownComplete = false;

	UPROPERTY()
	float MinSlideDuration = 1.f;
	UPROPERTY()
	float GroundFriction = 0.f;
	UPROPERTY()
	float MaxDuration = 3.f;

	UFUNCTION(NotBlueprintCallable)
	void OnPlayerRespawn(AHazePlayerCharacter Player)
	{
		// Knockdown should never carry over from previous life
		if (IsActive())
			bKnockdownComplete = true;
		ConsumeAction(n"KnockDown"); 
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!IsActioning(n"KnockDown"))
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(bKnockdownComplete)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;	
	}

    UFUNCTION(BlueprintOverride)
	bool RemoteAllowShouldActivate(FCapabilityRemoteValidationParams ActivationParams) const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		ActivationParams.AddVector(n"KnockdownDirection", GetAttributeVector(n"KnockdownDirection"));
		ActivationParams.AddValue(n"KnockdownGroundFriction", GetAttributeValue(n"KnockdownGroundFriction"));
		ActivationParams.AddValue(n"KnockdownSlideDuration", GetAttributeValue(n"KnockdownSlideDuration"));
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		// Binding this in setup does not work
		UPlayerRespawnComponent RespawnComp = UPlayerRespawnComponent::Get(Owner);
		if (RespawnComp != nullptr)
		 	RespawnComp.OnRespawn.AddUFunction(this, n"OnPlayerRespawn");

        CharacterOwner.BlockCapabilities(n"MovementInput", this);
        CharacterOwner.BlockCapabilities(n"CharacterFacing", this);
        CharacterOwner.BlockCapabilitiesExcluding(n"GameplayAction", n"CanCancelKnockdown", this);

		// Reset in case something has set these values since last deactivation:
		bKnockdownComplete = false;
		HaltMomentumTime = 0;

		// Calculate in which direction you're getting knocked down
		KnockDirection = ActivationParams.GetVector(n"KnockdownDirection");
		
		FRotator LocalRot = (CharacterOwner.GetActorQuat().Inverse() * KnockDirection.ToOrientationQuat()).Rotator();
		CharacterOwner.Mesh.SetAnimFloatParam(n"KnockDownYawDirection", LocalRot.Yaw);
		EKnockDownDirection KnockSide = GetKnockDownDirection(LocalRot.Yaw);

		FVector InitialVel = KnockDirection;

		// This might not be what we want, investigate. For now we nuka all other forces when starting knockdown.
		MoveComp.SetVelocity(InitialVel);

		// Initial burst force without friction and set to last for a while
		AlignRotation = GetAlignRotation(KnockSide, KnockDirection); 

		GroundFriction = ActivationParams.GetValue(n"KnockdownGroundFriction");
		MinSlideDuration = ActivationParams.GetValue(n"KnockdownSlideDuration");

		// Hack, use slotanims for now, ABP is wonky
		StartSlotAnims(KnockSide);

		MaxTime = Time::GetGameTimeSeconds() + MaxDuration;
	}	

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
        CharacterOwner.UnblockCapabilities(n"CharacterFacing", this);
        CharacterOwner.UnblockCapabilities(n"MovementInput", this);
        CharacterOwner.UnblockCapabilities(n"GameplayAction", this);

		ConsumeAction(n"KnockDown"); 
		bKnockdownComplete = false;
		
		// Stop any knock down animations that are still playing
		CharacterOwner.StopAnimationByAsset(AnimStart);
		CharacterOwner.StopAnimationByAsset(AnimMH);
		CharacterOwner.StopAnimationByAsset(AnimLand);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Set knockdown every tick we want acceleration to continue. 
		// When no longer set we'll end knockdown as soon as possible.
		bool bAccelerate = (ConsumeAction(n"KnockDown") == EActionStateStatus::Active);

		// Feature ABP expects a feature request every tick
        FHazeRequestLocomotionData AnimationRequest;
		AnimationRequest.AnimationTag = n"KnockDown";
		AnimationRequest.SubAnimationTag = NAME_None;
		
		if ((HaltMomentumTime > 0.f) && (Time::GetGameTimeSeconds() > HaltMomentumTime))
		{
			MoveComp.SetVelocity(FVector::ZeroVector);
			HaltMomentumTime = 0.f;
		}

		if (Time::GameTimeSeconds > MaxTime)
		{
			// Exit without land animation. It's likely we're falling a very long distance or 
			// have gotten stuck on a bounce pad or something like that.
			OnLandAnimDone();	
		}
		else if (bCanLand)
		{
			if (!MoveComp.IsAirborne())
			{
				// The user might choose not to have a AnimLand (slopesliding for example)
				if(AnimLand == nullptr)
				{
					bCanLand = false;
					OnLandAnimDone();
				}
				else
				{
					FHazeAnimationDelegate AnimDoneEvent;
					AnimDoneEvent.BindUFunction(this, n"OnLandAnimDone");
					CharacterOwner.PlaySlotAnimation(Animation = AnimLand, BlendTime = 0.1f, OnBlendingOut = AnimDoneEvent);
					bCanLand = false;
					
					// Check when we should come to a full stop, set by anim notify
					TArray<float> StopTimes;
					AnimLand.GetAnimNotifyTriggerTimes(UAnimNotify_KnockdownStop::StaticClass(), StopTimes);
					if(StopTimes.Num() > 0)
					{
						HaltMomentumTime = Time::GetGameTimeSeconds() + StopTimes[0] - 0.1f;
					}
				}
			}
		}

		if (MoveComp.CanCalculateMovement())
		{
			FHazeFrameMovement Movement = MoveComp.MakeFrameMovement(n"CharacterKnockDown");

			if (HasControl())
			{
				if(ActiveDuration > 0.05f)
				{
					if (MoveComp.IsGrounded() && (GroundFriction > 0.f))
					{	
						const FVector TargetVelocity = FMath::VInterpConstantTo(MoveComp.GetVelocity(), FVector::ZeroVector, DeltaTime, GroundFriction);
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
				
				// Request Knockdown until bCanLand is true
				MoveCharacter(Movement, bCanLand ? FeatureName::AirMovement : AnimationRequest.AnimationTag);
				CrumbComp.LeaveMovementCrumb();
			}
			else
			{
				FHazeActorReplicationFinalized ConsumedParams;
				CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
				Movement.ApplyConsumedCrumbData(ConsumedParams);

				// Request Knockdown until bCanLand is true
				MoveCharacter(Movement, bCanLand ? FeatureName::AirMovement : AnimationRequest.AnimationTag);
			}
		}
	}

	FRotator GetAlignRotation(EKnockDownDirection KnockSide, FVector KnockDirection)
	{
		FRotator KnockRot = KnockDirection.Rotation();		
		if (KnockSide == EKnockDownDirection::Back) 
			return KnockRot;
		else if (KnockSide == EKnockDownDirection::Front) 
			return KnockRot + FRotator(0.f, 180.f, 0.f);
		else if (KnockSide == EKnockDownDirection::Left)
			return KnockRot + FRotator(0.f, -90.f, 0.f);
		return KnockRot + FRotator(0.f, 90.f, 0.f);
	}

	// Hack slotanims below
	UAnimSequence AnimStart, AnimMH, AnimLand;
	bool bCanLand = false;

	void StartSlotAnims(EKnockDownDirection Direction)
	{
		bCanLand = false;
		ULocomotionFeatureKnockDown AnimFeature = ULocomotionFeatureKnockDown::Get(CharacterOwner);
		if (AnimFeature == nullptr) 
		{
			// No animations, deactivate straight away
			// For this capability to work properly we must also have added the knockdown feature.
			OnLandAnimDone();	
			return;
		}

		if (Direction == EKnockDownDirection::Back) 
		{
			AnimStart = AnimFeature.KnockDown_Back_Start.Sequence;
			AnimMH = AnimFeature.KnockDown_Back_mh.Sequence;
			AnimLand = AnimFeature.KnockDown_Back_Land.Sequence;
		}
		else if (Direction == EKnockDownDirection::Front) 
		{
			AnimStart = AnimFeature.KnockDown_Front_Start.Sequence;
			AnimMH = AnimFeature.KnockDown_Front_mh.Sequence;
			AnimLand = AnimFeature.KnockDown_Front_Land.Sequence;
		}
		else if (Direction == EKnockDownDirection::Left)
		{
			AnimStart = AnimFeature.KnockDown_Left_Start.Sequence;
			AnimMH = AnimFeature.KnockDown_Left_mh.Sequence;
			AnimLand = AnimFeature.KnockDown_Left_Land.Sequence;
		}
		else
		{
			AnimStart = AnimFeature.KnockDown_Right_Start.Sequence;
			AnimMH = AnimFeature.KnockDown_Right_mh.Sequence;
			AnimLand = AnimFeature.KnockDown_Right_Land.Sequence;
		}
		FHazeAnimationDelegate AnimDoneEvent;
		AnimDoneEvent.BindUFunction(this, n"OnStartAnimDone");
        CharacterOwner.PlaySlotAnimation(Animation = AnimStart, BlendTime = 0.1f, OnBlendingOut = AnimDoneEvent);
	}

	UFUNCTION()
	void OnStartAnimDone()
	{
		CharacterOwner.PlaySlotAnimation(Animation = AnimMH, bLoop = true, BlendTime = 0.f);
		bCanLand = true;
	}

	UFUNCTION()
	void OnLandAnimDone()
	{
		bKnockdownComplete = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		UPlayerRespawnComponent RespawnComp = UPlayerRespawnComponent::Get(Owner);
		if (RespawnComp != nullptr)
			RespawnComp.OnRespawn.Unbind(this, n"OnPlayerRespawn");
	}
}
