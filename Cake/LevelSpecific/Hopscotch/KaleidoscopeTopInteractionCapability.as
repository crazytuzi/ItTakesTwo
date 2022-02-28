import Cake.LevelSpecific.Hopscotch.KaleidoscopeTopInteraction;
import Vino.Interactions.InteractionComponent;
import Vino.Tutorial.TutorialStatics;

class UKaleidoscopeTopInteractionCapability : UHazeCapability
{
	default CapabilityTags.Add(n"KaleidoscopeTopInteractionCapability");
	default CapabilityTags.Add(n"LevelSpecific");
	default CapabilityTags.Add(n"GameplayAction");

	default CapabilityDebugCategory = n"KaleidoscopeTopInteractionCapability";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	AKaleidoscopeTopInteraction KaleidoscopeTopInteraction;
	USceneComponent AttachComponent;
	UInteractionComponent InteractionComp;

	float TimeSinceActivation = 0.f;

	bool bPushing = false;
	bool bPulling = false;

	bool bHasHiddenCancelPrompt = false;

	UPROPERTY()
	UAnimSequence CodyPushFwdAnim;

	UPROPERTY()
	UAnimSequence CodyPushIdle;

	UPROPERTY()
	UAnimSequence CodyPullAnim;
	
	UPROPERTY()
	UAnimSequence MayPushFwdAnim;

	UPROPERTY()
	UAnimSequence MayPullAnim;

	UPROPERTY()
	UAnimSequence MayPushIdle;

	UAnimSequence PushAnimToPlay;
	UAnimSequence PushIdleAnimToPlay;
	UAnimSequence PullAnimToPlay;

	FVector PoiFocusDirection;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        if (IsActioning(n"PushingKaleidoscopeTop"))
			return EHazeNetworkActivation::ActivateUsingCrumb;
		
		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
       		if (!IsActioning(n"PushingKaleidoscopeTop"))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

 		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		TimeSinceActivation = 0.f;
		KaleidoscopeTopInteraction = Cast<AKaleidoscopeTopInteraction>(GetAttributeObject(n"KaleidoscopeTopInteraction"));
		InteractionComp = Cast<UInteractionComponent>(GetAttributeObject(n"InteractionComp"));
		AttachComponent = Cast<USceneComponent>(GetAttributeObject(n"AttachComp"));

		FTutorialPrompt UpDownTutorialPrompt;
		UpDownTutorialPrompt.DisplayType = ETutorialPromptDisplay::LeftStick_UpDown;
		ShowTutorialPrompt(Player, UpDownTutorialPrompt, this);

		ShowCancelPrompt(Player, this);	
		
		KaleidoscopeTopInteraction.UpdatePlayerArray(Player, true);
		Player.BlockCapabilities(n"Movement", this);
		Player.BlockCapabilities(CapabilityTags::Interaction, this);
		Player.BlockCapabilities(CapabilityTags::TotemMovement, this);
		Player.BlockCapabilities(CapabilityTags::Collision, this);
		Player.BlockMovementSyncronization(this);
		Player.AttachToComponent(AttachComponent, AttachmentRule = EAttachmentRule::KeepWorld);
		Player.SmoothSetLocationAndRotation(AttachComponent.WorldLocation, AttachComponent.WorldRotation);

		FHazeCameraBlendSettings Blend;
		Blend.BlendTime = 1.5f;
		Player.ApplyCameraOffsetOwnerSpace(FVector(-250.f, -250.f, 250.f), Blend, this);

		bHasHiddenCancelPrompt = false;
		PushAnimToPlay = Player == Game::GetCody() ? CodyPushFwdAnim : MayPushFwdAnim;
		PushIdleAnimToPlay = Player == Game::GetCody() ? CodyPushIdle : MayPushIdle;
		PullAnimToPlay = Player == Game::GetCody() ? CodyPullAnim : MayPullAnim;

		if (Player.HasControl())
			NetPlayPushAnim(PushIdleAnimToPlay);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		KaleidoscopeTopInteraction.UpdatePlayerArray(Player, false);
		Player.UnblockCapabilities(n"Movement", this);
		Player.UnblockCapabilities(CapabilityTags::Interaction, this);
		Player.UnblockCapabilities(CapabilityTags::TotemMovement, this);
		Player.UnblockCapabilities(CapabilityTags::Collision, this);
		Player.UnblockMovementSyncronization(this);
		Player.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		KaleidoscopeTopInteraction.SetInteractionPointEnabled(InteractionComp, true);

		RemoveTutorialPromptByInstigator(Player, this);
		
		if (!bHasHiddenCancelPrompt)
			RemoveCancelPromptByInstigator(Player, this);

		Player.ClearPointOfInterestByInstigator(this);
		Player.ClearCameraOffsetOwnerSpaceByInstigator(this);
		Player.StopAllSlotAnimations();

		Player.ConsumeButtonInputsRelatedTo(ActionNames::Cancel);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		TimeSinceActivation += DeltaTime;
		FVector2D Input = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw);

		KaleidoscopeTopInteraction.AddPlayerInput(Player, Input.Y);

		if (Player.HasControl())
		{
			if (Input.Y == 0 && (bPushing || bPulling))
			{
				bPushing = false;
				bPulling = false;
				NetPlayPushAnim(PushIdleAnimToPlay);
			}  
			if (Input.Y > 0.f && !bPushing)
			{
				bPushing = true;
				bPulling = false;
				NetPlayPushAnim(PushAnimToPlay);
			}

			if (Input.Y < 0.f && !bPulling)
			{
				bPulling = true;
				bPushing = false;
				NetPlayPushAnim(PullAnimToPlay);
			}
		}

		PoiFocusDirection = FVector(Player.GetActorLocation() + FVector(Player.GetActorForwardVector() * 5000.f));
		FHazePointOfInterest Poi;
		Poi.FocusTarget.Type = EHazeFocusTargetType::WorldOffsetOnly;
		Poi.FocusTarget.WorldOffset = PoiFocusDirection;
		FHazeCameraClampSettings Clamps;
		Clamps.ClampYawLeft = 80.f;
		Clamps.bUseClampYawLeft = true;
		Clamps.ClampYawRight = 80.f;
		Clamps.bUseClampYawRight = true;
		Poi.Clamps = Clamps;
		FHazeCameraBlendSettings Blend;
		Blend.BlendTime = 0.5f;
		Poi.Blend = Blend;
		Player.ApplyClampedPointOfInterest(Poi, this);

		if (!bHasHiddenCancelPrompt && KaleidoscopeTopInteraction.bBothPlayersInteracting)
		{
			bHasHiddenCancelPrompt = true;
			RemoveCancelPromptByInstigator(Player, this);
		}

		if (IsActioning(ActionNames::Cancel) && !KaleidoscopeTopInteraction.bBothPlayersInteracting && TimeSinceActivation >= 0.5f)
			Player.SetCapabilityActionState(n"PushingKaleidoscopeTop", EHazeActionState::Inactive);
	}

	UFUNCTION(NetFunction)
	void NetPlayPushAnim(UAnimSequence NewAnimToPlay)
	{
		Player.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(), NewAnimToPlay, true);
	}
}