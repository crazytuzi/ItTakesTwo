

import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Peanuts.Animation.Features.LocomotionFeatureLedgeGrab;
import Vino.Movement.Components.GrabbedCallbackComponent;
import Vino.Movement.Capabilities.LedgeGrab.CharacterLedgeGrabSettings;
import Vino.Movement.Capabilities.LedgeGrab.CharacterLedgeGrabNames;
import Vino.Movement.Capabilities.LedgeGrab.CharacterLedgeGrabGlobalFunctions;
import Vino.Movement.Components.LedgeGrab.LedgeGrabComponent;

class UCharacterLedgeGrabHangCapability : UCharacterMovementCapability
{
	default RespondToEvent(LedgeGrabActivationEvents::Grabbing);

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MovementSystemTags::LedgeGrab);
	default CapabilityTags.Add(LedgeGrabTags::Hang);
	default CapabilityTags.Add(LedgeGrabTags::HangMove);

	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 76;
	default SeperateInactiveTick(ECapabilityTickGroups::ReactionMovement, 41);

	default CapabilityDebugCategory = CapabilityTags::Movement;

	int HangDirSign = 0;
	FHazeAcceleratedFloat HandDeg;

    const FCharacterLedgeGrabSettings LedgeGrabSettings;
	ULedgeGrabComponent LedgeGrabComp;

	bool bArmIsOut = false;
	float ArmUpdateTime = -1.f;

	FCharacterLedgeGrabSettings Settings;

	//Work Data
	AHazePlayerCharacter PlayerOwner;
	
	UPrimitiveComponent LedgeGrabbed = nullptr;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);

		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		ensure(PlayerOwner != nullptr);
		LedgeGrabComp = ULedgeGrabComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate_EventBased() const
	{
		if (!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		if (!LedgeGrabComp.IsCurrentState(ELedgeGrabStates::Entering))
			return EHazeNetworkActivation::DontActivate;

		if (!LedgeGrabComp.PassedEnterDuration())
			return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		LedgeGrabComp.SetState(ELedgeGrabStates::Hang);

		Owner.BlockCapabilities(CapabilityTags::CharacterFacing, this);
		Owner.BlockCapabilities(CapabilityTags::Interaction, this);
		Owner.BlockCapabilities(n"BlockWhileLedgeGrabbing", this);
		Owner.BlockCapabilities(ActionNames::WeaponAim, this);
		
		HangDirSign = 0;
		Owner.SetCapabilityActionState(ActionNames::LedgeGrabbing, EHazeActionState::Active);

		LedgeGrabbed = LedgeGrabComp.LedgeGrabData.LedgeGrabbed;
		MoveComp.StartIgnoringComponent(LedgeGrabbed);
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreDeactivation(FCapabilityDeactivationSyncParams& Params)
	{
		if (LedgeGrabComp.IsCurrentState(ELedgeGrabStates::Drop))
			Params.AddActionState(LedgeGrabSyncNames::Dropped);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!MoveComp.CanCalculateMovement())
			return RemoteLocalControlCrumbDeactivation();

		if (!LedgeGrabComp.HasValidLedge())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
			
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if (LedgeGrabbed != nullptr && !LedgeGrabComp.IsCurrentState(ELedgeGrabStates::ClimbUp))
			MoveComp.StopIgnoringComponent(LedgeGrabbed);

		if (IsBlocked() && LedgeGrabComp.IsCurrentState(ELedgeGrabStates::Hang))
			LedgeGrabComp.LetGoOfLedge(ELedgeReleaseType::LetGo);

		Owner.UnblockCapabilities(CapabilityTags::CharacterFacing, this);
		Owner.UnblockCapabilities(CapabilityTags::Interaction, this);
		Owner.UnblockCapabilities(n"BlockWhileLedgeGrabbing", this);
		Owner.UnblockCapabilities(ActionNames::WeaponAim, this);

		Owner.SetCapabilityActionState(ActionNames::LedgeGrabbing, EHazeActionState::Inactive);
	}

	UFUNCTION(BlueprintOverride)
	void NotificationReceived(FName Notification, FCapabilityNotificationReceiveParams Params)
	{
		if (Notification == n"LedgeGrabArmUpdate")
		{
			bArmIsOut = Params.GetActionState(n"ArmOut") == EHazeActionState::Active;
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!HasControl() && !MoveComp.CanCalculateMovement())
			return;

		UpdateTurn(DeltaTime);
		
        FHazeFrameMovement HangAtLedgeMove = MoveComp.MakeFrameMovement(LedgeGrabTags::Hang);
		if (!HasControl())
			HangAtLedgeMove.OverrideCollisionSolver(n"NoCollisionSolver");

		HangAtLedgeMove.OverrideStepDownHeight(0.f);
		HangAtLedgeMove.OverrideStepUpHeight(0.f);
		HangAtLedgeMove.OverrideGroundedState(EHazeGroundedState::Grounded);
		LedgeGrabComp.SetFollow(HangAtLedgeMove);
        MoveCharacter(HangAtLedgeMove, FeatureName::LedgeGrab);
	}

	void UpdateTurn(float DeltaTime)
	{
		if (HasControl())
		{
			bool bWantsArmOut = UpdateBlendSpaceValues(GetAttributeVector(AttributeVectorNames::MovementDirection), DeltaTime);
			if (CanSendArmUpdate() && bWantsArmOut != bArmIsOut)
			{
				FCapabilityNotificationSendParams Params;
				Params.AddActionState(n"ArmOut", bWantsArmOut ? EHazeActionState::Active : EHazeActionState::Inactive);
				TriggerNotification(n"LedgeGrabArmUpdate", Params);

				ArmUpdateTime = System::GetGameTimeInSeconds();
			}
		}
		else 
		{
			FVector ArmDirection = FVector::ZeroVector;
			if (bArmIsOut)
				ArmDirection = LedgeGrabComp.LedgeGrabData.NormalPointingAwayFromWall;
				
			UpdateBlendSpaceValues(ArmDirection, DeltaTime);
		}
	}

	bool CanSendArmUpdate() const
	{
		float Dif = System::GetGameTimeInSeconds() - ArmUpdateTime;
		return Dif > 0.5f;
	}

	bool UpdateBlendSpaceValues(FVector InputDirection, float DeltaTime)
	{
		float TargetDegress = CalculateTargetDegres(InputDirection);
		float TargetAbs = FMath::Abs(TargetDegress);
		float TurnTime = 0.5f;
		bool bOutput = true;

		bool bTargetBelowTreshold = TargetAbs < Settings.HangHandMinDegress; 
		if (bTargetBelowTreshold)
			TurnTime = 1.25f;

		if (bTargetBelowTreshold && FMath::Abs(HandDeg.Value) < Settings.HangHandMinDegress)
		{
			HangDirSign = 0;
			bOutput = false;
		}

		HandDeg.AccelerateTo(TargetDegress, TurnTime, DeltaTime);
		PlayerOwner.SetAnimFloatParam(LedgeGrabAnimationParams::HangDirection, HandDeg.Value);
		return bOutput;
	}

	float CalculateTargetDegres(FVector InputDirection)
	{
		if (InputDirection.SizeSquared() < 0.5f)
			return 0.f;

		bool bShouldBeMaxed = false;
		float AwayFromWallDot = InputDirection.DotProduct(LedgeGrabComp.LedgeGrabData.NormalPointingAwayFromWall);
		if (AwayFromWallDot < 0.f)
		{
			bShouldBeMaxed = true;
			
			if (AwayFromWallDot < Settings.MaxExtraHangSideInput)
				return 0.f;
		}

		float InputVWallDot = InputDirection.DotProduct(LedgeGrabComp.LedgeGrabData.NormalPointingAwayFromWall.CrossProduct(MoveComp.WorldUp));
		if (bShouldBeMaxed)
			InputVWallDot = InputVWallDot > 0 ? 1 : -1;

		float Degress = Math::DotToDegrees(InputVWallDot);

		if (HangDirSign == 0)
			HangDirSign = Degress > 90.f ? -1 : 1;
		
		if (HangDirSign < 0)
			Degress = FMath::Abs(Degress - 180.f);

		return float(HangDirSign) * Degress;
	}

	UFUNCTION(BlueprintOverride)
	FString GetDebugString()
	{
		FString DebugText = "";
		return DebugText;
	}
};
