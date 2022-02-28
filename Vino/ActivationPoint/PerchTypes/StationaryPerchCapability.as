// 
// import Vino.Movement.MovementSystemTags;
// import Vino.Movement.Perch.PerchParams;

// class UStationaryPerchCapability : UHazeCapability
// {	
// 	default CapabilityTags.Add(PerchTags::Perch);

// 	default TickGroup = ECapabilityTickGroups::LastMovement;
// 	default TickGroupOrder = 150;

// 	default CapabilityDebugCategory = CapabilityTags::Movement;

//  	AHazePlayerCharacter PlayerOwner;
// 	UHazePlayerPointActivationComponent GrabPerchComponent;
// 	UHazeBaseMovementComponent MovementComponent;
// 	FHazePlaySlotAnimationParams SlotAnim;

// 	UFUNCTION(BlueprintOverride)
// 	void Setup(FCapabilitySetupParams SetupParams)
// 	{
// 		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
// 		GrabPerchComponent = UHazePlayerPointActivationComponent::Get(PlayerOwner);
// 		MovementComponent = UHazeBaseMovementComponent::Get(PlayerOwner);
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void PreTick(float DeltaTime)
// 	{

// 	}

//     UFUNCTION(BlueprintOverride)
// 	EHazeNetworkActivation ShouldActivate() const
// 	{
// 		UHazeActivationPoint ActivePerch = GrabPerchComponent.GetCurrentPerch();
// 		if(ActivePerch == nullptr)
// 			return EHazeNetworkActivation::DontActivate;

// 		if(GrabPerchComponent.CurrentActivationInstigatorIs())
// 			return EHazeNetworkActivation::DontActivate;

// 		if(GrabPerchComponent.GetPerchTravelType() != EHazeTotemTravelType::Done)
// 			return EHazeNetworkActivation::DontActivate;

// 		return EHazeNetworkActivation::ActivateLocal;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	EHazeNetworkDeactivation ShouldDeactivate() const
// 	{
// 		if(!GrabPerchComponent.CurrentActivationInstigatorIs())
// 			return EHazeNetworkDeactivation::DeactivateLocal;

// 		if(WasActionStarted(ActionNames::Cancel))
// 			return EHazeNetworkDeactivation::DeactivateFromControl;

// 		if(WasActionStarted(ActionNames::MovementJump))
// 			return EHazeNetworkDeactivation::DeactivateFromControl;

// 		if(WasActionStarted(ActionNames::MovementDash))
// 			return EHazeNetworkDeactivation::DeactivateFromControl;

// 		return EHazeNetworkDeactivation::DontDeactivate;
// 	}
	 
// 	UFUNCTION(BlueprintOverride)
// 	void OnActivated(FCapabilityActivationParams ActivationParams)
// 	{	
// 		PlayerOwner.BlockCapabilities(CapabilityTags::Movement, this);
// 		PlayerOwner.BlockMovementSyncronization(this);
// 		GrabPerchComponent.GrabCurrentPerch(this);
// 		GrabPerchComponent.SetPerchTravelType(EHazeTotemTravelType::Done);
// 		PlayerOwner.SetCapabilityActionState(PerchTags::BlockPerchTimeDilation, EHazeActionState::Active);
// 		PlayerOwner.SetCapabilityActionState(n"ResetAirDash", EHazeActionState::Active);
// 		PlayerOwner.SetCapabilityActionState(PerchTags::ForcePerchSearch, EHazeActionState::Active);
		

// 		UHazeLocomotionFeatureBase FoundFeature;
// 		PlayerOwner.GetFeatureFromTag(n"Perch", FoundFeature);
// 		UHazePerchComponentFeature PerchFeature = Cast<UHazePerchComponentFeature>(FoundFeature);
// 		if(PerchFeature != nullptr)
// 		{
// 			FHazePlaySequenceData Sequence;
// 			PerchFeature.GetAnimationData(EHazeTotemTravelType::Done, Sequence);
// 			SlotAnim.Animation = Sequence.Sequence;
// 			SlotAnim.PlayRate = Sequence.PlayRate;
// 			SlotAnim.bLoop = true;
// 			PlayerOwner.PlaySlotAnimation(SlotAnim);
// 		}
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void ControlPreDeactivation(FCapabilityDeactivationSyncParams& DeactivationParams)
// 	{
// 		if(WasActionStarted(ActionNames::Cancel))
// 			DeactivationParams.AddActionState(n"LeaveWithCancel");
// 		else if(WasActionStarted(ActionNames::MovementJump))
// 			DeactivationParams.AddActionState(n"LeaveWithJump");
// 		else if(WasActionStarted(ActionNames::MovementDash))
// 			DeactivationParams.AddActionState(n"LeaveWithDash");
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
// 	{	
// 		PlayerOwner.StopAnimationByAsset(SlotAnim.Animation);
// 		PlayerOwner.RootOffsetComponent.FreezeAndResetWithTime(0.2f);
// 		if(DeactivationParams.GetActionState(n"LeaveWithCancel"))
// 		{
// 			FVector Impulse = MovementComponent.GetWorldUp() * 1000.f;
// 			Impulse += PlayerOwner.GetActorForwardVector() * 400.f;
// 			MovementComponent.AddImpulse(Impulse);
// 		}
// 		else if(DeactivationParams.GetActionState(n"LeaveWithJump"))
// 		{
// 			PlayerOwner.SetCapabilityActionState(n"ForceJump", EHazeActionState::Active);
// 		}
// 		else if(DeactivationParams.GetActionState(n"LeaveWithDash"))
// 		{
// 			PlayerOwner.SetCapabilityActionState(n"ForceDash", EHazeActionState::Active);	
// 		}

// 		PlayerOwner.UnblockCapabilities(CapabilityTags::Movement, this);
// 		PlayerOwner.UnblockMovementSyncronization(this);
// 		GrabPerchComponent.ReleaseCurrentPerch(this);
// 		PlayerOwner.SetCapabilityActionState(PerchTags::BlockPerchTimeDilation, EHazeActionState::Inactive);
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void TickActive(float DeltaTime)
// 	{
// 		if(MovementComponent.CanCalculateMovement())
// 		{
// 			FHazeFrameMovement MoveRequest = MovementComponent.MakeFrameMovement(n"StationaryPerch");
// 			UHazeActivationPoint Perch = GrabPerchComponent.GetCurrentPerch();
// 			FTransform GrabTransform = Perch.GetGrabTransform(PlayerOwner);
// 			MovementComponent.SetTargetFacingRotation(GrabTransform.GetRotation());
// 			MoveRequest.ApplyTargetRotationDelta();
// 			MovementComponent.Move(MoveRequest);

// 			FHazeRequestLocomotionData AnimationRequest;
// 			AnimationRequest.AnimationTag = GrabPerchComponent.GetPerchFeatureName();
// 			AnimationRequest.SubAnimationTag = GrabPerchComponent.GetCurrentSubAnimationTag();
// 			PlayerOwner.RequestLocomotion(AnimationRequest);
// 		}
// 	}

// 	UFUNCTION(BlueprintOverride)	
// 	FString GetDebugString()
// 	{
// 		FString Str = "";
// 		return Str;
// 	} 
// };
