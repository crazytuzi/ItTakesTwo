import Cake.LevelSpecific.SnowGlobe.MagnetHockey.HockeyPuck;
import Cake.LevelSpecific.SnowGlobe.MagnetHockey.HockeyGoals;

event void FHockeyPlayerAdded();
event void FHockeyPlayerRemoved();
event void FHockeyPlayerLeft(AHazePlayerCharacter Player, AHockeyStartingPoint StartingPoint);

class AHockeyStartingPoint : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;
	default MeshComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent InteractComp;

	UPROPERTY(Category = "Mesh Materials")
	UMaterial DefaultMaterial;

	UPROPERTY(Category = "Mesh Materials")
	TPerPlayer<UMaterialInstance> ActivatedMaterial;

	FHockeyPlayerAdded OnPlayerAddedEvent;

	FHockeyPlayerRemoved OnPlayerRemovedEvent;

	FHockeyPlayerLeft OnPlayerLeftEvent;

	TPerPlayer<AHazePlayerCharacter> Players;

	AHazePlayerCharacter ChosenPlayer;

	UPROPERTY(Category = "Setup")
	AHockeyGoals HockeyGoal;

	UPROPERTY(Category = "Setup")
	float StartingRadius = 300.f;

	bool bPlayerAdded;

	bool bCanBeActivated;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Players[0] = Game::GetMay();
		Players[1] = Game::GetCody();

		InteractComp.OnActivated.AddUFunction(this, n"DisableInteractionPoint");

		SetColours(Players[0], false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		DistanceChecking();
	}

	void DistanceChecking()
	{
		if (!bCanBeActivated)
			return;

		// float DistanceMay = (Players[0].ActorLocation - ActorLocation).Size();
		// float DistanceCody = (Players[1].ActorLocation - ActorLocation).Size();

		// if (!bPlayerAdded)
		// {
		// 	if (DistanceMay <= StartingRadius && !bPlayerAdded)
		// 	{
		// 		bPlayerAdded = true;
		// 		// OnPlayerAddedEvent.Broadcast();
		// 		// SetColours(Players[0], true);
		// 		ChosenPlayer = Players[0];
		// 		HockeyGoal.SetPlayerOwner(EHockeyGoalPlayerOwner::May);
		// 	}
		// 	else if (DistanceCody <= StartingRadius && !bPlayerAdded)
		// 	{
		// 		bPlayerAdded = true;
		// 		// OnPlayerAddedEvent.Broadcast();
		// 		// SetColours(Players[1], true);
		// 		ChosenPlayer = Players[1];
		// 		HockeyGoal.SetPlayerOwner(EHockeyGoalPlayerOwner::Cody);
		// 	}
		// }
		// else 
		// {
		// 	if (ChosenPlayer == Game::GetMay())
		// 	{
		// 		if (DistanceMay > StartingRadius && bPlayerAdded)
		// 		{
		// 			bPlayerAdded = false;
		// 			// OnPlayerRemovedEvent.Broadcast();
		// 			SetColours(Players[0], false);
		// 			EnableInteractionPoint();
		// 			OnPlayerLeftEvent.Broadcast(Players[0]);
		// 		}
		// 	}
		// 	else
		// 	{
		// 		if (DistanceCody > StartingRadius && bPlayerAdded)
		// 		{
		// 			bPlayerAdded = false;
		// 			// OnPlayerRemovedEvent.Broadcast();
		// 			SetColours(Players[1], false);
		// 			EnableInteractionPoint();
		// 			OnPlayerLeftEvent.Broadcast(Players[1]);
		// 		}
		// 	}
		// }
	}

	UFUNCTION()
	void SetColours(AHazePlayerCharacter Player, bool bActivated)
	{
		if (bActivated)
		{
			if (Player == Game::GetMay())
				MeshComp.SetMaterial(0, ActivatedMaterial[0]);
			else
				MeshComp.SetMaterial(0, ActivatedMaterial[1]);
		}
		else 
			MeshComp.SetMaterial(0, DefaultMaterial);
	}

	UFUNCTION()
	void SetColoursDefault()
	{
		MeshComp.SetMaterial(0, DefaultMaterial);
	}

	UFUNCTION()
	void DisableInteractionPoint(UInteractionComponent InteractComp, AHazePlayerCharacter Player)
	{
		InteractComp.Disable(n"Hockey Used");
		SetColours(Player, true);
	}

	UFUNCTION()
	void EnableInteractionPoint()
	{
		InteractComp.Enable(n"Hockey Used");
		SetColoursDefault();
	}

	UFUNCTION()
	void ResetSettings()
	{
		bPlayerAdded = false;
	}
}