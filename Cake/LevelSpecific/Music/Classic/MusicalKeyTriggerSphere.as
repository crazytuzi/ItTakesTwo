import Cake.LevelSpecific.Music.Classic.MusicKeyComponent;
import Cake.LevelSpecific.Music.Classic.MusicalFollowerKey;

class UMusicalKeyTriggerDummyComponent : UActorComponent{}

#if EDITOR

class UMusicalKeyTriggerComponentVisualizer : UHazeScriptComponentVisualizer
{
    default VisualizedClass = UMusicalKeyTriggerDummyComponent::StaticClass();

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
        UMusicalKeyTriggerDummyComponent Comp = Cast<UMusicalKeyTriggerDummyComponent>(Component);
        if (!ensure((Comp != nullptr) && (Comp.GetOwner() != nullptr)))
			return;

		AMusicalKeyTriggerSphere Trigger = Cast<AMusicalKeyTriggerSphere>(Comp.Owner);

		DrawWireSphere(Trigger.ActorLocation, Trigger.TriggerRadius, FLinearColor::Green, 3.0f);

		for(AMusicalKeyDestination Destination : Trigger.KeyDestinations)
		{
			if(Destination == nullptr)
				continue;

			DrawDashedLine(Trigger.ActorLocation, Destination.ActorLocation, FLinearColor::Red, 20.0f);
		}
    }
}

#endif // EDITOR

/*
	Checking if a player that is within the given radius controls a valid key.
*/

event void FOnPlayerPossessMusicalKey(AHazePlayerCharacter Player, AMusicalFollowerKey Key);
event void FMusicKeyTriggerSignature();

class AMusicalKeyTriggerSphere : AHazeActor
{
#if !TEST
	default PrimaryActorTick.bStartWithTickEnabled = false;
	default SetActorTickInterval(0.25f);
#endif // !TEST

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, NotEditable)
	UMusicalKeyTriggerDummyComponent VisualaizerDmmmy;
	default VisualaizerDmmmy.bIsEditorOnly = true;

	UPROPERTY()
	FMusicKeyTriggerSignature OnUnlocked;

	UPROPERTY()
	TSet<AMusicalKeyDestination> KeyDestinations;

	private TSet<AMusicalFollowerKey> UsedKeys;

	// Cached list used to get keys from player key component
	private TArray<AMusicalFollowerKey> KeyList;

	UPROPERTY()
	FOnPlayerPossessMusicalKey OnPlayerPossessKey;

	UPROPERTY()
	float TriggerRadius = 700.0f;

	UPROPERTY(Category = Debug)
	bool bDrawRadius = false;

	TArray<AHazePlayerCharacter> PlayerList;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlayerList.Add(Game::GetMay());
		PlayerList.Add(Game::GetCody());

#if !TEST
		if(HasControl())
#endif // !TEST
			SetActorTickEnabled(true);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
#if TEST
		if(bDrawRadius)
		{
			System::DrawDebugSphere(ActorLocation, TriggerRadius, 12, FLinearColor::Green, 0.0f, 5.0f);
		}

		if(!HasControl())
			return;
#endif // TEST

		KeyList.Reset();
		for(AHazePlayerCharacter Player : PlayerList)
		{
			if(Player.ActorCenterLocation.DistSquared(ActorLocation) < FMath::Square(TriggerRadius))
			{
				UMusicKeyComponent KeyComp = UMusicKeyComponent::Get(Player);

				if(KeyComp != nullptr && KeyComp.HasKey())
				{
					KeyComp.GetAllKeys(KeyList);

					for(AMusicalFollowerKey Key : KeyList)
					{
						if(IsKeyValid(Key) && HasFreeSlots())
						{
							NetHandlePlayerPossessKey(Player, Key);
						}
					}
				}
			}
		}
	}

	bool HasFreeSlots() const
	{
		return KeyDestinations.Num() > 0;
	}

	bool IsKeyValid(AMusicalFollowerKey Key) const
	{
		return !UsedKeys.Contains(Key);
	}

	UFUNCTION(NetFunction)
	void NetHandlePlayerPossessKey(AHazePlayerCharacter Player, AMusicalFollowerKey Key)
	{
		UsedKeys.Add(Key);
		Key.bIsUsed = true;
		Key.ClearFollowTarget_Local();
		
		AMusicalKeyDestination Destination = FreeKeyDestination;
		Key.TargetLocationActor = Destination;
		KeyDestinations.Remove(Destination);
		Key.MusicKeyState = EMusicalKeyState::GoToLocation;
		Key.MoveToTargetLocation();
		
		OnPlayerPossessKey.Broadcast(Player, Key);

		if(!HasFreeSlots())
		{
			SetActorTickEnabled(false);
			OnUnlocked.Broadcast();
		}
	}

	private AMusicalKeyDestination GetFreeKeyDestination() const property
	{
		for(AMusicalKeyDestination Destination : KeyDestinations)
		{
			return Destination;
		}

		return nullptr;
	}

	UFUNCTION()
	private void Handle_OnDestinationReached()
	{

	}
}
