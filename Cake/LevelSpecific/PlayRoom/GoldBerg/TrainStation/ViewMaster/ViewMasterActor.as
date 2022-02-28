import Vino.Interactions.ThreeShotInteraction;
import Vino.Camera.Actors.BallSocketCamera;
class AViewMasterActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;

	UPROPERTY()
	AThreeShotInteraction ThreeShotInteraction;

	UPROPERTY()
	FHazeCameraBlendSettings CameraSettings;

	UPROPERTY()
	ABallSocketCamera Camera;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent ZoomSync;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PlayMovementAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopMovementAudioEvent;

	UPROPERTY()
	AActor Cutie;

	AHazePlayerCharacter Interactingplayer;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ThreeShotInteraction.OnThreeShotActivated.AddUFunction(this, n"StartInteract");
		ThreeShotInteraction.OnEndBlendedIn.AddUFunction(this, n"StopInteract");
	}

	UFUNCTION(NetFunction)
	void NetSetOwningPlayer(AHazePlayerCharacter Player)
	{
		ZoomSync.OverrideControlSide(Player);
	}

	UFUNCTION()
	void StartInteract(AHazePlayerCharacter _Player, AThreeShotInteraction Interaction)
	{
		Interactingplayer = _Player;
		Interactingplayer.SetCapabilityAttributeObject(n"ViewMaster", this);
	}

	UFUNCTION()
	void StopInteract(AHazePlayerCharacter _Player, AThreeShotInteraction Interaction)
	{
		_Player.SetCapabilityAttributeObject(n"ViewMaster", nullptr);
		Interactingplayer = nullptr;
	}
}