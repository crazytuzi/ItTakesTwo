
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Peanuts.Animation.Features.LocomotionFeatureLedgeGrab;
import Vino.Movement.Components.GrabbedCallbackComponent;
import Peanuts.Movement.DefaultCharacterCollisionSolver;
import Vino.Movement.Capabilities.LedgeGrab.CharacterLedgeGrabSettings;
import Vino.Movement.Capabilities.LedgeGrab.CharacterLedgeGrabNames;
import Vino.Movement.Capabilities.LedgeGrab.CharacterLedgeGrabGlobalFunctions;
import Vino.Movement.Components.LedgeGrab.LedgeGrabComponent;
import Vino.Movement.Jump.AirJumpsComponent;

class UCharacterEnterLedgeGrabCapability : UCharacterMovementCapability
{
	default RespondToEvent(LedgeGrabActivationEvents::Grabbing);

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MovementSystemTags::LedgeGrab);
	default CapabilityTags.Add(LedgeGrabTags::Enter);
	default CapabilityTags.Add(LedgeGrabTags::HangMove);
	
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 75;
	default SeperateInactiveTick(ECapabilityTickGroups::ReactionMovement, 40);

	default CapabilityDebugCategory = CapabilityTags::Movement;

    const FCharacterLedgeGrabSettings DefaultLedgeGrabSettings;

	//Work Data
	FVector RelativeHangOffset = FVector::ZeroVector;
	FHazeAcceleratedVector HangPositionAccelerator;
	
	AHazePlayerCharacter PlayerOwner;
	ULedgeGrabComponent LedgeGrabComp;
	UCharacterAirJumpsComponent AirJumpsComp;

	// we store a refrence too the ledge primitive so we can stop ignoring it when tracing.
	UPrimitiveComponent GrabbedLedge = nullptr;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);

		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		ensure(PlayerOwner != nullptr);

		LedgeGrabComp = ULedgeGrabComponent::GetOrCreate(Owner);
		AirJumpsComp = UCharacterAirJumpsComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate_EventBased() const
	{
		if(!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		if (LedgeGrabComp.HasValidTargetLedge())
			return EHazeNetworkActivation::ActivateUsingCrumb;

        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		// We let hang decide when enter is done. We want the remote to stay in entering until it knows hang started.

		if (!MoveComp.CanCalculateMovement())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (!LedgeGrabComp.HasValidLedge())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}
	
	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& Params)const
	{
		// We want to make sure we hang in the same location on the remote as we do on the control.
		// To handle this we make data relative to the ledgeprimitive if its networked.
		// Otherwise we just keep everything in worldspace.
		const UPrimitiveComponent LedgeHangingOn = LedgeGrabComp.TargetLedgeData.LedgeGrabbed;

		if (LedgeHangingOn.IsNetworked())
		{
			Params.AddObject(LedgeGrabSyncNames::HangObject, LedgeGrabComp.TargetLedgeData.LedgeGrabbed);

			FVector RelativeHangPosition = LedgeHangingOn.WorldTransform.InverseTransformPosition(LedgeGrabComp.TargetLedgeData.ActorHangLocation.Location);
			Params.AddVector(LedgeGrabSyncNames::RelativeHangPosition, RelativeHangPosition);

			FVector RelativeNormalRotation = LedgeHangingOn.WorldRotation.UnrotateVector(LedgeGrabComp.TargetLedgeData.NormalPointingAwayFromWall);
			Params.AddVector(LedgeGrabSyncNames::RelativeNormal, RelativeNormalRotation);

			MoveComp.SetMoveWithComponent(LedgeGrabComp.TargetLedgeData.LedgeGrabbed, NAME_None);
		}
		else
		{
			Params.AddVector(LedgeGrabSyncNames::HangPosition, LedgeGrabComp.TargetLedgeData.ActorHangLocation.Location);
			Params.AddVector(LedgeGrabSyncNames::LedgeNormal, LedgeGrabComp.TargetLedgeData.NormalPointingAwayFromWall);
		}

		Params.AddObject(LedgeGrabSyncNames::ContactSurface, LedgeGrabComp.TargetLedgeData.ContactMat);

		Params.AddVector(LedgeGrabSyncNames::LeftHandLocation, LedgeGrabComp.TargetLedgeData.LeftHandRelative.Location);
		Params.AddVector(LedgeGrabSyncNames::RightHandLocation, LedgeGrabComp.TargetLedgeData.RightHandRelative.Location);

		Params.AddVector(LedgeGrabSyncNames::LeftHandForwardRotation, LedgeGrabComp.TargetLedgeData.LeftHandRelative.Rotation.ForwardVector);
		Params.AddVector(LedgeGrabSyncNames::LeftHandUpRotation, LedgeGrabComp.TargetLedgeData.LeftHandRelative.Rotation.UpVector);

		Params.AddVector(LedgeGrabSyncNames::RightHandForwardRotation, LedgeGrabComp.TargetLedgeData.RightHandRelative.Rotation.ForwardVector);
		Params.AddVector(LedgeGrabSyncNames::RightHandUpRotation, LedgeGrabComp.TargetLedgeData.RightHandRelative.Rotation.UpVector);
	}

	void LoadActivationVariables(const FCapabilityActivationParams& ActivationParams, FLedgeGrabPhysicalData& LedgeGrabData)
	{
		FVector LocalPosition = FVector::ZeroVector;
		UPrimitiveComponent LedgeHangingOn = Cast<UPrimitiveComponent>(ActivationParams.GetObject(LedgeGrabSyncNames::HangObject));

		LedgeGrabData.LedgeGrabbed = LedgeHangingOn;
		if (LedgeHangingOn != nullptr)
		{
			LedgeGrabData.ActorHangLocation.Location = LedgeHangingOn.WorldTransform.TransformPosition(ActivationParams.GetVector(LedgeGrabSyncNames::RelativeHangPosition));
			LedgeGrabData.NormalPointingAwayFromWall = LedgeHangingOn.WorldRotation.RotateVector(ActivationParams.GetVector(LedgeGrabSyncNames::RelativeNormal));
		}
		else
		{
			LedgeGrabData.ActorHangLocation.Location = ActivationParams.GetVector(LedgeGrabSyncNames::HangPosition);
			LedgeGrabData.NormalPointingAwayFromWall = ActivationParams.GetVector(LedgeGrabSyncNames::LedgeNormal);
		}

		LedgeGrabData.ContactMat = Cast<UPhysicalMaterial>(ActivationParams.GetObject(LedgeGrabSyncNames::ContactSurface));

		LedgeGrabData.LeftHandRelative.Location = ActivationParams.GetVector(LedgeGrabSyncNames::LeftHandLocation);
		LedgeGrabData.RightHandRelative.Location = ActivationParams.GetVector(LedgeGrabSyncNames::RightHandLocation);

		LedgeGrabData.LeftHandRelative.Rotation = Math::MakeRotFromXZ(ActivationParams.GetVector(LedgeGrabSyncNames::LeftHandForwardRotation), ActivationParams.GetVector(LedgeGrabSyncNames::LeftHandUpRotation)).Quaternion();
		LedgeGrabData.RightHandRelative.Rotation = Math::MakeRotFromXZ(ActivationParams.GetVector(LedgeGrabSyncNames::RightHandForwardRotation), ActivationParams.GetVector(LedgeGrabSyncNames::RightHandUpRotation)).Quaternion();
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		FLedgeGrabPhysicalData LedgeData;
		// The control side already has this data on the LedgeGrabComponent but we rebuild it anyway to verify that we will be using the same data on both side.
		LoadActivationVariables(ActivationParams, LedgeData);

		LedgeGrabComp.StartLedgeGrab(LedgeData);
		LedgeGrabComp.SetState(ELedgeGrabStates::Entering);

		Owner.BlockCapabilities(CapabilityTags::CharacterFacing, this);
		Owner.BlockCapabilities(CapabilityTags::Interaction, this);
		Owner.BlockCapabilities(n"BlockWhileLedgeGrabbing", this);
		Owner.BlockCapabilities(ActionNames::WeaponAim, this);
		AirJumpsComp.ResetJumpAndDash();

		// Everything before this point needs to be called so the events are synced up on both sides.
		if (ActivationParams.IsStale())
			return;

		GrabbedLedge = LedgeGrabComp.LedgeGrabData.LedgeGrabbed;
		if (GrabbedLedge != nullptr)
			MoveComp.StartIgnoringComponent(GrabbedLedge);
		
		HangPositionAccelerator.Value = FVector::ZeroVector;
		HangPositionAccelerator.Velocity = FVector::ZeroVector;

		MoveComp.SetSubAnimationTagToBeRequested(FeatureName::LedgeGrabStart);

		RelativeHangOffset = LedgeGrabComp.LedgeGrabData.ActorHangLocation.Location - MoveComp.OwnerLocation;
		MoveComp.SetTargetFacingDirection(-LedgeGrabComp.LedgeGrabData.NormalPointingAwayFromWall.GetSafeNormal());
		Owner.SetCapabilityActionState(ActionNames::LedgeGrabbing, EHazeActionState::Active);
	}	

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Owner.UnblockCapabilities(CapabilityTags::CharacterFacing, this);
		Owner.UnblockCapabilities(CapabilityTags::Interaction, this);
		Owner.UnblockCapabilities(n"BlockWhileLedgeGrabbing", this);
		Owner.UnblockCapabilities(ActionNames::WeaponAim, this);

		if ((IsBlocked() && LedgeGrabComp.IsCurrentState(ELedgeGrabStates::Entering)) || LedgeGrabComp.IsCurrentState(ELedgeGrabStates::Drop))
		{
			if (GrabbedLedge != nullptr)
				MoveComp.StopIgnoringComponent(GrabbedLedge);
			LedgeGrabComp.LetGoOfLedge(ELedgeReleaseType::LetGo);
		}

		Owner.SetCapabilityActionState(ActionNames::LedgeGrabbing, EHazeActionState::Inactive);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!HasControl() && !MoveComp.CanCalculateMovement())
			return;

		// Accelerate towards the relatvie hang position.
		const FVector PreviousHangPosition = HangPositionAccelerator.Value;
		const FVector NewHangPosition = HangPositionAccelerator.AccelerateTo(RelativeHangOffset, DefaultLedgeGrabSettings.LerpToHangPositionTime, DeltaTime);
		const FVector HangDelta = NewHangPosition - PreviousHangPosition;

        FHazeFrameMovement EnterLedgeMove = MoveComp.MakeFrameMovement(LedgeGrabTags::Enter);
		if (!HasControl())
			EnterLedgeMove.OverrideCollisionSolver(n"NoCollisionSolver");

		EnterLedgeMove.ApplyTargetRotationDelta();
		EnterLedgeMove.ApplyDelta(HangDelta);
		EnterLedgeMove.OverrideStepUpHeight(0.f);
		EnterLedgeMove.OverrideStepDownHeight(0.f);
		EnterLedgeMove.OverrideGroundedState(EHazeGroundedState::Grounded);
		LedgeGrabComp.SetFollow(EnterLedgeMove);
        MoveCharacter(EnterLedgeMove, FeatureName::LedgeGrab);
	}

	UFUNCTION(BlueprintOverride)
	FString GetDebugString()
	{
		FString DebugText = "";
		return DebugText;
	}

};
