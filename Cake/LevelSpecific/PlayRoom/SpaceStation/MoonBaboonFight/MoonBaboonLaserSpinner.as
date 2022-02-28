import Vino.PlayerHealth.PlayerHealthStatics;
import Peanuts.Audio.HazeAudioEffects.DopplerEffect;
import Peanuts.Audio.AudioStatics;

event void FLaserSpinnerSpawnEvent();

UCLASS(Abstract)
class AMoonBaboonLaserSpinner : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent SpinnerRoot;

	UPROPERTY(DefaultComponent, Attach = SpinnerRoot)
	UStaticMeshComponent SpinnerMesh;

	UPROPERTY(DefaultComponent, Attach = SpinnerMesh)
	UArrowComponent LaserNozzle0;

	UPROPERTY(DefaultComponent, Attach = SpinnerMesh)
	UArrowComponent LaserNozzle1;

	UPROPERTY(DefaultComponent, Attach = SpinnerMesh)
	UArrowComponent LaserNozzle2;

	UPROPERTY(DefaultComponent, Attach = SpinnerMesh)
	UArrowComponent LaserNozzle3;

	UPROPERTY(DefaultComponent, Attach = SpinnerMesh)
	UArrowComponent LaserNozzle4;

	UPROPERTY(DefaultComponent, Attach = SpinnerMesh)
	UArrowComponent LaserNozzle5;

	UPROPERTY(DefaultComponent, Attach = SpinnerMesh)
	UArrowComponent LaserNozzle6;

	UPROPERTY(DefaultComponent, Attach = SpinnerMesh)
	UArrowComponent LaserNozzle7;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bDisabledAtStart = true;

	UPROPERTY()
	ETimelineDirection SpinDirection;

	UPROPERTY(NotVisible)
	TArray<UArrowComponent> AllNozzles;
	TArray<UNiagaraComponent> Lasers;
	float CurLaserLength;
	float LaserLengthMultiplier = 2500.f;
	float MaximumLaserLength = 10000.f;
	float CurSpinSpeed;
	float SpinSpeedMultiplier = 0.35f;

	float DamageAmount = 0.5f;

	UPROPERTY()
	bool bHalfLaserAmount = false;

	UPROPERTY()
	float MaxSpinSpeed = 30.f;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem LaserEffect;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike SpawnTimeLike;

	bool bFullySpawned = false;
	bool bDespawning = false;	

	UPROPERTY()
	FLaserSpinnerSpawnEvent OnLaserSpinnerFullySpawned;

	UPROPERTY()
	FLaserSpinnerSpawnEvent OnLaserSpinnerFullyDespawned;

	TArray<AActor> ActorsToIgnore;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UPlayerDamageEffect> DamageEffect;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UPlayerDeathEffect> DeathEffect;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent TowerHazeAkComp;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent LaserSpinnerHazeAkComp;

	TArray<UHazeAkComponent> LaserHazeAkComps;
	TArray<bool> LaserPassbyTriggerChecks;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartLaserSpinnerLoopingEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopLaserSpinnerLoopingEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartLaserSpinnerLoopingCloseEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartLaserSpinnerPassbyEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent SpawnLaserSpinnerTowerEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent DespawnLaserSpinnerTowerEvent;

	UPROPERTY(Category = "Audio Events")
	float LaserMaxDistanceToPlayer = 1500.f;

	FHazeAudioEventInstance LaserSpinnerLoopingEventInstance;
	TArray<UDopplerEffect> DopplerEffectInstances;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorEnableCollision(false);

		SpawnTimeLike.BindUpdate(this, n"UpdateSpawn");
		SpawnTimeLike.BindFinished(this, n"FinishSpawn");

		GetComponentsByClass(AllNozzles);
		if (bHalfLaserAmount)
		{
			AllNozzles.RemoveAt(7);
			AllNozzles.RemoveAt(5);
			AllNozzles.RemoveAt(3);
			AllNozzles.RemoveAt(1);
		}

		TArray<AMoonBaboonLaserSpinner> AllLaserSpinners;
		GetAllActorsOfClass(AllLaserSpinners);
		for (AMoonBaboonLaserSpinner CurSpinner : AllLaserSpinners)
			ActorsToIgnore.Add(CurSpinner);

		for(UArrowComponent Nozzle : AllNozzles)
		{
			UHazeAkComponent LaserHazeAkComp = UHazeAkComponent::Create(this);
			LaserHazeAkComps.Add(LaserHazeAkComp);
			LaserPassbyTriggerChecks.Add(true);
		}	

		for(UHazeAkComponent LaserHazeAkComp : LaserHazeAkComps)
		{
			UDopplerEffect LaserDoppler = Cast<UDopplerEffect>(LaserHazeAkComp.AddEffect(UDopplerEffect::StaticClass()));
			LaserDoppler.PlayPassbySound(StartLaserSpinnerPassbyEvent, 0.3f, 2);

			DopplerEffectInstances.Add(LaserDoppler);

			LaserHazeAkComp.SetTrackDistanceToPlayer(true, MaxRadius = LaserMaxDistanceToPlayer);
		}

		for(int i = 0; i < DopplerEffectInstances.Num(); ++i)
		{
			DopplerEffectInstances[i].SetObjectDopplerValues(true, 10000.f, Observer = EHazeDopplerObserverType::May);
		}
	
	}

	UFUNCTION()
	void SpawnLaserSpinner()
	{
		SetActorEnableCollision(true);
		bFullySpawned = false;
		bDespawning = false;
		LaserLengthMultiplier = 2500.f;
		SpinSpeedMultiplier = 0.35f;
		CurLaserLength = 0.f;
		CurSpinSpeed = 0.f;
		SpawnTimeLike.PlayFromStart();
		TowerHazeAkComp.HazePostEvent(SpawnLaserSpinnerTowerEvent);		

		EnableActor(nullptr);
	}

	UFUNCTION()
	void StartDespawningLaser()
	{
		bDespawning = true;
		SpinSpeedMultiplier = -0.35f;
		LaserLengthMultiplier = -5000.f;
		TowerHazeAkComp.HazePostEvent(DespawnLaserSpinnerTowerEvent);	

		if(StopLaserSpinnerLoopingEvent != nullptr)
		{
			for(UHazeAkComponent LaserComp : LaserHazeAkComps)
			{
				LaserComp.HazePostEvent(StopLaserSpinnerLoopingEvent);
			}
		}

		ToggleLaserDopplerEffects(true);
	}

	UFUNCTION()
	void UpdateSpawn(float CurValue)
	{
		FVector CurLoc = FMath::Lerp(FVector(0.f, 0.f, -300.f), FVector(0.f, 0.f, 170.f), CurValue);
		SpinnerRoot.SetRelativeLocation(CurLoc);
	}

	UFUNCTION()
	void FinishSpawn()
	{
		if (!bDespawning)
		{
			for (UArrowComponent CurNozzle : AllNozzles)
			{
				UNiagaraComponent CurLaser = Niagara::SpawnSystemAttached(LaserEffect, CurNozzle, n"None", CurNozzle.WorldLocation, FRotator::ZeroRotator, EAttachLocation::KeepWorldPosition, true);
				Lasers.Add(CurLaser);
			}

			if(StartLaserSpinnerLoopingEvent != nullptr)		
			{
				for(UHazeAkComponent LaserComp : LaserHazeAkComps)
				{
					LaserComp.HazePostEvent(StartLaserSpinnerLoopingEvent);				
				}
			}

			if(StartLaserSpinnerLoopingCloseEvent != nullptr)
			{
				LaserSpinnerHazeAkComp.HazePostEvent(StartLaserSpinnerLoopingCloseEvent);
			} 
			
			//System::SetTimer(this, n"StartDespawningLaser", ActiveTime, false);
		}
		else
		{
			SetActorEnableCollision(false);
			OnLaserSpinnerFullyDespawned.Broadcast();
			ToggleLaserDopplerEffects(false);

			DisableActor(nullptr);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (Lasers.Num() != 0)
		{
			CurLaserLength += LaserLengthMultiplier * DeltaTime;
			CurLaserLength = FMath::Clamp(CurLaserLength, 0.f, MaximumLaserLength);
			
			if (CurLaserLength >= MaximumLaserLength && !bFullySpawned)
			{
				bFullySpawned = true;
				OnLaserSpinnerFullySpawned.Broadcast();
			}
					
			for (int i = 0; i < Lasers.Num(); ++i)
			{
				Lasers[i].SetNiagaraVariableVec3("User.BeamStart", Lasers[i].AttachParent.WorldLocation);
										
				FHitResult LaserHit;
				System::LineTraceSingle(Lasers[i].AttachParent.WorldLocation, Lasers[i].AttachParent.WorldLocation + (Lasers[i].AttachParent.ForwardVector * CurLaserLength), ETraceTypeQuery::Visibility, false, ActorsToIgnore, EDrawDebugTrace::None, LaserHit, true);
				
				FVector LaserEndLoc;

				if (LaserHit.bBlockingHit)
				{
					LaserEndLoc = LaserHit.Location;

					AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(LaserHit.Actor);
					if (Player != nullptr)
					{
						DealDamageToPlayer(Player);
					}
				}
				else LaserEndLoc = LaserHit.TraceEnd;

				Lasers[i].SetNiagaraVariableVec3("User.BeamEnd", LaserEndLoc);			

				FVector OutMayPos = FMath::ClosestPointOnLine(Lasers[i].AttachParent.WorldLocation, LaserEndLoc, Game::GetMay().GetActorLocation());	
				FVector OutCodyPos = FMath::ClosestPointOnLine(Lasers[i].AttachParent.WorldLocation, LaserEndLoc, Game::GetCody().GetActorLocation());								

				float CodyDistance = OutCodyPos.Distance(Game::GetCody().GetActorLocation());
                float MayDistance = OutMayPos.Distance(Game::GetMay().GetActorLocation());

				if(MayDistance <= CodyDistance)
                {
                    LaserHazeAkComps[i].SetWorldLocation(OutMayPos);
                }
                else
                {
                    LaserHazeAkComps[i].SetWorldLocation(OutCodyPos);                                       
                }							
			}			

			float DistanceToClosestPlayer = GetActorLocation().Distance(LaserSpinnerHazeAkComp.GetClosestPlayer().GetActorLocation());
			float NormalizedSpinnerDistance = FMath::Clamp(HazeAudio::NormalizeRTPC(DistanceToClosestPlayer, 0.f, CurLaserLength, 0.f, 1.f), 0.f, 1.f);	

			LaserSpinnerHazeAkComp.SetRTPCValue(HazeAudio::RTPC::LaserSpinnerDistanceRTPC, NormalizedSpinnerDistance, 0.f);	

			for(UHazeAkComponent LaserHazeAkComp : LaserHazeAkComps)
			{
				float ClosestPlayerDistance = LaserHazeAkComp.GetWorldLocation().Distance(LaserSpinnerHazeAkComp.GetClosestPlayer().GetActorLocation());
				float NormalizedDistance = FMath::Clamp(HazeAudio::NormalizeRTPC(ClosestPlayerDistance, 0.f, CurLaserLength, 0.f, 1.f), 0.f, 1.f);	

				LaserHazeAkComp.SetRTPCValue(HazeAudio::RTPC::LaserSpinnerDistanceRTPC, NormalizedSpinnerDistance, 0.f);
			}

			if (bDespawning && CurLaserLength == 0)
			{
				Lasers.Empty();
				SpawnTimeLike.ReverseFromEnd();
			}

			int SpinDirectionMultiplier = SpinDirection == ETimelineDirection::Forward ? 1 : -1;

			CurSpinSpeed += SpinSpeedMultiplier * SpinDirectionMultiplier;
			CurSpinSpeed = FMath::Clamp(CurSpinSpeed, -MaxSpinSpeed, MaxSpinSpeed);

			AddActorWorldRotation(FRotator(0.f, CurSpinSpeed * DeltaTime, 0.f));
		}
	}

	UFUNCTION()
	void ChangeDamageAmount(float NewDamageAmount)
	{
		DamageAmount = NewDamageAmount;
	}

	void DealDamageToPlayer(AHazePlayerCharacter Player)
	{
		Player.DamagePlayerHealth(DamageAmount, DamageEffect, DeathEffect);
	}

	void ToggleLaserDopplerEffects(bool bToggle)
	{
		for(UDopplerEffect Doppler : DopplerEffectInstances)
		{
			Doppler.bActive = bToggle;
		}
	}
}