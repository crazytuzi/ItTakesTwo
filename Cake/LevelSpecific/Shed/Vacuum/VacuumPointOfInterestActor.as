class AVacuumPointOfInterestActor : AHazeActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    UArrowComponent Direction;
    default Direction.ArrowSize = 2.f;

    UFUNCTION()
    void ApplyVacuumPointOfInterest(AHazePlayerCharacter Player, float Duration, float BlendTime)
    {
        FHazePointOfInterest PoISettings;
        PoISettings.FocusTarget.Actor = this;
		PoISettings.FocusTarget.Component = Direction;
        PoISettings.bMatchFocusDirection = true;
        PoISettings.Blend.BlendTime = BlendTime;
        PoISettings.Duration = Duration;

        Player.ApplyPointOfInterest(PoISettings, Player, EHazeCameraPriority::Script);
    }
}