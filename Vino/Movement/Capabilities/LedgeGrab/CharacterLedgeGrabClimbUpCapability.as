
import Vino.Movement.Components.MovementComponent;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Peanuts.Animation.Features.LocomotionFeatureLedgeGrab;
import Vino.Movement.Capabilities.LedgeGrab.CharacterLedgeGrabNames;
import Vino.Movement.MovementSystemTags;
import Vino.Movement.Capabilities.LedgeGrab.CharacterLedgeGrabGlobalFunctions;
import Vino.Movement.Components.LedgeGrab.LedgeGrabComponent;

class UCharacterLedgeGrabClimbUpCapability : UCharacterMovementCapability
{
	default RespondToEvent(LedgeGrabActivationEvents::Grabbing);

	default CapabilityTags.Add(CapabilityTags::Movement);	
	default CapabilityTags.Add(MovementSystemTags::LedgeGrab);
	default CapabilityTags.Add(LedgeGrabTags::ClimbUp);
	
	default TickGroup = ECapabilityTickGroups::ActionMovement;

	default CapabilityDebugCategory = CapabilityTags::Movement;
	default TickGroupOrder = 44;

	AHazePlayerCharacter Player = nullptr;

	ULedgeGrabComponent LedgeGrabComp;
	bool bDoneClimbingUp = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		Player = Cast<AHazePlayerCharacter>(Owner);
		LedgeGrabComp = ULedgeGrabComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate_EventBased() const
	{
		if (!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		if (!LedgeGrabComp.IsCurrentState(ELedgeGrabStates::Hang))
			return EHazeNetworkActivation::DontActivate;

		if (!WasActionStarted(ActionNames::MovementJump))
			return EHazeNetworkActivation::DontActivate;

		if (!CanClimbUp())
			return EHazeNetworkActivation::DontActivate;
		
		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!MoveComp.CanCalculateMovement())
			return RemoteLocalControlCrumbDeactivation();

		// TODO:: Should also check if were pushed by something.

		if (bDoneClimbingUp)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		FVector Impulse = FVector::ZeroVector;
		MoveComp.GetAccumulatedImpulse(Impulse);
		if(Impulse.SizeSquared() > FMath::Square(500.f))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Owner.BlockCapabilities(MovementSystemTags::Dash, this);
		Owner.BlockCapabilities(ActionNames::WeaponAim, this);
		Owner.BlockCapabilities(n"BlockWhileLedgeGrabbing", this);
		Owner.BlockCapabilities(CapabilityTags::Interaction, this);

		Owner.SetCapabilityActionState(ActionNames::LedgeGrabbing, EHazeActionState::Active);
		LedgeGrabComp.SetState(ELedgeGrabStates::ClimbUp);
		
		bDoneClimbingUp = false;
	
		ULocomotionFeatureLedgeGrab LedgeGrabFeature = ULocomotionFeatureLedgeGrab::Get(CharacterOwner);
		if (LedgeGrabFeature != nullptr)
		{
			FHazePlayLocomotionAnimationParams LocomotionAnimation;

			LocomotionAnimation.Animation = LedgeGrabFeature.LedgeClimbUp.Sequence;
			LocomotionAnimation.BlendTime = 0.f;

			Player.PlayLocomotionAnimation(
				FHazeAnimationDelegate(),
				FHazeAnimationDelegate(this, n"ClimbUpAnimationDone"),
				LocomotionAnimation);
		}
		else
		{
			bDoneClimbingUp = true;
		}
	}

	UFUNCTION()
	void ClimbUpAnimationDone()
	{
		bDoneClimbingUp = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Owner.UnblockCapabilities(MovementSystemTags::Dash, this);
		Owner.UnblockCapabilities(CapabilityTags::Interaction, this);
		Owner.UnblockCapabilities(n"BlockWhileLedgeGrabbing", this);
		Owner.UnblockCapabilities(ActionNames::WeaponAim, this);

		MoveComp.StopIgnoringComponent(LedgeGrabComp.LedgeGrabData.LedgeGrabbed);

		Owner.SetCapabilityActionState(ActionNames::LedgeGrabbing, EHazeActionState::Inactive);
		LedgeGrabComp.SetState(ELedgeGrabStates::None);
		LedgeGrabComp.LetGoOfLedge(ELedgeReleaseType::ClimbUp);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// On the remote we let the activation of the climb let us now that the hang/entering capability should deactivate.
		if (!HasControl() && !MoveComp.CanCalculateMovement())
			return;

		FHazeLocomotionTransform RootMotionTransform;
		CharacterOwner.RequestRootMotion(DeltaTime, RootMotionTransform);
		RootMotionTransform.DeltaTranslation = RootMotionTransform.DeltaTranslation * MoveComp.ActorScale;

		FHazeFrameMovement MoveData = MoveComp.MakeFrameMovement(LedgeGrabTags::ClimbUp);
		MoveData.ApplyRootMotion(RootMotionTransform);
		MoveData.OverrideStepUpHeight(0.f);
		MoveData.OverrideStepDownHeight(0.f);
		MoveData.OverrideGroundedState(EHazeGroundedState::Grounded);
		LedgeGrabComp.SetFollow(MoveData);

		ensure(!MoveData.ContainsNaN());

		MoveComp.Move(MoveData);
	}
	
	UFUNCTION(BlueprintOverride)
	FString GetDebugString()
	{	
		FString Str = "";
		Str += "Velocity: <Yellow>" + MoveComp.Velocity.Size() + "</> (" + MoveComp.Velocity.ToString() + ")\n";
		
		return Str;
	} 

	// Dependecy on Can jumpup already having returned true
	bool CanClimbUp() const
	{
		FCharacterLedgeGrabSettings ScaledGrabSettings = LedgeGrabComp.Settings.GetScaledLedgeGrabSettings(MoveComp.ActorScale);
		FVector HangOffset = Math::ConstructRotatorFromUpAndForwardVector(MoveComp.OwnerRotation.Vector(), MoveComp.WorldUp).RotateVector(ScaledGrabSettings.HangOffset);
		FVector LedgePosition = MoveComp.OwnerLocation - HangOffset;

		float ExtraPadding = 22.f;
		FVector CapsuleExtens = MoveComp.ActorShapeExtents;
		FVector LocalisedBoxExtents = MoveComp.OwnerRotation.RotateVector(FVector(CapsuleExtens.X - ExtraPadding, 0.f, CapsuleExtens.Z + 1));
		CapsuleExtens.X += ExtraPadding;
		FVector LedgePositionWithExtents = LedgePosition + LocalisedBoxExtents;

		FHazeTraceParams Query;
		Query.InitWithMovementComponent(MoveComp);
		Query.UnmarkToTraceWithOriginOffset();
		Query.TraceShape = FCollisionShape::MakeBox(CapsuleExtens);
		Query.OverlapLocation = LedgePositionWithExtents;

		TArray<FOverlapResult> OverlapResults;
		if (Query.Overlap(OverlapResults))
		{
			if (IsDebugActive())
				System::DrawDebugBox(LedgePositionWithExtents, CapsuleExtens, FLinearColor::Red, MoveComp.OwnerRotation.Rotator(),  1.f);
			
			return false;
		}

		if (IsDebugActive())
			System::DrawDebugBox(LedgePositionWithExtents, CapsuleExtens, FLinearColor::Green, MoveComp.OwnerRotation.Rotator(),  1.f);
		
		return true;
	}
};
