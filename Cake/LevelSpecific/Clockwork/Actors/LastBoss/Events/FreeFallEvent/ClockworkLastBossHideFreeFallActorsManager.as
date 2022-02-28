import Cake.LevelSpecific.Clockwork.Actors.LastBoss.Events.FreeFallEvent.ClockworkLastBossFreeFallBar;
import Cake.LevelSpecific.Clockwork.Actors.LastBoss.Events.FreeFallEvent.ClockworkLastBossFreeFallCog;
class AClockworkLastBossHideFreeFallActorsManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	UPROPERTY()
	TArray<AActor> Actors;

	UFUNCTION(CallInEditor, NotBlueprintCallable)
	void GetFreeFallActors()
	{
		TArray<AActor> Cogs;
		Gameplay::GetAllActorsOfClass(AClockworkLastBossFreeFallCog::StaticClass(), Cogs);
		
		for (auto Actor : Cogs)
			Actors.Add(Actor);

		TArray<AActor> Bars;
		Gameplay::GetAllActorsOfClass(AClockworkLastBossFreeFallBar::StaticClass(), Bars);
		
		for (auto Actor : Bars)
			Actors.Add(Actor);
	}

	UFUNCTION()
	void SetFreeFallActorsHidden(bool bShouldBeHidden)
	{
		for (auto Actor : Actors)
		{
			if (Actor != nullptr)
			{
				Actor.SetActorHiddenInGame(bShouldBeHidden);
			}
		}
	}
}