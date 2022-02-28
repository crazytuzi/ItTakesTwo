import Peanuts.Spline.SplineComponent;
import Peanuts.Audio.AudioSpline.AudioSpline;

struct FPlayAudioOnMonsterSplineDistance
{
	UPROPERTY()
	float DistanceToPlayAudio = 0.f;

	UPROPERTY()
	UAkAudioEvent DistanceAudioEvent;

	bool bHasPlayedAudio = false;
}

class AMicrophoneMonsterSpline : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UHazeSplineComponent Spline;
	default Spline.AutoTangents = true;
#if EDITOR
	default Spline.ScaleVisualizationWidth = 200.f;
	default Spline.bShouldVisualizeScale = true;
#endif

	UPROPERTY(DefaultComponent, Attach = Spline)
	UHazeSplineRegionContainerComponent SplineRegionContainer;

	UPROPERTY()
	float Speed = 2000.f;
	
	UPROPERTY()
	float SpeedDistance = 0.f;

	UPROPERTY()
	bool bTrackMonsterProgressOnSpline = false;

	UPROPERTY()
	TArray<FPlayAudioOnMonsterSplineDistance> PlayAudioOnMonsterSplineDistance;
	
	bool bShouldMoveOnSpline = false;
	float Distance = 0.f;

	UPROPERTY(DefaultComponent, NotVisible)
	UHazeAkComponent SplineHazeAkComp;
	default SplineHazeAkComp.DetachFromComponent(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);

	UPROPERTY(Category = "Audio")
	UAkAudioEvent StartSplineEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent StopSplineEvent;

	TArray<AHazePlayerCharacter> Players;
	TArray<UHazeListenerComponent> PlayerListeners;	
	TArray<FTransform> SplineEmitterPositions;

	UPROPERTY()
	bool bDebug = false;

	

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Players = Game::GetPlayers();

		SplineHazeAkComp.SetTrackDistanceToPlayer(true, nullptr, 6000.f);

		for(int i = 0; i < Players.Num(); ++i)
		{
			UHazeListenerComponent PlayerListener = UHazeListenerComponent::Get(Players[i]);
			PlayerListeners.Add(PlayerListener);
			FHazeSplineSystemPosition SplinePos = Spline.GetPositionClosestToWorldLocation(PlayerListeners[i].GetWorldLocation(), false);
			FTransform Transform = FTransform(SplinePos.GetWorldLocation());
			SplineEmitterPositions.Add(Transform);			
		}
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bDebug)
		{
			PrintToScreen("Duration: " + Spline.GetSplineLength() / Speed);
		}
		
		
		if (!bShouldMoveOnSpline)	
			return;


	
		Distance += DeltaTime * Speed;

		//PrintToScreen("" + this.Name + " is running at distance: " + Distance, 0.f, FLinearColor::Green);

		if (PlayAudioOnMonsterSplineDistance.Num() > 0)
		{
			for (auto AudioStruct : PlayAudioOnMonsterSplineDistance)
			{
				if (AudioStruct.bHasPlayedAudio)
					continue;
				
				if (Distance >= AudioStruct.DistanceToPlayAudio )
				{
					SplineHazeAkComp.HazePostEvent(AudioStruct.DistanceAudioEvent);
					AudioStruct.bHasPlayedAudio = true;
					//PrintScaled("TRIGGERED AUDIO", 1.f, FLinearColor::Red, 5.f);
				}
			}
		}
		UpdateSplineAudioPositions();

		if (Distance > Spline.GetSplineLength())
			bShouldMoveOnSpline = false;
	}

	void StartMoveOnSpline()
	{
		Distance = 0;
		bShouldMoveOnSpline = true;		
	}

	FTransform MovementOnSpline()
	{
		return Spline.GetTransformAtDistanceAlongSpline(Distance, ESplineCoordinateSpace::World);
	}

	bool IsOnEndOfSpline()
	{
		if (!bTrackMonsterProgressOnSpline)
			return false;

		if (Distance >= Spline.GetSplineLength())
			return true;
		else
			return false;
	}

		void UpdateSplineAudioPositions()
	{	
		for (int i = 0; i < SplineEmitterPositions.Num(); i++)
		{			
			FHazeSplineSystemPosition NewSplinePos = Spline.GetPositionClosestToWorldLocation(PlayerListeners[i].GetWorldLocation(), false);
			FVector NewLocation = NewSplinePos.GetWorldLocation();
			SplineEmitterPositions[i].SetLocation(NewLocation);
		}	

		SplineHazeAkComp.HazeSetMultiplePositions(SplineEmitterPositions, AkMultiPositionType::MultiDirections);	
	}

	void StartSplineAudio()
	{
		SplineHazeAkComp.HazePostEvent(StartSplineEvent);
	}

	void StopSplineAudio()
	{
		SplineHazeAkComp.HazePostEvent(StopSplineEvent);
	}
}