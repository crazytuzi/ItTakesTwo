import Cake.LevelSpecific.Hopscotch.RotatingKaleidoscope;
import Cake.LevelSpecific.Hopscotch.KaleidoscopeTopInteraction;
import Vino.Tutorial.TutorialPrompt;
import Vino.Tutorial.TutorialStatics;

class URotatingKalaidoscopeCapability : UHazeCapability
{
	default CapabilityTags.Add(n"LevelSpecific");
	default CapabilityTags.Add(n"GameplayAction");
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
    UHazeBaseMovementComponent Movement;
    ARotatingKaleidoscope RotatingKaleidoscope;
	USceneComponent AttachComponent;

	AKaleidoscopeTopInteraction KaleidoInteraction;

	bool bPushing = false;
	bool bPulling = false;

	float TimeSinceActivation = 0.f;

	UPROPERTY()
	UAnimSequence CodyPushFwdAnim;

	UPROPERTY()
	UAnimSequence CodyPushIdle;

	UPROPERTY()
	UAnimSequence COdyPullAnim;
	
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
        Movement = UHazeBaseMovementComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        if(IsActioning(n"PushingKaleidoscope"))
        {
            return EHazeNetworkActivation::ActivateUsingCrumb;
        }
        else
            return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
        if(!IsActioning(n"PushingKaleidoscope"))
            return EHazeNetworkDeactivation::DeactivateUsingCrumb;
        else    
            return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
        TimeSinceActivation = 0.f;
		Player.BlockCapabilities(n"Movement", this);
		Player.BlockCapabilities(CapabilityTags::Interaction, this);
		Player.BlockCapabilities(CapabilityTags::TotemMovement, this);
		Player.BlockCapabilities(CapabilityTags::Collision, this);
		Player.BlockMovementSyncronization(this);
        RotatingKaleidoscope = Cast<ARotatingKaleidoscope>(GetAttributeObject(n"RotatingKaleidoscope"));
		AttachComponent = Cast<USceneComponent>(GetAttributeObject(n"AttachComp"));
        Player.AttachToComponent(AttachComponent, AttachmentRule = EAttachmentRule::SnapToTarget);

		FTutorialPrompt UpDownTutorialPrompt;
		UpDownTutorialPrompt.DisplayType = ETutorialPromptDisplay::LeftStick_UpDown;
		ShowTutorialPrompt(Player, UpDownTutorialPrompt, this);

		ShowCancelPrompt(Player, this);	

		FHazeCameraBlendSettings Blend;
		Blend.BlendTime = 1.5f;
		Player.ApplyCameraOffsetOwnerSpace(FVector(-250.f, -250.f, 250.f), Blend, this);

		PushAnimToPlay = Player == Game::GetCody() ? CodyPushFwdAnim : MayPushFwdAnim;
		PushIdleAnimToPlay = Player == Game::GetCody() ? CodyPushIdle : MayPushIdle;
		PullAnimToPlay = Player == Game::GetCody() ? COdyPullAnim : MayPullAnim;

		if (Player.HasControl())
			NetPlayPushAnim(PushIdleAnimToPlay);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
        Player.UnblockCapabilities(n"Movement", this);
		Player.UnblockCapabilities(CapabilityTags::Interaction, this);
		Player.UnblockCapabilities(CapabilityTags::TotemMovement, this);
		Player.UnblockCapabilities(CapabilityTags::Collision, this);
        Player.SetCapabilityActionState(n"PushingKaleidoscope", EHazeActionState::Inactive);
		Player.UnblockMovementSyncronization(this);
        Player.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		RotatingKaleidoscope.StoppedInteracting();

		RemoveTutorialPromptByInstigator(Player, this);
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

        RotatingKaleidoscope.SetPlayerInput(Player, -Input.Y);

		if (Player.HasControl())
		{
			if (Input.Y == 0 && (bPushing || bPulling))
			{
				bPushing = false;
				bPulling = false;
				NetPlayPushAnim(PushIdleAnimToPlay);
			}  
			if (Input.Y > .15f && !bPushing)
			{
				bPushing = true;
				bPulling = false;
				NetPlayPushAnim(PushAnimToPlay);
			}

			if (Input.Y < -.15f && !bPulling)
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

		if (IsActioning(ActionNames::Cancel) && TimeSinceActivation >= .5f)
			Player.SetCapabilityActionState(n"PushingKaleidoscope", EHazeActionState::Inactive);
	}

	UFUNCTION(NetFunction)
	void NetPlayPushAnim(UAnimSequence NewAnimToPlay)
	{
		Player.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(), NewAnimToPlay, true);
	}
}