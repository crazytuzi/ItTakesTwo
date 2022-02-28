import Peanuts.Audio.AudioStatics;
import Peanuts.Audio.AudioSpline.AudioSplineEmitter;

class AAudioSpline : AHazeActor
{
	UPROPERTY(DefaultComponent)
	UHazeSplineComponentBase SplineComponent;

	UPROPERTY()
	TArray<FAudioSplineEmitter> Emitters;	

	UPROPERTY(DefaultComponent)
	UHazeAkComponent SplineAkComp;	
	default SplineAkComp.bIsStatic = true;

	UPROPERTY(DefaultComponent, NotEditable)
	UHazeDisableComponent DisableComp;
	default DisableComp.bActorIsVisualOnly = true;	
	default DisableComp.bAutoDisable = false;

	// If 'LazyOverlapsEnabled' is used, the disable the actor cant enable until at least 1 player is inside the range
	UPROPERTY(DefaultComponent)
	UHazeLazyPlayerOverlapComponent EnableArea;
	default EnableArea.bLazyOverlapsEnabled = false;
	default EnableArea.bAlwaysCheckLazyOverlaps = true;

	UPROPERTY()
	AkMultiPositionType PositioningType = AkMultiPositionType::MultiDirections;

	UPROPERTY()
	int32 DisableDistanceBuffer = 3000;

	UPROPERTY()
	float OcclusionRefreshInterval = 0.0f;

	UPROPERTY()
	float MaxAttenuationMultiplier = 1.0f;

	UPROPERTY()
	bool bTrackPlayerElevation = false;

	UPROPERTY()
	float MaxElevationTrackRange = 1000.f;

	UPROPERTY()
	bool bTrackPlayerElevationAngle = false;

	UPROPERTY()
	bool bLinkToAmbientZone = false;

	UPROPERTY(meta = (EditCondition = "bLinkToAmbientZone"))
	bool bFollowZonePriority = false;

	UPROPERTY(NotVisible)
	bool bDebug = false;	

	float MaxRangeEnabled = 0.f;

	float LastListenerProximityCompensationValue = 0.f;

	TArray<AHazePlayerCharacter> Players;
	TArray<UHazeListenerComponent> PlayerListeners;	
	TArray<FTransform> SplineEmitterPositions;	

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{	
		Players = Game::GetPlayers();
		SplineAkComp.OcclusionRefreshInterval = 0.0f;
		SplineAkComp.SetTrackElevation(bTrackPlayerElevation, MaxElevationTrackRange);		
		SplineAkComp.SetTrackElevationAngle(bTrackPlayerElevationAngle);
		
		if(bLinkToAmbientZone)
			SplineAkComp.CreateZoneLinkEffect(bFollowZonePriority);

		for(FAudioSplineEmitter& Emitter : Emitters) 
		{
			if (Emitter.bPlayOnStart)
			{				
				SplineAkComp.HazePostEvent(Emitter.Event);				
				DisableComp.AutoDisableRange = (SplineAkComp.ScaledMaxAttenuationRadius + SplineComponent.BoundsRadius) + DisableDistanceBuffer;
			}			
		}				

		for(int i = 0; i < Players.Num(); ++i)
		{
			UHazeListenerComponent PlayerListener = UHazeListenerComponent::Get(Players[i]);
			PlayerListeners.Add(PlayerListener);
			FHazeSplineSystemPosition SplinePos = SplineComponent.GetPositionClosestToWorldLocation(PlayerListeners[i].GetWorldLocation(), false);
			FTransform Transform = FTransform(SplinePos.GetWorldLocation());
			SplineEmitterPositions.Add(Transform);			
		}

		
		DisableComp.SetUseAutoDisable(DisableComp.AutoDisableRange > 0);

		if(EnableArea.bLazyOverlapsEnabled)
		{
			if(!EnableArea.IsAnyPlayerOverlapping())
				DisableActor(EnableArea);

			EnableArea.OnPlayerBeginOverlap.AddUFunction(this, n"OnPlayerActivatedZone");
			EnableArea.OnPlayerEndOverlap.AddUFunction(this, n"OnPlayerDeactivatedZone");
		}

		UpdateComponentPositions();
	}

	void UpdateComponentPositions()
	{	
		for (int i = 0; i < SplineEmitterPositions.Num(); i++)
		{			
			FHazeSplineSystemPosition NewSplinePos = SplineComponent.GetPositionClosestToWorldLocation(PlayerListeners[i].GetWorldLocation(), false);
			FVector NewLocation = NewSplinePos.GetWorldLocation();
			SplineEmitterPositions[i].SetLocation(NewLocation);

			#if EDITOR
			if(bDebug)
			{
				for(FAudioSplineEmitter Emitter : Emitters)
				{					
					FVector SplinePosVector = FVector(SplineEmitterPositions[i].GetLocation().X, SplineEmitterPositions[i].GetLocation().Y, SplineEmitterPositions[i].GetLocation().Z);				
					if(bDebug && SplinePosVector.Distance(PlayerListeners[i].GetWorldLocation()) < Emitter.Event.HazeMaxAttenuationRadius)
					{
						System::DrawDebugLine(PlayerListeners[i].GetWorldLocation(), NewLocation, FLinearColor::Red);							
					}
				}	
			}
			#endif		
		}	

		SplineAkComp.HazeSetMultiplePositions(SplineEmitterPositions, PositioningType);	
	}

	UFUNCTION(NotBlueprintCallable)
	protected void OnPlayerActivatedZone(AHazePlayerCharacter Player)
	{
		if(EnableArea.OverlappingPlayersCount() == 1)
			EnableActor(EnableArea);
	}

	UFUNCTION(NotBlueprintCallable)
	protected void OnPlayerDeactivatedZone(AHazePlayerCharacter Player)
	{
		if(EnableArea.OverlappingPlayersCount() == 0)
			DisableActor(EnableArea);
	}

	UFUNCTION(BlueprintCallable)
	void StartAudioSplineEvent(UAkAudioEvent Event = nullptr, FName InTag = n"")
	{
		if(Event == nullptr)
		{
			for(FAudioSplineEmitter& SplineEvent : Emitters)
			{
				if(SplineEvent.Tag == InTag)
				{
					SplineAkComp.HazePostEvent(SplineEvent.Event, EventTag = SplineEvent.Tag);
					break;				
				}
			}
		}
		else
		{
			SplineAkComp.HazePostEvent(Event);
		}

		DisableComp.AutoDisableRange = (SplineAkComp.ScaledMaxAttenuationRadius + SplineComponent.BoundsRadius) + DisableDistanceBuffer;			
		const bool bShouldDisable = DisableComp.AutoDisableRange > 0.f;
		DisableComp.SetUseAutoDisable(bShouldDisable);
	}

	float GetShortestListenerDistance()
	{
		float ShortestDistance = Math::BigNumber;

		for (int i = 0; i < SplineEmitterPositions.Num(); i++)
		{
			float Dist = SplineEmitterPositions[i].Location.DistSquared(PlayerListeners[i].GetWorldLocation());

			if(Dist > ShortestDistance)
				continue;

			ShortestDistance = Dist;
		}

		return FMath::Sqrt(ShortestDistance);
	}

	float GetFurthestListenerDistance()
	{
		float FurthestDistance = Math::SmallNumber;

		for (int i = 0; i < SplineEmitterPositions.Num(); i++)
		{
			float Dist = Math::SmallNumber;
			
			for(UHazeListenerComponent& Listener : PlayerListeners)
			{
				SplineEmitterPositions[i].Location.DistSquared(PlayerListeners[i].GetWorldLocation());
				if(Dist > MaxRangeEnabled)
					continue;

				if(Dist < FurthestDistance)
					continue;

				FurthestDistance = Dist;
			}
		}

		return FMath::Sqrt(FurthestDistance);
	}

	void SetListenerProximityCompensation()
	{
		float ListenerProximityCompensationValue = GetFurthestListenerDistance() / MaxRangeEnabled;

		if(ListenerProximityCompensationValue == LastListenerProximityCompensationValue)
			return;

		SplineAkComp.SetRTPCValue(HazeAudio::RTPC::ListenerProximityBoostCompensation, ListenerProximityCompensationValue);
		LastListenerProximityCompensationValue = ListenerProximityCompensationValue;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{		
		if(SplineAkComp.bIsPlaying)
		{
			UpdateComponentPositions();
			SplineAkComp.MaxElevationTrackRange = MaxElevationTrackRange;
		}	
	}

	UFUNCTION(BlueprintCallable)
	void SetDebug(bool Value)
	{
		bDebug = Value;
	}

	UFUNCTION(BlueprintCallable)
	bool GetDebugState()
	{
		return bDebug;
	}
}