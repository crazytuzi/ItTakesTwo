
struct FOneShotAnimationSettings
{
    UPROPERTY(Category = "One Shot Animation")
    UAnimSequence CodyAnimation;

    UPROPERTY(Category = "One Shot Animation")
    UAnimSequence MayAnimation;

    UPROPERTY(Category = "One Shot Animation", AdvancedDisplay)
    float BlendTime = 0.2f;

    UPROPERTY(Category = "One Shot Animation", AdvancedDisplay)
    EHazeBlendType BlendType = EHazeBlendType::BlendType_Inertialization;

    UAnimSequence GetAnimationFor(AHazeActor Actor) const
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

struct FOneShotAnimationEvents
{
    UPROPERTY()
    FHazeAnimationDelegate OnBlendedIn;

    UPROPERTY()
    FHazeAnimationDelegate OnBlendingOut;
};

UFUNCTION(Category = "Animation", Meta = (AutoSplit = "Settings, Events"))
void PlayOneShotAnimation(AHazeActor Target, FOneShotAnimationSettings Settings, FOneShotAnimationEvents Events)
{
    if (Settings.GetAnimationFor(Target) != nullptr)
    {
        Target.PlayEventAnimation(
            OnBlendedIn = Events.OnBlendedIn,
            OnBlendingOut = Events.OnBlendingOut,
            Animation = Settings.GetAnimationFor(Target),
            BlendType = Settings.BlendType,
            BlendTime = Settings.BlendTime);
    }
    else
    {
        Events.OnBlendedIn.ExecuteIfBound();
        Events.OnBlendingOut.ExecuteIfBound();
    }
}