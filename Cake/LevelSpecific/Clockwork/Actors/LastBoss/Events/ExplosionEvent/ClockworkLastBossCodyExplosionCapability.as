import Cake.LevelSpecific.Clockwork.Actors.LastBoss.Events.ExplosionEvent.ClockworkLastBossCodyExplosionComponent;
class UClockworkLastBossCodyExplosionCapability : UHazeCapability
{
	default CapabilityTags.Add(n"ClockworkLastBossCodyExplosionCapability");

	default CapabilityDebugCategory = n"ClockworkLastBossCodyExplosionCapability";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UClockworkLastBossCodyExplosionComponent Comp;
	float CurrentTime = 0.f;
	float CurrentCurveTime = 0.f;
	float CurrentTimeDelta = 0.f;
	float CurrentTimeLastTick = 0.f;
	float TimeIntervalFrom = 0.f;
	float TimeIntervalTo = 0.f;
	float TimeIntervalDuration = 0.f;
	bool bShouldUseDuration = false;
	bool bShouldGoBackwards = false;
	bool bShouldUseCurve = false;
	UCurveFloat Curve;
	AClockworkLastBossExplosionActorBase ActorToGetTimeFrom;


	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);

		if(Player == Game::GetMay())
			return;

		Comp = UClockworkLastBossCodyExplosionComponent::GetOrCreate(Player);

		Comp.OnNewExplosionInterval.AddUFunction(this, n"OnNewExplosionIntervalSet");
		Comp.OnInstantExplosionTime.AddUFunction(this, n"OnSetInstantExplosionTime");
	}

	UFUNCTION()
	void OnNewExplosionIntervalSet(float From, float To, bool bDuration, float Duration, AClockworkLastBossExplosionActorBase NewActorToGetTimeFrom, bool bNewShouldGoBackwards, UCurveFloat OptionalCurve)
	{
		CurrentTime = From;
		TimeIntervalFrom = From;
		TimeIntervalTo = To;
		bShouldUseDuration = bDuration;
		TimeIntervalDuration = Duration;
		ActorToGetTimeFrom = NewActorToGetTimeFrom;
		bShouldGoBackwards = bNewShouldGoBackwards;

		if (OptionalCurve != nullptr)
		{
			bShouldUseCurve = true;
			Curve = OptionalCurve;
		} else 
		{
			bShouldUseCurve = false;
		}

		Player.SetCapabilityAttributeObject(n"AudioExplosionActor", NewActorToGetTimeFrom);		
	}

	UFUNCTION()
	void OnSetInstantExplosionTime(float NewTime)
	{
		bShouldUseDuration = false;
		CurrentTime = NewTime;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        if (Player != Game::GetCody())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (Player != Game::GetCody())
			return EHazeNetworkDeactivation::DeactivateFromControl;
	
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		
	}

	/* ----------------------------------------------------------------------------------------------- */
								/* How CurrentTime is Being Used */
	// The value CurrentTime is being sent to FX and it is what is driving the FX forward or backwards 
	// CurrentTime will sometimes tick over a certain amount of time, and sometimes based on Cody's time ability
	// CurrentTime interval 0 - 1 is being ticked over time during the AfterRewindSmash Cutscene (when the explosion starts)
	// CurrentTime interval 1 - 2 is driven by Cody's time ability during the explosion gameplay
	// CurrentTime interval 2 - 3 is based on the FinalExplosion cutscene duration 2 = start of cutscene, 3 = end of cutscene
	// CurrentTime interval 3 - 5 is begin ticked over time during the SprintToCouple event.

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		PrintToScreen("ExplosionArray: " + Comp.ExplosionEffectArray.Num());
		PrintToScreen("TimeIntervalDuration: " + TimeIntervalDuration);

		for(auto FX : Comp.ExplosionEffectArray)
		{
			FX.TimeChange(CurrentTime);
		}
		
		for(auto Spot : Comp.SpotlightController)
		{
			Spot.SetScrubTime(CurrentTime);
		}

		for(auto Cog : Comp.CogArray)
		{
			if (CurrentTime < 2.f)
				Cog.CurrentTimeControlSpeed = CurrentTimeDelta;
			else 
				Cog.CurrentTimeControlSpeed = CurrentTimeDelta * 10.f;
		}

		Player.SetCapabilityAttributeValue(n"AudioCurrentTime", CurrentTime);

		if (bShouldUseDuration && !bShouldGoBackwards && !bShouldUseCurve)
		{
			if (CurrentTime < TimeIntervalTo)
				CurrentTime += DeltaTime / (TimeIntervalDuration / (TimeIntervalTo - TimeIntervalFrom));
		} 
		else if (bShouldUseDuration && !bShouldGoBackwards && bShouldUseCurve)
		{
			if (CurrentCurveTime < TimeIntervalTo)
			{
				CurrentCurveTime += DeltaTime / (TimeIntervalDuration / (TimeIntervalTo - TimeIntervalFrom));
				CurrentTime = Curve.GetFloatValue(CurrentCurveTime);
			}
		}
		 else if (bShouldUseDuration && bShouldGoBackwards)
		{
			if (CurrentTime > TimeIntervalTo)
				CurrentTime -= DeltaTime / (TimeIntervalDuration / (TimeIntervalFrom - TimeIntervalTo));
		}
		 else if (ActorToGetTimeFrom != nullptr)
		{
			CurrentTime = FMath::GetMappedRangeValueClamped(FVector2D(0.f, 1.f), FVector2D(TimeIntervalFrom, TimeIntervalTo), ActorToGetTimeFrom.CurrentTime);
		}

		CurrentTimeDelta = (CurrentTime - CurrentTimeLastTick) / DeltaTime; 
		CurrentTimeLastTick = CurrentTime;
	}	
}