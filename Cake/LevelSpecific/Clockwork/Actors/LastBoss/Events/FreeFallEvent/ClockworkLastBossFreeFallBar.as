import Vino.PlayerHealth.PlayerDamageEffect;
import Vino.PlayerHealth.PlayerHealthStatics;
import Vino.Collision.LazyPlayerOverlapManagerComponent;
class AClockworkLastBossFreeFallBar : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent BarMesh;

	UPROPERTY(DefaultComponent, Attach = BarMesh)
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
	UAkAudioEvent BarAppearAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent BarDisappearAudioEvent;

	UPROPERTY()
	UNiagaraSystem HitFX;

	UPROPERTY()
	float DistanceToActive = 7500.f;

	UPROPERTY()
	float DistanceToDeactivate = -10.f;

	UPROPERTY()
	FHazeTimeLike MoveBarTimeline;
	default MoveBarTimeline.Duration = 0.5f;

	FVector StartingLocation = FVector::ZeroVector;
	
	UPROPERTY(Meta = (MakeEditWidget))
	FVector TargetLocation = FVector::ZeroVector;

	UPROPERTY()
	bool bShowTargetState = false;

	UPROPERTY()
	TSubclassOf<UPlayerDamageEffect> DamageEffect;	

	UPROPERTY()
	bool bStartWithRandomDelay = true;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CamShake;

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
		MoveBarTimeline.BindUpdate(this, n"MoveBarTimelineUpdate");
		MeshRoot.SetRelativeLocation(StartingLocation);

		BarMesh.OnComponentBeginOverlap.AddUFunction(this, n"OnMeshOverlap");

		OverlapComp.MakeOverlapsLazy(BarMesh);
		OverlapComp.SetLazyOverlapsEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (bShowTargetState)
		{
			MeshRoot.SetRelativeLocation(TargetLocation);
		} else
		{
			MeshRoot.SetRelativeLocation(StartingLocation);
		}

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{	
		if(GetDistanceToPlayer() < DistanceToActive && !bIsActivated && !bHasActivated)
		{
			bIsActivated = true;
			bHasActivated = true;
			SetBarActive(bIsActivated);
		}

		if (GetDistanceToPlayer() < DistanceToDeactivate && bIsActivated)
		{
			MoveBarTimeline.Duration = 0.25f;
			bIsActivated = false;
			SetBarActive(bIsActivated);
		}
	}

	UFUNCTION()
	void MoveBarTimelineUpdate(float CurrentValue)
	{
		MeshRoot.SetRelativeLocation(FMath::Lerp(StartingLocation, TargetLocation, CurrentValue));
		if (CurrentValue >= 1.f)
			PlayFX();
	}

	void PlayFX()
	{
		if (bHasPlayedFX)
			return;

		bHasPlayedFX = true;
		FXComp.Activate(true);
		
		Game::GetCody().PlayCameraShake(CamShake);

		Game::GetCody().PlayForceFeedback(ForceFeedback, false, false, n"FreeFallCog");
		Game::GetMay().PlayForceFeedback(ForceFeedback, false, false, n"FreeFallCog");
	}

	void SetToTargetLocation()
	{
		MeshRoot.SetRelativeLocation(TargetLocation);
		bDamageDisabled = true;
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
	void SetBarActive(bool bActivate)
	{
		if (bActivate)
		{
			if (bStartWithRandomDelay)
				System::SetTimer(this, n"PlayBarTimeline", FMath::RandRange(0.f, 0.25f), false);
			else
				PlayBarTimeline();
		}
		else
		{
			PlayBarTimelineReversed();
		}

		OverlapComp.SetLazyOverlapsEnabled(bActivate);
	}

	float GetDistanceToPlayer()
	{
		AHazePlayerCharacter Player = Game::GetCody();
		if (Player.IsPlayerDead())
			Player = Game::GetMay();

		float ZDistance = Player.GetActorLocation().Z - GetActorLocation().Z;
		return ZDistance;
	}

	UFUNCTION()
	void PlayBarTimeline()
	{
		MoveBarTimeline.PlayFromStart();
		HazeAkComp.HazePostEvent(BarAppearAudioEvent);
	}

	UFUNCTION()
	void PlayBarTimelineReversed()
	{
		MoveBarTimeline.ReverseFromEnd();
		HazeAkComp.HazePostEvent(BarDisappearAudioEvent);
	}
}