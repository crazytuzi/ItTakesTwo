import Cake.LevelSpecific.Music.Cymbal.Cymbal;
import Cake.LevelSpecific.Music.Cymbal.CymbalComponent;
import Vino.Movement.Components.MovementComponent;
import Peanuts.Audio.HazeAudioEffects.DopplerEffect;
event void FOnWallExploded());
event void FOnKilledPlayer(AHazePlayerCharacter Player));

class ASqueezeBoxProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent WallMesh;
	UPROPERTY(DefaultComponent, Attach = WallMesh)
	UBoxComponent WallMeshTrigger;
	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncVectorComponent SmoothVectorSync;
	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent SmoothFloatSync;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent CodyImpactLocation;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	USphereComponent SphereTrigger;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UNiagaraComponent ExplosionParticleSystem;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UNiagaraComponent WallOfSoundParticleSystem;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UArrowComponent PushBackArrowDirection;
	ASqueezeBoxProjectile Self;

	UPlayerHazeAkComponent PlayerHazeAkComp;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent ProjectileHazeAkComp;

	UPROPERTY()
	UForceFeedbackEffect ForceFeedbackShieldImpact;
	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShakeShieldImpact;

	UPROPERTY()
	float RandomUVFloat = 50;

	UDopplerEffect DopplerEffect;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PassByEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent CymbalBlockEvent;
	UPROPERTY()
	FOnWallExploded OnWallExploded;
	UPROPERTY()
	FOnKilledPlayer OnKilledPlayer;

	UPROPERTY()
	UNiagaraSystem ExplosionEffect;
	UMaterialInstanceDynamic Material;
	FHazeAcceleratedFloat AcceleratedFloatOpacity;
	FHazeAcceleratedFloat AcceleratedFlotWallScale;
	default AcceleratedFlotWallScale.Value = 8;

	FVector Velocity = 400.f;
	FVector Direction;

	UPROPERTY()
	float FadeHeightLocation = 13200;
	
	float StartTransparencyTimer = 0;
	float DeltaRotation = 2.f;

	bool CodyInsideSafeTrigger = false;
	bool MayInsideSafeTrigger = false;

	FVector InverseWallFowardVector;
	FVector ProjectileEndLocation;
	float DistanceFromEndLocation = 5000;
	bool bPlayerCanTakeDamage = true;
	bool bReachedEndPoint = false;
	bool DoOnce = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetControlSide(Game::GetCody());
		Direction = GetActorForwardVector();
		SmoothFloatSync.Value = 8;
		WallMeshTrigger.OnComponentBeginOverlap.AddUFunction(this, n"OnComponentBeginOverlap");
		SphereTrigger.OnComponentBeginOverlap.AddUFunction(this, n"OnComponentBeginOverlapSafe");
		SphereTrigger.OnComponentEndOverlap.AddUFunction(this, n"OnComponentEndOverlapSafe");
		InverseWallFowardVector = -GetActorForwardVector();
		WallMesh.SetVectorParameterValueOnMaterials(n"BubbleMinSize", FVector(500,0,0));
		WallMesh.SetVectorParameterValueOnMaterials(n"BubbleMaxSize", FVector(550,0,0));
		Material = WallMesh.CreateDynamicMaterialInstance(0);
		Material.SetScalarParameterValue(n"Opacity", 0);

		DopplerEffect = Cast<UDopplerEffect>(ProjectileHazeAkComp.AddEffect(UDopplerEffect::StaticClass()));
		DopplerEffect.PlayPassbySound(PassByEvent, 0.8f, 1.f, VelocityAngle = 0.5f);
	}

	UFUNCTION()
	void OnComponentBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
	UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, FHitResult& Hit)
	{
		if(bReachedEndPoint)
			return;

		UCymbalComponent CymbalComponent = UCymbalComponent::Get(Game::GetCody());

		if(OtherActor == Game::GetCody())
		{
			float DirectionDot = InverseWallFowardVector.DotProduct(Game::GetCody().GetActorForwardVector());
			float AngleDifference = FMath::Acos(DirectionDot) * RAD_TO_DEG;

			if(CymbalComponent.bShieldActive &&
			AngleDifference <= 60 && AngleDifference > -60)
			{
				if(Game::GetCody().HasControl())
					NetExplode();
				else
					Explode();

				Game::GetCody().PlayForceFeedback(ForceFeedbackShieldImpact, false, false, n"ForceFeedbackShieldImpact");
				Game::GetCody().PlayCameraShake(CameraShakeShieldImpact, 1.f);
			}
			else
			{
				if(CodyInsideSafeTrigger == false)
				{
					DamagePlayer(Game::GetCody());
				}
			}
		}



		if(OtherActor == Game::GetMay())
		{
			if(MayInsideSafeTrigger == false)
			{
				DamagePlayer(Game::GetMay());
			}
		}
	}

	UFUNCTION()
	void DamagePlayer(AHazePlayerCharacter Player)
	{
		if(!bPlayerCanTakeDamage)
			return;

		if(Player.IsPlayerDead() == false)
		{
			DamagePlayerHealth(Player, 100);

			if(Player.HasControl())
			{
				NetOnKilledPlayer(Player);
			}
		}
	}
	UFUNCTION(NetFunction)
	void NetOnKilledPlayer(AHazePlayerCharacter Player)
	{
		OnKilledPlayer.Broadcast(Player);
	}

	UFUNCTION()
	void OnComponentBeginOverlapSafe(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
	UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, FHitResult& Hit)
	{
		if(OtherActor == Game::GetCody())
		{
			CodyInsideSafeTrigger = true;
		}
		if(OtherActor == Game::GetMay())
		{
			MayInsideSafeTrigger = true;
		}
	}

	UFUNCTION()
	void OnComponentEndOverlapSafe(
		UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex)
	{
		if(OtherActor == Game::GetCody())
		{
			CodyInsideSafeTrigger = false;
		}
		if(OtherActor == Game::GetMay())
		{
			MayInsideSafeTrigger = false;
		}
	}


	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		FVector Location = CodyImpactLocation.GetWorldLocation();
		WallMesh.SetVectorParameterValueOnMaterials(n"BubbleLoc", Location);
		Material.SetScalarParameterValue(n"Hight", FadeHeightLocation);
		//PrintToScreen("AcceleratedFloatOpacity.Value "+ AcceleratedFloatOpacity.Value);
		//PrintToScreen("bEffectCandeLights " + bEffectCandeLights);

	//	if(Game::GetCody().HasControl())
	//	{
			FVector DeltaMove = Direction * Velocity * DeltaTime;
			AddActorWorldOffset(DeltaMove, true, FHitResult(), false);
		//	SmoothVectorSync.Value = this.GetActorLocation();

			AcceleratedFlotWallScale.SpringTo(44, 1, 0.8, DeltaTime);
			WallMesh.SetWorldScale3D(FVector(WallMesh.GetWorldScale().X, AcceleratedFlotWallScale.Value, WallMesh.GetWorldScale().Z));
		//	SmoothFloatSync.Value = AcceleratedFlotWallScale.Value;
		//	PrintToScreen("DistanceFromEndLocation " + DistanceFromEndLocation);
			
			
			if(DistanceFromEndLocation <= 1125)
			{
				ReachedEndPointFirst();
			}
			if(AcceleratedFloatOpacity.Value <= 0 && bPlayerCanTakeDamage == false)
			{
				ReachedEndPointSecond();
			}

			if(bReachedEndPoint)
				return;

			DistanceFromEndLocation =  (GetActorLocation() - ProjectileEndLocation).Size();
			if(DistanceFromEndLocation <= 2500)
			{
				AcceleratedFloatOpacity.SpringTo(0, 25, 0.8, DeltaTime);
				Material.SetScalarParameterValue(n"Opacity", AcceleratedFloatOpacity.Value);
			}
			else
			{
				AcceleratedFloatOpacity.SpringTo(1, 0.5f, 1.0, DeltaTime);
				Material.SetScalarParameterValue(n"Opacity", AcceleratedFloatOpacity.Value);
			}

		//	PrintToScreen("AcceleratedFloatOpacity "+ AcceleratedFloatOpacity.Value);

	//	}
	/*
		else
		{	
			SetActorLocation(SmoothVectorSync.Value);

			AcceleratedFlotWallScale.Value = SmoothFloatSync.Value;
			WallMesh.SetWorldScale3D(FVector(WallMesh.GetWorldScale().X, AcceleratedFlotWallScale.Value, WallMesh.GetWorldScale().Z));
			

			if(DistanceFromEndLocation <= 300)
			{
				ReachedEndPointFirst();
			}
			if(AcceleratedFloatOpacity.Value <= 0 && bPlayerCanTakeDamage == false)
			{
				ReachedEndPointSecond();
			}

			if(bReachedEndPoint)
				return;

			DistanceFromEndLocation =  (GetActorLocation() - ProjectileEndLocation).Size();
			if(DistanceFromEndLocation <= 2500)
			{
				AcceleratedFloatOpacity.SpringTo(0, 12, 0.8, DeltaTime);
				Material.SetScalarParameterValue(n"Opacity", AcceleratedFloatOpacity.Value);
			}
			else
			{
				AcceleratedFloatOpacity.SpringTo(1, 2, 08, DeltaTime);
				Material.SetScalarParameterValue(n"Opacity", AcceleratedFloatOpacity.Value);
			}
		}
		*/
	}

	UFUNCTION()
	void ReachedEndPointFirst()
	{
		if(bPlayerCanTakeDamage == true)
		{
			bPlayerCanTakeDamage = false;
			if(Game::GetCody().HasControl())
			{
				System::SetTimer(this, n"NetDestroyActor", 10.f, false);
			}
		}
	}
	UFUNCTION()
	void ReachedEndPointSecond()
	{
		if(bReachedEndPoint)
			return;
		
		bReachedEndPoint = true;
	}


	UFUNCTION(NetFunction)
	void NetDestroyActor()
	{
		DestroyActor();
	}

	UFUNCTION(NetFunction)
	void NetExplode()
	{
		Explode();
	}

	UFUNCTION()
	void Explode()
	{
		if(DoOnce)
			return;
		
		DoOnce = true;
		OnWallExploded.Broadcast();
		WallOfSoundParticleSystem.SetNiagaraVariableFloat("User.ForceStrength", 15000.f);
		SphereTrigger.SetWorldLocation(Game::GetCody().GetActorLocation() + FVector(0,0, 100.f));
		CodyImpactLocation.SetWorldLocation(Game::GetCody().GetActorLocation() + FVector(0,0, 45.f));
		Niagara::SpawnSystemAtLocation(ExplosionEffect, Game::GetCody().GetActorLocation(), Game::GetCody().GetActorRotation());
		Game::GetCody().PlayerHazeAkComp.HazePostEvent(CymbalBlockEvent);
	}
}