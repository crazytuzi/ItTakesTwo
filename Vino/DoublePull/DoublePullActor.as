import Vino.DoublePull.DoublePullComponent;
import Vino.Interactions.InteractionComponent;
import Peanuts.Spline.SplineActor;

UCLASS(Abstract)
class ADoublePullActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UDoublePullComponent DoublePull;

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent CodyInteraction;
	default CodyInteraction.MovementSettings.InitializeSmoothTeleport();

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent MayInteraction;
	default MayInteraction.MovementSettings.InitializeSmoothTeleport();

	/* Called whenever a player starts pulling. */
	UPROPERTY()
	FOnEnterDoublePull OnEnterDoublePull;

	/* Called whenever a player stops pulling. */
	UPROPERTY()
	FOnExitDoublePull OnExitDoublePull;

	/* Called when the double pull reaches the end. */
	UPROPERTY()
	FOnCompleteDoublePull OnCompleteDoublePull;

	/* Spline that the double pull actor starts on. */
	UPROPERTY()
	ASplineActor Spline;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CodyInteraction.DisableForPlayer(Game::GetMay(), n"NotForThisPlayer");
		MayInteraction.DisableForPlayer(Game::GetCody(), n"NotForThisPlayer");

		DoublePull.AddTrigger(CodyInteraction);
		DoublePull.AddTrigger(MayInteraction);

		if (Spline != nullptr)
			DoublePull.SwitchToSpline(UHazeSplineComponent::Get(Spline), bTeleportToStart=false);

		AddCapability(n"DoublePullSplineCapability");

		DoublePull.OnEnterDoublePull.AddUFunction(this, n"TriggerEnterDoublePull");
		DoublePull.OnExitDoublePull.AddUFunction(this, n"TriggerExitDoublePull");
		DoublePull.OnCompleteDoublePull.AddUFunction(this, n"TriggerCompleteDoublePull");
	}

	UFUNCTION()
	void ResetDoublePull()
	{
		DoublePull.ResetDoublePull();
	}

	UFUNCTION()
	void SwitchToSpline(ASplineActor NewSpline, bool bTeleportToStart = false)
	{
		DoublePull.SwitchToSpline(UHazeSplineComponent::Get(NewSpline), bTeleportToStart);
	}

	UFUNCTION()
	void RemoveFromSpline()
	{
		DoublePull.Spline = nullptr;
	}

	UFUNCTION()
	void EnterDoublePull(AHazePlayerCharacter Player)
	{
		auto Trigger = Player.IsCody() ? CodyInteraction : MayInteraction;
		DoublePull.EnterDoublePull(Trigger, Player);
	}

	UFUNCTION()
	void ExitDoublePull(AHazePlayerCharacter Player)
	{
		DoublePull.ExitDoublePull(Player);
	}

	UFUNCTION(NotBlueprintCallable)
	void TriggerEnterDoublePull(AHazePlayerCharacter Player)
	{
		OnEnterDoublePull.Broadcast(Player);
	}

	UFUNCTION(NotBlueprintCallable)
	void TriggerExitDoublePull(AHazePlayerCharacter Player)
	{
		OnExitDoublePull.Broadcast(Player);
	}

	UFUNCTION(NotBlueprintCallable)
	void TriggerCompleteDoublePull()
	{
		OnCompleteDoublePull.Broadcast();
	}
}