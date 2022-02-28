import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleFreezableComponent;

event void FOnPlatformFrozen();

class ACastleFirePlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent PlatformParent;

	UPROPERTY(DefaultComponent, Attach = PlatformParent)
	UStaticMeshComponent Platform;
	default Platform.bHiddenInGame = true;

	UPROPERTY(DefaultComponent, Attach = PlatformParent)
	UStaticMeshComponent Fireball;

	UPROPERTY(DefaultComponent, Attach = PlatformParent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(DefaultComponent)
	UCastleFreezableComponent FreezableComponent;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bAutoDisable = true;
	default DisableComponent.AutoDisableRange = 3000.f;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent FreezePlatformAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent UnfreezePlatformAudioEvent;

	UPROPERTY(meta = (MakeEditWidget))
	FVector StartLocation;
	FVector EndLocation;

	FRotator FireballRotationRate = FRotator(140, 160, 160);
	
	UPROPERTY()
	bool bManualSpawn = false;
	
	UPROPERTY()
	FOnPlatformFrozen OnPlatformFrozen;

	UPROPERTY()
	FHazeTimeLike PlatformMovement;
	default PlatformMovement.bLoop = true;
	default PlatformMovement.bSyncOverNetwork = true;
	default PlatformMovement.SyncTag = n"PlatformMovement";

	UPROPERTY()
	float FreezeDuration = 4;
	UPROPERTY(NotEditable)
	float FreezeDurationCurrent = 0.f;

	bool bFrozen = false;

	UPROPERTY()
	float StartTimeOverride = 0.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{		
		SetControlSide(Game::GetCody());

		PlatformMovement.SetNewTime(FMath::Clamp(StartTimeOverride, 0, PlatformMovement.Duration));
		PlatformMovement.BindUpdate(this, n"OnMovementUpdate");
		PlatformMovement.BindFinished(this, n"OnMovementFinished");

		EndLocation = PlatformParent.RelativeLocation;
		PlatformParent.SetRelativeLocation(StartLocation);

		FreezableComponent.OnFreeze.AddUFunction(this, n"FreezePlatform");
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		if (!bManualSpawn)
			PlatformMovement.PlayFromStart();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bFrozen)
		{
			FreezeDurationCurrent -= DeltaTime;
			OnFrozenUpdate(FMath::Clamp(FreezeDurationCurrent / FreezeDuration, 0.f, 1.f));
			
			if (FreezeDurationCurrent <= 0)
				UnfreezePlatform();
		}

		FRotator NewFireballRotation = Fireball.RelativeRotation + (FireballRotationRate * DeltaTime);
		Fireball.AddRelativeRotation(FQuat(FireballRotationRate * DeltaTime));
	}

	UFUNCTION()
	void OnMovementUpdate(float CurrentValue)
	{
		if (bFrozen)
			return;

		OnPlatformUpdate(CurrentValue);

		FVector NewLocation = FMath::Lerp(StartLocation, EndLocation, CurrentValue);
		PlatformParent.SetRelativeLocation(NewLocation);
	}

	UFUNCTION()
	void OnMovementFinished()
	{
		if (bManualSpawn)
			PlatformMovement.Stop();
	}

	UFUNCTION(BlueprintEvent)
	void FreezePlatform(AHazeActor ResponsibleFreezer)
	{
		// Fireball.SetHiddenInGame(true);
		Fireball.SetCollisionEnabled(ECollisionEnabled::NoCollision);

		// Platform.SetHiddenInGame(false);
		Platform.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);

		PlatformParent.SetRelativeLocation(EndLocation);

		PlatformMovement.Stop();

		FreezeDurationCurrent = FreezeDuration;
		bFrozen = true;

		OnFrozen();
		HazeAkComp.HazePostEvent(FreezePlatformAudioEvent);

		OnPlatformFrozen.Broadcast();
	}

	UFUNCTION(BlueprintEvent)
	void UnfreezePlatform()
	{
		bFrozen = false;

		// Platform.SetHiddenInGame(true);
		Platform.SetCollisionEnabled(ECollisionEnabled::NoCollision);

		// Fireball.SetHiddenInGame(false);
		Fireball.SetCollisionEnabled(ECollisionEnabled::QueryOnly);

		PlatformMovement.Play();

		OnUnFrozen();
		HazeAkComp.HazePostEvent(UnfreezePlatformAudioEvent);
	}

	UFUNCTION()
	void ReleaseFireball()
	{
		if (!PlatformMovement.IsPlaying())
		{
			PlatformMovement.PlayFromStart();
		}
			
	}

	UFUNCTION()
	void StartFireballLoop()
	{
		bManualSpawn = false;
		if (!PlatformMovement.IsPlaying())
		{
			PlatformMovement.PlayFromStart();
		}
			
	}

	UFUNCTION(BlueprintEvent)
	void OnPlatformUpdate(float MovePercentage)
	{
		
	}

	UFUNCTION(BlueprintEvent)
	void OnFrozen()
	{
		
	}

	UFUNCTION(BlueprintEvent)
	void OnFrozenUpdate(float FrozenPercentage)
	{
		
	}

	UFUNCTION(BlueprintEvent)
	void OnUnFrozen()
	{
		
	}
}