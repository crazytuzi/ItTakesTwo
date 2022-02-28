import Vino.Movement.Components.GroundPound.GroundpoundedCallbackComponent;
import Vino.Buttons.GroundPoundButton;
import Cake.LevelSpecific.Clockwork.LeaveCloneMechanic.PlayerTimeSequenceComponent;

event void FActivateTheHellTower(AHazePlayerCharacter Player);

class AHellTowerActivationGroundPound : AHazeActor
{
	UPROPERTY()
	FActivateTheHellTower OnActivateTheHellTower;

	UPROPERTY(DefaultComponent)
	UGroundPoundedCallbackComponent GroundPoundComp;

	UPROPERTY()
	TPerPlayer<AGroundPoundButton> ConnectedButton;

	int PoundCount;

	bool bHasBeenActive;

	AHazePlayerCharacter LastPlayer;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GroundPoundComp.OnActorGroundPounded.AddUFunction(this, n"OnPounded");

		ConnectedButton[0].OnButtonGroundPoundStarted.AddUFunction(this, n"OnPounded");
		ConnectedButton[1].OnButtonGroundPoundStarted.AddUFunction(this, n"OnPounded");
		
		ConnectedButton[0].OnButtonReset.AddUFunction(this, n"OnPoundReset");
		ConnectedButton[1].OnButtonReset.AddUFunction(this, n"OnPoundReset");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime) 
	{
		if (PoundCount == 2 && !bHasBeenActive)
		{
			System::SetTimer(this, n"DelayedActivation", 1.f, false);
			ConnectedButton[0].DisableAutomaticReset();
			ConnectedButton[1].DisableAutomaticReset();
			bHasBeenActive = true;			
		}
	}

	UFUNCTION()
	void DelayedActivation()
	{
		OnActivateTheHellTower.Broadcast(LastPlayer);
		DisableActor(this);

		UTimeControlSequenceComponent MayComp = UTimeControlSequenceComponent::Get(Game::May);
		MayComp.DeactiveClone(Game::May);
	}

	UFUNCTION()
	void OnPounded(AHazePlayerCharacter Player)
	{
		if (IsActorDisabled())
			return;

		PoundCount++;

		LastPlayer = Player;

		if (PoundCount > 2)
			PoundCount = 2;
	}

	UFUNCTION()
	void OnPoundReset()
	{
		PoundCount--;

		if (PoundCount < 0)
			PoundCount = 0;
	}

}