import Vino.Movement.MovementSystemTags;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.Grinding.GrindingCapabilityTags;
import Vino.Movement.Grinding.UserGrindComponent;
import Vino.Movement.Grinding.GrindSettings;
import Vino.Movement.SplineLock.SplineLockComponent;
import Rice.Math.MathStatics;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingTags;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingComponent;;

class UIceSkatingGrindingJumpCapability : UHazeCapability
{
	default CapabilityTags.Add(IceSkatingTags::IceSkating);
	default CapabilityTags.Add(IceSkatingTags::Jump);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementAction);
	default CapabilityTags.Add(MovementSystemTags::Grinding);
	default CapabilityTags.Add(GrindingCapabilityTags::Movement);
	default CapabilityTags.Add(GrindingCapabilityTags::Jump);

	default CapabilityDebugCategory = n"IceSkating";	
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 109;

	default SeperateInactiveTick(ECapabilityTickGroups::ReactionMovement, 114);

	AHazePlayerCharacter Player;
	UIceSkatingComponent SkateComp;
	UUserGrindComponent UserGrindComp;
	UHazeMovementComponent MoveComp;

	FIceSkatingGrindSettings GrindSettings;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		SkateComp = UIceSkatingComponent::GetOrCreate(Player);
		UserGrindComp = UUserGrindComponent::GetOrCreate(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{		
		if (!SkateComp.bIsIceSkating)
       		return EHazeNetworkActivation::DontActivate;

		if (SkateComp.ForceJumpPosition.IsOnValidSpline())
		{
	        return EHazeNetworkActivation::ActivateUsingCrumb;
		}
		else
		{
			if (!SkateComp.IsAbleToJump())
		        return EHazeNetworkActivation::DontActivate;

			if (!UserGrindComp.HasActiveGrindSpline())
	       		return EHazeNetworkActivation::DontActivate;

			if (!UserGrindComp.ActiveGrindSpline.bCanJump)
	       		return EHazeNetworkActivation::DontActivate;

			if (UserGrindComp.SplinePosition.WorldUpVector.DotProduct(MoveComp.WorldUp) < 0.f)
				return EHazeNetworkActivation::DontActivate;

			if (!WasActionStarted(ActionNames::MovementJump))
	       		return EHazeNetworkActivation::DontActivate;

	        return EHazeNetworkActivation::ActivateUsingCrumb;
	    }
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		// Hard-reset the force jump if we cant activate
		if (IsBlocked() || !SkateComp.bIsIceSkating)
			SkateComp.ForceJumpPosition = FHazeSplineSystemPosition();
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		FHazeSplineSystemPosition JumpSplinePosition;
		if (SkateComp.ForceJumpPosition.IsOnValidSpline())
		{
			JumpSplinePosition = SkateComp.ForceJumpPosition;
			ActivationParams.AddActionState(n"ForceJump");
		}
		else
		{
			JumpSplinePosition = UserGrindComp.SplinePosition;
		}

		ActivationParams.AddStruct(n"JumpPosition", JumpSplinePosition);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		SetMutuallyExclusive(GrindingCapabilityTags::Jump, true);
		SetMutuallyExclusive(IceSkatingTags::Jump, true);

		FHazeSplineSystemPosition JumpPosition;
		ActivationParams.GetStruct(n"JumpPosition", JumpPosition);
		bool bForceJump = ActivationParams.GetActionState(n"ForceJump");

		if (bForceJump)
		{
			// If we're forced to jump, make sure to set the velocity to what our target is supposed to be
			AGrindspline GrindSpline = Cast<AGrindspline>(JumpPosition.Spline.Owner);
			MoveComp.Velocity = JumpPosition.WorldForwardVector * GrindSpline.CustomSpeed.DesiredMiddle;
		}

		// Add up-impulse
		MoveComp.AddImpulse(MoveComp.WorldUp * GrindSettings.JumpUpImpulse);

		// Add side-impulse
		if (!SkateComp.bGrindJumpShouldBlockInput)
		{
			FVector MoveInput = GetAttributeVector(AttributeVectorNames::MovementDirection);

			FVector TangentRight = JumpPosition.WorldRightVector;
			TangentRight.Z = 0.f;
			TangentRight.Normalize();

			FVector HorizontalImpulse = (GetAttributeVector(AttributeVectorNames::MovementDirection) * GrindSettings.JumpSideImpulse).ConstrainToDirection(TangentRight);
			MoveComp.AddImpulse(HorizontalImpulse);
		}
		
		if (UserGrindComp.HasActiveGrindSpline())
		{
			UserGrindComp.StartGrindSplineCooldown(UserGrindComp.ActiveGrindSpline);
			UserGrindComp.LeaveActiveGrindSpline(EGrindDetachReason::Jump);
		}

		if (UserGrindComp.GrindingForceFeedbackData != nullptr && UserGrindComp.GrindingForceFeedbackData.GrindJumpRumble != nullptr)
			Player.PlayForceFeedback(UserGrindComp.GrindingForceFeedbackData.GrindJumpRumble, false, true, NAME_None, 0.6f);

		SkateComp.ForceJumpPosition = FHazeSplineSystemPosition();
		SkateComp.StartJumpCooldown();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SetMutuallyExclusive(GrindingCapabilityTags::Jump, false);
		SetMutuallyExclusive(IceSkatingTags::Jump, false);
	}
}
