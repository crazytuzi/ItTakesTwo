import Vino.Movement.Components.MovementComponent;

import Vino.Movement.MovementSystemTags;
import Vino.Movement.Helpers.MovementJumpHybridData;

bool CheckIfTickGroupIsMovementTickGroup(ECapabilityTickGroups TickGroupToCheck)
{
    int TickGroupInt = TickGroupToCheck;
    int MinTickGroup = ECapabilityTickGroups::Input;
    int MaxTickGroup = ECapabilityTickGroups::GamePlay;
    return (TickGroupInt > MinTickGroup) && (TickGroupInt < MaxTickGroup);
}

UCLASS(Abstract)
class UCharacterMovementCapability : UHazeCapability
{
	default CapabilityDebugCategory = CapabilityTags::Movement;

    UPROPERTY(NotEditable)
	UHazeMovementComponent MoveComp;

	UPROPERTY(NotEditable)
    UHazeCrumbComponent CrumbComp;

	UPROPERTY(NotEditable)
	UMovementSettings ActiveMovementSettings = nullptr;

	AHazeCharacter CharacterOwner;
	FName DebugFinalizer = NAME_None;

	FQuat LastFrameRotation = FQuat::Identity;

    UFUNCTION(BlueprintEvent, NotBlueprintCallable)
    void OnActionCrumbPreRemoval(FName ActionName){}

    UFUNCTION(BlueprintOverride)
	bool RemoteAllowShouldActivate(FCapabilityRemoteValidationParams ActivationParams) const
	{
		return MoveComp.CanCalculateMovement();
	}

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		CharacterOwner = Cast<AHazeCharacter>(Owner);
        ensure(CharacterOwner != nullptr);
		MoveComp = UHazeMovementComponent::Get(Owner);
        CrumbComp = UHazeCrumbComponent::GetOrCreate(Owner);
		ActiveMovementSettings = UMovementSettings::GetSettings(Owner);
 		devEnsure(CheckIfTickGroupIsMovementTickGroup(TickGroup), "TickGroup is not set Correctly on " + Name +  ". all Movement capabilities has to be in a movement Tickgroup. If you are unsure what group to put your capability in you can ask Simon or Tyko.");
	}

    UFUNCTION()
    void MoveCharacter(const FHazeFrameMovement& MoveData, FName AnimationRequestTag, FName SubAnimationRequestTag = NAME_None)
    {
        if(AnimationRequestTag != NAME_None)
        {
            SendMovementAnimationRequest(MoveData, AnimationRequestTag, SubAnimationRequestTag);
        }
        MoveComp.Move(MoveData);
    }
    
    UFUNCTION()
    void SendMovementAnimationRequest(const FHazeFrameMovement& MoveData, FName AnimationRequestTag, FName SubAnimationRequestTag)
    {
		if(!CharacterOwner.Mesh.CanRequestLocomotion())
			return;

        FHazeRequestLocomotionData AnimationRequest;
 
        AnimationRequest.LocomotionAdjustment.DeltaTranslation = MoveData.MovementDelta;

		if (HasControl())
		{
			AnimationRequest.LocomotionAdjustment.DeltaRotation = MoveData.Rotation * Owner.ActorQuat.Inverse();
        	AnimationRequest.LocomotionAdjustment.WorldRotation = MoveData.Rotation;
			CharacterOwner.SetAnimVectorParam(n"RawInput",GetAttributeVector(AttributeVectorNames::MovementRaw));
		}
		else
		{
			// TODO (LV): Is this needed still? Seems weird to interp with a quat stored in the capability that 
			// isn't updated when the capability is first started. Why do we need this anyway?
			FQuat NewRotation = FMath::QInterpTo(LastFrameRotation, MoveData.Rotation, Owner.GetActorDeltaSeconds(), 10.f);
			AnimationRequest.LocomotionAdjustment.DeltaRotation = NewRotation * Owner.ActorQuat.Inverse();
			AnimationRequest.LocomotionAdjustment.WorldRotation = NewRotation;

			LastFrameRotation = NewRotation;
		}

 		AnimationRequest.WantedVelocity = MoveData.Velocity;
		AnimationRequest.WantedWorldTargetDirection = GetAttributeVector(AttributeVectorNames::MovementDirection);
        AnimationRequest.WantedWorldFacingRotation = MoveComp.GetTargetFacingRotation();
		AnimationRequest.MoveSpeed = MoveComp.MoveSpeed;
		
		if(!MoveComp.GetAnimationRequest(AnimationRequest.AnimationTag))
		{
			AnimationRequest.AnimationTag = AnimationRequestTag;
		}

        if (!MoveComp.GetSubAnimationRequest(AnimationRequest.SubAnimationTag))
        {
            AnimationRequest.SubAnimationTag = SubAnimationRequestTag;
        }

        CharacterOwner.RequestLocomotion(AnimationRequest);
    }

    UFUNCTION()
    FVector GetHorizontalAirDeltaMovement(float DeltaTime, FVector Input, float MoveSpeed)const
    {    
        const FVector ForwardVelocity = MoveComp.Velocity.ConstrainToPlane(MoveComp.WorldUp);
        const FVector InputVector = Input.ConstrainToPlane(MoveComp.WorldUp);
        if(!InputVector.IsNearlyZero())
        {
            const FVector CurrentForwardVelocityDir = ForwardVelocity.GetSafeNormal();
            const float CorrectInputAmount = (InputVector.DotProduct(CurrentForwardVelocityDir) + 1) * 0.5f;           
        
            const FVector WorstInputVelocity = InputVector * MoveSpeed;
            const FVector BestInputVelocity = InputVector * FMath::Max(MoveSpeed, ForwardVelocity.Size());

            const FVector TargetVelocity = FMath::Lerp(WorstInputVelocity, BestInputVelocity, CorrectInputAmount);
            return FMath::VInterpConstantTo(ForwardVelocity, TargetVelocity, DeltaTime, ActiveMovementSettings.AirControlLerpSpeed) * DeltaTime; 
        }
        else
        {
            return ForwardVelocity * DeltaTime;
        }          
    }

	// Returns the inheritedVelocity.
	UFUNCTION()
	FVector StartJumpWithInheritedVelocity(FMovementCharacterJumpHybridData& JumpData, float JumpImpulse)
	{
		FVector InheritedVelocity = MoveComp.GetInheritedVelocity(false);
		FVector HorizontalInherited = InheritedVelocity.ConstrainToPlane(MoveComp.WorldUp);
		float VerticalInherited = FMath::Max(InheritedVelocity.DotProduct(MoveComp.WorldUp), 0.f);

		MoveComp.OnJumpTrigger(HorizontalInherited, VerticalInherited);
		MoveComp.AddImpulse(HorizontalInherited);
		JumpData.StartJump(JumpImpulse + VerticalInherited);
		return InheritedVelocity;
	}

    protected bool ShouldBeGrounded() const
    {
		if(HasControl())
		{
			// This is to handle impulses on the ground that pushes the character up
			FVector Impulse = FVector::ZeroVector;
			MoveComp.GetAccumulatedImpulse(Impulse);
			if(Impulse.DotProduct(MoveComp.WorldUp) > 0.f && Impulse.ConstrainToDirection(MoveComp.WorldUp).Size() > ActiveMovementSettings.VerticalForceAirPushOffThreshold)
				return false;
		}

 		return !MoveComp.IsAirborne();
    }

	// Returns MovementDirection once it has been constrained to slope.
	// Will be the input length. Returns ActorForward if input is nearly zero
	FVector GetMoveDirectionOnSlope(FVector SlopeNormal)
    {
		FVector MoveDirection = GetAttributeVector(AttributeVectorNames::MovementDirection);

		// Protect against no input
		if(MoveDirection.IsNearlyZero())
			MoveDirection = Math::ConstrainVectorToSlope(Owner.ActorForwardVector, SlopeNormal, MoveComp.WorldUp);
		else
			MoveDirection = Math::ConstrainVectorToSlope(MoveDirection, SlopeNormal, MoveComp.WorldUp);

        return MoveDirection.GetSafeNormal();
    }

	// Returns MovementDirection once it has been constrained to plane.
	// Will be the input length. Returns ActorForward if input is nearly zero
	FVector GetMoveDirectionOnPlane(FVector PlaneNormal)
    {
		FVector MoveDirection = GetAttributeVector(AttributeVectorNames::MovementDirection);
		MoveDirection = MoveDirection.ConstrainToPlane(PlaneNormal).GetSafeNormal();

		// Protect against no input
		if(MoveDirection.IsNearlyZero())
			MoveDirection = Owner.ActorForwardVector;
			
        return MoveDirection * GetAttributeVector(AttributeVectorNames::MovementDirection).Size();
    }

	EHazeNetworkDeactivation RemoteLocalControlCrumbDeactivation() const
	{
		if (HasControl())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		
		return EHazeNetworkDeactivation::DeactivateLocal;
	}
}
