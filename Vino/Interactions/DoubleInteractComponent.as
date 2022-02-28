
event void FDoubleInteractTriggered();

enum EDoubleInteractState
{
	NotInteracting,
	WaitingForValidation,
	Interacting
};

/**
 * A double interaction component does nothing on its own,
 * but allows for managing double interacts in network
 * without causing desyncs.
 */
class UDoubleInteractComponent : UActorComponent
{
	/* This event is called when both players have entered the interaction on both sides. */
	UPROPERTY()
	FDoubleInteractTriggered OnTriggered;

	private TPerPlayer<EDoubleInteractState> State(EDoubleInteractState::NotInteracting); 
	private int TriggerCount = 0;

	/* Check whether the player is currently able to cancel the double interact. */
	UFUNCTION()
	bool CanPlayerCancel(AHazePlayerCharacter Player)
	{
		return State[Player] == EDoubleInteractState::Interacting;
	}

	/* Whether the player is currently interacting with this at all. */
	UFUNCTION()
	bool IsPlayerInteracting(AHazePlayerCharacter Player)
	{
		return State[Player] != EDoubleInteractState::NotInteracting;
	}

	/* Indicate that a player wants to start interacting with the double interact. */
	UFUNCTION()
	void StartInteracting(AHazePlayerCharacter Player)
	{
		if (Player.HasControl())
		{
			devEnsure(State[Player] == EDoubleInteractState::NotInteracting, "Player "+Player+" is already interacting with double interact "+Owner.Name+".");
			NetPlayerStartInteracting(Player);
		}
	}

	/**
	 * Indicate that a player wants to cancel interacting with the double interact.
	 * OBS! Don't call this if CanPlayerCancel() returns false, or you will get an error.
	 */
	void CancelInteracting(AHazePlayerCharacter Player)
	{
		// Ignore cancels if the player isn't interacting at all,
		// this just makes some stuff easier (we can cancel after triggering).
		if (State[Player] == EDoubleInteractState::NotInteracting)
			return;

		if (Player.HasControl())
		{
			if (!CanPlayerCancel(Player))
			{
				devEnsure(false, "Player "+Player+" attempted to cancel a double interact on "+Owner.Name+" but CanPlayerCancel is false.");
				return;
			}

			NetPlayerStopInteracting(Player);
		}
	}

	UFUNCTION(NetFunction, NotBlueprintCallable)
	void NetPlayerStartInteracting(AHazePlayerCharacter Player)
	{
		if (!Network::IsNetworked())
		{
			State[Player] = EDoubleInteractState::Interacting;
			if (State[Player.OtherPlayer] != EDoubleInteractState::NotInteracting)
				NetEnforceTrigger(TriggerCount);
		}
		else if (Player.HasControl())
		{
			State[Player] = EDoubleInteractState::WaitingForValidation;
		}
		else
		{
			State[Player] = EDoubleInteractState::Interacting;

			if (State[Player.OtherPlayer] != EDoubleInteractState::NotInteracting)
			{
				// Both players are interacting, trigger this interaction
				NetEnforceTrigger(TriggerCount);
			}
			else
			{
				// Other player isn't interacting yet, send back to allow cancel
				NetAllowCancel(Player);
			}
		}
	}

	UFUNCTION(NetFunction, NotBlueprintCallable)
	void NetPlayerStopInteracting(AHazePlayerCharacter Player)
	{
		State[Player] = EDoubleInteractState::NotInteracting;
	}

	UFUNCTION(NetFunction, NotBlueprintCallable)
	void NetEnforceTrigger(int TriggerNumber)
	{
		if (TriggerCount > TriggerNumber)
			return;

		for (EDoubleInteractState& PlayerState : State)
		{
			if (PlayerState == EDoubleInteractState::NotInteracting)
				devEnsureAlways(false, "Double interact component "+Owner.Name+" detected a desync. Something went hella wrong.");
			PlayerState = EDoubleInteractState::NotInteracting;
		}

		OnTriggered.Broadcast();
		TriggerCount += 1;
	}

	UFUNCTION(NetFunction, NotBlueprintCallable)
	void NetAllowCancel(AHazePlayerCharacter Player)
	{
		State[Player] = EDoubleInteractState::Interacting;
	}
};