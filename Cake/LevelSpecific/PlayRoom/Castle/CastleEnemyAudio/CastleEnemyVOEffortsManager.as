import Peanuts.Audio.AudioStatics;

struct FCastleEnemyTypeVOEventData
{
	UPROPERTY()
	UAkAudioEvent OnIdleEvent;

	UPROPERTY()
	UAkAudioEvent OnAggroEvent;

	UPROPERTY()
	UAkAudioEvent OnAttackPlayerEvent;

	UPROPERTY()
	UAkAudioEvent OnTakeDamageEvent;

	UPROPERTY()
	UAkAudioEvent OnKilledEvent;
}

enum ECastleEnemyVOTypes
{
	SmallKnight,
	LargeKnight,
	Mage,
	Shielder,
	None
}

class UCastleEnemyVOEffortsManager : UActorComponent
{
	UPROPERTY()
	TArray<FCastleEnemyTypeVOEventData> ToyKnightSmallVO;

	UPROPERTY()
	TArray<FCastleEnemyTypeVOEventData> ToyKnightLargeVO;

	UPROPERTY()
	TArray<FCastleEnemyTypeVOEventData> ToyMageVO;

	UPROPERTY()
	TArray<FCastleEnemyTypeVOEventData> ToyShielderVO;	

	private TArray<FCastleEnemyTypeVOEventData> AvaliableToyKnightSmallEvents;
	private TArray<FCastleEnemyTypeVOEventData> AvaliableToyKnightLargeEvents;
	private TArray<FCastleEnemyTypeVOEventData> AvaliableToyMageEvents;
	private TArray<FCastleEnemyTypeVOEventData> AvaliableToyShielderEvents;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AvaliableToyKnightSmallEvents = ToyKnightSmallVO;
		AvaliableToyKnightLargeEvents = ToyKnightLargeVO;
		AvaliableToyMageEvents = ToyMageVO;
		AvaliableToyShielderEvents = ToyShielderVO;
		SetComponentTickEnabled(false);
	}

	FCastleEnemyTypeVOEventData GetQueuedVOEvents(ECastleEnemyVOTypes EnemyType)
	{

		FCastleEnemyTypeVOEventData QueuedEventData;

		switch(EnemyType)
		{
			case(ECastleEnemyVOTypes::SmallKnight):			
				return GetNextAvaliableVOEvent(AvaliableToyKnightSmallEvents, ToyKnightSmallVO);
			
			case(ECastleEnemyVOTypes::LargeKnight):
				return GetNextAvaliableVOEvent(AvaliableToyKnightLargeEvents, ToyKnightLargeVO);

			case(ECastleEnemyVOTypes::Mage):
				return GetNextAvaliableVOEvent(AvaliableToyMageEvents, ToyMageVO);

			case(ECastleEnemyVOTypes::Shielder):
				return GetNextAvaliableVOEvent(AvaliableToyShielderEvents, ToyShielderVO);
		}	

		return GetNextAvaliableVOEvent(AvaliableToyKnightSmallEvents, ToyKnightSmallVO);
	}

	FCastleEnemyTypeVOEventData GetNextAvaliableVOEvent(TArray<FCastleEnemyTypeVOEventData>& AvaliableData, TArray<FCastleEnemyTypeVOEventData>& OriginalData)
	{
		if(AvaliableData.Num() == 0)
			AvaliableData = OriginalData;
		
		auto QueuedEventData = AvaliableData[0];
		AvaliableData.RemoveAtSwap(0);

		return QueuedEventData;
	}
}



