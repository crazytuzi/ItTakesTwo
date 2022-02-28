import Vino.PlayerHealth.PlayerHealthStatics;
import Vino.Collision.LazyPlayerOverlapManagerComponent;
class AClockworkLastBossFreeFallCog : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;
	
	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent BarMesh;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent CogMesh1;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent CogMesh2;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UNiagaraComponent FXComp;
	default FXComp.bAutoActivate = false;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.bDisabledAtStart = true;

	UPROPERTY(DefaultComponent)
	ULazyPlayerOverlapManagerComponent OverlapComp;
	default OverlapComp.ActorResponsiveDistance = 20000.f;
	default OverlapComp.bAutoActivate = false;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent CogAppearAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent CogDisappearAudioEvent;

	UPROPERTY()
	UNiagaraSystem HitFX;

	UPROPERTY()
	float DistanceToActive = 7500.f;

	UPROPERTY()
	float DistanceToDeactivate = -100.f;

	UPROPERTY()
	bool bStartWithRandomDelay = false;

	UPROPERTY()
	FHazeTimeLike MoveCogTimeline;
	default MoveCogTimeline.Duration = 0.5f;

	FVector StartingLocation = FVector::ZeroVector;
	
	UPROPERTY(Meta = (MakeEditWidget))
	FVector TargetLocation = FVector::ZeroVector;
	FRotator StartingRotation = FRotator::ZeroRotator;
	
	UPROPERTY(Meta = (MakeEditWidget))
	FRotator TargetRotation = FRotator::ZeroRotator;

	UPROPERTY()
	bool bShowTargetState = false;

	UPROPERTY()
	TSubclassOf<UPlayerDamageEffect> DamageEffect;	

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CamShake;

	UPROPERTY()
	UNiagaraSystem FX;

	UPROPERTY()
	bool bShouldGoBack = true;

	UPROPERTY()
	UForceFeedbackEffect ForceFeedback;

	bool bHasActivated = false;
	bool bIsActivated = false;
	bool bHasDamagedPlayer = false;
	bool bHasPlayedFX = false;
	bool bDamageDisabled = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveCogTimeline.BindUpdate(this, n"MoveCogTimelineUpdate");
		MeshRoot.SetRelativeLocation(StartingLocation);
		MeshRoot.SetRelativeRotation(StartingRotation);

		CogMesh1.OnComponentBeginOverlap.AddUFunction(this, n"OnMeshOverlap");
		CogMesh2.OnComponentBeginOverlap.AddUFunction(this, n"OnMeshOverlap");
		BarMesh.OnComponentBeginOverlap.AddUFunction(this, n"OnMeshOverlap");

		OverlapComp.MakeOverlapsLazy(CogMesh1);
		OverlapComp.MakeOverlapsLazy(CogMesh2);
		OverlapComp.MakeOverlapsLazy(BarMesh);
		OverlapComp.SetLazyOverlapsEnabled(false);

		FXComp.SetRelativeRotation(TargetRotation);
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (bShowTargetState)
		{
			MeshRoot.SetRelativeLocation(TargetLocation);
			MeshRoot.SetRelativeRotation(TargetRotation);
		} else
		{
			MeshRoot.SetRelativeLocation(StartingLocation);
			MeshRoot.SetRelativeRotation(StartingRotation);
		}

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{	
		if(GetDistanceToPlayer() < DistanceToActive && !bIsActivated && !bHasActivated)
		{
			bIsActivated = true;
			bHasActivated = true;
			SetCogsActive(bIsActivated);
		}

		if (GetDistanceToPlayer() < DistanceToDeactivate && bIsActivated)
		{
			bIsActivated = false;
			SetCogsActive(bIsActivated);
		}
		
		CogMesh1.AddRelativeRotation(FRotator(0.f, 350.f * DeltaTime, 0.f));
		CogMesh2.AddRelativeRotation(FRotator(0.f, 350.f * DeltaTime, 0.f));
	}

	UFUNCTION()
	void MoveCogTimelineUpdate(float CurrentValue)
	{
		MeshRoot.SetRelativeLocation(FMath::Lerp(StartingLocation, TargetLocation, CurrentValue));
		MeshRoot.SetRelativeRotation(FMath::LerpShortestPath(StartingRotation, TargetRotation, CurrentValue));
	}

	UFUNCTION()
	void OnMeshOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex, 
    bool bFromSweep, FHitResult& Hit)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		if (Player == nullptr)
			return;

		if (!Player.HasControl())
			return;

		if (bHasDamagedPlayer)
			return;
		
		if (bDamageDisabled)
			return;

		bHasDamagedPlayer = true;
		NetPlayerHitCog(Player);
		Player.SetCapabilityActionState(n"FreeFallCollidedBar", EHazeActionState::ActiveForOneFrame);
		Niagara::SpawnSystemAttached(HitFX, Player.RootComponent, NAME_None, FVector::ZeroVector, FRotator::ZeroRotator, EAttachLocation::SnapToTarget, true);
	}

	UFUNCTION(NetFunction)
	void NetPlayerHitCog(AHazePlayerCharacter Player)
	{
		Player.DamagePlayerHealth(0.25f, DamageEffect);
		//DestroyActor();
	}

	UFUNCTION()
	void SetCogsActive(bool bActivate)
	{
		if (bActivate)
		{
			if (bStartWithRandomDelay)
				System::SetTimer(this, n"PlayCogTimeline", FMath::RandRange(0.f, 0.4f), false);
			else
				PlayCogTimeline();
		}
		else
		{
			if (bShouldGoBack)
				PlayCogTimelineReversed();
		}

		OverlapComp.SetLazyOverlapsEnabled(bActivate);
	}

	UFUNCTION()
	void PlayCogTimeline()
	{
		MoveCogTimeline.PlayFromStart();
		PlayCogFX();
		HazeAkComp.HazePostEvent(CogAppearAudioEvent);
	}

	UFUNCTION()
	void PlayCogTimelineReversed()
	{
		MoveCogTimeline.ReverseFromEnd();
		HazeAkComp.HazePostEvent(CogDisappearAudioEvent);
	}

	void SetToTargetLocation()
	{
		MeshRoot.SetRelativeLocation(TargetLocation);
		MeshRoot.SetRelativeRotation(TargetRotation);
		bDamageDisabled = true;
	}

	void PlayCogFX()
	{
		if (bHasPlayedFX)
			return;

		bHasPlayedFX = true;
		FXComp.Activate(true);
		//Niagara::SpawnSystemAttached(FX, FXComp, n"", FVector::ZeroVector, FRotator::ZeroRotator, EAttachLocation::SnapToTarget, true);

		Game::GetCody().PlayCameraShake(CamShake);
		
		Game::GetCody().PlayForceFeedback(ForceFeedback, false, false, n"FreeFallCog");
		Game::GetMay().PlayForceFeedback(ForceFeedback, false, false, n"FreeFallCog");
	}

	float GetDistanceToPlayer()
	{
		AHazePlayerCharacter Player = Game::GetCody();
		if (Player.IsPlayerDead())
			Player = Game::GetMay();

		float ZDistance = Player.GetActorLocation().Z - GetActorLocation().Z;
		return ZDistance;
	}
}