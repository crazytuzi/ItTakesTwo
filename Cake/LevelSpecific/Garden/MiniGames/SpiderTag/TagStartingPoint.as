import Vino.Interactions.InteractionComponent;
import Cake.LevelSpecific.Garden.MiniGames.SpiderTag.TagCancelComp;


enum ETagTargetPlayer
{
	May,
	Cody
};

event void FPlayerCancelled(UInteractionComponent InteractComp, AHazePlayerCharacter Player, ATagStartingPoint TagStartingPoint);

class ATagStartingPoint : AHazeActor
{
	FPlayerCancelled OnPlayerCancelledEvent;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;
	default MeshComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent InteractionComp;

	UPROPERTY(Category = "Mesh Materials")
	UMaterial DefaultMaterial;

	UPROPERTY(Category = "Mesh Materials")
	TPerPlayer<UMaterial> ActivatedMaterial;

	UPROPERTY(Category = "Capability")
	UHazeCapabilitySheet CapabilitySheet;

	UPROPERTY(meta = (MakeEditWidget), Category = "TeleportLocation")
	FVector TeleportLocation;
	
	FVector WorldLocation;

	UPROPERTY(Category = "TeleportLocation")
	FRotator FacingRotation; 

	UPROPERTY(Category = "Setup")
	ETagTargetPlayer TagTargetPlayer;

	TPerPlayer<AHazePlayerCharacter> Players;

	AHazePlayerCharacter ChosenPlayer;

	UPROPERTY(Category = "Setup")
	float StartingRadius = 300.f;

	bool bPlayerAdded;

	bool bCanBeActivated;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Players[0] = Game::GetMay();
		Players[1] = Game::GetCody();

		InteractionComp.OnActivated.AddUFunction(this, n"OnInteractionActivated");

		WorldLocation = RootComponent.RelativeTransform.TransformPosition(TeleportLocation);
		FacingRotation = FRotator::MakeFromX(ActorForwardVector);
		
		//*** DISABLED FOR UXR ***//
		// InteractionComp.DisableForPlayer(Game::Cody, n"TagInteraction");
		// InteractionComp.DisableForPlayer(Game::May, n"TagInteraction");

		if (TagTargetPlayer == ETagTargetPlayer::May)
			InteractionComp.DisableForPlayer(Game::Cody, n"TagInteraction");
		else 
			InteractionComp.DisableForPlayer(Game::May, n"TagInteraction");
	}

	UFUNCTION()
	void RemoveStartPointCapabilities()
	{
		ChosenPlayer.RemoveCapabilitySheet(CapabilitySheet);
	}	

	UFUNCTION()
	void OnInteractionActivated(UInteractionComponent InteractComp, AHazePlayerCharacter Player)
	{
		Player.AddCapabilitySheet(CapabilitySheet);

		ChosenPlayer = Player;

		UTagCancelComp CancelComp = UTagCancelComp::Get(Player);

		if (CancelComp == nullptr)
			return;

		CancelComp.TagStartingPointObj = this;
		CancelComp.bCanCancel = true;

		Print("INTERACTED");
	}

	UFUNCTION()
	void OnCancelInteraction(UInteractionComponent InteractComp, AHazePlayerCharacter Player)
	{
		OnPlayerCancelledEvent.Broadcast(InteractComp, Player, this);
	}

	UFUNCTION()
	void TeleportInteractingPlayer()
	{
		ChosenPlayer.TeleportActor(WorldLocation, FacingRotation);
	}
}