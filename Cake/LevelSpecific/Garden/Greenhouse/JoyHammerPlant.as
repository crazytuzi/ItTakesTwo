import Vino.PlayerHealth.PlayerHealthComponent;
import Cake.LevelSpecific.Garden.Greenhouse.JoyHammerPlant_AnimNotify;
import Vino.PlayerHealth.PlayerHealthStatics;
import Cake.LevelSpecific.Garden.Greenhouse.JoyPotGrowingPlants;
import Cake.LevelSpecific.Garden.Greenhouse.JoyPotBaseActor;

UCLASS(Abstract)
class AJoyHammerPlant : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent RootComp;
	UPROPERTY(DefaultComponent)
	USceneComponent HammerImpactDistanceCheckLocation;

	UPROPERTY(DefaultComponent, Attach = RotationRoot)
	UHazeSkeletalMeshComponentBase SkeletalMesh;

	UPROPERTY(DefaultComponent)
	UCapsuleComponent HammerCollider;

	UPROPERTY(DefaultComponent)
	USceneComponent EffectLocation;

	UPROPERTY()
	AJoyPotGrowingPlants JoyPotGrowingPlant;

	UPROPERTY()
	AJoyPotBaseActor JoyPotBaseActor;

	UPROPERTY(Category="JoyHammer")
	bool bPlayerIsInRange = false;

	UPROPERTY(Category="JoyHammer")
	float PlayerInRangeDistance = 800.0f;

	UPROPERTY(Category="JoyHammer")
	float HitRange = 450.0f;

	UPROPERTY(Category="JoyHammer")
	TSubclassOf<UPlayerDeathEffect> DeathEffect;

	UPROPERTY(Category="Audio")
	TSubclassOf<UHazeCapability> HammerPlantAudioCapabilityClass;

	UPROPERTY()
	UNiagaraSystem HammerImpactEffectGround;
	UPROPERTY()
	UNiagaraSystem HammerImpactEffectPlates;
	UPROPERTY()
	UNiagaraSystem ExtraSlowmoEffectPlate;
	UPROPERTY(DefaultComponent)
	UNiagaraComponent HammerSpawnLoopEffect;
	
	UPROPERTY()
	UNiagaraSystem HammerSpawnEffect;
	UPROPERTY()
	UNiagaraSystem HammerDespawnEffect;


	UPROPERTY()
	APlayerTrigger PlayerDeathVolume;

	UPROPERTY()
	bool bPlateDestroyed;
	
	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShake;
	UPROPERTY()
	UForceFeedbackEffect ForceFeedback;
	FHazeAcceleratedFloat AcceleratedFloat;
	UPROPERTY()
	bool bSettingShouldPlayerBeAbleToDieAfterSmash = true;
	bool bCanPlayerDieAfterSmash = true;

	UPROPERTY()
	bool bPlantAlive = false;
	bool bPlantIdle = false;
	bool bPlantPrepareSmash = false;
	bool bPlantSmash = false;

	UPROPERTY()
	bool bPlantIsInPhase3 = false;

	UPROPERTY()
	FVector HeadScale = FVector(1,1,1);

	UPROPERTY()
	ADecalActor ShadowDecal;
	UPROPERTY()
	bool UseShadowDecalForVFXImpactLocation = false;
	bool bLerpShadowBigger = false;
	bool bLerpShadowSmaller = false;
	UPROPERTY()
	bool bSpawnExtraSlowmoEffect = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HammerCollider.AttachToComponent(SkeletalMesh, n"Head", EAttachmentRule::SnapToTarget);
		HammerCollider.AddLocalOffset(FVector(0, 0, 150));
		HammerSpawnLoopEffect.AttachToComponent(SkeletalMesh, n"Head", EAttachmentRule::SnapToTarget);
		HammerImpactDistanceCheckLocation.AttachToComponent(SkeletalMesh, n"Head", EAttachmentRule::SnapToTarget);
		HammerImpactDistanceCheckLocation.AddLocalOffset(FVector(0, 0, 200));
		//EffectLocation.AttachToComponent(SkeletalMesh, n"Head", EAttachmentRule::SnapToTarget);
		//EffectLocation.AddLocalOffset(FVector(100, 225, 170));
		HammerCollider.OnComponentBeginOverlap.AddUFunction(this, n"OnComponentBeginOverlap");
		
		FHazeAnimNotifyDelegate HammerSmashDelegate;
		HammerSmashDelegate.BindUFunction(this, n"HammerSmashHappened");
		BindAnimNotifyDelegate(UAnimNotify_JoyHammerSmash::StaticClass(), HammerSmashDelegate);
		DisableActor(this);

		if(ShadowDecal == nullptr)
			return;
		ShadowDecal.SetActorScale3D(FVector(0,0,0));

		AddCapability(HammerPlantAudioCapabilityClass);
	}

	UFUNCTION()
	void PlantDeactivate()
	{
		Niagara::SpawnSystemAtLocation(HammerDespawnEffect, GetActorLocation(), GetActorRotation());
		bPlantAlive = false;
		bPlantIdle = false;
		bPlantPrepareSmash = false;
		bPlantSmash = false;
		System::SetTimer(this, n"DestroyPlant", 3.0f, true);	
	}

	UFUNCTION()
	void DestroyPlant()
	{
		ShadowDecal.SetActorHiddenInGame(true);
		DestroyActor();
	}

	UFUNCTION()
	void PlantActivate()
	{
		if(this.HasControl())
		{
			NetPlantActivate();
		}
	}
	UFUNCTION(NetFunction)
	void NetPlantActivate()
	{
		Niagara::SpawnSystemAtLocation(HammerSpawnEffect, GetActorLocation(), GetActorRotation());
		HammerSpawnLoopEffect.Activate();
		Game::GetMay().PlayCameraShake(CameraShake, 1.f);
		Game::GetCody().PlayCameraShake(CameraShake, 1.f);
		Game::GetCody().PlayForceFeedback(ForceFeedback, false, false, n"HammerHit");
		Game::GetMay().PlayForceFeedback(ForceFeedback, false, false, n"HammerHit");
		EnableActor(this);
		bPlantAlive = true;
		bPlantIdle = true;
		System::SetTimer(this, n"StopHammerSpawnEffect", 1.5f, false);
	}
	UFUNCTION()
	void StopHammerSpawnEffect()
	{
		HammerSpawnLoopEffect.Deactivate();
	}


	
	UFUNCTION()
	void PlantPrepareSmash(float PrepareTime)
	{
		if(this.HasControl())	
		{
			NetPlantPrepareSmash(PrepareTime);
		}
	}
	UFUNCTION(NetFunction)
	void NetPlantPrepareSmash(float PrepareTime)
	{
		bPlantPrepareSmash = true;
		bCanPlayerDieAfterSmash = true;
		bPlantSmash = false;
		System::SetTimer(this, n"PlantSmash", PrepareTime, false);	
		bLerpShadowSmaller = false;
		bLerpShadowBigger = true;
	}



	UFUNCTION()
	void PlantSmash()
	{	
		bPlantPrepareSmash = false;
		bPlantSmash = true;
		System::SetTimer(this, n"RemoveShadow", 0.75f, false);	
	}

	UFUNCTION()
	void RemoveShadow()
	{
		if(bPlantPrepareSmash != true)
		{
			bLerpShadowBigger = false;
			bLerpShadowSmaller = true;
		}
	}

	UFUNCTION()
	void DamagePlayer(AHazePlayerCharacter Player)
	{
		DamagePlayerHealth(Player, 100);
	}



	UFUNCTION()
	void HammerSmashHappened(AHazeActor Actor, UHazeSkeletalMeshComponentBase MeshComp, UAnimNotify AnimNotify)
	{
		FVector HeadLocation = SkeletalMesh.GetSocketLocation(n"Head");
		float DistanceToMay = HeadLocation.DistXY(Game::GetMay().ActorLocation);
		float DistanceToCody = HeadLocation.DistXY(Game::GetCody().ActorLocation);

		if(bSettingShouldPlayerBeAbleToDieAfterSmash == false)
		{
			System::SetTimer(this, n"TempDisableDeathCollision", 0.35f, false);	
		}

		if(!UseShadowDecalForVFXImpactLocation)
		{
			if(bPlantIsInPhase3 == false)
			{
				Niagara::SpawnSystemAtLocation(HammerImpactEffectGround, EffectLocation.GetWorldLocation(), GetActorRotation());
			}
			else
			{
				Niagara::SpawnSystemAtLocation(HammerImpactEffectPlates, EffectLocation.GetWorldLocation(), GetActorRotation());

				if(bSpawnExtraSlowmoEffect)
					Niagara::SpawnSystemAtLocation(ExtraSlowmoEffectPlate, EffectLocation.GetWorldLocation(), GetActorRotation());
			}

		}
		else
		{
			if(bPlantIsInPhase3 == false)
			{
				Niagara::SpawnSystemAtLocation(HammerImpactEffectGround, ShadowDecal.GetActorLocation(), GetActorRotation());
			}
			else
			{
				Niagara::SpawnSystemAtLocation(HammerImpactEffectPlates, ShadowDecal.GetActorLocation(), GetActorRotation());

				if(bSpawnExtraSlowmoEffect)
					Niagara::SpawnSystemAtLocation(ExtraSlowmoEffectPlate, ShadowDecal.GetActorLocation(), GetActorRotation());
			}
		}


		Game::GetMay().PlayCameraShake(CameraShake, 1.f);
		Game::GetCody().PlayCameraShake(CameraShake, 1.f);
		Game::GetCody().PlayForceFeedback(ForceFeedback, false, false, n"HammerHit");
		Game::GetMay().PlayForceFeedback(ForceFeedback, false, false, n"HammerHit");


		if(DistanceToMay < HitRange)
		{
			if(Game::GetMay().HasControl())
			{
				DamagePlayer(Game::GetMay());
				//Print("May Died from Distance check", 4.f);
			}
		}
		else
		{
			TArray<AActor> Actors;
			PlayerDeathVolume.GetOverlappingActors(Actors);
			for (auto ActorLocal : Actors)
			{
				auto Player = Cast<AHazePlayerCharacter>(ActorLocal);
				if (Player != nullptr)
				{
					if(Game::GetMay().HasControl())
					{
						DamagePlayer(Player);
						//Print("May Died Pot death volume", 4.f);
					}
				}	
			}
		}

		if(DistanceToCody < HitRange)
		{
			if(Game::GetCody().HasControl())
			{
				DamagePlayer(Game::GetCody());
			}
		}
		else
		{
			TArray<AActor> Actors;
			PlayerDeathVolume.GetOverlappingActors(Actors);
			for (auto ActorLocal : Actors)
			{
				auto Player = Cast<AHazePlayerCharacter>(ActorLocal);
				if (Player != nullptr)
				{
					if(Game::GetCody().HasControl())
					{
						DamagePlayer(Player);
					}
				}	
			}
		}
		
		SetCapabilityActionState(n"AudioSmashImpact", EHazeActionState::Active);

		if(JoyPotGrowingPlant == nullptr)
			return;

		JoyPotGrowingPlant.PlayImpactAnimation();
		JoyPotBaseActor.ImpactCrumble();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		//PrintToScreen("bCanPlayerDieAfterSmash " + bCanPlayerDieAfterSmash);
		if(bPlantPrepareSmash == true or bPlantSmash == true)
		{
			FVector HeadLocation = SkeletalMesh.GetSocketLocation(n"Head");
			float DistanceToMay = HeadLocation.DistXY(Game::GetMay().ActorLocation);
			float DistanceToCody = HeadLocation.DistXY(Game::GetCody().ActorLocation);

			if(DistanceToMay < PlayerInRangeDistance || DistanceToCody < PlayerInRangeDistance)
			{
				bPlayerIsInRange = true;
			}
			else
			{
				bPlayerIsInRange = false;			
			}


			if(bLerpShadowBigger == true)
			{
				AcceleratedFloat.SpringTo(3.75f, 15, 1, DeltaSeconds * 2.f);
				ShadowDecal.SetActorScale3D(FVector(0.2, AcceleratedFloat.Value, AcceleratedFloat.Value));
			}
			if(bLerpShadowSmaller == true)
			{
				AcceleratedFloat.SpringTo(0, 15, 1, DeltaSeconds * 17.f);
				ShadowDecal.SetActorScale3D(FVector(0.2, AcceleratedFloat.Value, AcceleratedFloat.Value));
			}
		}
	}


	UFUNCTION()
	void TempDisableDeathCollision()
	{
		bCanPlayerDieAfterSmash = false;
	}

	UFUNCTION()
	void OnComponentBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
	UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, FHitResult& Hit)
	{
		if(bPlantPrepareSmash == true)
			return;
		if(bCanPlayerDieAfterSmash == false)
			return;

		if(OtherActor == Game::GetCody())
		{
			if(Game::GetCody().HasControl())
			{
				DamagePlayer(Game::GetCody());
			}
		}
		if(OtherActor == Game::GetMay())
		{
			if(Game::GetMay().HasControl())
			{
				DamagePlayer(Game::GetMay());
				//Print("May Died from Overlapp", 4.f);
			}
		}
	}
}