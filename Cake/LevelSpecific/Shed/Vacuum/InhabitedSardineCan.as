import Peanuts.Triggers.PlayerTrigger;
import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackGlobalBindFunctions;
import Vino.Movement.Components.GroundPound.GroundpoundedCallbackComponent;
import Vino.Movement.Components.GroundPound.GroundPoundThroughComponent;
import Vino.Movement.Components.MovementComponent;
import Vino.Movement.Capabilities.GroundPound.CharacterGroundPoundStatics;

class AInhabitedSardineCan : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent CanMesh;

	UPROPERTY(DefaultComponent, Attach = CanMesh)
	UStaticMeshComponent MonsterMesh;

	UPROPERTY(DefaultComponent)
	UGroundPoundThroughComponent GroundPoundThroughComp;

	UPROPERTY()
	APlayerTrigger Trigger;

	TArray<AHazePlayerCharacter> PlayersOnCan;
	TArray<AHazePlayerCharacter> NearbyPlayers;

	UPROPERTY(BlueprintReadOnly)
	bool bShouldJump = false;

	UPROPERTY(BlueprintReadOnly)
	bool bFlipping = false;

	UPROPERTY(BlueprintReadOnly)
	FVector GroundLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Trigger.OnPlayerEnter.AddUFunction(this, n"Hide");
		Trigger.OnPlayerLeave.AddUFunction(this, n"Reveal");

		FActorImpactedByPlayerDelegate ImpactDelegate;
		ImpactDelegate.BindUFunction(this, n"PlayerLanded");
		BindOnDownImpactedByPlayer(this, ImpactDelegate);

		FActorNoLongerImpactingByPlayerDelegate NoImpactDelegate;
		NoImpactDelegate.BindUFunction(this, n"PlayerLeft");
		BindOnDownImpactEndedByPlayer(this, NoImpactDelegate);

		FGroundPoundedThroughDelegate GroundPoundDelegate;
		GroundPoundDelegate.BindUFunction(this, n"GroundPounded");
		BindOnActorGroundPoundedThrough(this, GroundPoundDelegate);

		GroundLocation = CanMesh.WorldLocation;
	}

	UFUNCTION(NotBlueprintCallable)
	void Hide(AHazePlayerCharacter Player)
	{
		NearbyPlayers.AddUnique(Player);
		BP_Hide();
	}

	UFUNCTION(NotBlueprintCallable)
	void Reveal(AHazePlayerCharacter Player)
	{
		NearbyPlayers.Remove(Player);
		if (NearbyPlayers.Num() == 0)
			BP_Reveal();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Hide() {}

	UFUNCTION(BlueprintEvent)
	void BP_Reveal() {}

	UFUNCTION(NotBlueprintCallable)
	void PlayerLanded(AHazePlayerCharacter Player, FHitResult Hit)
	{
		if (PlayersOnCan.Contains(Player))
			return;

		bShouldJump = true;
		PlayersOnCan.Add(Player);
		if (PlayersOnCan.Num() == 1)
			BP_StartJumping();
	}

	UFUNCTION(BlueprintEvent)
	void BP_StartJumping() {}

	UFUNCTION(NotBlueprintCallable)
	void PlayerLeft(AHazePlayerCharacter Player)
	{
		if (!PlayersOnCan.Contains(Player))
			return;

		PlayersOnCan.Remove(Player);

		if (PlayersOnCan.Num() == 0)
			bShouldJump = false;
	}

	UFUNCTION(NotBlueprintCallable)
	void GroundPounded(AHazePlayerCharacter Player)
	{
		if (bFlipping)
			return;
		
		bShouldJump = false;
		bFlipping = true;
		BP_GroundPounded();
		CanMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);

		LockPlayerInGroundPoundLand(Player);

		UHazeMovementComponent MoveComp = UHazeMovementComponent::Get(Player);
		if (MoveComp != nullptr)
		{
			MoveComp.StopIgnoringActor(this);
		}
	}

	UFUNCTION(BlueprintEvent)
	void BP_GroundPounded() {}

	UFUNCTION()
	void FlipCompleted()
	{
		bFlipping = false;
		CanMesh.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);

		for (auto Player : Game::GetPlayers())
			UnlockPlayerInGroundPoundLand(Player);
	}
}
