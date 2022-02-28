import Vino.Movement.Capabilities.Swimming.SnowGlobeSwimmingComponent;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.Capabilities.Swimming.Core.SwimmingTags;

class USnowGlobeSwimmingBreachDiveCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MovementSystemTags::Swimming);
	default CapabilityTags.Add(SwimmingTags::AboveWater);
	default CapabilityTags.Add(SwimmingTags::Breach);
	default CapabilityTags.Add(SwimmingTags::BreachDive);

	default CapabilityDebugCategory = n"Movement Swimming";
	
	default TickGroup = ECapabilityTickGroups::ReactionMovement;
	default TickGroupOrder = 198;

	AHazePlayerCharacter Player;
	USnowGlobeSwimmingComponent SwimComp; 

	FVector Velocity;
	FVector MidwayTargetDirection;
	FVector ExitTargetDirection;
	FVector DiveVelocity;

	bool bDiveEnter = true;
	bool bSkipEnter = false;

	float DiveEnterDuration = 0.5f;
	float DiveExitDuration = 0.2f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		
		Player = Cast<AHazePlayerCharacter>(Owner);
		SwimComp = USnowGlobeSwimmingComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		if(!IsActioning(ActionNames::MovementCrouch))
			return EHazeNetworkActivation::DontActivate;

		if(MoveComp.IsGrounded())
			return EHazeNetworkActivation::DontActivate;

		if(SwimComp.bIsInWater)
			return EHazeNetworkActivation::DontActivate;

		if(SwimComp.SwimmingState != ESwimmingState::Breach)
			return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!MoveComp.CanCalculateMovement())
		{
			if (HasControl())
				return EHazeNetworkDeactivation::DeactivateUsingCrumb;
			else
				return EHazeNetworkDeactivation::DeactivateLocal;
		}

		if(MoveComp.IsGrounded())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(SwimComp.bIsInWater)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{		
		Player.SetAnimBoolParam(n"BreachDive", true);

		Velocity = MoveComp.GetVelocity();

		if (Velocity.DotProduct(FVector::UpVector) > 0)
			bSkipEnter = false;
		else
			bSkipEnter = true;

		SwimComp.SwimmingState = ESwimmingState::BreachDive;

		ExitTargetDirection = (Player.ActorForwardVector + (Player.ActorUpVector * -2)).GetSafeNormal();
		MidwayTargetDirection = SlerpVector(Velocity.GetSafeNormal(), ExitTargetDirection, 0.20f).GetSafeNormal();	
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		// If nothing else in the swimming system took over...
		if (SwimComp.SwimmingState == ESwimmingState::Breach)
			SwimComp.SwimmingState = ESwimmingState::Inactive;

		// Should be consumed by animation, but just in case...
		Player.SetAnimBoolParam(n"BreachDive", false);
		Player.SetCapabilityActionState(n"ResetDolphinCombo", EHazeActionState::Active);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (MoveComp.CanCalculateMovement())
		{	
			FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"SwimmingBreach");
			CalculateFrameMove(FrameMove, DeltaTime);
			MoveCharacter(FrameMove, n"SwimmingBreach");
			
			CrumbComp.LeaveMovementCrumb();	
		}
	}	

	void CalculateFrameMove(FHazeFrameMovement& FrameMove, float DeltaTime)
	{	
		if (HasControl())
		{					
			if (ActiveDuration < DiveEnterDuration && !bSkipEnter)
			{
				float LerpValue = Math::Saturate(ActiveDuration / DiveEnterDuration);
				FVector NewDirection = SlerpVector(Velocity.GetSafeNormal(), MidwayTargetDirection, LerpValue);
				float NewLength = FMath::Lerp(Velocity.Size(), 10.f, LerpValue);

				Velocity = NewDirection * NewLength;
			}
			else if (ActiveDuration < DiveEnterDuration + DiveExitDuration)
			{
				float AddedSkipValue = bSkipEnter ? DiveEnterDuration : 0.f;
				float LerpValue = Math::Saturate((ActiveDuration - DiveEnterDuration + AddedSkipValue) / DiveExitDuration);

				FVector NewDirection = SlerpVector(MidwayTargetDirection, ExitTargetDirection, LerpValue).GetSafeNormal();
				float NewLength = FMath::Lerp(10.f, 4000.f, LerpValue);

				Velocity = NewDirection * NewLength;
			}

			FrameMove.ApplyVelocity(Velocity);
			FrameMove.OverrideStepUpHeight(0.f);
			FrameMove.OverrideStepDownHeight(0.f);
			//FrameMove.ApplyAndConsumeImpulses();

			MoveComp.SetTargetFacingDirection(Velocity.GetSafeNormal());
			FrameMove.ApplyTargetRotationDelta();
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			FrameMove.ApplyConsumedCrumbData(ConsumedParams);
		}	
	}


	FVector SlerpVector(FVector A, FVector B, float Alpha)
	{
		float Loc_Alpha = Math::Saturate(Alpha);
        float Angle = FMath::Acos(A.GetSafeNormal().DotProduct(B.GetSafeNormal()));
        FVector Axis = A.CrossProduct(B).GetSafeNormal();
        FQuat RotateQuat(Axis, Angle * Loc_Alpha);

        return RotateQuat.RotateVector(A);
	}
}
