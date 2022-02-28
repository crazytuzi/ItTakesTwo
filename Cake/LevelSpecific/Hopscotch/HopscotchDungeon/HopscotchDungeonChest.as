import Vino.Interactions.DoubleInteractionActor;
class AHopscotchDungeonChest : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase ChestMesh;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USceneComponent LeftSpinnerRoot;
	
	UPROPERTY(DefaultComponent, Attach = LeftSpinnerRoot)
	UStaticMeshComponent LeftSpinner;

	UPROPERTY(DefaultComponent, Attach = LeftSpinnerRoot)
	UStaticMeshComponent LeftSpinnerCenter;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USceneComponent RightSpinnerRoot;

	UPROPERTY(DefaultComponent, Attach = RightSpinnerRoot)
	UStaticMeshComponent RightSpinner;

	UPROPERTY(DefaultComponent, Attach = RightSpinnerRoot)
	UStaticMeshComponent RightSpinnerCenter;

	UPROPERTY()
	ADoubleInteractionActor ConnectedDoubleInteract;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ConnectedDoubleInteract.OnDoubleInteractionCompleted.AddUFunction(this, n"Interacted");
	}

	UFUNCTION()
	void Interacted()
	{
		OpenChest();
		ConnectedDoubleInteract.Disable(n"ChestOpened");
	}

	UFUNCTION()
	void DisableChest()
	{
		ConnectedDoubleInteract.Disable(n"StartDisabled");
	}

	UFUNCTION()
	void SetChestToOpenState()
	{
		DisableChest();
		HideFidgetSpinners();
	}

	UFUNCTION()
	void OpenChest()
	{

	}

	UFUNCTION()
	void HideFidgetSpinners()
	{
		RightSpinner.SetHiddenInGame(true);
		LeftSpinner.SetHiddenInGame(true);
		RightSpinnerCenter.SetHiddenInGame(true);
		LeftSpinnerCenter.SetHiddenInGame(true);
	}
}