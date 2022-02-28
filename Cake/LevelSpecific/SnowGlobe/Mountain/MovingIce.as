import Peanuts.Spline.SplineComponent;
import Peanuts.Triggers.PlayerTrigger;
import Cake.Environment.BreakableComponent;
import Cake.LevelSpecific.SnowGlobe.Mountain.ExplodingIce;
import Cake.LevelSpecific.SnowGlobe.Mountain.TriggerableFX;
import Peanuts.Audio.AudioStatics;
import Vino.PlayerHealth.PlayerHealthStatics;

event void FKeyPointReached(int KeyPointIndex);
event void FEndPointReached();
event void FStoppedMoving(int KeyPointIndex);


struct FMovingIcePoint
{
	float PointDistance;

	UPROPERTY()
	float Delay = 0.f;

	UPROPERTY()
	float Speed = 1.f;

	UPROPERTY()
	float ShakeStrength = 1.f;

	UPROPERTY()
	TArray<AMovingIce> MoversToTrigger;

	UPROPERTY()
	TArray<AActor> EffectActors;

	UPROPERTY(Meta = (MakeEditWidget))
	FTransform Transform;
}

class UMovingIceSplineComponent : UHazeSplineComponent
{
    UFUNCTION(BlueprintOverride)
    void OnEditorPostKeyAddedAtIndex(int Index)
    {
		AMovingIce Parent = Cast<AMovingIce>(Owner);
		Parent.AddKeyPoint(Index);
    }

    UFUNCTION(BlueprintOverride)
    void OnEditorPostKeyRemovedAtIndex(int Index)
    {
		AMovingIce Parent = Cast<AMovingIce>(Owner);
		Parent.RemoveKeyPoint(Index);
    }
}

class AMovingIce : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MovingComponent;

	UPROPERTY(DefaultComponent, Attach = Root)
	UMovingIceSplineComponent Spline;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent LoopStartEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent LoopStopEvent;

	#if EDITOR
    default Spline.bShouldVisualizeScale = true;
	#endif

	UPROPERTY()
 	FKeyPointReached OnKeyPointReached;

	UPROPERTY()
 	FStoppedMoving OnStoppedMoving;

	UPROPERTY(Meta = (ClampMin = "0.0", ClampMax = "100.0", UIMin = "0.0", UIMax = "100.0"))
	float PreviewScrub = 0.f;

	UPROPERTY()
	TArray<FMovingIcePoint> KeyPoints;

	UPROPERTY()
	float PreActivateDelay = 0.f;

	UPROPERTY()
	float Speed = 400.f;
	
	UPROPERTY()
	float ShakeFrequency = 3.f;

	UPROPERTY()
	float ShakeMagnitude = 1.f;

	UPROPERTY()
	APlayerTrigger PlayerTrigger;

	UPROPERTY()
	bool bTriggeredBySecondPlayer = false;

	UPROPERTY(meta = (EditCondition="bTriggeredBySecondPlayer == true", EditConditionHides)))
	bool bTriggerIfSecondPlayerIsDead = false;

	UPROPERTY()
	bool bBothPlayerTrigger = false;

	TArray<AHazePlayerCharacter> Players;

	UPROPERTY()
	bool bIsActive = false;

	UPROPERTY()
	bool bTriggerOnce = false;

	bool bTriggered = false;

	UPROPERTY()
	FVector WidgetOffset = FVector(0, 0, 100.f);

	int NextPoint = 1;
	int PrevPoint = 0;

	float Delay;
	float DistanceOnSpline;

	bool bMovingForward = true; 

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		AttachChildsToComponent(MovingComponent);
		CreateWidgets();
		Preview(PreviewScrub);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if ( PlayerTrigger != nullptr)
		{
			PlayerTrigger.OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");
			PlayerTrigger.OnPlayerLeave.AddUFunction(this, n"OnPlayerLeave");
		}

		OnKeyPointReached.AddUFunction(this, n"KeyPointReached");

		NextPoint = 1;
		PrevPoint = 0;

		AttachChildsToComponent(MovingComponent);

		UpdateTransform(0, false);

		//AttachChildsToComponent(MovingComponent);

		if(bIsActive)
			StartMoving();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bIsActive)
		{
			PreActivateDelay -= DeltaSeconds;

			if (PreActivateDelay <= 0)
			{
				Delay -= DeltaSeconds;

				if (Delay <= 0)
					Move();
			}
			else
			{
				UpdateTransform(0, true);
			}
		}
	}

	UFUNCTION()
	void AddKeyPoint(int Index)
	{
		Print("Added KeyPoint: " + Index);

		FMovingIcePoint KeyPoint;
		KeyPoint.Transform.Location = Spline.GetLocationAtSplinePoint(Index, ESplineCoordinateSpace::Local) + WidgetOffset;
		KeyPoint.PointDistance = Spline.GetDistanceAlongSplineAtSplinePoint(Index);
		KeyPoints.Insert(KeyPoint, Index);

		UpdateWidgets();
	}

	UFUNCTION()
	void RemoveKeyPoint(int Index)
	{
		Print("Removed KeyPoint: " + Index);

		KeyPoints.RemoveAt(Index);

		UpdateWidgets();
	}

	UFUNCTION()
	void StartMoving()
	{
		// Enable tick
		SetActorTickEnabled(true);

		TriggerPoint(0); // This looks dangerous - Robert
		
		bIsActive = true;

		if (StartEvent != nullptr)
		HazeAkComp.HazePostEvent(StartEvent);

		if (LoopStartEvent != nullptr)
		HazeAkComp.HazePostEvent(LoopStartEvent);
	}

	UFUNCTION()
	void StopMoving()
	{
		bIsActive = false;

		if (StopEvent != nullptr)
		HazeAkComp.HazePostEvent(StopEvent);

		if (LoopStopEvent != nullptr)
		HazeAkComp.HazePostEvent(LoopStopEvent);

		OnStoppedMoving.Broadcast(NextPoint);

		// Disable Tick
		SetActorTickEnabled(false);
	}

	UFUNCTION()
	void OnPlayerEnter(AHazePlayerCharacter Player)
	{
		Players.AddUnique(Player);

		if (bTriggerOnce && bTriggered)
			return;

		if (bTriggeredBySecondPlayer)
		{
			if (Players.Num() >= 2 || (bTriggerIfSecondPlayerIsDead && Player.OtherPlayer.IsPlayerDead()))
			{
				bTriggered = true;
				StartMoving();
			}
		}
		else
		{
			bTriggered = true;
			StartMoving();
		}
	}

	UFUNCTION()
	void OnPlayerLeave(AHazePlayerCharacter Player)
	{
		if (bBothPlayerTrigger)
			Players.Remove(Player);
	}

	UFUNCTION(BlueprintEvent)
	void KeyPointReached(int KeyPointIndex)
	{
	}

	UFUNCTION()
	void AttachChildsToComponent(USceneComponent SceneComponent)
	{
		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors);

		for (auto Actor : AttachedActors)
		{
			Actor.AttachToComponent(SceneComponent, AttachmentRule = EAttachmentRule::KeepWorld);

			UHazeInheritPlatformVelocityComponent InheritPlatformVelocityComponent = UHazeInheritPlatformVelocityComponent::GetOrCreate(Actor);	
			InheritPlatformVelocityComponent.bInheritVerticalVelocity = true;	
		}
	}

	UFUNCTION()
	void Move()
	{
		if ((Speed < 0.f && bMovingForward) || (Speed > 0.f && !bMovingForward))
			ChangeDirection();

		float Alpha = (DistanceOnSpline - KeyPoints[PrevPoint].PointDistance) / (KeyPoints[NextPoint].PointDistance - KeyPoints[PrevPoint].PointDistance);
		float SpeedModifier = FMath::Lerp(KeyPoints[PrevPoint].Speed, KeyPoints[NextPoint].Speed, Alpha);

		DistanceOnSpline += Speed * SpeedModifier * ActorDeltaSeconds;

		if ((DistanceOnSpline >= KeyPoints[NextPoint].PointDistance && bMovingForward) || (DistanceOnSpline <= KeyPoints[NextPoint].PointDistance && !bMovingForward))
		{
			OnKeyPointReached.Broadcast(NextPoint);
			TriggerPoint(NextPoint);

			if (NextPoint == 0 || NextPoint == KeyPoints.Num() - 1)
			{
				StopMoving();
				DistanceOnSpline = FMath::Clamp(DistanceOnSpline, 0, Spline.GetSplineLength());	
				UpdateTransform(DistanceOnSpline, false);

				return;
			}

			Delay = KeyPoints[NextPoint].Delay;			
			PrevPoint = NextPoint;

			if (bMovingForward)
				NextPoint++;
			else
				NextPoint--;
		}

	//	PrevPoint = NextPoint - 1;

		UpdateTransform(DistanceOnSpline, true);
	}

	UFUNCTION()
	void ChangeDirection()
	{
		bMovingForward = !bMovingForward;

		int NewPrevPoint = NextPoint;
		int NewNextPoint = PrevPoint;

		PrevPoint = NewPrevPoint;
		NextPoint = NewNextPoint;

		PrintToScreen("Changed Direction", 10.f, FLinearColor::Green);
	}

	UFUNCTION()
	void TriggerPoint(int Point)
	{
		// Trigger Movers
		if (KeyPoints[Point].MoversToTrigger.Num() > 0)
		{
			for (auto Mover : KeyPoints[Point].MoversToTrigger)
			{
				Mover.StartMoving();
			}
		}

		// Trigger Effects
		if (KeyPoints[Point].EffectActors.Num() > 0)
		{
			for (auto Actor : KeyPoints[Point].EffectActors)
			{
				AExplodingIce ExplodingIce = Cast<AExplodingIce>(Actor);

				if (ExplodingIce != nullptr)
				{
					ExplodingIce.Break();
				}

				ATriggerableFX TriggerableFX = Cast<ATriggerableFX>(Actor);
				
				if (TriggerableFX != nullptr)
				{
					TriggerableFX.TriggerFX();
				}

				/*
				UBreakableComponent BreakableComponent = UBreakableComponent::Get(Actor);
				if (BreakableComponent != nullptr)
				{
					FBreakableHitData HitData;
					HitData.HitLocation = BreakableComponent.GetWorldLocation();
					HitData.ScatterForce = 25;
					BreakableComponent.Break(HitData);
				}
				*/
			}
		}
	}

	UFUNCTION(CallInEditor)
	void CreateWidgets()
	{
		for (int i = 0; i < 2; i++)
		{			
			if (!KeyPoints.IsValidIndex(i))
			{
				FMovingIcePoint KeyPoint;
				KeyPoint.Transform.Location = Spline.GetLocationAtSplinePoint(i, ESplineCoordinateSpace::Local) + WidgetOffset;
				KeyPoint.PointDistance = Spline.GetDistanceAlongSplineAtSplinePoint(i);
				KeyPoints.Add(KeyPoint);
			}
		}		

		UpdateWidgets();
	}

	UFUNCTION()
	void UpdateWidgets()
	{
		for (int i = 0; i < KeyPoints.Num(); i++)
		{
			FMovingIcePoint& KeyPoint = KeyPoints[i];
			KeyPoint.Transform.Location = Spline.GetLocationAtSplinePoint(i, ESplineCoordinateSpace::Local) + WidgetOffset;
			KeyPoint.PointDistance = Spline.GetDistanceAlongSplineAtSplinePoint(i);
		}
	}

	UFUNCTION()
	void Preview(float Distance)
	{
		float PreviewDistanceOnSpline = Distance * 0.01f * Spline.GetSplineLength();

		for (int i = 0; i < KeyPoints.Num(); i++)
		{
			FMovingIcePoint& KeyPoint = KeyPoints[i];

			if (KeyPoints[i].PointDistance >= PreviewDistanceOnSpline)
			{
				NextPoint = i;
				PrevPoint = FMath::Max(0, i - 1);
				break;
			}
		}

		UpdateTransform(PreviewDistanceOnSpline, false);
	}

	UFUNCTION()
	void SetNewDistance(float Distance)
	{
		DistanceOnSpline = FMath::Clamp(Distance, 0.f, Spline.GetSplineLength());

		for (int i = 0; i < KeyPoints.Num(); i++)
		{
			FMovingIcePoint& KeyPoint = KeyPoints[i];

			if (KeyPoints[i].PointDistance >= DistanceOnSpline) 
			{
				NextPoint = i;
				PrevPoint = FMath::Max(0, i - 1);
				break;
			}	
		}

		UpdateTransform(DistanceOnSpline, false);
	}

	UFUNCTION()
	void UpdateTransform(float Distance, bool bShake)
	{
		FTransform MovementTransform;

		float Alpha = 1.f;

		if (KeyPoints[NextPoint].PointDistance - KeyPoints[PrevPoint].PointDistance != 0.f)
			Alpha = (Distance - KeyPoints[PrevPoint].PointDistance) / (KeyPoints[NextPoint].PointDistance - KeyPoints[PrevPoint].PointDistance);

		MovementTransform.Location = Spline.GetLocationAtDistanceAlongSpline(Distance, ESplineCoordinateSpace::World);
		MovementTransform.Rotation = FMath::LerpShortestPath(KeyPoints[PrevPoint].Transform.Rotator(), KeyPoints[NextPoint].Transform.Rotator(), Alpha).Quaternion();
		MovementTransform.Rotation = GetActorTransform().TransformRotation(MovementTransform.Rotation);
		MovementTransform.Scale3D = FMath::Lerp(KeyPoints[PrevPoint].Transform.Scale3D, KeyPoints[NextPoint].Transform.Scale3D, Alpha);

		if (bShake)
		{
			float ShakeScale = FMath::Lerp(KeyPoints[PrevPoint].ShakeStrength, KeyPoints[NextPoint].ShakeStrength, Alpha);

			FTransform ShakeTransform = Shake(1.f * ShakeScale, 1.f * ShakeScale, 0.f * ShakeScale, Distance);

			MovementTransform.Location = MovementTransform.Location + ShakeTransform.Location;
			MovementTransform.Rotation = MovementTransform.Rotation * ShakeTransform.Rotation;
			MovementTransform.Scale3D = MovementTransform.Scale3D + ShakeTransform.Scale3D;
		}

		MovementTransform.NormalizeRotation();
		MovingComponent.SetWorldTransform(MovementTransform);
	}

	UFUNCTION()
	FTransform Shake(float Location, float Rotation, float Scale, float Distance)
	{
		FTransform Shake;

		Shake.Location = GetShakeVector(Location, 0.f, Distance);
		Shake.Rotation = FRotator(GetShakeVector(Rotation, 2.f, Distance).X, GetShakeVector(Rotation, 2.f, Distance).Y, GetShakeVector(Rotation, 2.f, Distance).Z).Quaternion();
		Shake.Scale3D = GetShakeVector(Scale, 5.f, Distance).GetAbs();

		return Shake;
	}

	FVector GetShakeVector(float Strength, float Offset, float Distance)
	{
		float Time = System::GetGameTimeInSeconds() + Offset;
	//	float Time = Distance + Offset;

		FVector ShakeVector;

		ShakeVector.X = FMath::Sin(Time * ShakeFrequency * 3.f) + FMath::Sin(Time * ShakeFrequency * 4.f);
		ShakeVector.Y = FMath::Sin(Time * ShakeFrequency * 5.f) + FMath::Sin(Time * ShakeFrequency * 2.f);
		ShakeVector.Z = FMath::Sin(Time * ShakeFrequency * 7.f) + FMath::Sin(Time * ShakeFrequency * 6.f);
	
		ShakeVector *= ShakeMagnitude * Strength;

		return ShakeVector;
	}	

}