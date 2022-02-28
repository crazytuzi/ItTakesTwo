import Cake.Weapons.AimTargetIndicator.AimTargetIndicatorWidget;
class UAimTargetIndicatorComponent : UActorComponent
{
	TArray<USceneComponent> AimTargetIndicators;
	bool bShouldBeVisible = false;
}

class UAimTargetIndicatorWidgetComponent : UActorComponent
{
	UPROPERTY(Category = "Widgets")
	TSubclassOf<UAimTargetIndicatorWidget> WidgetClass;
}

void AddAimIndicatorTarget(AHazePlayerCharacter Player, USceneComponent Target)
{
	auto IndicatorComp = UAimTargetIndicatorComponent::GetOrCreate(Player);
	IndicatorComp.AimTargetIndicators.AddUnique(Target);
}

void RemoveAimIndicatorTarget(AHazePlayerCharacter Player, USceneComponent Target)
{
	auto IndicatorComp = UAimTargetIndicatorComponent::GetOrCreate(Player);
	IndicatorComp.AimTargetIndicators.Remove(Target);
}

void SetAimTargetIndicatorVisible(AHazePlayerCharacter Player, bool bIsVisible)
{
	UAimTargetIndicatorComponent::GetOrCreate(Player).bShouldBeVisible = bIsVisible;
}