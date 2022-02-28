import Peanuts.Triggers.PlayerTrigger;
import Vino.Triggers.VOBarkTriggerComponent;

enum EVOBarkPlayerTriggerType
{
	AnyPlayersInside,				
	BothPlayersInside,				
	OnlyOnePlayerInside,
	BothPlayersOnlyFirstInsideBarks,
	BothPlayersOnlyLastInsideBarks 
}


class AVOBarkPlayerTrigger : APlayerTrigger
{
	default PrimaryActorTick.bStartWithTickEnabled = false;
	default BrushColor = FLinearColor::Teal;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UVOBarkTriggerComponent VOBarkTriggerComponent;

	UPROPERTY(DefaultComponent)
	UBillboardComponent BillboardComponent;
	default BillboardComponent.Sprite = Asset("/Engine/EditorResources/AudioIcons/S_Ambient_Sound_Simple.S_Ambient_Sound_Simple");

	UPROPERTY(Category = "VOBark")
	EVOBarkPlayerTriggerType TriggerType;

	// If set, we will only trigger if a Player is using all of these Capability Tags
	UPROPERTY(Category = "VOBark")
	TArray<FName> CapabilityTags;

	// Class wich decides if an entered Player will trigger
	UPROPERTY(Category = "VOBark")
	TSubclassOf<UHazePlayerCondition> PlayerConditionClass;

	UPROPERTY()
	FPlayerTriggerEvent OnBarkTriggered;

	TArray<AHazePlayerCharacter> EnteredPlayers;

	TArray<AHazePlayerCharacter> ValidPlayers;

	UHazePlayerCondition PlayerCondition;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		VOBarkTriggerComponent.bTriggerLocally = bTriggerLocally;

		OnPlayerEnter.AddUFunction(this, n"PlayerEnter");
		OnPlayerLeave.AddUFunction(this, n"PlayerLeave");
		VOBarkTriggerComponent.OnVOBarkTriggered.AddUFunction(this, n"BarkTriggered");
	
		if (PlayerConditionClass.IsValid())
			PlayerCondition = Cast<UHazePlayerCondition>(NewObject(this, PlayerConditionClass));

		Super::BeginPlay();
	}

	UFUNCTION(NotBlueprintCallable)
	void PlayerEnter(AHazePlayerCharacter Player)
	{
		EnteredPlayers.AddUnique(Player);

		if (CapabilityTags.Num() > 0 || PlayerCondition != nullptr)
			SetActorTickEnabled(true);
		else
			EnterValid(Player);
	}

	UFUNCTION(NotBlueprintCallable)
	void PlayerLeave(AHazePlayerCharacter Player)
	{
		EnteredPlayers.Remove(Player);

		if (ValidPlayers.Contains(Player))
			LeaveValid(Player);

		if (EnteredPlayers.Num() == 0)
			SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		for (auto Player : EnteredPlayers)
		{
			bool bConditionValid = MeetPlayerConditions(Player);

			if (bConditionValid && !ValidPlayers.Contains(Player))
				EnterValid(Player);
			else if (!bConditionValid && ValidPlayers.Contains(Player))
				LeaveValid(Player);
		}
	}

	bool MeetPlayerConditions(AHazePlayerCharacter Player)
	{
		if (PlayerCondition != nullptr && !PlayerCondition.MeetCondition(Player))
			return false;

		for (auto CapabilityTag : CapabilityTags)
		{
			if (!Player.IsAnyCapabilityActive(CapabilityTag))
				return false;
		}
	
		return true;
	}

	UFUNCTION(NotBlueprintCallable)
	void EnterValid(AHazePlayerCharacter Player)
	{
		ValidPlayers.AddUnique(Player);

		// VOBark triggering is networked by VOBarkTriggerComponent
		switch (TriggerType)
		{
			case EVOBarkPlayerTriggerType::AnyPlayersInside:
			{
				if (ValidPlayers.Num() == 1)
					VOBarkTriggerComponent.SetBarker(Player);

				VOBarkTriggerComponent.OnStarted();

				break;
			}
			case EVOBarkPlayerTriggerType::BothPlayersInside:
			{
				if (ValidPlayers.Num() == 1)
					VOBarkTriggerComponent.SetBarker(Player, true);
				else
					VOBarkTriggerComponent.OnStarted();

				break;
			}
			case EVOBarkPlayerTriggerType::BothPlayersOnlyFirstInsideBarks:
			{
				if (ValidPlayers.Num() == 1)
					VOBarkTriggerComponent.SetBarker(Player);
				else
					VOBarkTriggerComponent.OnStarted();

				break;
			}
			case EVOBarkPlayerTriggerType::BothPlayersOnlyLastInsideBarks:
			{
				VOBarkTriggerComponent.SetBarker(Player);
				if (ValidPlayers.Num() > 1)
					VOBarkTriggerComponent.OnStarted();
				break;
			}
			case EVOBarkPlayerTriggerType::OnlyOnePlayerInside:
			{
				if (ValidPlayers.Num() == 1)
				{
					VOBarkTriggerComponent.SetBarker(Player);
					VOBarkTriggerComponent.OnStarted();
				}
				else
					VOBarkTriggerComponent.OnEnded();

				break;
			}
		}

	}

	UFUNCTION(NotBlueprintCallable)
	void LeaveValid(AHazePlayerCharacter Player)
	{
		ValidPlayers.Remove(Player);

		// VOBark triggering is networked by VOBarkTriggerComponent
		switch (TriggerType)
		{
			case EVOBarkPlayerTriggerType::AnyPlayersInside:
			{
				if (ValidPlayers.Num() == 0)
					VOBarkTriggerComponent.OnEnded();
				else
					VOBarkTriggerComponent.SetBarker(ValidPlayers[0]);	

				break;
			}
			case EVOBarkPlayerTriggerType::BothPlayersInside:
			{
				VOBarkTriggerComponent.OnEnded();
		
				if (ValidPlayers.Num() > 0)
					VOBarkTriggerComponent.SetBarker(ValidPlayers[0], true);
					
				break;
			}
			case EVOBarkPlayerTriggerType::BothPlayersOnlyFirstInsideBarks:
			case EVOBarkPlayerTriggerType::BothPlayersOnlyLastInsideBarks:
			{
				VOBarkTriggerComponent.OnEnded();
		
				if (ValidPlayers.Num() > 0)
					VOBarkTriggerComponent.SetBarker(ValidPlayers[0]);
					
				break;
			}
			case EVOBarkPlayerTriggerType::OnlyOnePlayerInside:
			{
				if (ValidPlayers.Num() == 1)
				{
					VOBarkTriggerComponent.SetBarker(ValidPlayers[0]);
					VOBarkTriggerComponent.OnStarted();
				}
				else
					VOBarkTriggerComponent.OnEnded();

				break;
			}
		}
		
	}

	UFUNCTION(NotBlueprintCallable)
	void BarkTriggered(AHazeActor Actor)
	{
		OnBarkTriggered.Broadcast(Cast<AHazePlayerCharacter>(Actor));
	}

}