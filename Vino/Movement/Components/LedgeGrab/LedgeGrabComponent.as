import Peanuts.Animation.Features.LocomotionFeatureLedgeGrab;
import Vino.Movement.Components.LedgeGrab.LedgrabData;
import Vino.Movement.Capabilities.LedgeGrab.CharacterLedgeGrabNames;

enum ELedgeGrabStates
{
	None,
	Entering,
	Hang,
	JumpOff,
	ClimbUp,
	JumpUp,
	Drop,
	MAX,
};

struct FLedgeGrabAnimationData
{
	UPROPERTY()
	FTransform LeftHand = FTransform::Identity;	
	UPROPERTY()
	FTransform RightHand = FTransform::Identity;
	UPROPERTY()
	FTransform ActorHangLocation = FTransform::Identity;
}

class ULedgeGrabComponent : UActorComponent
{
	ELedgeGrabStates CurrentState = ELedgeGrabStates::None;

	UHazeMovementComponent MoveComp = nullptr;
	FLedgeGrabPhysicalData TargetLedgeData;
	FLedgeGrabPhysicalData GrabData;

	UPROPERTY()
	FLedgeGrabAnimationData LedgeGrabAnimationData;

	FTransform LeftWristOffset = FTransform::Identity;
	FTransform RightWristOffset = FTransform::Identity;

	FCharacterLedgeGrabSettings Settings;	

	float InactiveTimer = 0.f;
	AHazePlayerCharacter OwningPlayer;
	
	float EnterStartedTime = -1.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveComp = UHazeMovementComponent::Get(Owner);
		ensure(MoveComp != nullptr);

		OwningPlayer = Cast<AHazePlayerCharacter>(Owner);
		ensure(OwningPlayer != nullptr);

		CalculateAnimationOffsets();
		InactiveTimer = Settings.LedgeGrabCooldown;

		// We base the characters hand position from animations so if a feature changes we need to update the offsets we use.
		OwningPlayer.Mesh.OnFeatureListChanged.AddUFunction(this, n"CalculateAnimationOffsets");
	}

	UFUNCTION(BlueprintOverride)
	void OnResetComponent(EComponentResetType ResetType)
	{
		CurrentState = ELedgeGrabStates::None;
		TargetLedgeData.Reset();
		GrabData.Reset();
		EnterStartedTime = -1.f;
		InactiveTimer = 0.f;
	}

	UFUNCTION()
	void CalculateAnimationOffsets()
	{
		ULocomotionFeatureLedgeGrab LedgeGrabFeature = ULocomotionFeatureLedgeGrab::Get(OwningPlayer);
		if (LedgeGrabFeature == nullptr)
			return;

		RightWristOffset = GetHandWristOffset(n"RightHand", n"Totem", LedgeGrabFeature);
		LeftWristOffset = GetHandWristOffset(n"LeftHand", n"Totem", LedgeGrabFeature);

		Settings.HandOffset = CalculateBoneOffset(n"Totem", n"RightHand", LedgeGrabFeature).ConstrainToPlane(FVector::ForwardVector).Size();
		Settings.HangOffset = CalculateHangOffset(n"Root", n"Totem", LedgeGrabFeature);
	}

	void TickInactiveTimer(float DeltaTime)
	{
		InactiveTimer -= DeltaTime;
	}

	bool AllowedToActivate() const
	{
		return InactiveTimer < 0.f;
	}

	bool IsCurrentState(ELedgeGrabStates InState)
	{
		return CurrentState == InState;
	}

	void SetState(ELedgeGrabStates StateToBe)
	{
		ensure(StateToBe != ELedgeGrabStates::MAX);
		CurrentState = StateToBe;
	}

	void SetStateIfCurrentState(ELedgeGrabStates CheckState, ELedgeGrabStates WantedState)
	{
		if (CheckState == CurrentState)
			SetState(WantedState);
	}

	void SetTargetLedge(FLedgeGrabPhysicalData LedgeData)
	{
		ensure(HasControl());
		TargetLedgeData = LedgeData;
		OwningPlayer.SetCapabilityActionState(LedgeGrabActivationEvents::Grabbing, EHazeActionState::Active);
	}

	bool HasValidTargetLedge() const
	{
		return TargetLedgeData.IsValid();
	}

	bool HasValidLedge() const
	{
		return GrabData.IsValid();
	}

	void StartLedgeGrab(const FLedgeGrabPhysicalData& DataToSet)
	{
		if (HasControl())
			ensure(TargetLedgeData.IsValid());

		GrabData = DataToSet;
		TargetLedgeData = FLedgeGrabPhysicalData();
		UpdateAnimationData();
		FindCallbackComponent();
		CallGrabEvent();
		EnterStartedTime = System::GetGameTimeInSeconds();
	}

	void LetGoOfLedge(ELedgeReleaseType ReleaseType, float InactiveTime = 0.4f)
	{
		CallLetGoEvent(ReleaseType);
		GrabData = FLedgeGrabPhysicalData();
		EnterStartedTime = -1.f;
		InactiveTimer = InactiveTime;
		
		OwningPlayer.SetCapabilityActionState(LedgeGrabActivationEvents::Cooldown, EHazeActionState::Active);
		OwningPlayer.SetCapabilityActionState(LedgeGrabActivationEvents::Grabbing, EHazeActionState::Inactive);
	}
	
	bool PassedEnterDuration() const
	{
		float Dif = System::GetGameTimeInSeconds() - EnterStartedTime;

		return Dif >= Settings.EnterDuration;
	}

	void UpdateAnimationData()
	{
		LedgeGrabAnimationData.LeftHand =  LeftWristOffset * GrabData.LeftHandRelative;
		LedgeGrabAnimationData.RightHand = RightWristOffset * GrabData.RightHandRelative;
		LedgeGrabAnimationData.ActorHangLocation = LedgeGrabData.ActorHangLocation;
	}

	void FindCallbackComponent()
	{
		if (GrabData.LedgeGrabbed == nullptr) 
			return;
		
		if (!GrabData.LedgeGrabbed.IsNetworked())
			return;

		AHazeActor ActorGrabbedOnto = Cast<AHazeActor>(GrabData.LedgeGrabbed.Owner);
		if (ActorGrabbedOnto != nullptr)
			GrabData.LedgeGrabCallbackComponent = UGrabbedCallbackComponent::Get(ActorGrabbedOnto);
	}

	UFUNCTION()
	const FLedgeGrabPhysicalData& GetLedgeGrabData() const property
	{
		return GrabData;
	}

	void CallGrabEvent()
	{
		if (GrabData.LedgeGrabCallbackComponent != nullptr)
			GrabData.LedgeGrabCallbackComponent.GrabActor(OwningPlayer, GrabData.LedgeGrabbed);
	}

	void CallLetGoEvent(ELedgeReleaseType ReleaseType)
	{
		if (GrabData.LedgeGrabCallbackComponent != nullptr)
			GrabData.LedgeGrabCallbackComponent.LetGoOfActor(OwningPlayer, GrabData.LedgeGrabbed, ReleaseType);
	}

	FVector CalculateHangOffset(FName HangPositionBone, FName LedgePositionBone, ULocomotionFeatureLedgeGrab LedgeGrabFeature) const
	{
		FVector Output = CalculateBoneOffset(HangPositionBone, LedgePositionBone, LedgeGrabFeature);
		Output = Output.ConstrainToPlane(FVector::RightVector);

		return Output;
	}

	FVector CalculateBoneOffset(FName FirstBone, FName SecondBone, ULocomotionFeatureLedgeGrab LedgeGrabFeature) const
	{
		if (!ensure(LedgeGrabFeature != nullptr))
			return 0.f;
		
		FTransform FirstBoneTransform;
		FTransform SecondBoneTransform;
		Animation::GetAnimBoneTransform(FirstBoneTransform, LedgeGrabFeature.LedgeHangMH.Sequence, FirstBone);
		Animation::GetAnimBoneTransform(SecondBoneTransform, LedgeGrabFeature.LedgeHangMH.Sequence, SecondBone);

		FTransform Dif = FirstBoneTransform.GetRelativeTransform(SecondBoneTransform);
		return Dif.Location;
	}

	FTransform GetHandWristOffset(FName Wrist, FName Hand, ULocomotionFeatureLedgeGrab LedgeGrabFeature) const
	{
		if (!ensure(LedgeGrabFeature != nullptr))
			return FTransform::Identity;
		
		FTransform HandTransform;
		FTransform WristTransform;
		Animation::GetAnimBoneTransform(HandTransform, LedgeGrabFeature.LedgeHangMH.Sequence, Hand);
		Animation::GetAnimBoneTransform(WristTransform, LedgeGrabFeature.LedgeHangMH.Sequence, Wrist);

		FTransform Output = WristTransform.GetRelativeTransform(HandTransform);
		Output.Location = Output.Location.ConstrainToPlane(FVector::RightVector);
		return Output;
	}

	void SetFollow(FHazeFrameMovement& FrameData)
	{
		if (LedgeGrabData.LedgeGrabbed != nullptr)
			FrameData.SetMoveWithComponent(LedgeGrabData.LedgeGrabbed, LedgeGrabData.ForwardHit.BoneName);

		if (LedgeGrabData.ContactMat != nullptr)
			FrameData.OverrideContactMaterial(LedgeGrabData.ContactMat);
	}

}
