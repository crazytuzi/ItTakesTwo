import Cake.LevelSpecific.Music.LevelMechanics.Backstage.SilentRoom.MicrophoneChase.MicrophoneMonster;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.SilentRoom.MicrophoneChase.BreakableSoundFoam;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.BackstageEmissiveSpotlight;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.BackstageSpotlight;
import Cake.LevelSpecific.Music.VOBanks.MusicBackstageVOBank;

event void FOnBreakVolumeActivated();

class AMicrophoneMonsterBreakVolume : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBoxComponent BoxCollision;

	UPROPERTY()
	TArray<ABreakableActor> BreakableActorArray;

	UPROPERTY()
	TArray<ABackstageEmissiveSpotlight> SpotLightMeshArray; 

	UPROPERTY()
	TArray<ABackstageSpotlight> SpotLightArray;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CamShake;

	UPROPERTY()
	bool bShouldPlayCamShake = true;

	UPROPERTY()
	float SpotlightFadeinDuration = 0.5f;

	UPROPERTY()
	float SpotlightDelay = 0.f;

	UPROPERTY()
	float ActivateReflectionTime = 0.f;

	UPROPERTY()
	FOnBreakVolumeActivated BreakVolumeActivated;

	UPROPERTY()
	bool bShouldTriggerMonsterAnimState = false;

	UPROPERTY(Meta = (EditCondition="bShouldTriggerMonsterAnimState", EditConditionHides))
	EMotherSnakeAnimState MonsterAnimState;

	UPROPERTY(Meta = (EditCondition="bShouldTriggerMonsterAnimState", EditConditionHides))
	float AnimStateDuration;

	UPROPERTY()
	bool bShouldPlayVO = false;

	UPROPERTY(Meta = (EditCondition="bShouldPlayVO", EditConditionHides))
	UMusicBackstageVOBank VoBank;

	bool bHasBrokenBreakableActor = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BoxCollision.OnComponentBeginOverlap.AddUFunction(this, n"BeginOverlap");
	}

	UFUNCTION()
	void BeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex, 
    bool bFromSweep, FHitResult& Hit)
	{
		if (bHasBrokenBreakableActor)
			return;

		AMicrophoneMonster Monster = Cast<AMicrophoneMonster>(OtherActor);
		if (Monster == nullptr)
			return;

		if (bShouldTriggerMonsterAnimState)
		{
			Monster.SetNewMicrophoneAnimationState(MonsterAnimState, AnimStateDuration);
		}

		if (bShouldPlayVO)
		{
			PlayFoghornVOBankEvent(VoBank, n"FoghornDBMusicBackstageMicrophoneChaseEffortCody");
			PlayFoghornVOBankEvent(VoBank, n"FoghornDBMusicBackstageMicrophoneChaseEffortMay");
		}

		bHasBrokenBreakableActor = true;

		BreakVolumeActivated.Broadcast();

		if (bShouldPlayCamShake)
			Game::GetCody().PlayCameraShake(CamShake);
		

		for (ABreakableActor BreakActor : BreakableActorArray)
		{
			FBreakableHitData HitData;
			// HitData.DirectionalForce = FVector(0.f, 0.f, 10.f);
			// HitData.HitLocation = FVector::ZeroVector
			// HitData.ScatterForce = 0.f
			BreakActor.BreakBreakableActor(HitData);
		}

		for (ABackstageEmissiveSpotlight SpotMesh : SpotLightMeshArray)
		{
			SpotMesh.ActivateSpotlights(SpotlightFadeinDuration, SpotlightDelay);
		}

		for (ABackstageSpotlight Spotlight : SpotLightArray)
		{
			Spotlight.ActivateLights(SpotlightFadeinDuration, SpotlightDelay, ActivateReflectionTime);
		}
	}
}