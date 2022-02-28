import Peanuts.Spline.SplineComponent;
import Cake.LevelSpecific.Clockwork.HorseDerby.DerbyHorseSplineTrack;
import Cake.LevelSpecific.Clockwork.HorseDerby.DerbyHorseActor;

event void FOnDisableHorseDerbyObstacle(AHorseDerbyObstacleActor Actor);

enum EHorseDerbyObstacle
{
	Crouch,
	Jump
}

enum EHorseDerbyObstacleType
{
	LowObstacles,
	HighObstacles
}

class AHorseDerbyObstacleActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent EffectLocation;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent CollisionTrigger;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent SparkSystem;
	default SparkSystem.SetAutoActivate(false);

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ObstacleDestructionEvent;

	UPROPERTY(Category = "Setup")
	TSubclassOf<UHazeCapability> ObstacleSplineMoveCapability;

	UPROPERTY(DefaultComponent)
	UHazeSplineFollowComponent SplineFollowComp;

	UPROPERTY(Category = "Setup")
	EHorseDerbyObstacleType HorseDerbyObstacleType;
	
	ADerbyHorseActor TargetPlayer;

	UPROPERTY(Category = "Settings")
	FVector Offset = FVector::ZeroVector;

	UPROPERTY()
	UNiagaraSystem BreakEffect;

	UPROPERTY(Category = "Debug")
	bool bReverseResetDirection = false;

	ADerbyHorseSplineTrack SplineTrack;

	FOnDisableHorseDerbyObstacle DisableEvent;

	UPROPERTY(Category = "Debug")
	bool ActiveObstacle = false;

	UPROPERTY()
	float CullDistanceMultiplier = 1.0f;

	UPROPERTY()
	float PlayRate;
	
	float MaxDelay = 1.2f;

	float BwdRangeHigh = 60.f;
	float BwdRangeLow = -200.f;

	float ForwardRange = 250.f;
	float BackwardRange;

	bool bCollided = false;

	UPROPERTY()
	FRotator StartingRot;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		MeshComp.SetCullDistance(Editor::GetDefaultCullingDistance(MeshComp) * CullDistanceMultiplier);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (HorseDerbyObstacleType == EHorseDerbyObstacleType::LowObstacles)
			BackwardRange = BwdRangeLow;
		else
			BackwardRange = BwdRangeHigh;
	
		SetActorTickEnabled(false);

		StartingRot = MeshComp.RelativeRotation;

		PlayRate = FMath::RandRange(0.8f, MaxDelay);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bCollided)
		{
			BP_MeshShifting();

			FVector TargetDelta =  ActorLocation - TargetPlayer.ActorLocation;
			float Distance = ActorForwardVector.DotProduct(TargetDelta);

			if (Distance <= ForwardRange && Distance >= BackwardRange)
			{
				if (HorseDerbyObstacleType == EHorseDerbyObstacleType::LowObstacles && TargetPlayer.HorseDerbyActorState != EHorseDerbyActorState::Jump)
				{
					bCollided = true;
					
					if (TargetPlayer.HasControl())
						NetOnCollision();

					if (TargetPlayer.HorseDerbyCollideState == EHorseDerbyCollideState::Available)
						TargetPlayer.Collided = true;
				}
				else if (HorseDerbyObstacleType == EHorseDerbyObstacleType::HighObstacles && TargetPlayer.HorseDerbyActorState != EHorseDerbyActorState::Crouch)
				{
					bCollided = true;

					if (TargetPlayer.HasControl())
						NetOnCollision();
					
					if (TargetPlayer.HorseDerbyCollideState == EHorseDerbyCollideState::Available)
						TargetPlayer.Collided = true;
				}
			}
		}
	}

	void SetTargetPlayer(ADerbyHorseActor InPlayer)
	{
		SetActorTickEnabled(true);
		SparkSystem.SetActive(true);
		TargetPlayer = InPlayer;
		bCollided = false;

		if (InPlayer.InteractingPlayer.IsMay())
			Print("Obstacle: " + Name);
	}

	void InitializeObstacle()
	{
		AddCapability(ObstacleSplineMoveCapability);
	}

	UFUNCTION(NetFunction)
	void NetOnCollision()
	{
		Niagara::SpawnSystemAtLocation(BreakEffect, EffectLocation.WorldLocation, FRotator(0,180.f,0));
		UHazeAkComponent::HazePostEventFireForget(ObstacleDestructionEvent, this.GetActorTransform());
		DisableEvent.Broadcast(this);
		SparkSystem.SetActive(false);
		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintEvent)
	void BP_MeshShifting() {}

	UFUNCTION(BlueprintEvent)
	void BP_SetPlayRate() {}
}