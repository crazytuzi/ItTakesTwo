import Peanuts.Spline.SplineActor;
import Cake.Environment.BreakableComponent;

event void FOnPlayerHitObstacle(ATrackRunnerObstacle Obstacle, AHazePlayerCharacter Player, bool TimedOut);
import void ReturnTrackRunnerObstacleToPool(ATrackRunnerObstacle Obstacle) from "Cake.LevelSpecific.Music.LevelMechanics.Classic.SideContent.TrackRunnerManager";

class ATrackRunnerObstacle : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent BaseMesh;
	UPROPERTY(DefaultComponent, Attach = BaseMesh)
	UStaticMeshComponent WallMesh;
	UPROPERTY(DefaultComponent, Attach = WallMesh)
	UHazeLazyPlayerOverlapComponent LazyTrigger;
	default LazyTrigger.ResponsiveDistanceThreshold = 4000;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UArrowComponent PushBackArrowDirection;
	UPROPERTY(DefaultComponent, Attach = WallMesh)
	UBreakableComponent BreakableComponent;

	
	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent DestroyObstacleAudioEvent;

	UPROPERTY()
	FHazeAcceleratedFloat AcceleratedFloat;
	UPROPERTY()
	FHazeAcceleratedFloat AcceleratedFloatY;

	UPROPERTY()
	EObstaclesTypes ObstacleType = EObstaclesTypes::Medium;

	UPROPERTY()
	FOnPlayerHitObstacle OnPlayerHitObstacle;
	UPROPERTY()
	UNiagaraSystem ExplosionEffect;

	UPROPERTY()
	ASplineActor SplineToFollow;
	float CurrentFollowSpeed = 400;
	UPROPERTY()
	float DistanceAlongSpline;

	float Velocity = 1000.f;
	float LifeSpanTimer = 1;
	UPROPERTY()
	float ShieldSpringToSiffness = 10;
	UPROPERTY()
	float ShieldSpringToDampness = 0.5f;
	UPROPERTY()
	float SpringToReturnValue = -80.0f;
	bool LifeTimeEnded = true;
	bool bMiniGameEnded = false;
	bool bShouldImpactPlayer = true;
	float UpDownTimerOriginal = 1.f;
	float UpDownTimer = 1.f;
	bool bIsDown = true;

	UPROPERTY()
	bool IsObstacleSmallMovingRight = false;
	UPROPERTY()
	bool IsObstacleSmallMovingLeft = false;
	UPROPERTY()
	bool IsObstacleBigMovingRight = false;
	UPROPERTY()
	bool IsObstacleBigMovingLeft = false;
	bool bMoveLeft;

	AHazePlayerCharacter PlayerSide;

	UObject ObstaclePool;
	bool bObstaclePoolLeft;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AcceleratedFloat.Value = WallMesh.GetRelativeLocation().Z;
		//Trigger.OnComponentBeginOverlap.AddUFunction(this, n"OnComponentBeginOverlap");
		LazyTrigger.OnPlayerBeginOverlap.AddUFunction(this, n"OnPlayerOverlap");

		if(IsObstacleSmallMovingRight or IsObstacleSmallMovingLeft)
		{	
			if(IsObstacleSmallMovingRight or IsObstacleBigMovingRight)
				bMoveLeft = true;
			if(IsObstacleSmallMovingLeft or IsObstacleBigMovingLeft)
				bMoveLeft = false;
		}	
	}

	UFUNCTION(NotBlueprintCallable)
	void OnPlayerOverlap(AHazePlayerCharacter Player)
	{
		if(IsActorDisabled())
			return;
		if(!bShouldImpactPlayer)
			return;

		if(Player == Game::GetCody())
		{
			if(Player.HasControl())
			{
				OnPlayerHitObstacle.Broadcast(this, Game::GetCody(), false);
			}
		}
		else if(Player== Game::GetMay())
		{
			if(Player.HasControl())
			{
				OnPlayerHitObstacle.Broadcast(this, Game::GetMay(), false);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(IsActorDisabled())
			return;

		if(SplineToFollow != nullptr)
		{
			if(!bMiniGameEnded)
			{
				DistanceAlongSpline += Velocity * DeltaTime;
				FVector Loc = SplineToFollow.Spline.GetLocationAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World);
				FRotator Rot = SplineToFollow.Spline.GetRotationAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World);
				SetActorLocationAndRotation(Loc, Rot);
			}
		}

		LifeSpanTimer -= DeltaTime;
		if(LifeSpanTimer <= 0.f)
		{
			if(PlayerSide.HasControl())
			{
				if(LifeTimeEnded == true)
					return;

				LifeTimeEnded = true;
				OnPlayerHitObstacle.Broadcast(this, PlayerSide, true);
			}
		}

		MoveSideWays(DeltaTime);

		//ToScreen("SplineToFollow.Spline.GetSplineLength() " + SplineToFollow.Spline.GetSplineLength());
		//ToScreen("DistanceAlongSpline" + DistanceAlongSpline);
		if(DistanceAlongSpline >= SplineToFollow.Spline.GetSplineLength())
		{
			OnManualDisable();
		}
		if(DistanceAlongSpline >= 7650.f or bMiniGameEnded)
		{
			MoveDown(DeltaTime);
			return;
		}
		if(DistanceAlongSpline >= 600.f &&  DistanceAlongSpline < 7200)
		{
			MoveUp(DeltaTime);
			return;
		}
	}


	void MoveUp(float DeltaTime)
	{
		if(!bMiniGameEnded)
		{
			AcceleratedFloat.SpringTo(0, ShieldSpringToSiffness * 5.f, ShieldSpringToDampness, DeltaTime);
			WallMesh.SetRelativeLocation(FVector(WallMesh.GetRelativeLocation().X, WallMesh.GetRelativeLocation().Y, AcceleratedFloat.Value));
		}
	}
	void MoveDown(float DeltaTime)
	{
		AcceleratedFloat.SpringTo(SpringToReturnValue, ShieldSpringToSiffness * 5.f, ShieldSpringToDampness, DeltaTime * 1.35f);
		WallMesh.SetRelativeLocation(FVector(WallMesh.GetRelativeLocation().X, WallMesh.GetRelativeLocation().Y, AcceleratedFloat.Value));
	}

	void OnMiniGameEnded()
	{
		bMiniGameEnded = true;
	}

	void OnReuseFromPool()
	{
	}

	void OnManualDisable(bool bForceImmediate = false)
	{
		if (!IsActorDisabled())
		{
			DisableActor(nullptr);
			if (bForceImmediate)
				ReturnToObstaclePool();
			else
				Sync::FullSyncPoint(this, n"ReturnToObstaclePool");
		}
	}

	UFUNCTION()
	private void ReturnToObstaclePool()
	{
		ReturnTrackRunnerObstacleToPool(this);
	}

	void DestroyObstacle(AHazePlayerCharacter InstigatorPlayer)
	{
		Niagara::SpawnSystemAtLocation(ExplosionEffect, InstigatorPlayer.GetActorLocation(), InstigatorPlayer.GetActorRotation());
		BreakableComponent.SetHiddenInGame(false);


		WallMesh.SetHiddenInGame(true);

		BreakableComponent.SetHiddenInGame(true);
				/*
		FBreakableHitData HitData;
		HitData.DirectionalForce = this.GetActorForwardVector() * -1000.f + this.GetActorUpVector() * 2000;
		HitData.ScatterForce = 8.f;
		BreakableComponent.Break(HitData);
		*/
		System::SetTimer(this, n"DestroyCompleted", 1.f, false);

		if(ObstacleType == EObstaclesTypes::Small)
		{
			InstigatorPlayer.PlayerHazeAkComp.HazePostEvent(DestroyObstacleAudioEvent);
		}
		else if(ObstacleType == EObstaclesTypes::Medium)
		{
			InstigatorPlayer.PlayerHazeAkComp.HazePostEvent(DestroyObstacleAudioEvent);
		}
		else if(ObstacleType == EObstaclesTypes::Large)
		{
			InstigatorPlayer.PlayerHazeAkComp.HazePostEvent(DestroyObstacleAudioEvent);
		}
	}
	
	UFUNCTION()
	private void DestroyCompleted()
	{
		OnManualDisable();
	}

	void MoveSideWays(float DeltaTime)
	{		
		if(IsObstacleSmallMovingLeft)
		{
			if(AcceleratedFloatY.Value <= -190)
				bMoveLeft = false;
			if(AcceleratedFloatY.Value >= 190)
				bMoveLeft = true;

			if(!bMoveLeft)
			{
				AcceleratedFloatY.SpringTo(190, 2, 0.6f, DeltaTime);
				WallMesh.SetRelativeLocation(FVector(WallMesh.GetRelativeLocation().X, AcceleratedFloatY.Value, WallMesh.GetRelativeLocation().Z));
			}
			if(bMoveLeft)
			{
				AcceleratedFloatY.SpringTo(-190, 2, 0.6f, DeltaTime);
				WallMesh.SetRelativeLocation(FVector(WallMesh.GetRelativeLocation().X, AcceleratedFloatY.Value, WallMesh.GetRelativeLocation().Z));
			}
		}
		if(IsObstacleSmallMovingRight)
		{
			if(AcceleratedFloatY.Value <= -190)
				bMoveLeft = true;
			if(AcceleratedFloatY.Value >= 190)
				bMoveLeft = false;

			if(!bMoveLeft)
			{
				AcceleratedFloatY.SpringTo(-190, 2, 0.6f, DeltaTime);
				WallMesh.SetRelativeLocation(FVector(WallMesh.GetRelativeLocation().X, AcceleratedFloatY.Value, WallMesh.GetRelativeLocation().Z));
			}
			if(bMoveLeft)
			{
				AcceleratedFloatY.SpringTo(190, 2, 0.6f, DeltaTime);
				WallMesh.SetRelativeLocation(FVector(WallMesh.GetRelativeLocation().X, AcceleratedFloatY.Value, WallMesh.GetRelativeLocation().Z));
			}
		}



		if(IsObstacleBigMovingLeft)
		{
			if(AcceleratedFloatY.Value <= -130)
				bMoveLeft = false;
			if(AcceleratedFloatY.Value >= 130)
				bMoveLeft = true;

			if(!bMoveLeft)
			{
				AcceleratedFloatY.SpringTo(130, 3, 0.6f, DeltaTime);
				WallMesh.SetRelativeLocation(FVector(WallMesh.GetRelativeLocation().X, AcceleratedFloatY.Value, WallMesh.GetRelativeLocation().Z));
			}
			if(bMoveLeft)
			{
				AcceleratedFloatY.SpringTo(-130, 3, 0.6f, DeltaTime);
				WallMesh.SetRelativeLocation(FVector(WallMesh.GetRelativeLocation().X, AcceleratedFloatY.Value, WallMesh.GetRelativeLocation().Z));
			}
		}
		if(IsObstacleBigMovingRight)
		{
			if(AcceleratedFloatY.Value <= -130)
				bMoveLeft = true;
			if(AcceleratedFloatY.Value >= 130)
				bMoveLeft = false;

			if(!bMoveLeft)
			{
				AcceleratedFloatY.SpringTo(-130, 3, 0.6f, DeltaTime);
				WallMesh.SetRelativeLocation(FVector(WallMesh.GetRelativeLocation().X, AcceleratedFloatY.Value, WallMesh.GetRelativeLocation().Z));
			}
			if(bMoveLeft)
			{
				AcceleratedFloatY.SpringTo(130, 3, 0.6f, DeltaTime);
				WallMesh.SetRelativeLocation(FVector(WallMesh.GetRelativeLocation().X, AcceleratedFloatY.Value, WallMesh.GetRelativeLocation().Z));
			}
		}
	}
}

enum EObstaclesTypes
{
	Small,
	Medium,
	Large,
}
