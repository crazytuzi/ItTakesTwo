import Peanuts.Audio.AudioStatics;

struct FWaspVOEventData
{
	UPROPERTY()
	UAkAudioEvent OnIdleEvent;

	UPROPERTY()
	UAkAudioEvent OnAggroEvent;

	UPROPERTY()
	TArray<UAnimSequence> OnAggroAnim;

	UPROPERTY()
	UAkAudioEvent OnTauntEvent;

	UPROPERTY()
	TArray<UAnimSequence> OnTauntAnim;

	UPROPERTY()
	UAkAudioEvent OnAttackPlayerEvent;

	UPROPERTY()
	TArray<UAnimSequence> OnAttackAnim;

	UPROPERTY()
	UAkAudioEvent OnStunnedEvent;

	UPROPERTY()
	TArray<UAnimSequence> OnStunnedAnim;

	UPROPERTY()
	UAkAudioEvent OnRecoverEvent;
	
	UPROPERTY()
	TArray<UAnimSequence> OnRecoverAnim;

	UPROPERTY()
	UAkAudioEvent OnKilledEvent;
}

struct FBeetleRidingHeavyWaspVOEventData
{
	UPROPERTY()
	UAkAudioEvent OnAttackEvent;

	UPROPERTY()
	UAkAudioEvent OnKilledEvent;
}

class UWaspVOManager : UActorComponent
{
	UPROPERTY()
	TArray<FWaspVOEventData> WaspVODatas;

	UPROPERTY()
	TArray<FBeetleRidingHeavyWaspVOEventData> BeetleRidingHeavyWaspAttackEventDatas;

	private TArray<FWaspVOEventData> AvaliableEventDatas;
	private TArray<FBeetleRidingHeavyWaspVOEventData> AvailableHeavyWaspAttackEventDatas;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AvaliableEventDatas = WaspVODatas;
		AvailableHeavyWaspAttackEventDatas = BeetleRidingHeavyWaspAttackEventDatas;
		SetComponentTickEnabled(false);
	}

	FWaspVOEventData GetNextAvaliableVOEventData()
	{
		if(AvaliableEventDatas.Num() == 0)
			AvaliableEventDatas = WaspVODatas;
		
		auto QueuedEventData = AvaliableEventDatas[0];
		AvaliableEventDatas.RemoveAtSwap(0);

		return QueuedEventData;
	}

	FBeetleRidingHeavyWaspVOEventData GetNextAvaliableHeavyWaspEventData()
	{
		if(AvailableHeavyWaspAttackEventDatas.Num() == 0)
			AvailableHeavyWaspAttackEventDatas = BeetleRidingHeavyWaspAttackEventDatas;

		auto QueuedEvent = AvailableHeavyWaspAttackEventDatas[0];

		AvailableHeavyWaspAttackEventDatas.RemoveAtSwap(0);
		return QueuedEvent;
	}

}