import Cake.LevelSpecific.Hopscotch.HomeworkArea.HomeworkChallenge;
import Cake.LevelSpecific.Hopscotch.HomeworkArea.HomeworkMemoryCard;
import Cake.LevelSpecific.Hopscotch.HomeworkArea.HomeworkMemoryBook;

UCLASS(Abstract, HideCategories = "Cooking Replication Input Actor Capability LOD")
class AHomeworkChallengeMemory : AHomeworkChallenge
{
	UPROPERTY()
	TArray<AHomeworkMemoryCard> MemoryCardArray;
	
	TArray<FVector> MemoryLocArray;

	FVector MiddleLocation;
	
	int CardsFlippedCounter;
	int NumberOfFails;
	
	UPROPERTY()
	int MaxTries;
	default MaxTries = 7.f;

	EMemoryFruit FlippedCard01;
	EMemoryFruit FlippedCard02;

	float TimerDelay = 1.5f;

	bool bMemoryChallengeCompleted;
	bool bHasFailedAtLeastOnce = false;

	UPROPERTY()
	AHomeworkMemoryBook HomeworkMemoryBook;

	AHomeworkMemoryCard MemoryCard01;
	AHomeworkMemoryCard MemoryCard02;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AHomeworkChallenge::BeginPlay_Implementation();
		NetSyncMemorycardArray(MemoryCardArray);
		HomeworkMemoryBook.SetNewMaxTries(MaxTries);
	}

	UFUNCTION(NetFunction)
	void NetSyncMemorycardArray(TArray<AHomeworkMemoryCard> NewMemoryCardArray)
	{
		MemoryCardArray = NewMemoryCardArray;
		SetRandomAnimalsOnCards();
		BindFlipCardEvent();
		SetMiddleLocation();
	}

	void BindFlipCardEvent()
	{
		for (AHomeworkMemoryCard Card : MemoryCardArray)
		{
			Card.CardFlippedEvent.AddUFunction(this, n"CardFlippedEvent");
			MemoryLocArray.Add(Card.CardMeshRoot.GetWorldLocation());
		}
	}

	void SetMiddleLocation()
	{
		FVector TempVec;

		for (FVector Vec : MemoryLocArray)
		{
			TempVec += Vec;
		}

		MiddleLocation = TempVec / MemoryLocArray.Num();
	}

	void StartChallenge()
	{
		AHomeworkChallenge::StartChallenge();
		StartIntialFlip();
	}

	UFUNCTION()
	void StartIntialFlip()
	{
		for (AHomeworkMemoryCard Card : MemoryCardArray)
		{
			Card.InitialFlip();
		}
		
		System::SetTimer(this, n"StartShuffle", TimerDelay, false);
	}

	UFUNCTION()
	void UnflipFlippedCards()
	{
		for (AHomeworkMemoryCard Card : MemoryCardArray)
		{
			if (Card.bCardIsFlipped)
			{
				Card.FlipBackCard();
			}
		}

		ReshuffleCards();
	}
	
	UFUNCTION()
	void ReshuffleCards()
	{
		System::SetTimer(this, n"StartShuffle", TimerDelay, false);
	}

	UFUNCTION()
	void StartShuffle()
	{
		float HeightAddition = 0.f;
		for (AHomeworkMemoryCard Card : MemoryCardArray)
		{
			Card.bHasShuffled = false;
			Card.StartLocBeforeShuffle = Card.CardMeshRoot.WorldLocation;
			Card.TargetLocBeforeShuffle = MiddleLocation + FVector(0.f, 0.f, HeightAddition);
			Card.MoveCardsToMiddleTimer();
			
			// Just to avoid Z fighting
			HeightAddition += 0.1f;
		}
		if (HasControl())
		{
			MemoryCardArray.Shuffle();
			NetShuffleArray(MemoryCardArray);
		}
	}

	UFUNCTION(NetFunction)
	void NetShuffleArray(TArray<AHomeworkMemoryCard> CardArrayShuffled)
	{
		MemoryCardArray.Empty();
		
		for (AHomeworkMemoryCard Card : CardArrayShuffled)
		{
			MemoryCardArray.Add(Card);	
		}
		
		System::SetTimer(this, n"StartMovingCards", TimerDelay, false);

	}

	UFUNCTION()
	void StartMovingCards()
	{
		float Delay = 0.05;
		for (int i = 0; i < MemoryCardArray.Num(); i++)
		{
			MemoryCardArray[i].MoveCardDelay = Delay;
			MemoryCardArray[i].bHasShuffled = true;
			MemoryCardArray[i].StartLocAfterShuffle = MiddleLocation;
			MemoryCardArray[i].TargetLocAfterShuffle = MemoryLocArray[i];
			MemoryCardArray[i].MoveCardsAfterShuffleTimer();
			Delay += 0.05f;
		}
		System::SetTimer(this, n"EnableInteractionPoints", TimerDelay, false);
	}

	UFUNCTION()
	void EnableInteractionPoints()
	{
		for (AHomeworkMemoryCard Card : MemoryCardArray)
		{
			Card.SetFlipTargets();	
			Card.SetInteractionPointEnabled(true);
		}
		NumberOfFails = 0;
		
		if (bHasFailedAtLeastOnce)
			HomeworkMemoryBook.UpdateTries(NumberOfFails);
	}

	UFUNCTION()
	void CardFlippedEvent(EMemoryFruit Animal, AHomeworkMemoryCard MemoryCard)
	{

		if (CardsFlippedCounter < 2)
		{
			switch (CardsFlippedCounter)
			{
				case 0:
				FlippedCard01 = Animal;
				MemoryCard01 = MemoryCard;
				break;

				case 1:
				FlippedCard02 = Animal;
				MemoryCard02 = MemoryCard;
				break;
			}

			CardsFlippedCounter++;

			if (CardsFlippedCounter == 2)
			{
				for (AHomeworkMemoryCard Card : MemoryCardArray)
				{
					Card.SetInteractionPointEnabled(false);
				}

				if (FlippedCard01 == FlippedCard02)
				{
					MemoryCardArray.Remove(MemoryCard01);
					MemoryCardArray.Remove(MemoryCard02);
					MemoryCard01 = nullptr;
					MemoryCard02 = nullptr;
					System::SetTimer(this, n"FlipBackCards", 1.f, false);
					CardsFlippedCounter = 0;
					HomeworkMemoryBook.AudioRightAnswer();
				} else 
				{
					NumberOfFails++;
					HomeworkMemoryBook.UpdateTries(NumberOfFails);
					HomeworkMemoryBook.AudioWrongAnswer();
					System::SetTimer(this, n"FlipBackCards", 1.f, false);
					CardsFlippedCounter = 0;
				}
			}
		}
	}

	UFUNCTION()
	void FlipBackCards()
	{
		if (MemoryCard01 != nullptr)
			MemoryCard01.FlipBackCard();
		
		if(MemoryCard02 != nullptr)
			MemoryCard02.FlipBackCard();

		CheckIfChallengeIsCompleted();

		if (NumberOfFails == MaxTries && !bMemoryChallengeCompleted)
		{
			MemoryCardArray.Empty();
			GetAllActorsOfClass(MemoryCardArray);
			UnflipFlippedCards();
			FailedChallenge();
			bHasFailedAtLeastOnce = true;
		}

		if (NumberOfFails < MaxTries)
		{
			for (AHomeworkMemoryCard Card : MemoryCardArray)
			{
				Card.SetInteractionPointEnabled(true);
			}
		}
	}

	UFUNCTION()
	void CheckIfChallengeIsCompleted()
	{
		if (MemoryCardArray.Num() == 0 && HasControl())
		{
			NetCheckIfChallengeIsCompleted();
			HomeworkMemoryBook.AudioFinalSuccess();
		}
	}

	UFUNCTION(NetFunction)
	void NetCheckIfChallengeIsCompleted()
	{
		ChallengeCompleted.Broadcast(this);
		bMemoryChallengeCompleted = true;
	}

	void SetRandomAnimalsOnCards()
	{
		for (int i = 0; i < MemoryCardArray.Num(); i++)
		{
			switch (i)
			{
				case 0:
				MemoryCardArray[i].SetAnimal(EMemoryFruit::Banana);
				break;

				case 1:
				MemoryCardArray[i].SetAnimal(EMemoryFruit::Banana);
				break;

				case 2:
				MemoryCardArray[i].SetAnimal(EMemoryFruit::Cherry);
				break;

				case 3:
				MemoryCardArray[i].SetAnimal(EMemoryFruit::Cherry);
				break;

				case 4:
				MemoryCardArray[i].SetAnimal(EMemoryFruit::Eggplant);
				break;

				case 5:
				MemoryCardArray[i].SetAnimal(EMemoryFruit::Eggplant);
				break;

				case 6:
				MemoryCardArray[i].SetAnimal(EMemoryFruit::Orange);
				break;
				
				case 7:
				MemoryCardArray[i].SetAnimal(EMemoryFruit::Orange);
				break;

				case 8:
				MemoryCardArray[i].SetAnimal(EMemoryFruit::Pear);
				break;

				case 9:
				MemoryCardArray[i].SetAnimal(EMemoryFruit::Pear);
				break;

				case 10:
				MemoryCardArray[i].SetAnimal(EMemoryFruit::Strawberry);
				break;

				case 11:
				MemoryCardArray[i].SetAnimal(EMemoryFruit::Strawberry);
				break;
			}
		}
	}
}