import Cake.LevelSpecific.Clockwork.Actors.LastBoss.ClockworkLastBossStatics;
import Peanuts.KeyableMovingActor.KeyableMovingActor;

event void PlatformStartMove();

UCLASS(Meta = (AutoCollapseCategories = "KeyedData DEPRECATED"))
class AClockworkLastBossMovingObject : AKeyableMovingActor
{
	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent ObjectRoot;

	UPROPERTY(DefaultComponent, Attach = ObjectRoot)
	USceneComponent MeshRoot01;

	UPROPERTY(DefaultComponent, Attach = MeshRoot01)
	UStaticMeshComponent Mesh01;
	default Mesh01.CastShadow = true;
	default Mesh01.bCastDynamicShadow = false;
	default Mesh01.LightmapType = ELightmapType::ForceVolumetric;

	UPROPERTY(DefaultComponent, Attach = MeshRoot01)
	USceneComponent MeshRoot02;

	UPROPERTY(DefaultComponent, Attach = MeshRoot02)
	UStaticMeshComponent Mesh02;
	default Mesh02.CastShadow = true;
	default Mesh02.bCastDynamicShadow = false;
	default Mesh02.LightmapType = ELightmapType::ForceVolumetric;

	UPROPERTY(DefaultComponent, Attach = MeshRoot02)
	USceneComponent MeshRoot03;

	UPROPERTY(DefaultComponent, Attach = MeshRoot03)
	UStaticMeshComponent Mesh03;
	default Mesh03.CastShadow = true;
	default Mesh03.bCastDynamicShadow = false;
	default Mesh03.LightmapType = ELightmapType::ForceVolumetric;

	UPROPERTY(DefaultComponent, Attach = MeshRoot03)
	USceneComponent MeshRoot04;

	UPROPERTY(DefaultComponent, Attach = MeshRoot04)
	UStaticMeshComponent Mesh04;	
	default Mesh04.CastShadow = true;
	default Mesh04.bCastDynamicShadow = false;
	default Mesh04.LightmapType = ELightmapType::ForceVolumetric;

	UFUNCTION(BlueprintOverride)
	void GetKeyableComponents(TArray<USceneComponent>& OutComponents)
	{
		OutComponents.Add(ObjectRoot);
		OutComponents.Add(MeshRoot01);
		OutComponents.Add(MeshRoot02);
		OutComponents.Add(MeshRoot03);
		OutComponents.Add(MeshRoot04);
	}
	
	UPROPERTY()
	FHazeTimeLike WiggleTimeline;
	default WiggleTimeline.Duration = 0.2f;
 
	UPROPERTY()
	bool bShouldWiggleAtIterationFinished = false;

	UPROPERTY()
	bool bShouldPlayCamShakeOnFinished = true;

	UPROPERTY()
	bool bShouldPlayForceFeedbackOnFinished = true;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CamShake;

	UPROPERTY()
	UForceFeedbackEffect ForceFeedback;

	UPROPERTY()
	float WiggleAmount = 50.f;
	
	UPROPERTY()
	EClockworkMoveNumber ClockworkMoveNumber;

	UPROPERTY()
	bool bHiddenUntillMoved = false;

	UPROPERTY(Category = "Debug")
	bool bShouldMoveAtBeginPlay = false;

	UPROPERTY()
	float StartDelay = 0.f;

	UPROPERTY()
	PlatformStartMove AudioPlatformStartMove;

	FVector StartingWiggleLocation;
	FVector TargetWiggleLocation;

	FTransform ActorStartPosition;

	bool bShouldLerpToRemoveActor = false;
	float RemoveLerpDuration = 2.f;
	float RemoveLerpAlpha = 0.f;

	bool bIsMoving = false;
	float CurrentTime = 0.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		WiggleTimeline.BindUpdate(this, n"WiggleTimelineUpdate");
		ActorStartPosition = ActorTransform;
		
		if (bShouldMoveAtBeginPlay)
			InitiateMove();

		if (bHiddenUntillMoved)
			SetActorHiddenInGame(true);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bShouldLerpToRemoveActor)
		{
			RemoveLerpAlpha += DeltaTime / RemoveLerpDuration;
			SetActorLocation(ActorStartPosition.Location - (30000.f * RemoveLerpAlpha));

			if (RemoveLerpAlpha >= 1.f)
				DestroyActor();
		}

		if (bIsMoving)
		{
			CurrentTime += DeltaTime;

			if (CurrentTime >= GetTotalDuration())
			{
				bIsMoving = false;
				MoveComponentsToTime(GetTotalDuration());

				if (bShouldWiggleAtIterationFinished)
				{
					StartingWiggleLocation = GetActorLocation();
					TargetWiggleLocation = GetActorLocation() + FVector(0.f, 0.f, WiggleAmount);

					WiggleTimeline.PlayFromStart();
				}

				if (bShouldPlayCamShakeOnFinished)
				{
					TArray<AHazePlayerCharacter> Players = Game::GetPlayers();
					for(auto Player : Players)
						Player.PlayCameraShake(CamShake);
				}

				if (bShouldPlayForceFeedbackOnFinished)
				{
					TArray<AHazePlayerCharacter> Players = Game::GetPlayers();
					for(auto Player : Players)
						Player.PlayForceFeedback(ForceFeedback, false, false, n"MovingObjectClockBos");
				}
			}
			else
			{
				MoveComponentsToTime(FMath::Max(CurrentTime, 0.f));
			}
		}

		if (!bIsMoving && !bShouldLerpToRemoveActor)
			SetActorTickEnabled(false);
	}

	UFUNCTION()
	void InitiateMove(float Delay = 0.f)
	{
		if (bHiddenUntillMoved)
			SetActorHiddenInGame(false);

		bIsMoving = true;
		SetActorTickEnabled(true);

		CurrentTime = -(Delay + StartDelay);
		MoveComponentsToTime(FMath::Max(CurrentTime, 0.f));
		AudioPlatformStartMove.Broadcast();
	}

	UFUNCTION()
	void TeleportToEndLocation()
	{
		if (bHiddenUntillMoved)
			SetActorHiddenInGame(false);

		MoveComponentsToTime(GetTotalDuration());
	}

	UFUNCTION()
	void WiggleTimelineUpdate(float CurrentValue)
	{
		SetActorLocation(FMath::Lerp(StartingWiggleLocation, TargetWiggleLocation, FMath::Sin(CurrentValue * PI)));
	}

	UFUNCTION()
	void LerpAndRemoveObject(float Delay)
	{
		if (Delay <= 0.f)
		{
			bShouldLerpToRemoveActor = true;
			SetActorTickEnabled(true);
			bIsMoving = false;
		}
		else
		{
			System::SetTimer(this, n"SetShouldLerpToRemove", Delay, false);
		}
	}

	UFUNCTION()
	void SetShouldLerpToRemove()
	{
		bShouldLerpToRemoveActor = true;
		SetActorTickEnabled(true);
		bIsMoving = false;
	}

	UFUNCTION(BlueprintEvent)
	void DestroyMovingObject()
	{
	}
}