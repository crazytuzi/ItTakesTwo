struct FThreeShotAnimationSettings
{
    UPROPERTY(Category = "Cody Animation")
    UAnimSequence Cody_StartAnimation;

    UPROPERTY(Category = "Cody Animation")
    UAnimSequence Cody_MHAnimation;

    UPROPERTY(Category = "Cody Animation")
    UAnimSequence Cody_EndAnimation;

    UPROPERTY(Category = "May Animation")
    UAnimSequence May_StartAnimation;

    UPROPERTY(Category = "May Animation")
    UAnimSequence May_MHAnimation;

    UPROPERTY(Category = "May Animation")
    UAnimSequence May_EndAnimation;

    /* If set, the player can manually cancel the three shot during its MH. */
    UPROPERTY(Category = "Three Shot Animation")
    bool bCanPlayerCancel = true;

    /* Whether the player can cancel the three shot during the enter animation or not. */
    UPROPERTY(Category = "Three Shot Animation", Meta = (EditCondition = "bCanPlayerCancel", EditConditionHides), AdvancedDisplay)
    bool bCanCancelDuringEnter = false;

    UPROPERTY(Category = "Three Shot Animation", AdvancedDisplay)
    float BlendTime = 0.2f;

    UPROPERTY(Category = "Three Shot Animation", AdvancedDisplay)
    EHazeBlendType BlendType = EHazeBlendType::BlendType_Inertialization;

    UAnimSequence GetStartAnimation(AHazeActor Actor) const
    {
        return ChooseAnimation(Actor, Cody_StartAnimation, May_StartAnimation);
    }

    UAnimSequence GetMHAnimation(AHazeActor Actor) const
    {
        return ChooseAnimation(Actor, Cody_MHAnimation, May_MHAnimation);
    }

    UAnimSequence GetEndAnimation(AHazeActor Actor) const
    {
        return ChooseAnimation(Actor, Cody_EndAnimation, May_EndAnimation);
    }

    private UAnimSequence ChooseAnimation(AHazeActor Actor, UAnimSequence CodyAnimation, UAnimSequence MayAnimation) const
    {
        AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Actor);
        if (Player == nullptr)
            return CodyAnimation != nullptr ? CodyAnimation : MayAnimation;
        
        if (Player.IsCody())
            return CodyAnimation;
        else
            return MayAnimation;
    }
};

struct FThreeShotAnimationEvents
{
    UPROPERTY()
    FHazeAnimationDelegate OnStartBlendedIn;

    UPROPERTY()
    FHazeAnimationDelegate OnStartBlendingOut;

    UPROPERTY()
    FHazeAnimationDelegate OnMHBlendedIn;

    UPROPERTY()
    FHazeAnimationDelegate OnMHTick;

    UPROPERTY()
    FHazeAnimationDelegate OnMHBlendingOut;

    UPROPERTY()
    FHazeAnimationDelegate OnEndBlendedIn;

    UPROPERTY()
    FHazeAnimationDelegate OnEndBlendingOut;
};

/* Play a standard Three-Shot animation on the specified actor. */
UFUNCTION(NotBlueprintCallable, Category = "Animation")
UThreeShotAnimation PlayThreeShotAnimation(AHazeActor Target, FThreeShotAnimationSettings Settings, FThreeShotAnimationEvents Events)
{
    auto Component = UThreeShotAnimationComponent::GetOrCreate(Target);

    UThreeShotAnimation AnimHandle = UThreeShotAnimation();
    AnimHandle.Actor = Target;
    AnimHandle.Component = Component;
    AnimHandle.Settings = Settings;
    AnimHandle.Events = Events;

    Component.PlayThreeShot(AnimHandle);
    return AnimHandle;
}

/* Play a standard Three-Shot animation on the specified actor. */
UFUNCTION(DisplayName = "Play Three Shot Animation", Category = "Animation", meta = (UseExecPins, ReturnDisplayName = "Animation Handle"))
UThreeShotAnimation BP_PlayThreeShotAnimation(AHazeActor Target, FThreeShotAnimationSettings Settings,
    FHazeAnimationDelegate OnStartBlendedIn,
    FHazeAnimationDelegate OnStartBlendingOut,
    FHazeAnimationDelegate OnMHBlendedIn,
    FHazeAnimationDelegate OnMHTick,
    FHazeAnimationDelegate OnMHBlendingOut,
    FHazeAnimationDelegate OnEndBlendedIn,
    FHazeAnimationDelegate OnEndBlendingOut
)
{
    auto Component = UThreeShotAnimationComponent::GetOrCreate(Target);

    FThreeShotAnimationEvents Events;
    Events.OnStartBlendedIn = OnStartBlendedIn;
    Events.OnStartBlendingOut = OnStartBlendingOut;
    Events.OnMHBlendedIn = OnMHBlendedIn;
    Events.OnMHTick = OnMHTick;
    Events.OnMHBlendingOut = OnMHBlendingOut;
    Events.OnEndBlendedIn = OnEndBlendedIn;
    Events.OnEndBlendingOut = OnEndBlendingOut;

    UThreeShotAnimation AnimHandle = UThreeShotAnimation();
    AnimHandle.Actor = Target;
    AnimHandle.Component = Component;
    AnimHandle.Settings = Settings;
    AnimHandle.Events = Events;

    Component.PlayThreeShot(AnimHandle);
    return AnimHandle;
}

/* End a currently playing Three-Shot animation manually. */
UFUNCTION(Category = "Animation")
void EndThreeShotAnimation(UThreeShotAnimation AnimationHandle)
{
    if (AnimationHandle != nullptr)
        AnimationHandle.End();
}

enum EThreeShotState
{
    Started,
    StartBlendedIn,
    StartBlendingOut,
    MHBlendedIn,
    MHBlendingOut,
    EndBlendedIn,
    EndBlendingOut,
    Finished
};

class UThreeShotAnimation
{
    EThreeShotState State = EThreeShotState::Started;
    AHazeActor Actor;
    UThreeShotAnimationComponent Component;
    FThreeShotAnimationSettings Settings;
    FThreeShotAnimationEvents Events;
    UHazeCapability EndCapability;
	int AnimationId = -1;

    void ProgressToState(EThreeShotState NewState)
    {
        if (NewState >= EThreeShotState::StartBlendedIn && State < EThreeShotState::StartBlendedIn)
            Events.OnStartBlendedIn.ExecuteIfBound();
        if (NewState >= EThreeShotState::StartBlendingOut && State < EThreeShotState::StartBlendingOut)
            Events.OnStartBlendingOut.ExecuteIfBound();
        if (NewState >= EThreeShotState::MHBlendedIn && State < EThreeShotState::MHBlendedIn)
            Events.OnMHBlendedIn.ExecuteIfBound();
        if (NewState >= EThreeShotState::MHBlendingOut && State < EThreeShotState::MHBlendingOut)
            Events.OnMHBlendingOut.ExecuteIfBound();
        if (NewState >= EThreeShotState::EndBlendedIn && State < EThreeShotState::EndBlendedIn)
            Events.OnEndBlendedIn.ExecuteIfBound();
        if (NewState >= EThreeShotState::EndBlendingOut && State < EThreeShotState::EndBlendingOut)
            Events.OnEndBlendingOut.ExecuteIfBound();
		if (NewState > State)
			State = NewState;
    }

    void Start()
    {
        PlayStartAnimation();
    }

    void PlayStartAnimation()
    {
        FHazeAnimationDelegate BlendedIn;
        BlendedIn.BindUFunction(this, n"StartBlendedIn");

        FHazeAnimationDelegate BlendingOut;
        BlendingOut.BindUFunction(this, n"StartBlendingOut");

        if (Settings.GetStartAnimation(Actor) != nullptr)
        {
            Actor.PlaySlotAnimation(
                OnBlendedIn = BlendedIn,
                OnBlendingOut = BlendingOut,
                Animation = Settings.GetStartAnimation(Actor),
                BlendType = Settings.BlendType,
                BlendTime = Settings.BlendTime);
        }
        else
        {
            BlendedIn.ExecuteIfBound();
            BlendingOut.ExecuteIfBound();
        }
    }

    UFUNCTION(NotBlueprintCallable)
    void StartBlendedIn()
    {
		ProgressToState(EThreeShotState::StartBlendedIn);
    }

    UFUNCTION(NotBlueprintCallable)
    void StartBlendingOut()
    {
        if (State < EThreeShotState::StartBlendingOut)
        {
            ProgressToState(EThreeShotState::StartBlendingOut);
            PlayMHAnimation();
        }
    }

    void PlayMHAnimation()
    {
        FHazeAnimationDelegate BlendedIn;
        BlendedIn.BindUFunction(this, n"MHBlendedIn");

        FHazeAnimationDelegate BlendingOut;

        if (Settings.GetMHAnimation(Actor) != nullptr)
        {
            Actor.PlaySlotAnimation(
                OnBlendedIn = BlendedIn,
                OnBlendingOut = BlendingOut,
                Animation = Settings.GetMHAnimation(Actor),
                BlendType = Settings.BlendType,
                BlendTime = Settings.BlendTime,
                bLoop = true);
        }
        else
        {
            BlendedIn.ExecuteIfBound();
        }
    }

    UFUNCTION(NotBlueprintCallable)
    void MHBlendedIn()
    {
		ProgressToState(EThreeShotState::MHBlendedIn);
    }

    void PlayEndAnimation()
    {
        FHazeAnimationDelegate BlendedIn;
        BlendedIn.BindUFunction(this, n"EndBlendedIn");

        FHazeAnimationDelegate BlendingOut;
        BlendingOut.BindUFunction(this, n"EndBlendingOut");

        if (Settings.GetEndAnimation(Actor) != nullptr)
        {
            Actor.PlaySlotAnimation(
                OnBlendedIn = BlendedIn,
                OnBlendingOut = BlendingOut,
                Animation = Settings.GetEndAnimation(Actor),
                BlendType = Settings.BlendType,
                BlendTime = Settings.BlendTime);
        }
        else
        {
			Actor.StopAnimation(BlendTime = Settings.BlendTime);
            BlendedIn.ExecuteIfBound();
            BlendingOut.ExecuteIfBound();
        }
    }

    UFUNCTION(NotBlueprintCallable)
    void EndBlendedIn()
    {
		ProgressToState(EThreeShotState::EndBlendedIn);
    }

    UFUNCTION(NotBlueprintCallable)
    void EndBlendingOut()
    {
		ProgressToState(EThreeShotState::EndBlendingOut);
        RemoveFromComponent();
    }

    void End()
    {
        if (State < EThreeShotState::MHBlendingOut)
        {
            ProgressToState(EThreeShotState::MHBlendingOut);
            PlayEndAnimation();
        }
    }

    void ForceStop()
    {
		ProgressToState(EThreeShotState::Finished);
        Actor.StopAnimation(BlendTime = Settings.BlendTime);
        RemoveFromComponent();
    }

    void RemoveFromComponent()
    {
        if (Component != nullptr && Component.CurrentAnimation == this)
            Component.CurrentAnimation = nullptr;

		auto Player = Cast<AHazePlayerCharacter>(Actor);
		if (Player != nullptr)
		{
			Player.RemoveCapabilitySheet(Player.DefaultAnimationSheet, this);
			if (Component != nullptr)
				Player.TriggerMovementTransition(Component, n"FinishThreeShot");
		}
    }
};

class UThreeShotAnimationComponent : UActorComponent
{
    UThreeShotAnimation CurrentAnimation;
	int NextAnimationId = 0;

	TArray<int> PendingAnimationCancels;

	default PrimaryComponentTick.bStartWithTickEnabled = false;

    void PlayThreeShot(UThreeShotAnimation AnimHandle)
    {
        if (CurrentAnimation != nullptr)
            CurrentAnimation.ForceStop();

        CurrentAnimation = AnimHandle;
		CurrentAnimation.AnimationId = NextAnimationId++;

		auto Player = Cast<AHazePlayerCharacter>(Owner);
		if (Player != nullptr)
		{
			Player.TriggerMovementTransition(this, n"StartThreeShot");
			Player.AddCapabilitySheet(Player.DefaultAnimationSheet, EHazeCapabilitySheetPriority::Animation, CurrentAnimation);
		}

        CurrentAnimation.Start();
		SetComponentTickEnabled(true);
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        // Tick the current animation's mh tick if needed
        if (CurrentAnimation != nullptr)
        {
            if (CurrentAnimation.State >= EThreeShotState::MHBlendedIn
             && CurrentAnimation.State <= EThreeShotState::MHBlendingOut)
            {
                CurrentAnimation.Events.OnMHTick.ExecuteIfBound();
            }

			if (!HasControl() && PendingAnimationCancels.Contains(CurrentAnimation.AnimationId))
			{
				PendingAnimationCancels.Remove(CurrentAnimation.AnimationId);
				CurrentAnimation.End();
			}
        }
		else
		{
			SetComponentTickEnabled(false);
		}
    }

    bool HasCancelableThreeShots()
    {
        if (CurrentAnimation == nullptr)
            return false;
        if (!CurrentAnimation.Settings.bCanPlayerCancel)
            return false;
        if (!CurrentAnimation.Settings.bCanCancelDuringEnter)
		{
			if (CurrentAnimation.State < EThreeShotState::StartBlendingOut)
				return false;
		}
		if (CurrentAnimation.State >= EThreeShotState::MHBlendingOut)
			return false;
        return true;
    }

    UFUNCTION(NetFunction)
    void NetCancelThreeShots(int AnimationId)
    {
        if (CurrentAnimation != nullptr && CurrentAnimation.AnimationId >= AnimationId)
		{
            CurrentAnimation.End();
		}
		else if (AnimationId >= NextAnimationId)
		{
			PendingAnimationCancels.Add(AnimationId);
		}
    }

	UFUNCTION(BlueprintOverride)
	void OnResetComponent(EComponentResetType ResetType)
	{
		if (CurrentAnimation != nullptr)
			CurrentAnimation.ForceStop();

		if (ResetType == EComponentResetType::PostRestart)
		{
			PendingAnimationCancels.Empty();
			NextAnimationId = 0;
		}
	}

    UFUNCTION(NetFunction)
    void NetForceStopThreeShots()
    {
        if (CurrentAnimation != nullptr)
            CurrentAnimation.ForceStop();
    }
};