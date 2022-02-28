import Cake.LevelSpecific.Music.NightClub.DJVinylPlayer;
import Peanuts.Pendulum.PendulumComponent;

class ADJStandPendulum : ADJVinylPlayer
{
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UPendulumComponent PendulumComponent;

	default ProgressMultiplier = 0.8f;

	UPROPERTY(Category = Pendulum)
	float PendulumSuccessAmount = 7.0f;
	UPROPERTY(Category = Pendulum, meta = (ClampMin = 0.0))
	float PendulumFailureAmount = 0.25f;

	private int NumInteractingPlayers = 0;

	void PendulumBegin(AHazePlayerCharacter Player)
	{
		PendulumComponent.StartPendulum();
	}

	void PendulumEnd(AHazePlayerCharacter Player)
	{
		PendulumComponent.StopPendulum();
		PendulumComponent.RemovePlayer(Player);
	}

	void OnDJStandStart()
	{
		Super::OnDJStandStart();
		PendulumComponent.StartPendulum();
	}

	void OnDJStandFailure()
	{
		PendulumComponent.StopPendulum();
		Super::OnDJStandFailure();
	}

	void OnDJStandSuccess()
	{
		PendulumComponent.StopPendulum();
		Super::OnDJStandSuccess();
	}

	void OnPlayerInteractionBegin(AHazePlayerCharacter Player)
	{
		Super::OnPlayerInteractionBegin(Player);
		PendulumComponent.AddPlayer(Player);
		PendulumComponent.OnSuccess.AddUFunction(this, n"Handle_PendulumSuccess");
		PendulumComponent.OnFail.AddUFunction(this, n"Handle_PendulumFailure");

		// In this case we are in full-screen and have two widgets so one might be displayed on top of another and it might be the wrong icon, so let's make sure this player is the owner of both widgets
		if(NumInteractingPlayers == 0)
		{
			for(auto Widget : PendulumComponent.Widgets)
			{
				if(Widget.Player != Player)
				{
					Widget.OverrideWidgetPlayer(Player);
				}
			}
		}
		else
		{
			// Now both players are standing on this dj-station, so we want to display the widget with the player that has control.
			if(Network::IsNetworked() && Player.HasControl())
			{
				for(auto Widget : PendulumComponent.Widgets)
				{
					if(Widget.Player != Player)
					{
						Widget.OverrideWidgetPlayer(Player);
					}
				}
			}
		}

		NumInteractingPlayers++;
	}

	void OnPlayerInteractionEnd(AHazePlayerCharacter Player)
	{
		NumInteractingPlayers--;
		PendulumComponent.RemovePlayer(Player);
		PendulumComponent.OnFail.Clear();
		PendulumComponent.OnSuccess.Clear();
		Super::OnPlayerInteractionEnd(Player);

		if(NumInteractingPlayers == 1)
		{
			for(auto Widget : PendulumComponent.Widgets)
			{
				if(Widget.Player == Player)
				{
					Widget.OverrideWidgetPlayer(Player.OtherPlayer);
				}
			}
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void Handle_PendulumSuccess(AHazePlayerCharacter Player)
	{
		AddToProgress(PendulumSuccessAmount);
	}

	UFUNCTION(NotBlueprintCallable)
	void Handle_PendulumFailure(AHazePlayerCharacter Player)
	{
		AddToProgress(-PendulumFailureAmount);
	}
}
