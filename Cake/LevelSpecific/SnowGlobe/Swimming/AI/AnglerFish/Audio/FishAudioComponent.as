import Peanuts.Audio.AudioStatics;
import Cake.LevelSpecific.SnowGlobe.Swimming.AI.AnglerFish.Behaviours.FishBehaviourComponent;

class UFishAudioComponent : UActorComponent
{
	
	UPROPERTY()
	UHazeAkComponent BodyHazeAkComp;

	UPROPERTY()
	UHazeAkComponent TailFinHazeAkComp;

	UPROPERTY()
	UHazeAkComponent LanternHazeAkComp;

	UFishBehaviourComponent BehaviourComp;

	FHazeAudioEventInstance ChargeEventInstance;

	UPROPERTY(Category = "AudioEvents")
	UAkAudioEvent BodyMovementBodyOneShotEvent;

	UPROPERTY(Category = "AudioEvents")
	UAkAudioEvent LanternLoopEvent;

	UPROPERTY(Category = "AudioEvents")
	UAkAudioEvent GruntsEvent;

	UPROPERTY(Category = "AudioEvents")
	UAkAudioEvent PlayChargePlayerEvent;
	
	UPROPERTY(Category = "VOBark")
	UFoghornVOBankDataAssetBase VOBankDataAsset = Asset("/Game/Blueprints/LevelSpecific/SnowGlobe/VOBanks/SnowGlobeLakeVOBank.SnowGlobeLakeVOBank");

	bool bWaitForRecover = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BehaviourComp = UFishBehaviourComponent::Get(Owner);

		if(TailFinHazeAkComp != nullptr)
		{			
			TailFinHazeAkComp.SetTrackElevation(true, 20000.f);		
			TailFinHazeAkComp.SetTrackDistanceToPlayer(true);
		}
		
		if(BodyHazeAkComp != nullptr)
		{
			BodyHazeAkComp.SetTrackDistanceToPlayer(true);
			BodyHazeAkComp.SetTrackElevation(true, 20000.f);
			BodyHazeAkComp.HazePostEvent(GruntsEvent);
		}

		if(LanternHazeAkComp != nullptr)
			LanternHazeAkComp.HazePostEvent(LanternLoopEvent);		

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{		
		if(BehaviourComp.State == EFishState::Attack || BehaviourComp.State == EFishState::Combat && !bWaitForRecover)
			bWaitForRecover = true;

		WaitForRecover();			
	}

	UFUNCTION()
	void PrepareBlindCharge(AHazePlayerCharacter& PlayerTarget)
	{
		if (!BehaviourComp.IsValidTarget(PlayerTarget))
			return;

		if(BodyHazeAkComp != nullptr)
		{
			HazeAudio::SetPlayerPanning(BodyHazeAkComp, PlayerTarget);
			BodyHazeAkComp.SetTrackDistanceToPlayer(true, PlayerTarget);
			ChargeEventInstance = BodyHazeAkComp.HazePostEvent(PlayChargePlayerEvent);
			
			float Distance = BodyHazeAkComp.GetWorldLocation().Distance(PlayerTarget.GetActorLocation()) / 10000.f;
			float SeekDistance = 1.f - FMath::Clamp(Distance, 0.f, 1.f);
			BodyHazeAkComp.SeekOnPlayingEvent(PlayChargePlayerEvent, ChargeEventInstance.PlayingID, SeekDistance, bSeekToNearestMarker = true);

			float RecoverFade = (1.f - SeekDistance) * 1000.f;
			BodyHazeAkComp.SetRTPCValue("Rtpc_Cha_Enemies_AnglerFish_AttackRun_Duration", 1.f, RecoverFade);
		}
	}

	UFUNCTION()
	void CleanupBlindCharge()
	{
		BodyHazeAkComp.SetTrackDistanceToPlayer(true);
		BodyHazeAkComp.SetRTPCValue("Rtpc_Cha_Enemies_AnglerFish_AttackRun_Duration", 0.f, 2000.f);

		if(!BodyHazeAkComp.EventInstanceIsPlaying(ChargeEventInstance))
			return;

		BodyHazeAkComp.HazeStopEvent(ChargeEventInstance.PlayingID, 2000.f, EAkCurveInterpolation::Log3);

	}

	UFUNCTION()
	void WaitForRecover()
	{
		if(!bWaitForRecover)
			return;			
		
		if(BehaviourComp.State == EFishState::Recover)
		{
			if(BodyHazeAkComp.HazeIsEventActive(ChargeEventInstance.PlayingID))
				BodyHazeAkComp.HazeStopEvent(ChargeEventInstance.PlayingID, 1000.f, CurveType = EAkCurveInterpolation::Log3);
				
			BodyHazeAkComp.HazePostEvent(GruntsEvent);
			LanternHazeAkComp.HazePostEvent(LanternLoopEvent);
			bWaitForRecover = false;
		}
	}
	
}