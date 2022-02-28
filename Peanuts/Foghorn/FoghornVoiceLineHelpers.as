
struct FFoghornBarkRuntimeData
{
	int NextIndex = 0;

	bool UseShuffled = false;
	TArray<int> ShuffledIndices;

	bool PersistPlayOnce = false;
	bool SuperPersistPlayOnce = false;
	bool PlayedOnce = false;
	bool AllPlayedOnce = false;
	float CooldownTimer = 0.0f;
	int ResumeCount = 0;
}

struct FFoghornDialogueRuntimeData
{
	bool PersistPlayOnce = false;
	bool SuperPersistPlayOnce = false;
	bool PlayedOnce = false;
	float CooldownTimer = 0.0f;
	int ResumeCount = 0;
}

bool IsActorValid(AActor Actor)
{
	return Actor != nullptr && !Actor.IsActorBeingDestroyed();
}

namespace FoghornVoiceLineHelpers
{
	int GetNextVoiceLine(FFoghornBarkRuntimeData& RuntimeData, UFoghornBarkDataAsset BarkAsset)
	{
		if (RuntimeData.UseShuffled)
		{
			return GetNextShuffled(RuntimeData, BarkAsset);
		}
		else
		{
			return GetNextOrdered(RuntimeData, BarkAsset);
		}
	}

	int GetNextOrdered(FFoghornBarkRuntimeData& RuntimeData, UFoghornBarkDataAsset BarkAsset)
	{
		int Index = RuntimeData.NextIndex;
		RuntimeData.NextIndex = (RuntimeData.NextIndex + 1)% BarkAsset.VoiceLines.Num();
		if (RuntimeData.NextIndex == 0)
		{
			RuntimeData.AllPlayedOnce = true;
		}
		return Index;
	}

	void SetupShuffle(FFoghornBarkRuntimeData& RuntimeData, const UFoghornBarkDataAsset& BarkAsset)
	{
		if (BarkAsset.VoiceLines.Num() == 1)
		{
			RuntimeData.NextIndex = 0;
			return;
		}

		switch(BarkAsset.ShuffleType)
		{
			case EFoghornShuffleType::PlaylistShuffle:
				RuntimeData.UseShuffled = true;
				RuntimeData.ShuffledIndices.Empty();
				for (int i=0; i<BarkAsset.VoiceLines.Num(); ++i)
				{
					RuntimeData.ShuffledIndices.Add(i);
				}
				RuntimeData.ShuffledIndices.Shuffle();

				RuntimeData.NextIndex = 0;
				break;

			case EFoghornShuffleType::TrueRandom:
				RuntimeData.UseShuffled = true;
				RuntimeData.NextIndex = FMath::RandRange(0, RuntimeData.ShuffledIndices.Num() - 1);
				break;

			case EFoghornShuffleType::Ordered:
				RuntimeData.NextIndex = 0;
				break;
		}
	}

	void ShuffleList(FFoghornBarkRuntimeData& RuntimeData)
	{
		int BannedStartIndex = RuntimeData.ShuffledIndices.Last();
		RuntimeData.ShuffledIndices.Shuffle();
		if (RuntimeData.ShuffledIndices[0] == BannedStartIndex)
		{
			RuntimeData.ShuffledIndices.Swap(0, FMath::RandRange(1, RuntimeData.ShuffledIndices.Num() - 1));
		}

		RuntimeData.NextIndex = 0;
	}

	int GetNextShuffled(FFoghornBarkRuntimeData& RuntimeData, UFoghornBarkDataAsset BarkAsset)
	{
		int ShuffledIndex = 0;
		if(BarkAsset.ShuffleType == EFoghornShuffleType::PlaylistShuffle)
		{
			ShuffledIndex = RuntimeData.ShuffledIndices[RuntimeData.NextIndex];
			RuntimeData.NextIndex++;

			if (RuntimeData.NextIndex >= RuntimeData.ShuffledIndices.Num())
			{
				ShuffleList(RuntimeData);
				RuntimeData.AllPlayedOnce = true;
			}
		}
		else if(BarkAsset.ShuffleType == EFoghornShuffleType::TrueRandom)
		{
			ShuffledIndex = RuntimeData.NextIndex;

			RuntimeData.NextIndex = FMath::RandRange(0, BarkAsset.VoiceLines.Num() - 2);
			if (RuntimeData.NextIndex >= ShuffledIndex)
				RuntimeData.NextIndex++;
		}

		return ShuffledIndex;
	 }

	AActor GetActorForBark(EFoghornActor Character, AActor ActorOverride)
	{
		AActor Actor = ActorOverride;
		if (Actor == nullptr)
		{
			switch(Character)
			{
				case EFoghornActor::Cody:
					Actor = Game::GetCody();
					break;
				case EFoghornActor::May:
					Actor = Game::GetMay();
					break;
				default:
					PrintError("ActorOverride expected but not set");
					return nullptr;
			}
		}
		return Actor;
	}
}