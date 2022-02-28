import Cake.LevelSpecific.Tree.LarvaBasket.LarvaBasketSettings;
import Cake.LevelSpecific.Tree.LarvaBasket.LarvaBasketBall;
import Cake.LevelSpecific.Tree.LarvaBasket.LarvaBasketScoreWidget;

import void LarvaBasketPlayerGainScore(AHazePlayerCharacter Player, int Score) from 'Cake.LevelSpecific.Tree.LarvaBasket.LarvaBasketManager';

class ALarvaBasketHoop : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent HoopRoot;

	UPROPERTY(DefaultComponent, Attach = HoopRoot)
	UBoxComponent ScoreCollision;

	UPROPERTY(EditDefaultsOnly, Category = "Basket")
	TSubclassOf<ULarvaBasketScoreWidget> ScoreWidgetClass;
	ULarvaBasketScoreWidget ScoreWidget;

	const FTransform AttachRoot = FTransform(Math::MakeQuatFromXZ(FVector(0.f, 0.f, 1.f), FVector(0.f, -1.f, 0.f)));

	ALarvaBasketHoopSpawner OwningSpawner;

	ELarvaBasketScoreType ScoreType;
	UHazeSplineComponentBase Spline;
	float Distance = 0.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ScoreCollision.OnComponentBeginOverlap.AddUFunction(this, n"HandleBeginOverlap");
		ScoreCollision.OnComponentEndOverlap.AddUFunction(this, n"HandleEndOverlap");

		ScoreWidget = Cast<ULarvaBasketScoreWidget>(Game::May.AddWidget(ScoreWidgetClass));
		ScoreWidget.ScoreType = ScoreType;

		Spline = OwningSpawner.Spline;
		AttachToComponent(Spline);
	}

	void EnableHoop(ELarvaBasketScoreType InScoreType)
	{
		ScoreType = InScoreType;
		Distance = 0.f;
		HoopRoot.RelativeScale3D = FVector(LarvaBasketGetHoopSizeForType(ScoreType));
		ScoreWidget.ScoreType = ScoreType;

		EnableActor(this);
		BP_OnScoreTypeSet(InScoreType);
	}

	void DisableHoop()
	{
		DisableActor(this);
	}

    UFUNCTION()
    void HandleBeginOverlap(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex,
        bool bFromSweep, FHitResult& Hit)
    {
    	auto Ball = Cast<ALarvaBasketBall>(OtherActor);
    	if (Ball == nullptr)
    		return;

    	if (!Ball.PlayerOwner.HasControl())
    		return;

    	NetBallScore(Ball, ScoreType);
    }


    UFUNCTION()
    void HandleEndOverlap(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex)
    {
    }

    UFUNCTION(NetFunction)
    void NetBallScore(ALarvaBasketBall Ball, ELarvaBasketScoreType InScoreType)
    {
    	LarvaBasketPlayerGainScore(Ball.PlayerOwner, LarvaBasketGetScoreForType(InScoreType));
    	Ball.DeactivateBall();

    	BP_OnScored();

		ScoreWidget.SetWidgetWorldPosition(ScoreCollision.WorldLocation);
		ScoreWidget.PlayShowAnimation();
    }

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (Spline == nullptr)
			return;

		Distance += OwningSpawner.Speed * DeltaTime;
		if (Distance > Spline.SplineLength || Distance < 0.f)
			DisableHoop();

		ActorRelativeTransform = AttachRoot * Spline.GetTransformAtDistanceAlongSpline(Distance, ESplineCoordinateSpace::Local);
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnScored() {}

	UFUNCTION(BlueprintEvent)
	void BP_OnScoreTypeSet(ELarvaBasketScoreType Type) {}
}

class ALarvaBasketHoopSpawner : AHazeActor
{
	UPROPERTY(DefaultComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UBillboardComponent Billboard;

	UPROPERTY(EditInstanceOnly, Category = "Basket")
	AActor SplineActor;

	UPROPERTY(EditInstanceOnly, Category = "Basket")
	TSubclassOf<ALarvaBasketHoop> HoopClass;

	// All hoops spawned, used for recycling and re-enabling
	TArray<ALarvaBasketHoop> Hoops;

	UPROPERTY(EditInstanceOnly, Category = "Basket")
	float DistanceOffsetPercent = 0.f;

	UPROPERTY()
	UHazeSplineComponentBase Spline;

	float Speed = LarvaBasket::HoopRailSpeed;
	int NumSpawnedHoops = 0;
	float LastSpawnDistance = 0.f;

	TArray<int> ScoreProportions;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (SplineActor != nullptr)
		{
			Spline = UHazeSplineComponentBase::Get(SplineActor);
			AttachToComponent(Spline);

			FHazeSplineSystemPosition StartPosition = Spline.GetPositionAtStart(true);
			ActorRelativeTransform = StartPosition.RelativeTransform;
		}
		else
		{
			Spline = nullptr;
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LastSpawnDistance = DistanceOffsetPercent * LarvaBasket::HoopSpawnSpacing;

		// Fill the hoop pool with stuff
		for(int i=0; i<LarvaBasket::HoopPoolSize; ++i)
		{
			auto Hoop = Cast<ALarvaBasketHoop>(SpawnActor(HoopClass, bDeferredSpawn = true, Level = GetLevel()));
			Hoop.MakeNetworked(this, NumSpawnedHoops++);
			Hoop.DisableHoop();
			Hoop.OwningSpawner = this;

			FinishSpawningActor(Hoop);
			Hoops.Add(Hoop);
		}

		ScoreProportions = LarvaBasket::ScoreBaseProportions;
	}

	int GetRandomScoreIndex()
	{
		int TotalOdds = 0;
		for(int i=0; i<3; ++i)
			TotalOdds += ScoreProportions[i];

		float Value = FMath::RandRange(0.f, float(TotalOdds));
		for(int i=0; i<3; ++i)
		{
			if (Value <= ScoreProportions[i])
				return i;

			Value -= ScoreProportions[i];
		}

		ensure(false);
		return 0;
	}

	ALarvaBasketHoop GetHoopToActivate()
	{
		// First to find a disabled hoop somewhere
		for(auto Hoop : Hoops)
		{
			if (Hoop.IsActorDisabled())
				return Hoop;
		}

		devEnsure(false, "Ran out of hoops in the LarvaBasketHoopSpawner");
		return nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		LastSpawnDistance += Speed * DeltaTime;
		if (FMath::Abs(LastSpawnDistance) >= LarvaBasket::HoopSpawnSpacing)
		{
			int ScoreIndex = GetRandomScoreIndex();

			// Increase/reset the odds of all types
			// This prevents 'patchy' randomness, and makes the distribution a bit more averaged
			for(int i=0; i<3; ++i)
			{
				if (i == ScoreIndex)
					ScoreProportions[i] = LarvaBasket::ScoreBaseProportions[i];
				else
					ScoreProportions[i]++;
			}

			ALarvaBasketHoop Hoop = GetHoopToActivate();

			if (HasControl())
				NetActivateHoop(Hoop, ELarvaBasketScoreType(ScoreIndex));

			LastSpawnDistance -= LarvaBasket::HoopSpawnSpacing * FMath::Sign(LastSpawnDistance);
		}
	}

	UFUNCTION(NetFunction)
	void NetActivateHoop(ALarvaBasketHoop Hoop, ELarvaBasketScoreType ScoreType)
	{
		Hoop.EnableHoop(ScoreType);
	}
}