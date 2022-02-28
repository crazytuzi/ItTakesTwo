import Vino.Interactions.InteractionComponent;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.LightRoom.LightRoomSpotlight;
import void InitializeLightRoomSpotlight(AHazePlayerCharacter, ALightRoomSpotlight, ALightRoomSpotlightController) from "Cake.LevelSpecific.Music.LevelMechanics.Backstage.LightRoom.LightRoomSpotlightCharacterComponent";
import Vino.Camera.Actors.KeepInViewCameraActor;

event void FControllerWasActivated(AHazePlayerCharacter Player);

class ALightRoomSpotlightController : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh;
	
	// UPROPERTY(DefaultComponent, Attach = Root)
	// UInteractionComponent InteractionComp;

	UPROPERTY(DefaultComponent, Attach = InteractionComp)
	USkeletalMeshComponent PreviewMesh;
	default PreviewMesh.bIsEditorOnly = true;
	default PreviewMesh.bHiddenInGame = true;
	default PreviewMesh.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY()
	ALightRoomSpotlight ConnectedSpotlight;

	UPROPERTY()
	AKeepInViewCameraActor KeepInViewCam;

	UPROPERTY()
	FControllerWasActivated OnControllerWasActivated;

	AHazePlayerCharacter PlayerUsingController;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		//InteractionComp.OnActivated.AddUFunction(this, n"ControllerActivated");
		//ActivateControllerInteraction(false);
	}

	// UFUNCTION()
	// void ActivateControllerInteraction(bool bShouldActivate)
	// {
	// 	if (bShouldActivate)
	// 	{
	// 		for (auto Players : Game::GetPlayers())
	// 			InteractionComp.EnableForPlayer(Players, n"SetActive");
	// 	} else
	// 	{
	// 		for (auto Players : Game::GetPlayers())
	// 			InteractionComp.DisableForPlayer(Players, n"SetActive");
	// 	}
	// }

	// UFUNCTION()
	// void ControllerActivated(UInteractionComponent Component, AHazePlayerCharacter Player)
	// {
	// 	for (auto Players : Game::GetPlayers())
	// 		InteractionComp.DisableForPlayer(Players, n"ControllerActive");
		
	// 	PlayerUsingController = Player;
		
	// 	InitializeLightRoomSpotlight(Player, ConnectedSpotlight, this);
	// 	FHazeCameraBlendSettings Blend;
	// 	KeepInViewCam.ActivateCamera(Player.OtherPlayer, Blend, this);
	// 	Player.OtherPlayer.ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen);
	// 	ConnectedSpotlight.UpdatePlayerToFollow(Player.OtherPlayer);
	// 	OnControllerWasActivated.Broadcast(Player);
	// }

	UFUNCTION()
	void ActivateLightRoomController(AHazePlayerCharacter Player)
	{
		PlayerUsingController = Player;
		
		InitializeLightRoomSpotlight(Player, ConnectedSpotlight, this);
		FHazeCameraBlendSettings Blend;
		KeepInViewCam.ActivateCamera(Player.OtherPlayer, Blend, this);
		Player.OtherPlayer.ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen);
		ConnectedSpotlight.UpdatePlayerToFollow(Player.OtherPlayer);
		OnControllerWasActivated.Broadcast(Player);
	}

	void StopUsingController()
	{
		// for (auto Player : Game::GetPlayers())
		// 	InteractionComp.EnableForPlayer(Player, n"ControllerActive");

		PlayerUsingController.DeactivateCameraByInstigator(this);
		PlayerUsingController = nullptr;
	}
}