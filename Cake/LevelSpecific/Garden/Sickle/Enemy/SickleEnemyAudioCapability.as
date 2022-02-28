import Peanuts.Audio.AudioStatics;
import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleEnemy;

class SickleEnemyAudioCapability : UHazeCapability
{
	default TickGroup = ECapabilityTickGroups::AfterPhysics;

	UHazeAkComponent HazeAkComp;
	ASickleEnemy SickleEnemy;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent SickleEnemySpawnAudioEvent;
	
	UPROPERTY(Category = "Audio")
	UAkAudioEvent SickleDamageAudioEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent SickleKillAudioEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent SickleKillDamageAudioEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent VineDamageAudioEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent VineKillAudioEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent VineKillDamageAudioEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent TurretDamageAudioEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent TurretKillAudioEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent TurretKillDamageAudioEvent;
	
	UPROPERTY(Category = "Audio")
	UAkAudioEvent VineConnectedAudioEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent VineDisconnectedAudioEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent StopSlamAttackAudioEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent TomatoDamageAudioEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent TomatoKillAudioEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent TomatoKillDamageAudioEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent ForcedKillAudioEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent ForcedKillDamageAudioEvent;
	
	
	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		SickleEnemy = Cast<ASickleEnemy>(Owner);
		HazeAkComp = SickleEnemy.HazeAkComp;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::ActivateLocal;
	}
	
	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ConsumeAction(n"AudioSickleEnemySpawn") == EActionStateStatus::Active)
		{
			HazeAkComp.HazePostEvent(SickleEnemySpawnAudioEvent);
			//PrintScaled("Sickle Enemy Spawn", 0.5f, FLinearColor::Green, 2.f);
		}
		
		if (ConsumeAction(n"AudioSickleDamage") == EActionStateStatus::Active)
		{
			HazeAkComp.HazePostEvent(SickleDamageAudioEvent);
			//PrintScaled("Sickle Damage", 1.f, FLinearColor::Green, 2.f);
		}

		if (ConsumeAction(n"AudioSickleKill") == EActionStateStatus::Active)
		{
			HazeAkComp.HazePostEvent(SickleKillAudioEvent);
			UHazeAkComponent::HazePostEventFireForget(SickleKillDamageAudioEvent, SickleEnemy.GetActorTransform());
			//PrintScaled("Sickle Kill", 1.f, FLinearColor::Green, 2.f);
		}

		if (ConsumeAction(n"AudioVineDamage") == EActionStateStatus::Active)
		{
			HazeAkComp.HazePostEvent(VineDamageAudioEvent);
			//PrintScaled("Vine Damage", 1.f, FLinearColor::Green, 2.f);
		}

		if (ConsumeAction(n"AudioVineKill") == EActionStateStatus::Active)
		{
			HazeAkComp.HazePostEvent(VineKillAudioEvent);
			UHazeAkComponent::HazePostEventFireForget(VineKillDamageAudioEvent, SickleEnemy.GetActorTransform());
			//PrintScaled("Vine Kill", 1.f, FLinearColor::Green, 2.f);
		}

		if (ConsumeAction(n"AudioTurretDamage") == EActionStateStatus::Active)
		{
			HazeAkComp.HazePostEvent(TurretDamageAudioEvent);
			//PrintScaled("Turret Damage", 1.f, FLinearColor::Green, 2.f);
		}

		if (ConsumeAction(n"AudioTurretKill") == EActionStateStatus::Active)
		{
			HazeAkComp.HazePostEvent(TurretKillAudioEvent);
			UHazeAkComponent::HazePostEventFireForget(TurretKillDamageAudioEvent, SickleEnemy.GetActorTransform());
			//PrintScaled("Turret Kill", 1.f, FLinearColor::Green, 2.f);
		}
		
		if (ConsumeAction(n"AudioVineConnected") == EActionStateStatus::Active)
		{
			HazeAkComp.HazePostEvent(VineConnectedAudioEvent);
			//PrintScaled("Vine Connected", 1.f, FLinearColor::Green, 2.f);
		}

		if (ConsumeAction(n"AudioVineDisconnected") == EActionStateStatus::Active)
		{
			HazeAkComp.HazePostEvent(VineDisconnectedAudioEvent);
			//PrintScaled("Vine Disconnected", 1.f, FLinearColor::Green, 2.f);
		}

		if (ConsumeAction(n"AudioStopSlamAttack") == EActionStateStatus::Active)
		{
			HazeAkComp.HazePostEvent(StopSlamAttackAudioEvent);
			//PrintScaled("Stop Slam", 1.f, FLinearColor::Green, 2.f);
		}

		//need to add the rolling veg damage and kill logic
		if (ConsumeAction(n"AudioTomatoDamage") == EActionStateStatus::Active)
		{
			HazeAkComp.HazePostEvent(TomatoDamageAudioEvent);
			//PrintScaled("Tomato Damage", 1.f, FLinearColor::Green, 2.f);
		}

		if (ConsumeAction(n"AudioTomatoKill") == EActionStateStatus::Active)
		{
			HazeAkComp.HazePostEvent(TomatoKillAudioEvent);
			UHazeAkComponent::HazePostEventFireForget(TomatoKillDamageAudioEvent, SickleEnemy.GetActorTransform());
			//PrintScaled("Tomato Kill", 1.f, FLinearColor::Green, 2.f);

		}

		if (ConsumeAction(n"AudioForceKill") == EActionStateStatus::Active)
		{
			HazeAkComp.HazePostEvent(ForcedKillAudioEvent);
			UHazeAkComponent::HazePostEventFireForget(ForcedKillDamageAudioEvent, SickleEnemy.GetActorTransform());
			//PrintScaled("Forced Kill", 1.f, FLinearColor::Green, 2.f);

		}


	}


}