import Cake.LevelSpecific.Clockwork.Actors.LastBoss.Events.ExplosionEvent.ClockworkLastBossExplosionHazardousDebris;
import Cake.LevelSpecific.Clockwork.Actors.LastBoss.Events.ExplosionEvent.ClockworkLastBossExplosionFX;
import Cake.LevelSpecific.Clockwork.Widgets.TimeControlAbilityWidget;
import Cake.LevelSpecific.Clockwork.Actors.LastBoss.Events.ExplosionEvent.ClockworkLastBossExplosionActorBase;
import Cake.LevelSpecific.Clockwork.Actors.LastBoss.ClockworkLastBossStuckCog;
import Cake.LevelSpecific.Clockwork.Actors.LastBoss.Events.ExplosionEvent.ClockworkLastBossScrubbedSpotlightController;
import Cake.LevelSpecific.Clockwork.TimeControlMechanic.TimeControlComponent;

namespace ClockworkLastBoss
{
	UFUNCTION()
	void SetNewClockworkSequenceToScrub(AHazePlayerCharacter TargetPlayer, AHazeLevelSequenceActor SequenceActor, float ScrubMin, float ScrubMax)
	{
		UClockworkLastBossCodyExplosionComponent Comp = UClockworkLastBossCodyExplosionComponent::Get(TargetPlayer);

		if (Comp != nullptr)
		{
			Comp.CurrentSequenceToControl = SequenceActor;
			Comp.ScrubValueMin = ScrubMin;
			Comp.ScrubValueMax = ScrubMax;
		}
	}

	UFUNCTION()
	void SetNewExplosionScrubValueMinMax(AHazePlayerCharacter TargetPlayer, float Min, float Max)
	{
		UClockworkLastBossCodyExplosionComponent Comp = UClockworkLastBossCodyExplosionComponent::Get(TargetPlayer);

		if (Comp != nullptr)
		{
			Comp.ScrubValueMin = Min;
			Comp.ScrubValueMax = Max;
		}
	}

	UFUNCTION()
	void SetExplosionTimeScrubWidget(AHazePlayerCharacter TargetPlayer, TSubclassOf<UTimeControlAbilityWidget> TimeWidgetClassToSpawn)
	{
		UClockworkLastBossCodyExplosionComponent Comp = UClockworkLastBossCodyExplosionComponent::Get(TargetPlayer);

		if (Comp != nullptr)
		{
			Comp.TimeWidgetClass = TimeWidgetClassToSpawn;
		}
	}

	UFUNCTION()
	void SetHazardousDebrisArray(AHazePlayerCharacter TargetPlayer)
	{
		UClockworkLastBossCodyExplosionComponent Comp = UClockworkLastBossCodyExplosionComponent::Get(TargetPlayer);

		if (Comp != nullptr)
		{
			GetAllActorsOfClass(Comp.HazardousDebrisArray);
		}
	}

	UFUNCTION()
	void SetTimeScrubbableObjects(AHazePlayerCharacter TargetPlayer)
	{
		UClockworkLastBossCodyExplosionComponent Comp = UClockworkLastBossCodyExplosionComponent::Get(TargetPlayer);

		if (Comp != nullptr)
		{
			GetAllActorsOfClass(Comp.ExplosionEffectArray);
			GetAllActorsOfClass(Comp.CogArray);
			GetAllActorsOfClass(Comp.SpotlightController);
		}
	}

	UFUNCTION()
	void ResetCodyExplosionTime()
	{
		UClockworkLastBossCodyExplosionComponent Comp = UClockworkLastBossCodyExplosionComponent::Get(Game::GetCody());

		if (Comp != nullptr)
		{
			Comp.ResetCodyExplosionTime.Broadcast();
		}
	}

	UFUNCTION()
	void TriggerExplosionAutoScrub(float From, float To)
	{
		UClockworkLastBossCodyExplosionComponent Comp = UClockworkLastBossCodyExplosionComponent::Get(Game::GetCody());

		if (Comp != nullptr)
		{
			Comp.TriggerExplosionAutoScrub.Broadcast(From, To);
		}
	}

	UFUNCTION()
	void SetExplosionTimeInterval(float From, float To, bool bShouldUseDuration, float NewDuration, AClockworkLastBossExplosionActorBase NewActorToGetTimeFrom, bool bNewShouldGoBackwards, UCurveFloat OptionalCurve)
	{
		UClockworkLastBossCodyExplosionComponent Comp = UClockworkLastBossCodyExplosionComponent::GetOrCreate(Game::GetCody());

		if (Comp != nullptr)
		{
			Comp.OnNewExplosionInterval.Broadcast(From, To, bShouldUseDuration, NewDuration, NewActorToGetTimeFrom, bNewShouldGoBackwards, OptionalCurve);
		}
	}

	UFUNCTION()
	void SetInstantExplosionTime(float ExplosionTime)
	{
		UClockworkLastBossCodyExplosionComponent Comp = UClockworkLastBossCodyExplosionComponent::GetOrCreate(Game::GetCody());

		if (Comp != nullptr)
		{
			Comp.OnInstantExplosionTime.Broadcast(ExplosionTime);
		}
	}

	UFUNCTION()
	void ForceCodyTimeWidgetHidden(bool bHidden)
	{
		UTimeControlComponent Comp = UTimeControlComponent::Get(Game::GetCody());
		if (Comp != nullptr)
		{
			ESlateVisibility Visibility = bHidden ? ESlateVisibility::Hidden : ESlateVisibility::Visible;
			Comp.TimeWidget.SetVisibility(Visibility);
		}
	}
}

event void FResetCodyExplosionTime();
event void FTriggerExplosionAutoScrub(float From, float To);
event void FOnNewExplosionInterval(float From, float To, bool bDuration, float Duration, AClockworkLastBossExplosionActorBase ActorToGetTimeFrom, bool bShouldGoBackwards, UCurveFloat OptionalCurve);
event void FOnInstantExplosionTIme(float NewTime);

class UClockworkLastBossCodyExplosionComponent : UActorComponent
{
	// The current sequence that Cody can TimeScrub
	UPROPERTY()
	AHazeLevelSequenceActor CurrentSequenceToControl;

	TArray<AClockworkLastBossExplosionHazardousDebris> HazardousDebrisArray;
	TArray<AClockworkLastBossExplosionFX> ExplosionEffectArray;
	TArray<AClockworkLastBossStuckCog> CogArray;
	TArray<AClockworkLastBossScrubbedSpotlightController> SpotlightController;
	TSubclassOf<UTimeControlAbilityWidget> TimeWidgetClass;	
	UTimeControlAbilityWidget TimeWidget;
	FResetCodyExplosionTime ResetCodyExplosionTime;
	FTriggerExplosionAutoScrub TriggerExplosionAutoScrub;
	FOnNewExplosionInterval OnNewExplosionInterval;
	FOnInstantExplosionTIme OnInstantExplosionTime;
	AClockworkLastBossExplosionActorBase ActorToGetTimeFrom;

	float ScrubValueMin = 0.f;
	float ScrubValueMax = 0.f;

	float IntevalStart = 0;

	bool bIsScrubbingTime = false;
}