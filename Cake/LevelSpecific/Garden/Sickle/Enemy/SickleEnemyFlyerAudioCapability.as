import Peanuts.Audio.AudioStatics;
import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleEnemy;
import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleEnemyAudioCapability;

class SickleEnemyFlyerAudioCapability : SickleEnemyAudioCapability
{
	default TickGroup = ECapabilityTickGroups::AfterPhysics;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent StartAudioEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent EnemyKilledAudioEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent EnemyKilledDamageAudioEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent EnemyGroundedAudioEvent;

	bool bHasStoppedSound = false;
	int32 FlyingLoopPlayingID;
	
	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams) override
	{
		Super::Setup(SetupParams);
		HazeAkComp.SetTrackVelocity(true, 1200.f);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		FlyingLoopPlayingID = HazeAkComp.HazePostEvent(StartAudioEvent).PlayingID;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if(!bHasStoppedSound)
			HazeAkComp.HazeStopEvent(FlyingLoopPlayingID, FadeOutTimeMs = 100);
		
		bHasStoppedSound = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime) override
	{
		Super::TickActive(DeltaTime);

		if (!bHasStoppedSound && !SickleEnemy.IsAlive())
		{
			HazeAkComp.HazePostEvent(EnemyKilledAudioEvent);
			UHazeAkComponent::HazePostEventFireForget(EnemyKilledDamageAudioEvent, SickleEnemy.GetActorTransform());
			//PrintToScreenScaled("flyer killed", 2.f, FLinearColor :: LucBlue, 2.f);
			bHasStoppedSound = true;
		}

		if(ConsumeAction(n"GardenFlyerGrounded") == EActionStateStatus::Active)
			HazeAkComp.HazePostEvent(EnemyGroundedAudioEvent);
	}

}