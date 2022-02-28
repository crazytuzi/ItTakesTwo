import Vino.PlayerHealth.PlayerDeathEffect;
import Vino.PlayerHealth.PlayerHealthStatics;
import Peanuts.Audio.AudioStatics;
event void FOnFinished(AHazePlayerCharacter Player, float delay);

class ASpinningWheelDeath : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)	
	USceneComponent RootComp;
	UPROPERTY(DefaultComponent, Attach = RootComp)	
	USceneComponent WheelComp;
	UPROPERTY(DefaultComponent, Attach = WheelComp)	
	UStaticMeshComponent Mesh;
	UPROPERTY(DefaultComponent, Attach = RootComp)	
	USceneComponent LocationToMeasureFromSceneComp;
	UPROPERTY(DefaultComponent, Attach = Mesh)	
	USceneComponent ElectrocutionSceneComp;
	UPROPERTY(DefaultComponent, Attach = Mesh)	
	USceneComponent FreezeSceneComp;
	UPROPERTY(DefaultComponent, Attach = Mesh)	
	USceneComponent BurnSceneComp;
	UPROPERTY(DefaultComponent, Attach = Mesh)	
	USceneComponent LaserSceneComp;
	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PlaySpinWheelAudioEvent;
	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopSpinWheelAudioEvent;
	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent GongAudioEvent;
	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent LastClicksAudioEvent;
	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent LightningAudioEvent;
	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent FreezeAudioEvent;
	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent LaserAudioEvent;
	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent FireAudioEvent;

	UPROPERTY()
	AHazeCameraActor Camera;

	UPROPERTY()
	FOnFinished OnFinished;

	UPROPERTY()
	UNiagaraSystem ElectrocutionEffect;
	UPROPERTY()
	UNiagaraSystem FreezeEffect;
	UPROPERTY()
	UNiagaraSystem BurnEffect;
	UPROPERTY()
	UNiagaraSystem LaserEffect;

	UPROPERTY()
	TSubclassOf<UPlayerDeathEffect> ElectrocutionDeath;
	UPROPERTY()
	TSubclassOf<UPlayerDeathEffect> FreezeDeath;
	UPROPERTY()
	TSubclassOf<UPlayerDeathEffect> BurnDeath;
	UPROPERTY()
	TSubclassOf<UPlayerDeathEffect> LaserDeath;

	TArray<float> ArrayOfDistances;

	bool bWheelActive;
	bool bPlayingLastClicks = false;
	float TargetPitchValue;
	FHazeAcceleratedFloat AcceleratedFloat;


	float FuturePitch;
	float DeacclerationMultiplier = 1;
	float RotationVelocity = 1;

	float ElectrocutionDistance;
	float FreezeDistance;
	float BurnDistance;
	float LaserDistance;

	UPROPERTY()
	FLinearColor LaserEmissiveColor = FLinearColor(5, 0, 4.124, 0.5);
	UPROPERTY()
	FLinearColor FreezeEmissiveColor = FLinearColor(0, 1.4, 5, 0.5);
	UPROPERTY()
	FLinearColor FireEmissiveColor = FLinearColor(5, 0, 0.167, 0.5);
	UPROPERTY()
	FLinearColor LightingEmissiveColor = FLinearColor(5, 3.5, 0, 0.5);

	AHazePlayerCharacter PlayerInstigator;
	
	UPROPERTY()
	float LaserPlayerDeathTimer = 0.85f;
	UPROPERTY()
	float LaserVFXTimer = 0.85f;
	UPROPERTY()
	float FreezePlayerDeathTimer = 0.85f;
	UPROPERTY()
	float FreezeVFXTimer = 0.85f;
	UPROPERTY()
	float BurnPlayerDeathTimer = 0.85f;
	UPROPERTY()
	float BurnVFXTimer = 0.85f;
	UPROPERTY()
	float LightningPlayerDeathTimer = 0.85f;
	UPROPERTY()
	float LightningVFXTimer = 0.85f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay(){}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bWheelActive)
		{
			DeacclerationMultiplier = RotationVelocity * 0.005;
			if(RotationVelocity >= 200)
			{
				RotationVelocity -= 1.0f * DeacclerationMultiplier * (DeltaSeconds * 62);
			}

			if(RotationVelocity >= 100 && RotationVelocity < 200)
			{	
				RotationVelocity -= 1.75 * DeacclerationMultiplier * (DeltaSeconds * 62);
			}

			if(RotationVelocity >= 50 && RotationVelocity < 100)
			{	
				RotationVelocity -= 3.0 * DeacclerationMultiplier * (DeltaSeconds * 62);
			}
				
			if(RotationVelocity >= 15 && RotationVelocity < 50)
			{	
				RotationVelocity -= 4.0 * DeacclerationMultiplier * (DeltaSeconds * 62);
			}

			if(RotationVelocity >= 0 && RotationVelocity < 15)
			{	
				RotationVelocity -= 8.0f * DeacclerationMultiplier * (DeltaSeconds * 62);
			}

			FuturePitch = Mesh.GetRelativeRotation().Pitch + RotationVelocity * DeltaSeconds;
			WheelComp.AddLocalRotation(FRotator(0, FuturePitch, 0));

			if(FMath::IsNearlyZero(RotationVelocity, 0.5f))
			{
				WheelStopped();
			}
			
			float NormalizedRotation = HazeAudio::NormalizeRTPC01(RotationVelocity, 0.f, 500.f);

			HazeAkComp.SetRTPCValue("Rtpc_World_SideContent_Music_Interactions_WheelOfDeath_Spin", NormalizedRotation);

			if(!bPlayingLastClicks && NormalizedRotation <= 0.1f)
			{
				HazeAkComp.HazePostEvent(LastClicksAudioEvent);
				bPlayingLastClicks = true;
			}

	//		PrintToScreen("NormalizedRotation" + NormalizedRotation);
	//		PrintToScreen("RotationVelocity " + RotationVelocity);
	//		PrintToScreen("FuturePitch " + FuturePitch);
	//		PrintToScreen("DeacclerationMultiplier " + FuturePitch);
		}
	}

	UFUNCTION()
	void WheelStopped()
	{
		bWheelActive = false;
		System::SetTimer(this, n"CalculateDeath", 0.2f, false);
		HazeAkComp.HazePostEvent(StopSpinWheelAudioEvent);
	}

	UFUNCTION()
	void CalculateDeath()
	{
		ElectrocutionDistance = (LocationToMeasureFromSceneComp.GetWorldLocation() - ElectrocutionSceneComp.GetWorldLocation()).Size();
		FreezeDistance = (LocationToMeasureFromSceneComp.GetWorldLocation() - FreezeSceneComp.GetWorldLocation()).Size();
		BurnDistance = (LocationToMeasureFromSceneComp.GetWorldLocation() - BurnSceneComp.GetWorldLocation()).Size();
		LaserDistance = (LocationToMeasureFromSceneComp.GetWorldLocation() - LaserSceneComp.GetWorldLocation()).Size();

		ArrayOfDistances.Add(ElectrocutionDistance);
		ArrayOfDistances.Add(FreezeDistance);
		ArrayOfDistances.Add(BurnDistance);
		ArrayOfDistances.Add(LaserDistance);
		ArrayOfDistances.Sort(false);


		if(ArrayOfDistances[0] == ElectrocutionDistance)
		{
			Mesh.SetColorParameterValueOnMaterialIndex(4, n"Emissive Tint", LightingEmissiveColor);
			System::SetTimer(this, n"PlayerElectrocutionDeath", LightningPlayerDeathTimer, false);
			System::SetTimer(this, n"PlayerElectrocutionVFX", LightningVFXTimer, false);
			PlayerInstigator.PlayerHazeAkComp.HazePostEvent(LightningAudioEvent);
			HazeAkComp.HazePostEvent(GongAudioEvent);
			bPlayingLastClicks = false;
		}
		else if(ArrayOfDistances[0] == FreezeDistance)
		{
			Mesh.SetColorParameterValueOnMaterialIndex(3, n"Emissive Tint", FreezeEmissiveColor);
			System::SetTimer(this, n"PlayerFreezeDeath", FreezePlayerDeathTimer, false);
			System::SetTimer(this, n"PlayerFreezeVFX", FreezeVFXTimer, false);
			PlayerInstigator.PlayerHazeAkComp.HazePostEvent(FreezeAudioEvent);
			HazeAkComp.HazePostEvent(GongAudioEvent);
			bPlayingLastClicks = false;
		}
		else if(ArrayOfDistances[0] == BurnDistance)
		{
			Mesh.SetColorParameterValueOnMaterialIndex(2, n"Emissive Tint", FireEmissiveColor);
			System::SetTimer(this, n"PlayerBurnDeath", BurnPlayerDeathTimer, false);
			System::SetTimer(this, n"PlayerBurnVFX", BurnVFXTimer, false);
			PlayerInstigator.PlayerHazeAkComp.HazePostEvent(FireAudioEvent);
			HazeAkComp.HazePostEvent(GongAudioEvent);
			bPlayingLastClicks = false;
		}
		else if(ArrayOfDistances[0] == LaserDistance)
		{
			Mesh.SetColorParameterValueOnMaterialIndex(1, n"Emissive Tint", LaserEmissiveColor);
			System::SetTimer(this, n"PlayerLaserDeath", LaserPlayerDeathTimer, false);
			System::SetTimer(this, n"PlayerLaserVFX", LaserVFXTimer, false);
			PlayerInstigator.PlayerHazeAkComp.HazePostEvent(LaserAudioEvent);
			HazeAkComp.HazePostEvent(GongAudioEvent);
			bPlayingLastClicks = false;
		}


		//PrintToScreen("LightingDistance " + LightingDistance, 5.f);
		//PrintToScreen("CrushedDistance " + CrushedDistance, 5.f);
		//PrintToScreen("ExplosionDistance " + ExplosionDistance, 5.f);
		//PrintToScreen("DisintegrateDistance " + DisintegrateDistance, 5.f);
	}

	UFUNCTION()
	void PlayerElectrocutionDeath()
	{
		KillPlayer(PlayerInstigator, ElectrocutionDeath);
		System::SetTimer(this, n"UnblockFlyingTutorial", 0.825f, false);
		System::SetTimer(this, n"UnblockRespawn", 1.45f, false);
		OnFinished.Broadcast(PlayerInstigator, 0.0f);
	}
	UFUNCTION()
	void PlayerElectrocutionVFX()
	{
		Niagara::SpawnSystemAtLocation(ElectrocutionEffect, PlayerInstigator.GetActorLocation(), PlayerInstigator.GetActorRotation());
	}

	UFUNCTION()
	void PlayerFreezeDeath()
	{
		KillPlayer(PlayerInstigator, FreezeDeath);
		System::SetTimer(this, n"UnblockFlyingTutorial", 0.825f, false);
		System::SetTimer(this, n"UnblockRespawn", 1.45f, false);
		OnFinished.Broadcast(PlayerInstigator, 1.5f);
	}
	
	UFUNCTION()
	void PlayerFreezeVFX()
	{
		Niagara::SpawnSystemAtLocation(FreezeEffect, PlayerInstigator.GetActorLocation(), PlayerInstigator.GetActorRotation());
	}


	UFUNCTION()
	void PlayerBurnDeath()
	{
		KillPlayer(PlayerInstigator, BurnDeath);
		System::SetTimer(this, n"UnblockFlyingTutorial", 0.825f, false);
		System::SetTimer(this, n"UnblockRespawn", 1.45f, false);
		OnFinished.Broadcast(PlayerInstigator, 0.0f);
	}
	UFUNCTION()
	void PlayerBurnVFX()
	{
		Niagara::SpawnSystemAtLocation(BurnEffect, PlayerInstigator.GetActorLocation(), PlayerInstigator.GetActorRotation());
	}

	UFUNCTION()
	void PlayerLaserDeath()
	{
		KillPlayer(PlayerInstigator, LaserDeath);
		System::SetTimer(this, n"UnblockFlyingTutorial", 0.825f, false);
		System::SetTimer(this, n"UnblockRespawn", 1.45f, false);	
		OnFinished.Broadcast(PlayerInstigator, 0.0f);
	}
	UFUNCTION()
	void PlayerLaserVFX()
	{
		Niagara::SpawnSystemAtLocation(LaserEffect, PlayerInstigator.GetActorLocation(), PlayerInstigator.GetActorRotation());
	}


	UFUNCTION()
	void UnblockFlyingTutorial()
	{
		PlayerInstigator.SetCapabilityActionState(n"ClassicFlyingTutorial", EHazeActionState::Active);
	}
	UFUNCTION()
	void UnblockRespawn()
	{
		PlayerInstigator.UnblockCapabilities(CapabilityTags::MovementInput, this);
		PlayerInstigator.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		Camera.DeactivateCamera(PlayerInstigator, 3.f);
		PlayerInstigator.UnblockCapabilities(n"Respawn",this);
	}

	

	UFUNCTION()
	void ButtonPressed(AHazePlayerCharacter Player)
	{
		if(Player.HasControl())
		{
			float LocalVelocity;
			LocalVelocity = FMath::RandRange(534.5, 545.5);
			StartWheel(Player, LocalVelocity);
			HazeAkComp.HazePostEvent(PlaySpinWheelAudioEvent);
		}
	}
	UFUNCTION(NetFunction)
	void StartWheel(AHazePlayerCharacter Player, float Velocity)
	{
		ArrayOfDistances.Empty();
		bWheelActive = true;
		RotationVelocity += Velocity;

		Mesh.SetColorParameterValueOnMaterialIndex(1, n"Emissive Tint", FLinearColor(0,0,0,0));
		Mesh.SetColorParameterValueOnMaterialIndex(2, n"Emissive Tint", FLinearColor(0,0,0,0));
		Mesh.SetColorParameterValueOnMaterialIndex(3, n"Emissive Tint", FLinearColor(0,0,0,0));
		Mesh.SetColorParameterValueOnMaterialIndex(4, n"Emissive Tint", FLinearColor(0,0,0,0));
		
		PlayerInstigator = Player;
		PlayerInstigator.BlockCapabilities(n"Respawn",this);
		PlayerInstigator.BlockCapabilities(CapabilityTags::MovementInput, this);
		PlayerInstigator.BlockCapabilities(CapabilityTags::GameplayAction, this);
		PlayerInstigator.SetCapabilityActionState(n"ClassicFlyingTutorial", EHazeActionState::Inactive);

		FHazeCameraBlendSettings Blend;
		Blend.BlendTime = 4.f;
		Camera.ActivateCamera(PlayerInstigator, Blend, this, EHazeCameraPriority::Medium);
	}
}
