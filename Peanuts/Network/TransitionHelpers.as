
UFUNCTION(Category = "Network")
void TriggerMovementTransitionWithSmoothLerp(AHazePlayerCharacter Player, UObject Instigator)
{
	Player.TriggerMovementTransition(Instigator);

	UHazeCrumbComponent CrumbComp = UHazeCrumbComponent::Get(Player);
	Player.RootOffsetComponent.FreezeAndResetWithTime(0.2f + CrumbComp.PredictionLag);
}