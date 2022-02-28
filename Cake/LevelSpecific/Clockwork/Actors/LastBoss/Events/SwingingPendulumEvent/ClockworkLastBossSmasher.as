import Cake.LevelSpecific.Clockwork.Actors.LastBoss.ClockworkLastBossMovingObject;
import Cake.Environment.Breakable;
import Cake.Environment.BreakableStatics;
class AClockworkLastBossSmasher : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent FakeShadowMesh;
	default FakeShadowMesh.bHiddenInGame = true;
	default FakeShadowMesh.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent SmasherMesh;
	default SmasherMesh.bHiddenInGame = true;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent DestroyObjectCollision;

	UPROPERTY()
	ABreakableActor BreakableActorToActivate;

	UPROPERTY(DefaultComponent, Attach = SmasherMesh)
	UBoxComponent KillCollision;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent SmashFX;

	UPROPERTY()
	AClockworkLastBossMovingObject ObjectToDestroy;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PendulumImpactEvent;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CamShake;

	UPROPERTY()
	UForceFeedbackEffect SmasherForceFeedback;

	UPROPERTY()
	int SmashOrder = 0;

	FVector ShadowStartingScale = FVector(1.f, 1.f, 1.f);
	FVector ShadowTargetScale = FVector(13.f, 13.f, 13.f);

	FVector SmasherStartingLocation = FVector(0.f, 0.f, 16000.f);
	FVector SmasherTargetLocation = FVector(0.f, 0.f, -8750.f);

	bool bShouldTickTimer = false;
	bool bPendulumShouldFall = false;

	float ScaleShadowAlpha;
	float ScaleShadowDuration = 1.5f;

	float MovePendulumAlpha;
	float MovePendulumDuration = 2.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DestroyObjectCollision.OnComponentBeginOverlap.AddUFunction(this, n"TriggeredOnBeginOverlap");
		BreakableActorToActivate.SetActorHiddenInGame(true);
		BreakableActorToActivate.SetActorEnableCollision(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bShouldTickTimer)
			return;
		
		ScaleShadowAlpha += DeltaTime / ScaleShadowDuration;

		if (ScaleShadowAlpha > 0.75f)
			bPendulumShouldFall = true;
		
		if (ScaleShadowAlpha >= 1.f)
		{
			ScaleShadowAlpha = 1.f;
			FakeShadowMesh.SetHiddenInGame(true);
		}

		FakeShadowMesh.SetRelativeScale3D(FMath::Lerp(ShadowStartingScale, ShadowTargetScale, ScaleShadowAlpha));

		if (!bPendulumShouldFall)
			return;

		MovePendulumAlpha += DeltaTime / MovePendulumDuration;

		if (MovePendulumAlpha >= 1.f)
		{
			DestroyActor();
		}

		SmasherMesh.SetRelativeLocation(FMath::Lerp(SmasherStartingLocation, SmasherTargetLocation, MovePendulumAlpha));
	}

	UFUNCTION(CallInEditor)
	void SetReferences()
	{
		
		bool bObjectHasBeenSet = false;
		bool bBreakActorHasBeenSet = false;
		
		FVector Start = GetActorLocation() + FVector(0.f, 0.f, 5000.f);
		FVector End = GetActorLocation() + FVector(0.f, 0.f, -50000.f);
		FQuat Rot = FRotator::ZeroRotator.Quaternion();
		ETraceTypeQuery TraceType = ETraceTypeQuery::Visibility;			
		TArray<AActor> ActorsToIgnore;
		TArray<FHitResult> HitResultsArray;
	
		Trace::CapsuleTraceMultiAllHitsByChannel(Start, End, Rot, 10.f, 10.f, TraceType, true, ActorsToIgnore, HitResultsArray, -1.f);  

		for (FHitResult Hit : HitResultsArray)
		{
			AClockworkLastBossMovingObject Object = Cast<AClockworkLastBossMovingObject>(Hit.Actor);

			if (Object != nullptr && !bObjectHasBeenSet)
			{
				bObjectHasBeenSet = true;
				ObjectToDestroy = Object;
			}

			ABreakableActor BreakActor = Cast<ABreakableActor>(Hit.Actor);

			if (BreakActor != nullptr && !bBreakActorHasBeenSet)
			{
				bBreakActorHasBeenSet = true;
				BreakableActorToActivate = BreakActor;
			}
		}
}

	UFUNCTION()
	void StartSmash()
	{
		bShouldTickTimer = true;
		FakeShadowMesh.SetHiddenInGame(false);
		SmasherMesh.SetHiddenInGame(false);
	}

	void StartSmashFromTimer(float DelayAmount)
	{
		if (DelayAmount <= 0.f)
			StartSmash();
		else
			System::SetTimer(this, n"StartSmash", DelayAmount, false);
	}

	UFUNCTION()
    void TriggeredOnBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex, 
    bool bFromSweep, FHitResult& Hit)
    {
		AClockworkLastBossSmasher Smasher = Cast<AClockworkLastBossSmasher>(OtherActor);

		if (Smasher != nullptr)
		{
			TArray<AHazePlayerCharacter> Players = Game::GetPlayers();
			for (auto Player : Players)
				Player.PlayForceFeedback(SmasherForceFeedback, false, false, n"PendulumSmasher");

			SmashFX.Activate();
			BreakableActorToActivate.SetActorHiddenInGame(false);
			FBreakableHitData BreakHit;
			// BreakHit.HitLocation = BreakableActorToActivate.GetActorLocation();
			// BreakHit.DirectionalForce = FVector(0.f, 0.f, -10.f);
			// BreakHit.ScatterForce = 20.f;
			BreakBreakableActor(BreakableActorToActivate, BreakHit);
			Game::GetCody().PlayCameraShake(CamShake, 1.f);
			Game::GetMay().PlayCameraShake(CamShake, 1.f);

			/*
				TC: ObjectToDestroy is set in the level, via SetReferences editor function
				They all seem to have references set in the level, so the only way I can see ObjectToDestroy being nullptr is if it has already been destroyed
				Added a nullptr check, as all its doing is trying to destroy something that isn't there.
			*/
			if (ObjectToDestroy != nullptr)
				ObjectToDestroy.DestroyActor();
			HazeAkComp.HazePostEvent(PendulumImpactEvent);
		}
    }
}